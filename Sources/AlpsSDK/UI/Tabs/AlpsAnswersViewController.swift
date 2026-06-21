import UIKit

class AlpsAnswersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  var widgetData: WidgetDataResponse?

  private let searchField = UITextField()
  private let tableView = UITableView()
  private let emptyStateLabel = UILabel()
  private var articles: [Article] = []
  private var allArticles: [Article] = []
  private var isSearching = false
  private var searchTask: DispatchWorkItem?

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
    loadFeaturedArticles()
  }

  private func setupUI() {
    let searchContainer = UIView()
    searchContainer.backgroundColor = AlpsDesignTokens.searchBg
    searchContainer.layer.cornerRadius = AlpsDesignTokens.radiusInput
    searchContainer.clipsToBounds = true
    searchContainer.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(searchContainer)

    let searchIcon = UIImageView()
    searchIcon.image = UIImage(systemName: "magnifyingglass")
    searchIcon.tintColor = AlpsDesignTokens.textLight
    searchIcon.contentMode = .scaleAspectFit
    searchIcon.translatesAutoresizingMaskIntoConstraints = false
    searchIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
    searchIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
    searchContainer.addSubview(searchIcon)

    searchField.placeholder = "Search for articles and videos"
    searchField.font = UIFont.systemFont(ofSize: 13)
    searchField.textColor = AlpsDesignTokens.textMid
    searchField.borderStyle = .none
    searchField.delegate = self
    searchField.translatesAutoresizingMaskIntoConstraints = false
    searchContainer.addSubview(searchField)

    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "articleCell")
    tableView.separatorColor = AlpsDesignTokens.border
    tableView.separatorStyle = .singleLine
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)

    emptyStateLabel.text = "No articles found"
    emptyStateLabel.textAlignment = .center
    emptyStateLabel.textColor = AlpsDesignTokens.textBody
    emptyStateLabel.isHidden = true
    emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(emptyStateLabel)

    NSLayoutConstraint.activate([
      searchContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      searchContainer.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      searchContainer.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      searchContainer.heightAnchor.constraint(equalToConstant: 40),

      searchIcon.leftAnchor.constraint(equalTo: searchContainer.leftAnchor, constant: 12),
      searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

      searchField.leftAnchor.constraint(equalTo: searchIcon.rightAnchor, constant: 8),
      searchField.rightAnchor.constraint(equalTo: searchContainer.rightAnchor, constant: -12),
      searchField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

      tableView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 12),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  private func loadFeaturedArticles() {
    articles = []
    allArticles = []
    if let categories = widgetData?.categories {
      for category in categories {
        allArticles.append(contentsOf: category.articles)
        articles.append(contentsOf: category.articles.prefix(5))
      }
    }
    tableView.reloadData()
    updateEmptyState()
  }

  func textFieldDidChangeSelection(_ UITextField: UITextField) {
    searchTask?.cancel()

    guard let searchText = searchField.text, !searchText.isEmpty else {
      isSearching = false
      articles = allArticles.prefix(5).map { $0 }
      tableView.reloadData()
      updateEmptyState()
      return
    }

    isSearching = true

    let task = DispatchWorkItem { [weak self] in
      self?.apiClient.search(keyword: searchText) { [weak self] result in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            self?.articles = response.articles ?? []
            self?.tableView.reloadData()
            self?.updateEmptyState()
          case .failure(let error):
            print("[AnswersVC] Search failed: \(error)")
          }
        }
      }
    }

    searchTask = task
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
  }

  private func updateEmptyState() {
    emptyStateLabel.isHidden = !articles.isEmpty
    tableView.isHidden = articles.isEmpty
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    articles.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: "articleCell")
    let article = articles[indexPath.row]

    cell.contentView.subviews.forEach { $0.removeFromSuperview() }
    cell.selectionStyle = .gray
    cell.backgroundColor = .white

    let titleLabel = UILabel()
    titleLabel.text = article.title
    titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    titleLabel.numberOfLines = 2
    titleLabel.textColor = AlpsDesignTokens.textMid
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    cell.contentView.addSubview(titleLabel)

    let chevron = UILabel()
    chevron.text = "›"
    chevron.font = UIFont.systemFont(ofSize: 24)
    chevron.textColor = AlpsDesignTokens.textLight
    chevron.translatesAutoresizingMaskIntoConstraints = false
    cell.contentView.addSubview(chevron)

    if let description = article.description {
      let descLabel = UILabel()
      descLabel.text = description
      descLabel.font = UIFont.systemFont(ofSize: 12)
      descLabel.textColor = AlpsDesignTokens.textBody
      descLabel.numberOfLines = 2
      descLabel.translatesAutoresizingMaskIntoConstraints = false
      cell.contentView.addSubview(descLabel)

      NSLayoutConstraint.activate([
        titleLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
        titleLabel.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor, constant: 16),
        titleLabel.rightAnchor.constraint(equalTo: chevron.leftAnchor, constant: -12),

        descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
        descLabel.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor, constant: 16),
        descLabel.rightAnchor.constraint(equalTo: chevron.leftAnchor, constant: -12),
        descLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),

        chevron.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: -12),
        chevron.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        titleLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 16),
        titleLabel.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor, constant: 16),
        titleLabel.rightAnchor.constraint(equalTo: chevron.leftAnchor, constant: -12),
        titleLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -16),

        chevron.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: -12),
        chevron.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
      ])
    }

    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let article = articles[indexPath.row]
    openArticle(article)
  }

  private func openArticle(_ article: Article) {
    let articleVC = AlpsArticleViewController(article: article)
    if let nav = navigationController ?? (parent?.navigationController) {
      nav.pushViewController(articleVC, animated: true)
    }
  }

  func updateWidgetData(_ data: WidgetDataResponse) {
    widgetData = data
    allArticles = (data.categories).flatMap { $0.articles }
    loadFeaturedArticles()
  }

  func showError(_ error: String) {
    emptyStateLabel.text = "Error loading articles"
    emptyStateLabel.isHidden = false
    tableView.isHidden = true
  }
}
