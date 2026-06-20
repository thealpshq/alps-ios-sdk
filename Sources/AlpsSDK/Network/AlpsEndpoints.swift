import Foundation

enum AlpsEndpoints {
  case widgetData(widgetKey: String)
  case sendMessage(SendMessageRequest)
  case customerConversations(widgetKey: String, email: String)
  case search(widgetKey: String, keyword: String)
  case pusherAuth

  private var baseURL: String {
    "https://api.tryalps.com/api/v1"
  }

  var url: URL? {
    switch self {
    case .widgetData(let widgetKey):
      return URL(string: "\(baseURL)/user/widget-data/\(widgetKey)")

    case .sendMessage:
      return URL(string: "\(baseURL)/message/customer")

    case .customerConversations(let widgetKey, let email):
      let encoded = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
      return URL(string: "\(baseURL)/message/customer/conversations?widgetKey=\(widgetKey)&email=\(encoded)")

    case .search(let widgetKey, let keyword):
      let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
      return URL(string: "\(baseURL)/report/search/\(widgetKey)?keyword=\(encoded)")

    case .pusherAuth:
      return URL(string: "\(baseURL)/pusher/auth")
    }
  }

  var method: String {
    switch self {
    case .widgetData, .customerConversations, .search:
      return "GET"
    case .sendMessage, .pusherAuth:
      return "POST"
    }
  }

  func makeRequest() -> URLRequest? {
    guard let url = url else { return nil }
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    return request
  }

  func makeRequest(with body: Encodable) -> URLRequest? {
    guard let url = url else { return nil }
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if let body = body as? SendMessageRequest {
      do {
        request.httpBody = try JSONEncoder().encode(body)
      } catch {
        return nil
      }
    }

    return request
  }
}
