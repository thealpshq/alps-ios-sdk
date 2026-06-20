import UIKit
import WebKit

class AlpsArticleViewController: UIViewController {
  let article: Article
  private let webView = WKWebView()
  private let scrollView = UIScrollView()
  private let textView = UITextView()

  init(article: Article) {
    self.article = article
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    title = article.title
    navigationItem.largeTitleDisplayMode = .never

    setupUI()
    loadContent()
  }

  private func setupUI() {
    // Use WebView if HTML content, otherwise TextVie for plain text
    if let body = article.body, body.contains("<") {
      setupWebView()
    } else {
      setupTextView()
    }
  }

  private func setupWebView() {
    webView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(webView)

    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: view.topAnchor),
      webView.leftAnchor.constraint(equalTo: view.leftAnchor),
      webView.rightAnchor.constraint(equalTo: view.rightAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func setupTextView() {
    textView.isEditable = false
    textView.isScrollEnabled = true
    textView.font = UIFont.systemFont(ofSize: 16)
    textView.textColor = .darkGray
    textView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(textView)

    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      textView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      textView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func loadContent() {
    if article.body?.contains("<") == true {
      loadInWebView()
    } else {
      textView.text = article.body ?? article.description ?? "No content"
    }
  }

  private func loadInWebView() {
    guard let body = article.body else { return }

    let html = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; color: #333; padding: 16px; }
            img { max-width: 100%; height: auto; }
            code { background: #f5f5f5; padding: 2px 4px; border-radius: 3px; }
            pre { background: #f5f5f5; padding: 12px; border-radius: 3px; overflow-x: auto; }
        </style>
    </head>
    <body>\(body)</body>
    </html>
    """

    webView.loadHTMLString(html, baseURL: nil)
  }
}
