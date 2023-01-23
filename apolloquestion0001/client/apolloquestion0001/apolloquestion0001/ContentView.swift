import SwiftUI

import Apollo
import ApolloAPI
import ApolloWebSocket
import SwiftCodeGeneratedByApollo

// NB: Code below connects to http://localhost:4000/graphql so the app should be run in the simulator on the same machine where the graphql server is running
// NB: Set breakpoints as indicated by SET BREAKPOINT HERE below to catch the issue in action

class AppController: ObservableObject, WebSocketTransportDelegate {

    enum OperationState {
        case notStarted
        case pending
        case success(String)
        case networkFailure
        case failure
    }

    @Published var showConnect = true
    var webSocketTransport: WebSocketTransport?
    var apolloGraphQLConn: ApolloClient?

    var thing1SubscriptionCancellable: Apollo.Cancellable?
    @Published var thing1SubscriptionState: OperationState = .notStarted

    var thing2SubscriptionCancellable: Apollo.Cancellable?
    @Published var thing2SubscriptionState: OperationState = .notStarted

    func createApolloConnection (wsUrl: URL)
    -> (webSocketTransport: WebSocketTransport, client: ApolloClient?) {

        let request = URLRequest(url: wsUrl)

        let webSocket = ApolloWebSocket.WebSocket(request: request, protocol: .graphql_transport_ws)
        let webSocketTransport = WebSocketTransport(
            websocket: webSocket,
            config: WebSocketTransport.Configuration(
                reconnectionInterval: 2
            )
        )
        webSocketTransport.delegate = self

        let store = ApolloStore()
        let apolloClient = ApolloClient(networkTransport: webSocketTransport, store:store)

        return (webSocketTransport, apolloClient)
    }

    func handleThing1Result(_ result: Result<GraphQLResult<Thing1Subscription.Data>, any Error>) {
        switch result {
            case let .success(graphQLResult):
                //print("AppController: handleThing1Result success \(graphQLResult)")
                thing1SubscriptionState = .success("\(graphQLResult.data?.thing1Subscription.id ?? "nil")")
            case let .failure(e):
                print("AppController: handleThing1Result network error \(e)")
                thing1SubscriptionState = .networkFailure // SET BREAKPOINT HERE
        }
    }

    func handleThing2Result(_ result: Result<GraphQLResult<Thing2Subscription.Data>, any Error>) {
        switch result {
            case let .success(graphQLResult):
                //print("AppController: handleThing2Result success \(graphQLResult)")
                thing2SubscriptionState = .success("\(graphQLResult.data?.thing2Subscription.id ?? "nil")")
            case let .failure(e):
                print("AppController: handleThing2Result network error \(e)")
                thing2SubscriptionState = .networkFailure // SET BREAKPOINT HERE
        }
    }

    func connectAndRunOperations(_ wsUrl: String) {
        //print("AppController: connectAndRunOperations \(wsUrl)")

        thing1SubscriptionState = .pending
        thing2SubscriptionState = .pending
        showConnect = false

        let wsUrl = URL(string: wsUrl)
        let connInfo = createApolloConnection(wsUrl: wsUrl!)
        apolloGraphQLConn = connInfo.client
        webSocketTransport = connInfo.webSocketTransport

        thing1SubscriptionCancellable = apolloGraphQLConn?.subscribe(
            subscription: SwiftCodeGeneratedByApollo.Thing1Subscription()) { result in
                self.handleThing1Result(result)
            }

        thing2SubscriptionCancellable = apolloGraphQLConn?.subscribe(
            subscription: SwiftCodeGeneratedByApollo.Thing2Subscription()) { result in
                self.handleThing2Result(result)
            }

    }

    func cancelThing2Subscription() {
        thing2SubscriptionCancellable?.cancel()
        thing2SubscriptionCancellable = nil
    }

    func cancelOperationsAndDisconnect() {
        thing1SubscriptionCancellable?.cancel()
        thing1SubscriptionCancellable = nil
        thing2SubscriptionCancellable?.cancel()
        thing2SubscriptionCancellable = nil
        webSocketTransport?.closeConnection()
        webSocketTransport = nil
        apolloGraphQLConn = nil
        showConnect = true
    }

    public func webSocketTransportDidConnect(_ webSocketTransport: WebSocketTransport) {
        print("AppController: webSocketTransportDidConnect")
    }

    public func webSocketTransportDidReconnect(_ webSocketTransport: WebSocketTransport) {
        print("AppController: webSocketTransportDidReconnect")
    }

    public func webSocketTransport(_ webSocketTransport: WebSocketTransport, didDisconnectWithError error:Swift.Error?) {
        print("AppController: didDisconnectWithError")
    }

}

struct ContentView: View {
    @StateObject private var appController = AppController()
    var body: some View {
        VStack {
            Spacer()
            Text("Thing1: \(String(describing: appController.thing1SubscriptionState))")
            Text("Thing2: \(String(describing: appController.thing2SubscriptionState))")
            Spacer()
            if appController.showConnect {
                Button("Connect and Run Operations") {
                    appController.connectAndRunOperations("ws://localhost:4000/graphql")
                }
                Text("")
            }
            else {
                VStack {
                    Button("Cancel operations and disconnect") {
                        appController.cancelOperationsAndDisconnect()
                    }
                    Button("Cancel Thing2 subscription") {
                        appController.cancelThing2Subscription()
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
}
