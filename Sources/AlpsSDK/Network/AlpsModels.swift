import Foundation

// MARK: - Widget Data Response

struct WidgetDataResponse: Codable {
  let workspaceId: String
  let categories: [Category]
  let playlists: [Playlist]
  let profile: Profile?
  let teamName: String?
  let teamAvatarUrl: String?
  let widgetColor: String?
  let headerImageUrl: String?
  let welcomeMessage: String?
  let launcherText: String?
  let statusPageUrl: String?
  let pusherKey: String?
  let pusherCluster: String?
  let aiAgent: AIAgent?
  let onlineAgents: [OnlineAgent]?

  enum CodingKeys: String, CodingKey {
    case workspaceId, categories, playlists, profile
    case teamName, teamAvatarUrl, widgetColor, headerImageUrl
    case welcomeMessage, launcherText, statusPageUrl
    case pusherKey, pusherCluster
    case aiAgent, onlineAgents
  }
}

struct Category: Codable, Identifiable {
  let id: String
  let name: String
  let articles: [Article]
}

struct Playlist: Codable, Identifiable {
  let id: String
  let name: String
  let guides: [Guide]
}

struct Article: Codable, Identifiable {
  let id: String
  let title: String
  let description: String?
  let body: String?
  let status: String?
}

struct Guide: Codable, Identifiable {
  let id: String
  let title: String
  let content: String?
  let status: String?
}

struct Profile: Codable {
  let id: String
  let name: String?
}

struct AIAgent: Codable {
  let name: String?
  let profilePictureUrl: String?
}

struct OnlineAgent: Codable {
  let firstName: String?
  let lastName: String?
  let profilePicture: String?
}

// MARK: - Message & Conversation

struct Message: Codable, Identifiable {
  let id: String
  let conversationId: String
  let content: String
  let direction: String
  let senderType: String
  let isNote: Bool?
  let read: Bool?
  let createdAt: String
  let senderName: String?
  let senderProfilePicture: String?
}

struct Conversation: Codable, Identifiable {
  let id: String
  let workspaceId: String
  let status: String
  let customer: Customer
  let lastMessage: Message?
  let lastMessageAt: String?
  let createdAt: String
  let messages: [Message]?
}

struct Customer: Codable {
  let name: String?
  let email: String?
}

struct SendMessageRequest: Codable {
  let widgetKey: String
  let name: String?
  let email: String?
  let message: String
  let conversationId: String?
  let workspaceId: String?
  let sessionId: String?
  let source: String = "mobile-sdk"
  let os: String = "iOS"
  let priority: String = "normal"
}

struct SendMessageResponse: Codable {
  let conversationId: String
  let workspaceId: String
  let message: Message
}

struct CustomerConversationsResponse: Codable {
  let conversations: [ConversationSummary]
}

struct ConversationSummary: Codable, Identifiable {
  let id: String
  let lastMessage: Message?
  let status: String
  let createdAt: String
  let lastMessageAt: String?
}

// MARK: - Search Response

struct SearchResponse: Codable {
  let articles: [Article]?
  let collections: [Collection]?
  let playlists: [Playlist]?
}

struct Collection: Codable, Identifiable {
  let id: String
  let name: String?
}
