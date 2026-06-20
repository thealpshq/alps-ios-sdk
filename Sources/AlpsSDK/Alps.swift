import UIKit

public final class Alps {
  static let shared = Alps()

  private var config: AlpsConfig?
  private var windowManager: AlpsWindowManager?
  private var apiClient: AlpsAPIClient?

  private init() {}

  /// Initialize the Alps SDK with your widget key
  /// - Parameters:
  ///   - widgetKey: Your Alps widget key (required)
  ///   - userName: Customer name (optional, can be set later with identify())
  ///   - userEmail: Customer email (optional, can be set later with identify())
  public static func configure(
    widgetKey: String,
    userName: String? = nil,
    userEmail: String? = nil
  ) {
    let config = AlpsConfig(
      widgetKey: widgetKey,
      visitorName: userName,
      visitorEmail: userEmail
    )
    shared.setup(config: config)
  }

  private func setup(config: AlpsConfig) {
    self.config = config
    self.apiClient = AlpsAPIClient(config: config)

    DispatchQueue.main.async {
      self.windowManager = AlpsWindowManager(
        config: config,
        apiClient: self.apiClient!
      )
      self.windowManager?.setupLauncher()
    }
  }

  /// Show the Alps chat panel
  public static func show() {
    DispatchQueue.main.async {
      shared.windowManager?.showPanel()
    }
  }

  /// Hide the Alps chat panel
  public static func hide() {
    DispatchQueue.main.async {
      shared.windowManager?.hidePanel()
    }
  }

  /// Set the visitor identity (name and email)
  /// - Parameters:
  ///   - name: Visitor name
  ///   - email: Visitor email
  public static func identify(name: String, email: String) {
    guard let config = shared.config else { return }
    config.visitorName = name
    config.visitorEmail = email
    AlpsVisitorStore.save(config: config)
    shared.windowManager?.updateVisitorIdentity(name: name, email: email)
  }

  /// Clear visitor identity and close the panel
  public static func logout() {
    DispatchQueue.main.async {
      shared.windowManager?.hidePanel()
      AlpsVisitorStore.clear()
      if let config = shared.config {
        config.visitorName = nil
        config.visitorEmail = nil
      }
    }
  }
}
