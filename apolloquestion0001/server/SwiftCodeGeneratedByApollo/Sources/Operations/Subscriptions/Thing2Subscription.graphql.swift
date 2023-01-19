// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class Thing2Subscription: GraphQLSubscription {
  public static let operationName: String = "thing2Subscription"
  public static let document: ApolloAPI.DocumentType = .notPersisted(
    definition: .init(
      #"""
      subscription thing2Subscription {
        thing2Subscription {
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
      .field("thing2Subscription", Thing2Subscription.self),
    ] }

    public var thing2Subscription: Thing2Subscription { __data["thing2Subscription"] }

    /// Thing2Subscription
    ///
    /// Parent Type: `Thing2`
    public struct Thing2Subscription: SwiftCodeGeneratedByApollo.SelectionSet {
      public let __data: DataDict
      public init(data: DataDict) { __data = data }

      public static var __parentType: ApolloAPI.ParentType { SwiftCodeGeneratedByApollo.Objects.Thing2 }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("id", SwiftCodeGeneratedByApollo.ID.self),
        .field("description", String.self),
      ] }

      public var id: SwiftCodeGeneratedByApollo.ID { __data["id"] }
      public var description: String { __data["description"] }
    }
  }
}
