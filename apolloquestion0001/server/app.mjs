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
type Thing1 {
  id: ID!
  description: String!
}

type Thing2 {
  id: ID!
  description: String!
}

type Query {
  _dummy: String
}

type Subscription {
  thing1Subscription: Thing1!
  thing2Subscription: Thing2!
}

`;

const resolvers = {
  Subscription: {
    thing1Subscription: {
      subscribe: () => pubsub.asyncIterator(['Thing1']),
    },
    thing2Subscription: {
      subscribe: () => pubsub.asyncIterator(['Thing2']),
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

var timerCount = 0
setInterval(() => {
  timerCount += 1
  pubsub.publish('Thing1', {
    thing1Subscription: {
      id: "Thing1_" + timerCount,
      description: "Created via thing1Subscription"
    }
  });
  pubsub.publish('Thing2', {
    thing2Subscription: {
      id: "Thing2_" + timerCount,
      description: "Created via thing2Subscription"
    }
  });
}, 1);
