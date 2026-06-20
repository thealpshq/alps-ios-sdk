import UIKit

class AlpsWindowManager {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  private var launcherButton: AlpsLauncherButton?
  private var panelViewController: AlpsPanelViewController?
  private var widgetData: WidgetDataResponse?

  init(config: AlpsConfig, apiClient: AlpsAPIClient) {
    self.config = config
    self.apiClient = apiClient
  }

  func setupLauncher() {
    guard let keyWindow = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow }) else {
      return
    }

    launcherButton = AlpsLauncherButton()
    launcherButton?.onTap = { [weak self] in
      self?.showPanel()
    }

    if let launcher = launcherButton {
      keyWindow.addSubview(launcher)
      launcher.setupConstraints()
    }

    fetchWidgetData()
  }

  func showPanel() {
    guard let keyWindow = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow }) else {
      return
    }

    if panelViewController == nil {
      panelViewController = AlpsPanelViewController(
        config: config,
        apiClient: apiClient,
        widgetData: widgetData
      )
    }

    guard let panelVC = panelViewController else { return }

    if let presenter = keyWindow.rootViewController {
      let nav = UINavigationController(rootViewController: panelVC)
      nav.modalPresentationStyle = .pageSheet
      if #available(iOS 16.0, *) {
        if let sheet = nav.sheetPresentationController {
          sheet.detents = [.large()]
          sheet.prefersGrabberVisible = true
        }
      }
      presenter.present(nav, animated: true)
    }
  }

  func hidePanel() {
    panelViewController?.dismiss(animated: true)
    panelViewController = nil
  }

  func updateVisitorIdentity(name: String, email: String) {
    config.visitorName = name
    config.visitorEmail = email
    panelViewController?.updateVisitorInfo(name: name, email: email)
  }

  private func fetchWidgetData() {
    apiClient.fetchWidgetData { [weak self] result in
      switch result {
      case .success(let data):
        self?.widgetData = data
        self?.config.pusherKey = data.pusherKey
        self?.config.pusherCluster = data.pusherCluster
        self?.updateLauncherStyle(data)
      case .failure(let error):
        print("[AlpsWindowManager] Failed to fetch widget data: \(error)")
      }
    }
  }

  private func updateLauncherStyle(_ data: WidgetDataResponse) {
    if let color = data.widgetColor {
      launcherButton?.updateColor(color)
    }
    if let text = data.launcherText {
      launcherButton?.updateText(text)
    }
  }
}
