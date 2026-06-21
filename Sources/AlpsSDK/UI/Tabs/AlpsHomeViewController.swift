import UIKit

class AlpsHomeViewController: UIViewController {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  var widgetData: WidgetDataResponse?
  weak var panelViewController: AlpsPanelViewController?

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let debugLabel = UILabel()

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

    if widgetData == nil {
      debugLabel.text = "⏳ Loading widget data..."
      debugLabel.textColor = .systemOrange
    }
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

    debugLabel.numberOfLines = 0
    debugLabel.font = UIFont.systemFont(ofSize: 11)
    debugLabel.textColor = .systemGray
    debugLabel.isHidden = true
    stackView.addArrangedSubview(debugLabel)
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

    NSLayoutConstraint.activate([
      headerHStack.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 16),
      headerHStack.leftAnchor.constraint(equalTo: headerCard.leftAnchor, constant: 16),
      headerHStack.rightAnchor.constraint(equalTo: headerCard.rightAnchor, constant: -16),
      headerHStack.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16),
    ])

    let welcomeLabel = UILabel()
    welcomeLabel.text = data.welcomeMessage ?? ""
    welcomeLabel.numberOfLines = 0
    welcomeLabel.font = UIFont.systemFont(ofSize: 14)
    welcomeLabel.textColor = .white
    headerHStack.addArrangedSubview(welcomeLabel)

    let spacer = UIView()
    headerHStack.addArrangedSubview(spacer)

    let avatarContainer = UIView()
    avatarContainer.translatesAutoresizingMaskIntoConstraints = false
    avatarContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
    headerHStack.addArrangedSubview(avatarContainer)

    let agents = data.onlineAgents ?? []
    let displayAgents = Array(agents.prefix(3))

    for (index, agent) in displayAgents.enumerated() {
      let avatar = UIView()
      avatar.backgroundColor = AlpsDesignTokens.avatarBg
      avatar.layer.cornerRadius = 14
      avatar.clipsToBounds = true
      avatar.translatesAutoresizingMaskIntoConstraints = false
      avatar.widthAnchor.constraint(equalToConstant: 28).isActive = true
      avatar.heightAnchor.constraint(equalToConstant: 28).isActive = true
      avatarContainer.addSubview(avatar)

      let initial = UILabel()
      let firstName = agent.firstName ?? "A"
      initial.text = String(firstName.prefix(1)).uppercased()
      initial.textColor = .white
      initial.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
      initial.textAlignment = .center
      initial.translatesAutoresizingMaskIntoConstraints = false
      avatar.addSubview(initial)

      NSLayoutConstraint.activate([
        initial.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
        initial.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
      ])

      let xOffset = CGFloat(index) * -8
      NSLayoutConstraint.activate([
        avatar.leftAnchor.constraint(equalTo: avatarContainer.leftAnchor, constant: xOffset),
        avatar.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
      ])

      if let profileURL = agent.profilePicture, let url = URL(string: profileURL) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
          DispatchQueue.main.async {
            if let data = data, let image = UIImage(data: data) {
              let imageView = UIImageView(image: image)
              imageView.contentMode = .scaleAspectFill
              imageView.clipsToBounds = true
              imageView.translatesAutoresizingMaskIntoConstraints = false
              avatar.addSubview(imageView)
              NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: avatar.topAnchor),
                imageView.leftAnchor.constraint(equalTo: avatar.leftAnchor),
                imageView.rightAnchor.constraint(equalTo: avatar.rightAnchor),
                imageView.bottomAnchor.constraint(equalTo: avatar.bottomAnchor),
              ])
              initial.isHidden = true
            }
          }
        }.resume()
      }
    }

    let actionCard = UIView()
    actionCard.backgroundColor = .white
    actionCard.layer.borderWidth = 1
    actionCard.layer.borderColor = AlpsDesignTokens.border.cgColor
    actionCard.layer.cornerRadius = AlpsDesignTokens.radiusCard
    actionCard.clipsToBounds = true
    actionCard.translatesAutoresizingMaskIntoConstraints = false
    actionCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
    stackView.addArrangedSubview(actionCard)

    let actionStack = UIStackView()
    actionStack.axis = .vertical
    actionStack.spacing = 8
    actionStack.alignment = .fill
    actionStack.translatesAutoresizingMaskIntoConstraints = false
    actionCard.addSubview(actionStack)

    NSLayoutConstraint.activate([
      actionStack.topAnchor.constraint(equalTo: actionCard.topAnchor, constant: 12),
      actionStack.leftAnchor.constraint(equalTo: actionCard.leftAnchor, constant: 12),
      actionStack.rightAnchor.constraint(equalTo: actionCard.rightAnchor, constant: -12),
      actionStack.bottomAnchor.constraint(equalTo: actionCard.bottomAnchor, constant: -12),
    ])

    let titleStack = UIStackView()
    titleStack.axis = .horizontal
    titleStack.spacing = 8
    titleStack.alignment = .center
    actionStack.addArrangedSubview(titleStack)

    let actionLabel = UILabel()
    actionLabel.text = "Continue conversation"
    actionLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
    actionLabel.textColor = AlpsDesignTokens.textMid
    titleStack.addArrangedSubview(actionLabel)

    titleStack.addArrangedSubview(UIView())

    let chevron = UILabel()
    chevron.text = "›"
    chevron.font = UIFont.systemFont(ofSize: 20)
    chevron.textColor = AlpsDesignTokens.textBody
    titleStack.addArrangedSubview(chevron)

    if config.conversationId != nil {
      guard let email = config.visitorEmail else { return }

      apiClient.fetchCustomerConversations(email: email) { [weak self] result in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            if let first = response.conversations.first, let lastMsg = first.lastMessage {
              let preview = String((lastMsg.content).prefix(60))
              let previewLabel = UILabel()
              previewLabel.text = preview
              previewLabel.font = UIFont.systemFont(ofSize: 12)
              previewLabel.textColor = AlpsDesignTokens.textBody
              previewLabel.numberOfLines = 2
              actionStack.addArrangedSubview(previewLabel)

              let timeLabel = UILabel()
              timeLabel.text = self?.formatDate(first.lastMessageAt ?? first.createdAt) ?? ""
              timeLabel.font = UIFont.systemFont(ofSize: 12)
              timeLabel.textColor = AlpsDesignTokens.textLight
              actionStack.addArrangedSubview(timeLabel)
            }
          case .failure:
            break
          }
        }
      }
    }

    let tapAction = UITapGestureRecognizer(target: self, action: #selector(didTapContinueAction))
    actionCard.addGestureRecognizer(tapAction)
    actionCard.isUserInteractionEnabled = true

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

    let searchIcon = UILabel()
    searchIcon.text = "🔍"
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
    }
  }

  @objc private func didTapContinueAction() {
    panelViewController?.switchTab(to: .messages)
  }

  @objc private func didTapSearch() {
    panelViewController?.switchTab(to: .answers)
  }

  func updateWidgetData(_ data: WidgetDataResponse) {
    widgetData = data
    debugLabel.isHidden = false
    debugLabel.text = "✓ Data loaded: \(data.categories.count) categories"
    debugLabel.textColor = .systemGreen
    stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    populateContent()
  }

  func showError(_ error: String) {
    debugLabel.isHidden = false
    debugLabel.text = "❌ Failed to load: \(error)"
    debugLabel.textColor = .systemRed
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
