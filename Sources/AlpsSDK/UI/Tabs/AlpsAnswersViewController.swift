import UIKit

class AlpsAnswersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  var widgetData: WidgetDataResponse?

  private let searchBar = UISearchBar()
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
    // Search bar
    searchBar.delegate = self
    searchBar.placeholder = "Search help articles..."
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(searchBar)

    NSLayoutConstraint.activate([
      searchBar.topAnchor.constraint(equalTo: view.topAnchor),
      searchBar.leftAnchor.constraint(equalTo: view.leftAnchor),
      searchBar.rightAnchor.constraint(equalTo: view.rightAnchor),
      searchBar.heightAnchor.constraint(equalToConstant: 56),
    ])

    // Table view
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "articleCell")
    tableView.separatorStyle = .singleLine
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // Empty state
    emptyStateLabel.text = "No articles found"
    emptyStateLabel.textAlignment = .center
    emptyStateLabel.textColor = .systemGray
    emptyStateLabel.isHidden = true
    emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(emptyStateLabel)

    NSLayoutConstraint.activate([
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

  // MARK: - UISearchBarDelegate

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    searchTask?.cancel()

    guard !searchText.isEmpty else {
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

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }

  private func updateEmptyState() {
    emptyStateLabel.isHidden = !articles.isEmpty
    tableView.isHidden = articles.isEmpty
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    articles.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "articleCell", for: indexPath)
    let article = articles[indexPath.row]

    cell.contentView.subviews.forEach { $0.removeFromSuperview() }

    let titleLabel = UILabel()
    titleLabel.text = article.title
    titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    titleLabel.numberOfLines = 2
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    cell.contentView.addSubview(titleLabel)

    if let description = article.description {
      let descLabel = UILabel()
      descLabel.text = description
      descLabel.font = UIFont.systemFont(ofSize: 12)
      descLabel.textColor = .systemGray
      descLabel.numberOfLines = 2
      descLabel.translatesAutoresizingMaskIntoConstraints = false
      cell.contentView.addSubview(descLabel)

      NSLayoutConstraint.activate([
        titleLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
        titleLabel.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor, constant: 16),
        titleLabel.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: -16),

        descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
        descLabel.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor, constant: 16),
        descLabel.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: -16),
        descLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
      ])
    } else {
      NSLayoutConstraint.activate([
        titleLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
        titleLabel.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor, constant: 16),
        titleLabel.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: -16),
        titleLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
      ])
    }

    cell.accessoryType = .disclosureIndicator
    cell.selectionStyle = .gray

    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }

  // MARK: - UITableViewDelegate

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
}
