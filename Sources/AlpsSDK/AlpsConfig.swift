import Foundation

public class AlpsConfig {
  let widgetKey: String
  let apiBaseURL = "https://api.tryalps.com/api/v1"
  let cdnBaseURL = "https://cdn.tryalps.com"

  var visitorName: String?
  var visitorEmail: String?
  var conversationId: String?
  var pusherKey: String?
  var pusherCluster: String?

  init(
    widgetKey: String,
    visitorName: String? = nil,
    visitorEmail: String? = nil,
    conversationId: String? = nil
  ) {
    self.widgetKey = widgetKey
    self.visitorName = visitorName
    self.visitorEmail = visitorEmail
    self.conversationId = conversationId
  }

  var visitorId: String {
    if let email = visitorEmail {
      return email
    }
    if let name = visitorName {
      return name
    }
    let storedId = AlpsVisitorStore.getVisitorId(for: widgetKey)
    return storedId ?? UUID().uuidString
  }
}
