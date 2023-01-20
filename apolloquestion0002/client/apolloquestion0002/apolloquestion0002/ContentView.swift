// If the connect/disconnect is toggled at a fast enough pace, eventually a closure for an operation will be deallocated without ever being run
// See "SET A BREAKPOINT HERE TO SEE THE PROBLEM" below...

import SwiftUI

import Apollo
import ApolloAPI
import ApolloWebSocket
import SwiftCodeGeneratedByApollo

class AppController: ObservableObject, WebSocketTransportDelegate {
    var webSocketTransport: WebSocketTransport?
    var apolloGraphQLConn: ApolloClient?
    @Published var fetchReturnedResult = false
    @Published var mutationReturnedResult = false

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

    func connect (_ wsUrl: URL) {
        print("AppController: connect \(wsUrl)")
        let connInfo = createApolloConnection(wsUrl: wsUrl)
        apolloGraphQLConn = connInfo.client
        webSocketTransport = connInfo.webSocketTransport
    }

    public class ClosureIsGoneDetector {
        public var closureCalled = false
        let infoString: String

        init(_ infoString: String) {
            self.infoString = infoString
        }

        deinit {
            if !closureCalled {
                print("deinit on \(infoString) BUT CLOSURE WAS NOT CALLED")
            }
            else {
                print("deinit on \(infoString) AND CLOSURE WAS CALLED")
            }
        }
    }

    static func ifNotCancelled(_ closure: () -> ()) {
        do {
            try Task.checkCancellation()
            closure()
        }
        catch {
            print("cancelled!")
        }
    }

    @MainActor
    func fetchThingById(thingId: String) async -> Bool {
        var apolloCancellable: Apollo.Cancellable?
        return await withTaskCancellationHandler { [apolloCancellable] in
            apolloCancellable?.cancel()
        } operation: {
            await withCheckedContinuation { theContinuation in
                let closureIsGoneDetector = ClosureIsGoneDetector("fetchThingById")
                Self.ifNotCancelled {
                    apolloCancellable = self.apolloGraphQLConn?.fetch(
                        query: SwiftCodeGeneratedByApollo.ThingByIdQuery(
                            id: thingId)) { result in
                                self.fetchReturnedResult = true
                                closureIsGoneDetector.closureCalled = true
                                theContinuation.resume(returning: true)
                            }
                    // TODO artificially repro the problem apolloCancellable!.cancel()
                }
            }
        }
    }

    @MainActor
    func createThing(thingId: String) async -> Bool{
        var apolloCancellable: Apollo.Cancellable?
        return await withTaskCancellationHandler { [apolloCancellable] in
            apolloCancellable?.cancel()
        } operation: {
            await withCheckedContinuation { theContinuation in
                let closureIsGoneDetector = ClosureIsGoneDetector("createThing")
                Self.ifNotCancelled {
                    apolloCancellable = self.apolloGraphQLConn?.perform(
                        mutation: SwiftCodeGeneratedByApollo.CreateThingMutation(
                            id: thingId)) { result in
                                self.mutationReturnedResult = true
                                closureIsGoneDetector.closureCalled = true
                                theContinuation.resume(returning: true)
                            }
                }
            }
        }
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
            Text("fetchReturnedResult: \(appController.fetchReturnedResult ? "true" : "false")")
            Text("mutationReturnedResult: \(appController.mutationReturnedResult ? "true" : "false")")
            Spacer()
        }
        .onAppear {
            appController.connect(URL(string: "ws://localhost:4000/graphql")!)
            Task {
                await appController.fetchThingById(thingId: "idToFetch")
            }
            Task {
                await appController.createThing(thingId: "idToCreate")
            }
          }
        .padding()
    }
}
