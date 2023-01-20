// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class CreateThingMutation: GraphQLMutation {
  public static let operationName: String = "createThing"
  public static let document: ApolloAPI.DocumentType = .notPersisted(
    definition: .init(
      #"""
      mutation createThing($id: ID!) {
        createThing(id: $id) {
          __typename
          id
          description
        }
      }
      """#
    ))

  public var id: ID

  public init(id: ID) {
    self.id = id
  }

  public var __variables: Variables? { ["id": id] }

  public struct Data: SwiftCodeGeneratedByApollo.SelectionSet {
    public let __data: DataDict
    public init(data: DataDict) { __data = data }

    public static var __parentType: ApolloAPI.ParentType { SwiftCodeGeneratedByApollo.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("createThing", CreateThing.self, arguments: ["id": .variable("id")]),
    ] }

    public var createThing: CreateThing { __data["createThing"] }

    /// CreateThing
    ///
    /// Parent Type: `Thing`
    public struct CreateThing: SwiftCodeGeneratedByApollo.SelectionSet {
      public let __data: DataDict
      public init(data: DataDict) { __data = data }

      public static var __parentType: ApolloAPI.ParentType { SwiftCodeGeneratedByApollo.Objects.Thing }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("id", SwiftCodeGeneratedByApollo.ID.self),
        .field("description", String.self),
      ] }

      public var id: SwiftCodeGeneratedByApollo.ID { __data["id"] }
      public var description: String { __data["description"] }
    }
  }
}
