import UIKit

class AlpsPanelViewController: UIViewController {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  var widgetData: WidgetDataResponse?

  private let header = UIView()
  private let bottomTabBar = UIView()
  private let homeButton = UIButton(type: .system)
  private let messagesButton = UIButton(type: .system)
  private let answersButton = UIButton(type: .system)
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
    header.backgroundColor = AlpsDesignTokens.dark
    header.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(header)

    NSLayoutConstraint.activate([
      header.topAnchor.constraint(equalTo: view.topAnchor),
      header.leftAnchor.constraint(equalTo: view.leftAnchor),
      header.rightAnchor.constraint(equalTo: view.rightAnchor),
      header.heightAnchor.constraint(equalToConstant: 80),
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

    let logoContainer = UIView()
    logoContainer.translatesAutoresizingMaskIntoConstraints = false
    logoContainer.widthAnchor.constraint(equalToConstant: 42).isActive = true
    logoContainer.heightAnchor.constraint(equalToConstant: 42).isActive = true
    headerStack.addArrangedSubview(logoContainer)

    let avatar = UIImageView()
    avatar.contentMode = .scaleAspectFill
    avatar.layer.cornerRadius = 21
    avatar.clipsToBounds = true
    avatar.backgroundColor = AlpsDesignTokens.avatarBg
    avatar.translatesAutoresizingMaskIntoConstraints = false
    logoContainer.addSubview(avatar)

    NSLayoutConstraint.activate([
      avatar.topAnchor.constraint(equalTo: logoContainer.topAnchor),
      avatar.leftAnchor.constraint(equalTo: logoContainer.leftAnchor),
      avatar.rightAnchor.constraint(equalTo: logoContainer.rightAnchor),
      avatar.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor),
    ])

    let initialsLabel = UILabel()
    let teamName = widgetData?.teamName ?? "A"
    initialsLabel.text = String(teamName.prefix(1)).uppercased()
    initialsLabel.textColor = .white
    initialsLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    initialsLabel.textAlignment = .center
    initialsLabel.translatesAutoresizingMaskIntoConstraints = false
    logoContainer.addSubview(initialsLabel)

    NSLayoutConstraint.activate([
      initialsLabel.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
      initialsLabel.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
    ])

    if let logoURL = widgetData?.teamAvatarUrl, let url = URL(string: logoURL) {
      URLSession.shared.dataTask(with: url) { data, _, _ in
        DispatchQueue.main.async {
          if let data = data, let image = UIImage(data: data) {
            avatar.image = image
            initialsLabel.isHidden = true
          }
        }
      }.resume()
    }

    let textStack = UIStackView()
    textStack.axis = .vertical
    textStack.spacing = 2
    textStack.alignment = .leading
    headerStack.addArrangedSubview(textStack)

    let teamLabel = UILabel()
    teamLabel.text = widgetData?.teamName ?? "Support"
    teamLabel.font = UIFont.systemFont(ofSize: 11)
    teamLabel.textColor = AlpsDesignTokens.textLight
    textStack.addArrangedSubview(teamLabel)

    let welcomeLabel = UILabel()
    welcomeLabel.text = widgetData?.welcomeMessage ?? ""
    welcomeLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
    welcomeLabel.textColor = .white
    welcomeLabel.numberOfLines = 0
    textStack.addArrangedSubview(welcomeLabel)

    contentView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(contentView)

    let topBorder = UIView()
    topBorder.backgroundColor = AlpsDesignTokens.border
    topBorder.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(topBorder)

    bottomTabBar.backgroundColor = .white
    bottomTabBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(bottomTabBar)

    NSLayoutConstraint.activate([
      topBorder.heightAnchor.constraint(equalToConstant: 1),
      topBorder.leftAnchor.constraint(equalTo: view.leftAnchor),
      topBorder.rightAnchor.constraint(equalTo: view.rightAnchor),
      topBorder.bottomAnchor.constraint(equalTo: bottomTabBar.topAnchor),
    ])

    NSLayoutConstraint.activate([
      contentView.topAnchor.constraint(equalTo: header.bottomAnchor),
      contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentView.bottomAnchor.constraint(equalTo: bottomTabBar.topAnchor),

      bottomTabBar.leftAnchor.constraint(equalTo: view.leftAnchor),
      bottomTabBar.rightAnchor.constraint(equalTo: view.rightAnchor),
      bottomTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      bottomTabBar.heightAnchor.constraint(equalToConstant: 50),
    ])

    setupTabButtons()
  }

  private func setupTabButtons() {
    let buttons: [(UIButton, String, String)] = [
      (homeButton, "house.fill", "Home"),
      (messagesButton, "bubble.left.fill", "Messages"),
      (answersButton, "magnifyingglass", "Answers"),
    ]

    var previousButton: UIButton?

    for (button, iconName, label) in buttons {
      let stack = UIStackView()
      stack.axis = .vertical
      stack.spacing = 2
      stack.alignment = .center
      stack.isUserInteractionEnabled = false

      let icon = UIImageView()
      let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
      icon.image = UIImage(systemName: iconName, withConfiguration: config)
      icon.contentMode = .scaleAspectFit
      stack.addArrangedSubview(icon)

      let labelView = UILabel()
      labelView.text = label
      labelView.font = UIFont.systemFont(ofSize: 10)
      labelView.textColor = AlpsDesignTokens.textBody
      stack.addArrangedSubview(labelView)

      button.addSubview(stack)
      stack.translatesAutoresizingMaskIntoConstraints = false

      NSLayoutConstraint.activate([
        stack.centerXAnchor.constraint(equalTo: button.centerXAnchor),
        stack.centerYAnchor.constraint(equalTo: button.centerYAnchor),
      ])

      button.translatesAutoresizingMaskIntoConstraints = false
      button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
      button.tag = buttons.firstIndex(where: { $0.0 == button }) ?? 0
      bottomTabBar.addSubview(button)

      NSLayoutConstraint.activate([
        button.topAnchor.constraint(equalTo: bottomTabBar.topAnchor),
        button.bottomAnchor.constraint(equalTo: bottomTabBar.bottomAnchor),
        button.widthAnchor.constraint(equalTo: bottomTabBar.widthAnchor, multiplier: 1.0 / 3.0),
      ])

      if let previous = previousButton {
        button.leftAnchor.constraint(equalTo: previous.rightAnchor).isActive = true
      } else {
        button.leftAnchor.constraint(equalTo: bottomTabBar.leftAnchor).isActive = true
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
      if let stack = btn.subviews.first as? UIStackView,
         let icon = stack.arrangedSubviews.first as? UIImageView,
         let label = stack.arrangedSubviews.last as? UILabel {
        label.textColor = AlpsDesignTokens.textBody
        icon.tintColor = AlpsDesignTokens.textBody
      }
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

    if let stack = activeButton.subviews.first as? UIStackView,
       let icon = stack.arrangedSubviews.first as? UIImageView,
       let label = stack.arrangedSubviews.last as? UILabel {
      label.textColor = AlpsDesignTokens.accent
      icon.tintColor = AlpsDesignTokens.accent
    }
  }

  private func showHomeTab() {
    if homeViewController == nil {
      homeViewController = AlpsHomeViewController(
        config: config,
        apiClient: apiClient,
        widgetData: widgetData,
        panelViewController: self
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
