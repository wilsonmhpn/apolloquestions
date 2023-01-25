import SwiftUI

import Apollo
import ApolloAPI
import ApolloWebSocket
import SwiftCodeGeneratedByApollo

class AppController: ObservableObject {
    @Published var showViewWithTask: Bool = false
    @Published var fetchResult: String? = nil

    var webSocketTransport: WebSocketTransport?
    var apolloGraphQLConn: ApolloClient?

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

        let store = ApolloStore()
        let apolloClient = ApolloClient(networkTransport: webSocketTransport, store:store)

        return (webSocketTransport, apolloClient)
    }

    init (_ wsUrl: String) {
        let wsUrl = URL(string: wsUrl)
        let connInfo = createApolloConnection(wsUrl: wsUrl!)
        apolloGraphQLConn = connInfo.client
        webSocketTransport = connInfo.webSocketTransport
    }

    // TODO: Post this as a question somewhere...
    @MainActor
    func asyncFetch() async -> String {
        var fetchCancellable: Apollo.Cancellable?
        return await withTaskCancellationHandler { [fetchCancellable] in
            fetchCancellable?.cancel() // TODO: This is wrong; fetchCancellable will always be nil.  How to cancel an operation when it can't be created outside of the withCheckedContinuation closure?
        } operation: {
            return await withCheckedContinuation { continuation in
                do {
                    try Task.checkCancellation()
                    fetchCancellable = self.apolloGraphQLConn?.fetch(
                        query: SwiftCodeGeneratedByApollo.ThingByIdQuery(
                            id: "does_not_matter_1")) { result in
                                // Deliberately not resuming the closure; we're going to cancel it
                            }
                }
                catch {}
            }
        }
    }

    @MainActor
    func doFetch() async {
        fetchResult = await asyncFetch()
    }

    func toggleViewWithTask() {
        showViewWithTask = !showViewWithTask
    }
}

struct ContentView: View {
    @StateObject private var appController = AppController("ws://localhost:4000/graphql")
    var body: some View {
        VStack {
            Spacer()
            Button("Toggle view with task") {
                appController.toggleViewWithTask()
            }
            if appController.showViewWithTask {
                Text("Running task")
                    .task {
                        await appController.doFetch()
                    }
            }
            else {
                Text("Task not running")
            }
            Spacer()
        }
        .padding()
    }
}
