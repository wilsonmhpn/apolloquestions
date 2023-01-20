// If the connect/disconnect is toggled at a fast enough pace, eventually a closure for an operation will be deallocated without ever being run
// See "SET A BREAKPOINT HERE TO SEE THE PROBLEM" below...

import SwiftUI

import Apollo
import ApolloAPI
import ApolloWebSocket
import SwiftCodeGeneratedByApollo

class ClosureDeallocDetector {
    let description: String
    public var closureWasRun = false

    init(_ description: String) {
        self.description = description
    }
    deinit {
        if !closureWasRun {
            // SET A BREAKPOINT HERE TO SEE THE PROBLEM
            print("ClosureDeallocDetector: Closure for \(description) was deallocated without being run; anything waiting for success or failure will never know")
        }
    }
}

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

    var fetchCancellable: Apollo.Cancellable?
    @Published var fetchState: OperationState = .notStarted

    var mutationCancellable: Apollo.Cancellable?
    @Published var mutationState: OperationState = .notStarted

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

    func handleFetchResult(_ result: Result<GraphQLResult<ThingByIdQuery.Data>, any Error>) {
        switch result {
            case let .success(graphQLResult):
                print("AppController: handleFetchResult success \(graphQLResult)")
                fetchState = .success("\(graphQLResult.data?.thingById.id ?? "nil")")
            case let .failure(e):
                print("AppController: handleFetchResult network error \(e)")
                fetchState = .networkFailure
        }
    }

    func handleMutationResult(_ result: Result<GraphQLResult<CreateThingMutation.Data>, any Error>) {
        switch result {
            case let .success(graphQLResult):
                print("AppController: handleMutationResult success \(graphQLResult)")
                mutationState = .success("\(graphQLResult.data?.createThing.id ?? "nil")")
            case let .failure(e):
                print("AppController: handleMutationResult network error \(e)")
                mutationState = .networkFailure
        }
    }

    func connectAndRunOperations(_ wsUrl: String) {
        print("AppController: connectAndRunOperations \(wsUrl)")

        fetchState = .pending
        mutationState = .pending
        showConnect = false

        let wsUrl = URL(string: wsUrl)
        let connInfo = createApolloConnection(wsUrl: wsUrl!)
        apolloGraphQLConn = connInfo.client
        webSocketTransport = connInfo.webSocketTransport

        // ID for fetch doesn't matter, server just returns a Thing with that ID
        let fetchClosureDeallocDetector = ClosureDeallocDetector("fetch")
        fetchCancellable = apolloGraphQLConn?.fetch(
            query: SwiftCodeGeneratedByApollo.ThingByIdQuery(
                id: String(UUID().uuidString.prefix(8)))) { result in
                    fetchClosureDeallocDetector.closureWasRun = true
                    self.handleFetchResult(result)
                }

        // ID for mutation doesn't matter, server just returns a Thing with that ID
        let mutationClosureDeallocDetector = ClosureDeallocDetector("mutation")
        mutationCancellable = apolloGraphQLConn?.perform(
            mutation: SwiftCodeGeneratedByApollo.CreateThingMutation(
                id: String(UUID().uuidString.prefix(8)))) { result in
                    mutationClosureDeallocDetector.closureWasRun = true
                    self.handleMutationResult(result)
                }

    }

    func cancelOperationsAndDisconnect() {
        fetchCancellable?.cancel()
        fetchCancellable = nil
        mutationCancellable?.cancel()
        mutationCancellable = nil
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
            Text("Fetch state: \(String(describing: appController.fetchState))")
            Text("Mutation state: \(String(describing: appController.mutationState))")
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
                }
            }
            Spacer()
        }
        .padding()
    }
}
