// RUNNING THE SERVER:
// nvm use v16.14.0
// npm install @apollo/server express graphql cors body-parser apollo-server ws graphql-ws graphql-subscriptions
// node app.mjs

// GENERATING THE IOS PACKAGE AGAINST THE RUNNING SERVER:
// (the output of this is in the repo so there is no need to run it, just here for completeness)
// git clone https://github.com/apollographql/apollo-ios.git
// cd apollo-ios
// make build-cli
// cd ..
// ./apollo-ios/.build/release/apollo-ios-cli fetch-schema --path ./apollo-codegen-config.json
// ./apollo-ios/.build/release/apollo-ios-cli generate --path ./apollo-codegen-config.json
import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@apollo/server/express4';
import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { gql } from 'apollo-server';
import { createServer } from 'http';
import { ApolloServerPluginDrainHttpServer } from '@apollo/server/plugin/drainHttpServer';
import { makeExecutableSchema } from '@graphql-tools/schema';
import { WebSocketServer } from 'ws';
import { useServer } from 'graphql-ws/lib/use/ws';
import { PubSub } from 'graphql-subscriptions';

const pubsub = new PubSub();

const typeDefs = gql`
type Thing {
  id: ID!
  description: String!
}

type Query {
  thingById(id: ID!): Thing!
}

type Mutation {
  createThing(id: ID!): Thing!
}

`;

const resolvers = {
  Mutation: {
    createThing(_, { id }, __) {
      const thing = {
        id,
        description: "Created via createThing mutation"
      }
      return thing;
    },
  },
  Query: {
    thingById: (_, { id }, __) => {
      return {
        id,
        description: "Created as response to query"
      }
    },
  },
};

const schema = makeExecutableSchema({ typeDefs, resolvers });
const app = express();
const httpServer = createServer(app);
const wsServer = new WebSocketServer({
  server: httpServer,
  path: '/graphql',
});
const serverCleanup = useServer({ schema }, wsServer);
const server = new ApolloServer({
  schema,
  plugins: [
    ApolloServerPluginDrainHttpServer({ httpServer }),
    {
      async serverWillStart() {
        return {
          async drainServer() {
            await serverCleanup.dispose();
          },
        };
      },
    },
  ],
});

await server.start();
app.use('/graphql', cors(), bodyParser.json(), expressMiddleware(server));
app.use('/', cors(), bodyParser.json(),
  expressMiddleware(server, {
    context: async ({ req }) => ({ token: req.headers.token }),
  }),
);

const PORT = 4000;
httpServer.listen(PORT, () => {
  console.log(`Server is now running on http://localhost:${PORT}/graphql`);
});

