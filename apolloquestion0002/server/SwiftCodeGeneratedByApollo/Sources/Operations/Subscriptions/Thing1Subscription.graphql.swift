// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class Thing1Subscription: GraphQLSubscription {
  public static let operationName: String = "thing1Subscription"
  public static let document: ApolloAPI.DocumentType = .notPersisted(
    definition: .init(
      #"""
      subscription thing1Subscription {
        thing1Subscription {
          __typename
          id
          description
        }
      }
      """#
    ))

  public init() {}

  public struct Data: SwiftCodeGeneratedByApollo.SelectionSet {
    public let __data: DataDict
    public init(data: DataDict) { __data = data }

    public static var __parentType: ApolloAPI.ParentType { SwiftCodeGeneratedByApollo.Objects.Subscription }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("thing1Subscription", Thing1Subscription.self),
    ] }

    public var thing1Subscription: Thing1Subscription { __data["thing1Subscription"] }

    /// Thing1Subscription
    ///
    /// Parent Type: `Thing1`
    public struct Thing1Subscription: SwiftCodeGeneratedByApollo.SelectionSet {
      public let __data: DataDict
      public init(data: DataDict) { __data = data }

      public static var __parentType: ApolloAPI.ParentType { SwiftCodeGeneratedByApollo.Objects.Thing1 }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("id", SwiftCodeGeneratedByApollo.ID.self),
        .field("description", String.self),
      ] }

      public var id: SwiftCodeGeneratedByApollo.ID { __data["id"] }
      public var description: String { __data["description"] }
    }
  }
}
