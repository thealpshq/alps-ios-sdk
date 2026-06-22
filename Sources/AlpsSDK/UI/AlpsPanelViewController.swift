import UIKit
import WebKit

class AlpsPanelViewController: UIViewController, WKScriptMessageHandler {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  var widgetData: WidgetDataResponse?

  private let webView = WKWebView()

  init(
    config: AlpsConfig,
    apiClient: AlpsAPIClient,
    widgetData: WidgetDataResponse?
  ) {
    self.config = config
    self.apiClient = apiClient
    self.widgetData = widgetData
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    setupWebView()
    loadEmbedPage()
  }

  private func setupWebView() {
    let config = WKWebViewConfiguration()
    config.userContentController.add(self, name: "close")

    webView.configuration.userContentController.add(self, name: "close")
    webView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(webView)

    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: view.topAnchor),
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func loadEmbedPage() {
    let frontendBase = "https://tryalps.com"
    var components = URLComponents(string: "\(frontendBase)/api/widget-embed")!
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "widgetKey", value: config.widgetKey)
    ]
    if let name = config.visitorName, !name.isEmpty {
      queryItems.append(URLQueryItem(name: "userName", value: name))
    }
    if let email = config.visitorEmail, !email.isEmpty {
      queryItems.append(URLQueryItem(name: "userEmail", value: email))
    }
    components.queryItems = queryItems

    guard let url = components.url else { return }

    let request = URLRequest(url: url)
    webView.load(request)
  }

  func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    if message.name == "close" {
      dismiss(animated: true)
    }
  }
}
