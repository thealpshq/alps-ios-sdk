import UIKit

class AlpsHomeViewController: UIViewController {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  var widgetData: WidgetDataResponse?
  weak var panelViewController: AlpsPanelViewController?

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private var actionCardsStack: UIStackView?

  init(
    config: AlpsConfig,
    apiClient: AlpsAPIClient,
    widgetData: WidgetDataResponse?,
    panelViewController: AlpsPanelViewController? = nil
  ) {
    self.config = config
    self.apiClient = apiClient
    self.widgetData = widgetData
    self.panelViewController = panelViewController
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupUI()
    populateContent()
  }

  private func setupUI() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
      scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    stackView.axis = .vertical
    stackView.spacing = 16
    stackView.alignment = .fill
    stackView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 16),
      stackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
      stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])

  }

  private func populateContent() {
    guard let data = widgetData else { return }

    let headerCard = UIView()
    headerCard.backgroundColor = AlpsDesignTokens.dark
    headerCard.layer.cornerRadius = AlpsDesignTokens.radiusButton
    headerCard.clipsToBounds = true
    headerCard.translatesAutoresizingMaskIntoConstraints = false
    headerCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
    stackView.addArrangedSubview(headerCard)

    let headerHStack = UIStackView()
    headerHStack.axis = .horizontal
    headerHStack.spacing = 16
    headerHStack.alignment = .top
    headerHStack.translatesAutoresizingMaskIntoConstraints = false
    headerCard.addSubview(headerHStack)

    let avatarView = UIImageView()
    avatarView.contentMode = .scaleAspectFill
    avatarView.layer.cornerRadius = 21
    avatarView.clipsToBounds = true
    avatarView.backgroundColor = AlpsDesignTokens.avatarBg
    avatarView.translatesAutoresizingMaskIntoConstraints = false
    avatarView.widthAnchor.constraint(equalToConstant: 42).isActive = true
    avatarView.heightAnchor.constraint(equalToConstant: 42).isActive = true
    headerHStack.addArrangedSubview(avatarView)

    if let teamAvatarUrl = data.teamAvatarUrl, let url = URL(string: teamAvatarUrl) {
      URLSession.shared.dataTask(with: url) { imageData, _, _ in
        DispatchQueue.main.async {
          if let imageData = imageData, let image = UIImage(data: imageData) {
            avatarView.image = image
          }
        }
      }.resume()
    } else {
      let initials = UILabel()
      initials.text = (data.teamName?.prefix(1) ?? "A").uppercased()
      initials.textColor = .white
      initials.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
      initials.textAlignment = .center
      initials.translatesAutoresizingMaskIntoConstraints = false
      avatarView.addSubview(initials)

      NSLayoutConstraint.activate([
        initials.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
        initials.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
      ])
    }

    let headerLeftStack = UIStackView()
    headerLeftStack.axis = .vertical
    headerLeftStack.spacing = 4
    headerLeftStack.alignment = .leading
    headerHStack.addArrangedSubview(headerLeftStack)

    let greetingLabel = UILabel()
    let visitorName = config.visitorName?.split(separator: " ").first.map(String.init) ?? nil
    greetingLabel.text = visitorName.map { "Hey \($0)," } ?? "Hey there,"
    greetingLabel.font = UIFont.systemFont(ofSize: 13)
    greetingLabel.textColor = UIColor(hex: "#DDDDDD")
    headerLeftStack.addArrangedSubview(greetingLabel)

    let welcomeLabel = UILabel()
    welcomeLabel.text = data.welcomeMessage ?? "How can we help?"
    welcomeLabel.numberOfLines = 0
    welcomeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    welcomeLabel.textColor = .white
    headerLeftStack.addArrangedSubview(welcomeLabel)

    let cardsStack = UIStackView()
    cardsStack.axis = .vertical
    cardsStack.spacing = 8
    cardsStack.translatesAutoresizingMaskIntoConstraints = false
    headerLeftStack.addArrangedSubview(cardsStack)
    self.actionCardsStack = cardsStack

    if config.conversationId != nil {
      let continueCard = UIView()
      continueCard.backgroundColor = .white
      continueCard.layer.cornerRadius = 8
      continueCard.translatesAutoresizingMaskIntoConstraints = false
      continueCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
      actionCardsStack.addArrangedSubview(continueCard)

      let continueStack = UIStackView()
      continueStack.axis = .vertical
      continueStack.spacing = 8
      continueStack.alignment = .fill
      continueStack.translatesAutoresizingMaskIntoConstraints = false
      continueCard.addSubview(continueStack)

      NSLayoutConstraint.activate([
        continueStack.topAnchor.constraint(equalTo: continueCard.topAnchor, constant: 10),
        continueStack.leftAnchor.constraint(equalTo: continueCard.leftAnchor, constant: 12),
        continueStack.rightAnchor.constraint(equalTo: continueCard.rightAnchor, constant: -12),
        continueStack.bottomAnchor.constraint(equalTo: continueCard.bottomAnchor, constant: -10),
      ])

      let titleLabel = UILabel()
      titleLabel.text = "Continue conversation"
      titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
      titleLabel.textColor = AlpsDesignTokens.textMid
      continueStack.addArrangedSubview(titleLabel)

      let messageLabel = UILabel()
      messageLabel.font = UIFont.systemFont(ofSize: 12)
      messageLabel.textColor = AlpsDesignTokens.textBody
      messageLabel.numberOfLines = 1
      continueStack.addArrangedSubview(messageLabel)

      let timestampLabel = UILabel()
      timestampLabel.font = UIFont.systemFont(ofSize: 12)
      timestampLabel.textColor = AlpsDesignTokens.textLight
      continueStack.addArrangedSubview(timestampLabel)

      guard let email = config.visitorEmail else { return }

      apiClient.fetchCustomerConversations(email: email) { [weak self] result in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            if let first = response.conversations.first {
              messageLabel.text = String((first.lastMessage?.content ?? "No messages").prefix(40))

              let formatter = ISO8601DateFormatter()
              if let date = formatter.date(from: first.lastMessageAt ?? first.createdAt) {
                let relativeFormatter = RelativeDateTimeFormatter()
                timestampLabel.text = relativeFormatter.localizedString(for: date, relativeTo: Date())
              }
            }
          case .failure:
            break
          }
        }
      }

      continueCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapContinueAction)))
      continueCard.isUserInteractionEnabled = true
    } else {
      let chatCard = UIView()
      chatCard.backgroundColor = .white
      chatCard.layer.cornerRadius = 8
      chatCard.translatesAutoresizingMaskIntoConstraints = false
      chatCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
      actionCardsStack.addArrangedSubview(chatCard)

      let chatStack = UIStackView()
      chatStack.axis = .vertical
      chatStack.spacing = 2
      chatStack.alignment = .fill
      chatStack.translatesAutoresizingMaskIntoConstraints = false
      chatCard.addSubview(chatStack)

      NSLayoutConstraint.activate([
        chatStack.topAnchor.constraint(equalTo: chatCard.topAnchor, constant: 10),
        chatStack.leftAnchor.constraint(equalTo: chatCard.leftAnchor, constant: 12),
        chatStack.rightAnchor.constraint(equalTo: chatCard.rightAnchor, constant: -12),
        chatStack.bottomAnchor.constraint(equalTo: chatCard.bottomAnchor, constant: -10),
      ])

      let chatLabel = UILabel()
      chatLabel.text = "Chat with us"
      chatLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
      chatLabel.textColor = AlpsDesignTokens.textMid
      chatStack.addArrangedSubview(chatLabel)

      let chatSubLabel = UILabel()
      chatSubLabel.text = "Our agents are ready to help"
      chatSubLabel.font = UIFont.systemFont(ofSize: 12)
      chatSubLabel.textColor = AlpsDesignTokens.textBody
      chatStack.addArrangedSubview(chatSubLabel)

      chatCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapContinueAction)))
      chatCard.isUserInteractionEnabled = true
    }

    guard let email = config.visitorEmail else { return }
    apiClient.fetchCustomerConversations(email: email) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success(let response):
          let closedConversations = response.conversations.filter { $0.status != "active" }
          if !closedConversations.isEmpty {
            let historyCard = UIView()
            historyCard.backgroundColor = .white
            historyCard.layer.cornerRadius = 8
            historyCard.translatesAutoresizingMaskIntoConstraints = false
            historyCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
            self?.actionCardsStack.addArrangedSubview(historyCard)

            let historyStack = UIStackView()
            historyStack.axis = .vertical
            historyStack.spacing = 2
            historyStack.alignment = .fill
            historyStack.translatesAutoresizingMaskIntoConstraints = false
            historyCard.addSubview(historyStack)

            NSLayoutConstraint.activate([
              historyStack.topAnchor.constraint(equalTo: historyCard.topAnchor, constant: 10),
              historyStack.leftAnchor.constraint(equalTo: historyCard.leftAnchor, constant: 12),
              historyStack.rightAnchor.constraint(equalTo: historyCard.rightAnchor, constant: -12),
              historyStack.bottomAnchor.constraint(equalTo: historyCard.bottomAnchor, constant: -10),
            ])

            let historyLabel = UILabel()
            historyLabel.text = "Conversation History"
            historyLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            historyLabel.textColor = AlpsDesignTokens.textMid
            historyStack.addArrangedSubview(historyLabel)

            let countLabel = UILabel()
            countLabel.text = "\(closedConversations.count) past \(closedConversations.count == 1 ? "conversation" : "conversations")"
            countLabel.font = UIFont.systemFont(ofSize: 12)
            countLabel.textColor = AlpsDesignTokens.textBody
            historyStack.addArrangedSubview(countLabel)

            historyCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self?.didTapContinueAction)))
            historyCard.isUserInteractionEnabled = true
          }
        case .failure:
          break
        }
      }
    }

    NSLayoutConstraint.activate([
      headerHStack.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 16),
      headerHStack.leftAnchor.constraint(equalTo: headerCard.leftAnchor, constant: 16),
      headerHStack.rightAnchor.constraint(equalTo: headerCard.rightAnchor, constant: -16),
      headerHStack.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16),
    ])

    let findCard = UIView()
    findCard.backgroundColor = .white
    findCard.layer.borderWidth = 1
    findCard.layer.borderColor = AlpsDesignTokens.border.cgColor
    findCard.layer.cornerRadius = AlpsDesignTokens.radiusCard
    findCard.clipsToBounds = true
    findCard.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(findCard)

    let findStack = UIStackView()
    findStack.axis = .vertical
    findStack.spacing = 0
    findStack.alignment = .fill
    findStack.translatesAutoresizingMaskIntoConstraints = false
    findCard.addSubview(findStack)

    NSLayoutConstraint.activate([
      findStack.topAnchor.constraint(equalTo: findCard.topAnchor),
      findStack.leftAnchor.constraint(equalTo: findCard.leftAnchor),
      findStack.rightAnchor.constraint(equalTo: findCard.rightAnchor),
      findStack.bottomAnchor.constraint(equalTo: findCard.bottomAnchor),
    ])

    let searchBar = UIView()
    searchBar.backgroundColor = AlpsDesignTokens.searchBg
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    searchBar.heightAnchor.constraint(equalToConstant: 40).isActive = true
    findStack.addArrangedSubview(searchBar)

    let searchIcon = UIImageView()
    searchIcon.image = UIImage(systemName: "magnifyingglass")
    searchIcon.tintColor = AlpsDesignTokens.textLight
    searchIcon.contentMode = .scaleAspectFit
    searchIcon.translatesAutoresizingMaskIntoConstraints = false
    searchBar.addSubview(searchIcon)

    let searchLabel = UILabel()
    searchLabel.text = "Search for articles and videos"
    searchLabel.font = UIFont.systemFont(ofSize: 13)
    searchLabel.textColor = AlpsDesignTokens.textLight
    searchLabel.translatesAutoresizingMaskIntoConstraints = false
    searchBar.addSubview(searchLabel)

    NSLayoutConstraint.activate([
      searchIcon.leftAnchor.constraint(equalTo: searchBar.leftAnchor, constant: 12),
      searchIcon.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
      searchIcon.widthAnchor.constraint(equalToConstant: 16),
      searchIcon.heightAnchor.constraint(equalToConstant: 16),
      searchLabel.leftAnchor.constraint(equalTo: searchIcon.rightAnchor, constant: 8),
      searchLabel.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
    ])

    let tapSearch = UITapGestureRecognizer(target: self, action: #selector(didTapSearch))
    searchBar.addGestureRecognizer(tapSearch)
    searchBar.isUserInteractionEnabled = true

    let categoriesStack = UIStackView()
    categoriesStack.axis = .vertical
    categoriesStack.spacing = 0
    categoriesStack.alignment = .fill
    findStack.addArrangedSubview(categoriesStack)

    let displayCategories = data.categories.prefix(4)
    for (index, category) in displayCategories.enumerated() {
      let categoryRow = UIView()
      categoryRow.translatesAutoresizingMaskIntoConstraints = false
      categoryRow.heightAnchor.constraint(equalToConstant: 48).isActive = true
      categoriesStack.addArrangedSubview(categoryRow)

      if index > 0 {
        let separator = UIView()
        separator.backgroundColor = AlpsDesignTokens.border
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        categoriesStack.insertArrangedSubview(separator, at: index * 2 - 1)
      }

      let rowStack = UIStackView()
      rowStack.axis = .horizontal
      rowStack.spacing = 8
      rowStack.alignment = .center
      rowStack.translatesAutoresizingMaskIntoConstraints = false
      categoryRow.addSubview(rowStack)

      NSLayoutConstraint.activate([
        rowStack.topAnchor.constraint(equalTo: categoryRow.topAnchor),
        rowStack.leftAnchor.constraint(equalTo: categoryRow.leftAnchor, constant: 12),
        rowStack.rightAnchor.constraint(equalTo: categoryRow.rightAnchor, constant: -12),
        rowStack.bottomAnchor.constraint(equalTo: categoryRow.bottomAnchor),
      ])

      let nameLabel = UILabel()
      nameLabel.text = category.name
      nameLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
      nameLabel.textColor = AlpsDesignTokens.textMid
      rowStack.addArrangedSubview(nameLabel)

      let count = category.articles.count
      let countLabel = UILabel()
      countLabel.text = "\(count)"
      countLabel.font = UIFont.systemFont(ofSize: 12)
      countLabel.textColor = AlpsDesignTokens.textBody
      rowStack.addArrangedSubview(countLabel)

      rowStack.addArrangedSubview(UIView())

      let chevron2 = UILabel()
      chevron2.text = "›"
      chevron2.font = UIFont.systemFont(ofSize: 18)
      chevron2.textColor = AlpsDesignTokens.textLight
      rowStack.addArrangedSubview(chevron2)

      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCategory(_:)))
      categoryRow.addGestureRecognizer(tapGesture)
      categoryRow.isUserInteractionEnabled = true
      categoryRow.tag = index
      tapGesture.name = "category_\(category.id)"
    }
  }

  @objc private func didTapContinueAction() {
    panelViewController?.switchTab(to: .messages)
  }

  @objc private func didTapSearch() {
    panelViewController?.switchTab(to: .answers)
  }

  @objc private func didTapCategory(_ gesture: UITapGestureRecognizer) {
    guard let categoryView = gesture.view,
          let widgetData = widgetData else { return }

    let index = categoryView.tag
    let displayCategories = Array(widgetData.categories.prefix(4))
    guard index < displayCategories.count else { return }

    let category = displayCategories[index]
    let categoryVC = AlpsCategoryViewController(
      config: config,
      apiClient: apiClient,
      category: category
    )

    if let navController = (parent as? AlpsPanelViewController)?.navigationController {
      navController.pushViewController(categoryVC, animated: true)
    }
  }

  func updateWidgetData(_ data: WidgetDataResponse) {
    widgetData = data
    stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    populateContent()
  }

  func showError(_ error: String) {
    print("[HomeVC] Error: \(error)")
  }

  private func formatDate(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: dateString) {
      let relativeFormatter = RelativeDateTimeFormatter()
      return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
    return dateString
  }
}
