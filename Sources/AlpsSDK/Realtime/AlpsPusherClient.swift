import Foundation
import PusherSwift

class AlpsPusherClient {
  private var pusher: Pusher?
  private var conversationChannel: PusherChannel?

  var onMessageReceived: ((Message) -> Void)?
  var onTypingIndicator: ((String) -> Void)?
  var onConversationStatusChanged: ((String) -> Void)?

  func connect(pusherKey: String, cluster: String, conversationId: String) {
    let options = PusherClientOptions(
      host: .cluster(cluster)
    )

    pusher = Pusher(key: pusherKey, options: options)
    pusher?.connection.onConnected = { [weak self] in
      self?.subscribeToConversation(conversationId)
    }

    pusher?.connect()
  }

  private func subscribeToConversation(_ conversationId: String) {
    guard let pusher = pusher else { return }

    let channel = pusher.subscribe("private-conversation-\(conversationId)")
    self.conversationChannel = channel

    channel.bind(eventName: "message:new") { [weak self] data in
      self?.handleNewMessage(data)
    }

    channel.bind(eventName: "client-typing-start") { [weak self] data in
      if let dict = data as? [String: Any],
         let senderName = dict["senderName"] as? String {
        self?.onTypingIndicator?(senderName)
      }
    }

    channel.bind(eventName: "conversation:status-changed") { [weak self] data in
      if let dict = data as? [String: Any],
         let status = dict["status"] as? String {
        self?.onConversationStatusChanged?(status)
      }
    }
  }

  private func handleNewMessage(_ data: Any) {
    guard let dict = data as? [String: Any] else { return }

    do {
      let jsonData = try JSONSerialization.data(withJSONObject: dict)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      let message = try decoder.decode(Message.self, from: jsonData)
      onMessageReceived?(message)
    } catch {
      print("[AlpsPusherClient] Error decoding message: \(error)")
    }
  }

  func disconnect() {
    pusher?.disconnect()
  }
}
