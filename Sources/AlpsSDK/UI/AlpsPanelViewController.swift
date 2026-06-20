import UIKit

class AlpsPanelViewController: UIViewController {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  var widgetData: WidgetDataResponse?

  private let tabBar = UIView()
  private let homeButton = UIButton(type: .system)
  private let messagesButton = UIButton(type: .system)
  private let answersButton = UIButton(type: .system)
  private let contentView = UIView()
  private var currentTab: Tab = .home
  private var homeViewController: AlpsHomeViewController?
  private var messagesViewController: AlpsMessagesViewController?
  private var answersViewController: AlpsAnswersViewController?

  enum Tab {
    case home, messages, answers
  }

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

    setupUI()
    restoreVisitorIfNeeded()
    switchTab(to: .home)
  }

  private func setupUI() {
    // Header
    let header = UIView()
    header.backgroundColor = .systemGray6
    header.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(header)

    NSLayoutConstraint.activate([
      header.topAnchor.constraint(equalTo: view.topAnchor),
      header.leftAnchor.constraint(equalTo: view.leftAnchor),
      header.rightAnchor.constraint(equalTo: view.rightAnchor),
      header.heightAnchor.constraint(equalToConstant: 60),
    ])

    let titleLabel = UILabel()
    titleLabel.text = widgetData?.teamName ?? "Support"
    titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    header.addSubview(titleLabel)

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: header.leftAnchor, constant: 16),
      titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
    ])

    // Tab Bar
    tabBar.backgroundColor = .white
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    tabBar.layer.borderBottomWidth = 1
    tabBar.layer.borderColor = UIColor.systemGray5.cgColor
    view.addSubview(tabBar)

    NSLayoutConstraint.activate([
      tabBar.topAnchor.constraint(equalTo: header.bottomAnchor),
      tabBar.leftAnchor.constraint(equalTo: view.leftAnchor),
      tabBar.rightAnchor.constraint(equalTo: view.rightAnchor),
      tabBar.heightAnchor.constraint(equalToConstant: 50),
    ])

    setupTabButtons()

    // Content View
    contentView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(contentView)

    NSLayoutConstraint.activate([
      contentView.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
      contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func setupTabButtons() {
    let buttons: [(UIButton, String, Tab)] = [
      (homeButton, "Home", .home),
      (messagesButton, "Messages", .messages),
      (answersButton, "Answers", .answers),
    ]

    var previousButton: UIButton?

    for (button, title, tab) in buttons {
      button.setTitle(title, for: UIControlState.normal)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
      button.addTarget(self, action: #selector(tabTapped(_:)), for: UIControlEvents.touchUpInside)
      button.tag = buttons.firstIndex(where: { $0.0 == button }) ?? 0
      tabBar.addSubview(button)

      NSLayoutConstraint.activate([
        button.topAnchor.constraint(equalTo: tabBar.topAnchor),
        button.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
        button.widthAnchor.constraint(equalTo: tabBar.widthAnchor, multiplier: 1.0 / 3.0),
      ])

      if let previous = previousButton {
        button.leftAnchor.constraint(equalTo: previous.rightAnchor).isActive = true
      } else {
        button.leftAnchor.constraint(equalTo: tabBar.leftAnchor).isActive = true
      }

      previousButton = button
    }
  }

  @objc private func tabTapped(_ sender: UIButton) {
    let tabs: [Tab] = [.home, .messages, .answers]
    if let index = tabs.firstIndex(where: { _ in sender.tag < tabs.count }) {
      switchTab(to: tabs[sender.tag])
    }
  }

  func switchTab(to tab: Tab) {
    currentTab = tab
    updateTabButtonStates()

    // Remove previous content
    contentView.subviews.forEach { $0.removeFromSuperview() }

    switch tab {
    case .home:
      showHomeTab()
    case .messages:
      showMessagesTab()
    case .answers:
      showAnswersTab()
    }
  }

  private func updateTabButtonStates() {
    [homeButton, messagesButton, answersButton].forEach { btn in
      btn.setTitleColor(.systemGray, for: .normal)
    }

    let activeButton: UIButton
    switch currentTab {
    case .home:
      activeButton = homeButton
    case .messages:
      activeButton = messagesButton
    case .answers:
      activeButton = answersButton
    }

    activeButton.setTitleColor(.systemBlue, for: .normal)
  }

  private func showHomeTab() {
    if homeViewController == nil {
      homeViewController = AlpsHomeViewController(
        config: config,
        apiClient: apiClient,
        widgetData: widgetData
      )
    }

    if let vc = homeViewController {
      addChild(vc)
      vc.view.frame = contentView.bounds
      vc.view.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(vc.view)

      NSLayoutConstraint.activate([
        vc.view.topAnchor.constraint(equalTo: contentView.topAnchor),
        vc.view.leftAnchor.constraint(equalTo: contentView.leftAnchor),
        vc.view.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        vc.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ])

      vc.didMove(toParent: self)
    }
  }

  private func showMessagesTab() {
    if messagesViewController == nil {
      messagesViewController = AlpsMessagesViewController(
        config: config,
        apiClient: apiClient
      )
    }

    if let vc = messagesViewController {
      addChild(vc)
      vc.view.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(vc.view)

      NSLayoutConstraint.activate([
        vc.view.topAnchor.constraint(equalTo: contentView.topAnchor),
        vc.view.leftAnchor.constraint(equalTo: contentView.leftAnchor),
        vc.view.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        vc.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ])

      vc.didMove(toParent: self)
    }
  }

  private func showAnswersTab() {
    if answersViewController == nil {
      answersViewController = AlpsAnswersViewController(
        config: config,
        apiClient: apiClient,
        widgetData: widgetData
      )
    }

    if let vc = answersViewController {
      addChild(vc)
      vc.view.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(vc.view)

      NSLayoutConstraint.activate([
        vc.view.topAnchor.constraint(equalTo: contentView.topAnchor),
        vc.view.leftAnchor.constraint(equalTo: contentView.leftAnchor),
        vc.view.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        vc.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ])

      vc.didMove(toParent: self)
    }
  }

  func updateVisitorInfo(name: String, email: String) {
    config.visitorName = name
    config.visitorEmail = email
  }

  private func restoreVisitorIfNeeded() {
    if let stored = AlpsVisitorStore.load(widgetKey: config.widgetKey) {
      if config.visitorName == nil {
        config.visitorName = stored.name
      }
      if config.visitorEmail == nil {
        config.visitorEmail = stored.email
      }
      if config.conversationId == nil {
        config.conversationId = stored.conversationId
      }
    }
  }
}

// MARK: - Layer Border Extension

extension CALayer {
  var borderBottomWidth: CGFloat {
    get { 0 }
    set {
      let path = UIBezierPath(
        rect: CGRect(x: 0, y: bounds.height - newValue, width: bounds.width, height: newValue)
      )
      let shapeLayer = CAShapeLayer()
      shapeLayer.path = path.cgPath
      shapeLayer.fillColor = borderColor ?? UIColor.clear.cgColor
    }
  }
}
