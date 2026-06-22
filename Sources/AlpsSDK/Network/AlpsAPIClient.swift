import Foundation

class AlpsAPIClient {
  let config: AlpsConfig
  private let session = URLSession.shared

  init(config: AlpsConfig) {
    self.config = config
  }

  // MARK: - Widget Data

  func fetchWidgetData(completion: @escaping (Result<WidgetDataResponse, Error>) -> Void) {
    let endpoint = AlpsEndpoints.widgetData(widgetKey: config.widgetKey)
    request(endpoint, responseType: WidgetDataWrapper.self) { result in
      switch result {
      case .success(let wrapper):
        completion(.success(wrapper.data.data))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  // MARK: - Messages

  func sendMessage(
    name: String?,
    email: String?,
    message: String,
    completion: @escaping (Result<SendMessageResponse, Error>) -> Void
  ) {
    let req = SendMessageRequest(
      widgetKey: config.widgetKey,
      name: name,
      email: email,
      message: message,
      conversationId: config.conversationId,
      workspaceId: nil,
      sessionId: config.visitorId,
      source: "mobile-sdk",
      os: "iOS"
    )

    let endpoint = AlpsEndpoints.sendMessage(req)
    requestWithBody(endpoint, body: req, responseType: SendMessageResponse.self, completion: completion)
  }

  // MARK: - Conversations

  func fetchCustomerConversations(
    email: String,
    completion: @escaping (Result<CustomerConversationsResponse, Error>) -> Void
  ) {
    guard !email.isEmpty else {
      completion(.failure(AppError.missingEmail))
      return
    }

    let endpoint = AlpsEndpoints.customerConversations(widgetKey: config.widgetKey, email: email)
    request(endpoint, responseType: CustomerConversationsResponse.self, completion: completion)
  }

  func fetchConversationMessages(
    conversationId: String,
    completion: @escaping (Result<ConversationDetail, Error>) -> Void
  ) {
    let endpoint = AlpsEndpoints.conversationMessages(conversationId: conversationId)
    request(endpoint, responseType: ConversationDetail.self, completion: completion)
  }

  // MARK: - Search

  func search(
    keyword: String,
    completion: @escaping (Result<SearchResponse, Error>) -> Void
  ) {
    let endpoint = AlpsEndpoints.search(widgetKey: config.widgetKey, keyword: keyword)
    request(endpoint, responseType: SearchResponse.self, completion: completion)
  }

  // MARK: - Private Helpers

  private func request<T: Decodable>(
    _ endpoint: AlpsEndpoints,
    responseType: T.Type,
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    guard let request = endpoint.makeRequest() else {
      print("[AlpsAPIClient] Invalid request: \(endpoint)")
      completion(.failure(AppError.invalidRequest))
      return
    }

    print("[AlpsAPIClient] Fetching: \(request.url?.absoluteString ?? "unknown")")

    session.dataTask(with: request) { data, response, error in
      if let httpResponse = response as? HTTPURLResponse {
        print("[AlpsAPIClient] Status: \(httpResponse.statusCode)")
      }

      if let error = error {
        print("[AlpsAPIClient] Network error: \(error)")
        completion(.failure(error))
        return
      }

      guard let data = data else {
        print("[AlpsAPIClient] No data received")
        completion(.failure(AppError.noData))
        return
      }

      if let jsonString = String(data: data, encoding: .utf8) {
        print("[AlpsAPIClient] Response: \(jsonString.prefix(500))")
      }

      do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(T.self, from: data)
        print("[AlpsAPIClient] Decoded successfully")
        completion(.success(decoded))
      } catch {
        print("[AlpsAPIClient] Decoding error: \(error)")
        completion(.failure(error))
      }
    }.resume()
  }

  private func requestWithBody<T: Decodable>(
    _ endpoint: AlpsEndpoints,
    body: Encodable,
    responseType: T.Type,
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    guard var request = endpoint.makeRequest(with: body) else {
      completion(.failure(AppError.invalidRequest))
      return
    }

    do {
      request.httpBody = try JSONEncoder().encode(body)
    } catch {
      completion(.failure(error))
      return
    }

    session.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        completion(.failure(AppError.noData))
        return
      }

      do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(T.self, from: data)
        completion(.success(decoded))
      } catch {
        completion(.failure(error))
      }
    }.resume()
  }
}

// MARK: - Errors

enum AppError: Error, LocalizedError {
  case invalidRequest
  case noData
  case missingEmail
  case decodingError
  case networkError(String)

  var errorDescription: String? {
    switch self {
    case .invalidRequest:
      return "Invalid request"
    case .noData:
      return "No data received from server"
    case .missingEmail:
      return "Email is required"
    case .decodingError:
      return "Failed to decode response"
    case .networkError(let msg):
      return msg
    }
  }
}
