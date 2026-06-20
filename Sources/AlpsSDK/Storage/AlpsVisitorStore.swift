import Foundation

class AlpsVisitorStore {
  private static let defaults = UserDefaults.standard

  static func save(config: AlpsConfig) {
    let key = "alps-visitor-\(config.widgetKey)"
    let data = [
      "name": config.visitorName ?? "",
      "email": config.visitorEmail ?? "",
      "conversationId": config.conversationId ?? "",
      "visitorId": config.visitorId,
    ] as [String: Any]

    defaults.setValue(data, forKey: key)
  }

  static func load(widgetKey: String) -> (name: String?, email: String?, conversationId: String?)? {
    let key = "alps-visitor-\(widgetKey)"
    guard let data = defaults.dictionary(forKey: key) else { return nil }

    let name = (data["name"] as? String)?.isEmpty == false ? (data["name"] as? String) : nil
    let email = (data["email"] as? String)?.isEmpty == false ? (data["email"] as? String) : nil
    let conversationId = (data["conversationId"] as? String)?.isEmpty == false ? (data["conversationId"] as? String) : nil

    return (name, email, conversationId)
  }

  static func getVisitorId(for widgetKey: String) -> String? {
    let key = "alps-visitor-\(widgetKey)"
    guard let data = defaults.dictionary(forKey: key) else { return nil }
    return data["visitorId"] as? String
  }

  static func saveConversationId(_ conversationId: String, for widgetKey: String) {
    let key = "alps-conv-\(widgetKey)"
    defaults.setValue(conversationId, forKey: key)
  }

  static func getConversationId(for widgetKey: String) -> String? {
    let key = "alps-conv-\(widgetKey)"
    return defaults.string(forKey: key)
  }

  static func clear() {
    let domain = Bundle.main.bundleIdentifier ?? ""
    defaults.removePersistentDomain(forName: domain)
  }

  static func clearForWidget(_ widgetKey: String) {
    let visitorKey = "alps-visitor-\(widgetKey)"
    let convKey = "alps-conv-\(widgetKey)"
    defaults.removeObject(forKey: visitorKey)
    defaults.removeObject(forKey: convKey)
  }
}
