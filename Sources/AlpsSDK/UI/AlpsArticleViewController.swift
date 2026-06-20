import UIKit
import WebKit

class AlpsArticleViewController: UIViewController {
  let article: Article
  private let webView = WKWebView()
  private let progressView = UIProgressView()

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
    progressView.translatesAutoresizingMaskIntoConstraints = false
    progressView.progressTintColor = AlpsDesignTokens.dark
    progressView.trackTintColor = AlpsDesignTokens.border
    view.addSubview(progressView)

    webView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(webView)

    NSLayoutConstraint.activate([
      progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      progressView.leftAnchor.constraint(equalTo: view.leftAnchor),
      progressView.rightAnchor.constraint(equalTo: view.rightAnchor),
      progressView.heightAnchor.constraint(equalToConstant: 2),

      webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
      webView.leftAnchor.constraint(equalTo: view.leftAnchor),
      webView.rightAnchor.constraint(equalTo: view.rightAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == "estimatedProgress" {
      progressView.progress = Float(webView.estimatedProgress)
      progressView.isHidden = webView.estimatedProgress == 1.0
    }
  }

  deinit {
    webView.removeObserver(self, forKeyPath: "estimatedProgress")
  }

  private func loadContent() {
    guard let body = article.body else {
      let fallback = article.description ?? "No content available"
      loadPlainText(fallback)
      return
    }

    let html = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
              line-height: 1.7;
              color: \(AlpsDesignTokens.textMid.hex);
              padding: 16px;
              font-size: 13px;
            }
            h1 { font-size: 18px; font-weight: 700; margin-bottom: 12px; margin-top: 16px; }
            h2 { font-size: 15px; font-weight: 600; margin-bottom: 8px; margin-top: 12px; }
            h3 { font-size: 13px; font-weight: 600; margin-bottom: 8px; margin-top: 12px; }
            p { margin-bottom: 12px; }
            ul, ol { margin-left: 16px; margin-bottom: 12px; }
            li { margin-bottom: 4px; }
            code {
              background: \(AlpsDesignTokens.searchBg.hex);
              border-radius: 6px;
              padding: 2px 4px;
              font-family: "Menlo", "Monaco", monospace;
              font-size: 12px;
            }
            pre {
              background: \(AlpsDesignTokens.searchBg.hex);
              border-radius: 8px;
              padding: 12px;
              overflow-x: auto;
              margin-bottom: 12px;
              font-size: 12px;
            }
            blockquote {
              border-left: 3px solid \(AlpsDesignTokens.border.hex);
              padding-left: 12px;
              margin-left: 0;
              margin-bottom: 12px;
              color: \(AlpsDesignTokens.textBody.hex);
            }
            img { max-width: 100%; height: auto; border-radius: 8px; margin: 12px 0; }
            a { color: \(AlpsDesignTokens.dark.hex); text-decoration: none; }
            a:active { opacity: 0.6; }
        </style>
    </head>
    <body>\(body)</body>
    </html>
    """

    webView.loadHTMLString(html, baseURL: nil)
  }

  private func loadPlainText(_ text: String) {
    let html = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
              line-height: 1.7;
              color: \(AlpsDesignTokens.textMid.hex);
              padding: 16px;
              font-size: 13px;
            }
        </style>
    </head>
    <body>\(text.replacingOccurrences(of: "\n", with: "<br>"))</body>
    </html>
    """

    webView.loadHTMLString(html, baseURL: nil)
  }
}

extension UIColor {
  var hex: String {
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
    return String(format: "#%06x", rgb)
  }
}
