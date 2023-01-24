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

class AppController: ObservableObject {
    @Published var resultString: String? = nil
    @Published var fetchResult: String? = nil
    @Published var performResult: String? = nil

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

    //@MainActor // This *seems* to mitigate the issue - the usage of the main thread *seems* to propagate to the closure following withCheckedContinuation... is this by design or a coincidence?  In any case if all Apollo operations are initiated on the main thread, then no collision on sequence IDs should be possible
    func asyncFetch() async -> String {
        var fetchCancellable: Apollo.Cancellable?
        //print("asyncFetch called on \(Thread.current)")
        return await withTaskCancellationHandler { [fetchCancellable] in
            fetchCancellable?.cancel()
        } operation: {
            return await withCheckedContinuation { continuation in
                print("asyncFetch withCheckedContinuation called on \(Thread.current)")
                let closureIsGoneDetector = ClosureIsGoneDetector("fetchCancellable")
                do {
                    try Task.checkCancellation()
                    fetchCancellable = self.apolloGraphQLConn?.fetch(
                        query: SwiftCodeGeneratedByApollo.ThingByIdQuery(
                            id: "does_not_matter_1")) { result in
                                print("asyncFetch fetch closure called on \(Thread.current)")
                                if !closureIsGoneDetector.closureCalled {
                                    closureIsGoneDetector.closureCalled = true
                                    continuation.resume(returning: "asyncFetch closure called")
                                }
                            }
                }
                catch {}
            }
        }
    }

    //@MainActor // This *seems* to mitigate the issue - the usage of the main thread *seems* to propagate to the closure following withCheckedContinuation... is this by design or a coincidence?  In any case if all Apollo operations are initiated on the main thread, then no collision on sequence IDs should be possible
    func asyncPerform() async -> String {
        var fetchCancellable: Apollo.Cancellable?
        //print("asyncPerform called on \(Thread.current)")
        return await withTaskCancellationHandler { [fetchCancellable] in
            fetchCancellable?.cancel()
        } operation: {
            return await withCheckedContinuation { continuation in
                print("asyncPerform withCheckedContinuation called on \(Thread.current)")
                let closureIsGoneDetector = ClosureIsGoneDetector("fetchCancellable")
                do {
                    try Task.checkCancellation()
                    fetchCancellable = self.apolloGraphQLConn?.perform(
                        mutation: SwiftCodeGeneratedByApollo.CreateThingMutation(
                            id: "does_not_matter_2")) { result in
                                print("asyncPerform perform closure called on \(Thread.current)")
                                if !closureIsGoneDetector.closureCalled {
                                    closureIsGoneDetector.closureCalled = true
                                    continuation.resume(returning: "asyncPerform closure called")
                                }
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

    @MainActor
    func doPerform() async {
        performResult = await asyncPerform()
    }
}

struct ContentView: View {
    @StateObject private var appController = AppController("ws://localhost:4000/graphql")
    var body: some View {
        VStack {
            Spacer()
            if let fetchResult = appController.fetchResult {
                Text("The fetchResult is \(fetchResult)")
            }
            else {
                Text("The fetchResult is nil")
            }
            if let performResult = appController.performResult {
                Text("The performResult is \(performResult)")
            }
            else {
                Text("The performResult is nil")
            }
            Spacer()
        }
        .task {
            await appController.doFetch()
        }
        .task {
            await appController.doPerform()
        }
        .padding()
    }
}
