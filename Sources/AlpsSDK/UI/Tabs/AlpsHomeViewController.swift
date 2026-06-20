import UIKit

class AlpsHomeViewController: UIViewController {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  var widgetData: WidgetDataResponse?

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let debugLabel = UILabel()

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

    let headerStack = UIStackView()
    headerStack.axis = .vertical
    headerStack.spacing = 12
    headerStack.alignment = .leading
    headerStack.translatesAutoresizingMaskIntoConstraints = false
    headerCard.addSubview(headerStack)

    NSLayoutConstraint.activate([
      headerStack.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 16),
      headerStack.leftAnchor.constraint(equalTo: headerCard.leftAnchor, constant: 16),
      headerStack.rightAnchor.constraint(equalTo: headerCard.rightAnchor, constant: -16),
      headerStack.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16),
    ])

    if let message = data.welcomeMessage {
      let label = UILabel()
      label.text = message
      label.numberOfLines = 0
      label.font = UIFont.systemFont(ofSize: 14)
      label.textColor = .white
      headerStack.addArrangedSubview(label)
    }

    if let agents = data.onlineAgents, !agents.isEmpty {
      let agentsLabel = UILabel()
      agentsLabel.text = "Available Agents"
      agentsLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
      agentsLabel.textColor = AlpsDesignTokens.textLight
      headerStack.addArrangedSubview(agentsLabel)

      for agent in agents {
        let agentView = UIView()
        agentView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        agentView.layer.cornerRadius = AlpsDesignTokens.radiusCard
        agentView.translatesAutoresizingMaskIntoConstraints = false
        agentView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let nameLabel = UILabel()
        let fullName = "\(agent.firstName ?? "") \(agent.lastName ?? "")".trimmingCharacters(in: .whitespaces)
        nameLabel.text = fullName
        nameLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        agentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
          nameLabel.leftAnchor.constraint(equalTo: agentView.leftAnchor, constant: 12),
          nameLabel.centerYAnchor.constraint(equalTo: agentView.centerYAnchor),
        ])

        headerStack.addArrangedSubview(agentView)
      }
    }

    let actionCard = UIView()
    actionCard.backgroundColor = .white
    actionCard.layer.borderWidth = 1
    actionCard.layer.borderColor = AlpsDesignTokens.border.cgColor
    actionCard.layer.cornerRadius = AlpsDesignTokens.radiusCard
    actionCard.clipsToBounds = true
    actionCard.translatesAutoresizingMaskIntoConstraints = false
    actionCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
    stackView.addArrangedSubview(actionCard)

    let actionStack = UIStackView()
    actionStack.axis = .horizontal
    actionStack.spacing = 12
    actionStack.alignment = .center
    actionStack.translatesAutoresizingMaskIntoConstraints = false
    actionCard.addSubview(actionStack)

    let actionLabel = UILabel()
    actionLabel.text = "Continue conversation"
    actionLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
    actionLabel.textColor = AlpsDesignTokens.textMid
    actionStack.addArrangedSubview(actionLabel)

    let spacer = UIView()
    actionStack.addArrangedSubview(spacer)

    let chevron = UILabel()
    chevron.text = "›"
    chevron.font = UIFont.systemFont(ofSize: 20)
    chevron.textColor = AlpsDesignTokens.textBody
    actionStack.addArrangedSubview(chevron)

    NSLayoutConstraint.activate([
      actionStack.topAnchor.constraint(equalTo: actionCard.topAnchor, constant: 16),
      actionStack.leftAnchor.constraint(equalTo: actionCard.leftAnchor, constant: 12),
      actionStack.rightAnchor.constraint(equalTo: actionCard.rightAnchor, constant: -12),
      actionStack.bottomAnchor.constraint(equalTo: actionCard.bottomAnchor, constant: -16),
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
}
