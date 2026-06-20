import UIKit

class AlpsPanelViewController: UIViewController {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  var widgetData: WidgetDataResponse?

  private let tabBar = UIView()
  private let homeButton = UIButton(type: .system)
  private let messagesButton = UIButton(type: .system)
  private let answersButton = UIButton(type: .system)
  private let tabUnderline = UIView()
  private let contentView = UIView()
  private var currentTab: Tab = .home
  private var homeViewController: AlpsHomeViewController?
  private var messagesViewController: AlpsMessagesViewController?
  private var answersViewController: AlpsAnswersViewController?
  private var fetchError: String?

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
    let header = UIView()
    header.backgroundColor = AlpsDesignTokens.dark
    header.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(header)

    NSLayoutConstraint.activate([
      header.topAnchor.constraint(equalTo: view.topAnchor),
      header.leftAnchor.constraint(equalTo: view.leftAnchor),
      header.rightAnchor.constraint(equalTo: view.rightAnchor),
      header.heightAnchor.constraint(equalToConstant: 56),
    ])

    let headerStack = UIStackView()
    headerStack.axis = .horizontal
    headerStack.spacing = 12
    headerStack.alignment = .center
    headerStack.translatesAutoresizingMaskIntoConstraints = false
    header.addSubview(headerStack)

    NSLayoutConstraint.activate([
      headerStack.leftAnchor.constraint(equalTo: header.leftAnchor, constant: 16),
      headerStack.centerYAnchor.constraint(equalTo: header.centerYAnchor),
    ])

    let avatar = UIView()
    avatar.backgroundColor = AlpsDesignTokens.avatarBg
    avatar.layer.cornerRadius = 21
    avatar.clipsToBounds = true
    avatar.translatesAutoresizingMaskIntoConstraints = false
    avatar.widthAnchor.constraint(equalToConstant: 42).isActive = true
    avatar.heightAnchor.constraint(equalToConstant: 42).isActive = true
    headerStack.addArrangedSubview(avatar)

    let initials = UILabel()
    let teamName = widgetData?.teamName ?? "A"
    initials.text = String(teamName.prefix(1)).uppercased()
    initials.textColor = .white
    initials.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    initials.textAlignment = .center
    initials.translatesAutoresizingMaskIntoConstraints = false
    avatar.addSubview(initials)

    NSLayoutConstraint.activate([
      initials.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
      initials.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
    ])

    let titleLabel = UILabel()
    titleLabel.text = widgetData?.teamName ?? "Support"
    titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    titleLabel.textColor = .white
    headerStack.addArrangedSubview(titleLabel)

    tabBar.backgroundColor = .white
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabBar)

    NSLayoutConstraint.activate([
      tabBar.topAnchor.constraint(equalTo: header.bottomAnchor),
      tabBar.leftAnchor.constraint(equalTo: view.leftAnchor),
      tabBar.rightAnchor.constraint(equalTo: view.rightAnchor),
      tabBar.heightAnchor.constraint(equalToConstant: 48),
    ])

    setupTabButtons()

    tabUnderline.backgroundColor = AlpsDesignTokens.dark
    tabUnderline.translatesAutoresizingMaskIntoConstraints = false
    tabBar.addSubview(tabUnderline)

    NSLayoutConstraint.activate([
      tabUnderline.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
      tabUnderline.heightAnchor.constraint(equalToConstant: 2),
      tabUnderline.widthAnchor.constraint(equalTo: tabBar.widthAnchor, multiplier: 1.0 / 3.0),
      tabUnderline.leftAnchor.constraint(equalTo: tabBar.leftAnchor),
    ])

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

    for (button, title, _) in buttons {
      button.setTitle(title, for: .normal)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
      button.setTitleColor(AlpsDesignTokens.textBody, for: .normal)
      button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
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
    if sender.tag < tabs.count {
      switchTab(to: tabs[sender.tag])
    }
  }

  func switchTab(to tab: Tab) {
    currentTab = tab
    updateTabButtonStates()

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
      btn.setTitleColor(AlpsDesignTokens.textBody, for: .normal)
    }

    let activeButton: UIButton
    let tabIndex: CGFloat
    switch currentTab {
    case .home:
      activeButton = homeButton
      tabIndex = 0
    case .messages:
      activeButton = messagesButton
      tabIndex = 1
    case .answers:
      activeButton = answersButton
      tabIndex = 2
    }

    activeButton.setTitleColor(AlpsDesignTokens.dark, for: .normal)

    UIView.animate(withDuration: 0.2) {
      let newX = tabIndex * (self.tabBar.bounds.width / 3.0)
      self.tabUnderline.frame.origin.x = newX
    }
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

  func updateWidgetData(_ data: WidgetDataResponse) {
    widgetData = data
    fetchError = nil
    homeViewController?.updateWidgetData(data)
    answersViewController?.updateWidgetData(data)
  }

  func showError(_ error: String) {
    fetchError = error
    homeViewController?.showError(error)
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
