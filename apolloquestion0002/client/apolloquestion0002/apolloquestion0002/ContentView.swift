import SwiftUI

import Apollo
import ApolloAPI
import ApolloWebSocket
import SwiftCodeGeneratedByApollo


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

class AppController: ObservableObject, WebSocketTransportDelegate {

    @Published var showConnect = true
    var webSocketTransport: WebSocketTransport?
    var apolloGraphQLConn: ApolloClient?

    var createThingCancellable: Apollo.Cancellable?
    @Published var createThingState = false

    var fetchThingCancellable: Apollo.Cancellable?
    @Published var fetchThingState = false

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

    func connectAndRunOperations(_ wsUrl: String) {
        //print("AppController: connectAndRunOperations \(wsUrl)")

        showConnect = false

        let wsUrl = URL(string: wsUrl)
        let connInfo = createApolloConnection(wsUrl: wsUrl!)
        apolloGraphQLConn = connInfo.client
        webSocketTransport = connInfo.webSocketTransport

        let closureIsGoneDetector1 = ClosureIsGoneDetector("fetchThingCancellable")
        fetchThingCancellable = self.apolloGraphQLConn?.fetch(
            query: SwiftCodeGeneratedByApollo.ThingByIdQuery(
                id: "does_not_matter_1")) { result in
                    if !closureIsGoneDetector1.closureCalled {
                        closureIsGoneDetector1.closureCalled = true
                    }
                }

        let closureIsGoneDetector2 = ClosureIsGoneDetector("createThingCancellable")
        createThingCancellable = self.apolloGraphQLConn?.perform(
            mutation: SwiftCodeGeneratedByApollo.CreateThingMutation(
                id: "does_not_matter_2")) { result in
                    if !closureIsGoneDetector2.closureCalled {
                        closureIsGoneDetector2.closureCalled = true
                    }
                }

    }

    func cancelOperationsAndDisconnect() {
        createThingState = false
        fetchThingState = false
        createThingCancellable?.cancel()
        createThingCancellable = nil
        fetchThingCancellable?.cancel()
        fetchThingCancellable = nil
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
            Text("createThingState: \(appController.createThingState ? "true" : "false")")
            Text("fetchThingState: \(appController.fetchThingState ? "true" : "false")")
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

