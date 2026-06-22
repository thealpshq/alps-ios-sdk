import UIKit

class AlpsCategoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  let category: Category

  private let tableView = UITableView()

  init(
    config: AlpsConfig,
    apiClient: AlpsAPIClient,
    category: Category
  ) {
    self.config = config
    self.apiClient = apiClient
    self.category = category
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    title = category.name

    setupTableView()
    setupNavigationBar()
  }

  private func setupNavigationBar() {
    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }

  private func setupTableView() {
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "articleCell")
    tableView.separatorStyle = .singleLine
    tableView.separatorColor = AlpsDesignTokens.border
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    category.articles.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "articleCell", for: indexPath)
    let article = category.articles[indexPath.row]

    var config = cell.defaultContentConfiguration()
    config.text = article.title
    config.textProperties.font = UIFont.systemFont(ofSize: 13, weight: .medium)
    config.textProperties.color = AlpsDesignTokens.textMid
    config.secondaryText = article.description
    config.secondaryTextProperties.font = UIFont.systemFont(ofSize: 12)
    config.secondaryTextProperties.color = AlpsDesignTokens.textBody
    config.secondaryTextProperties.numberOfLines = 2
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let article = category.articles[indexPath.row]
    openArticle(article)
  }

  private func openArticle(_ article: Article) {
    let articleVC = AlpsArticleViewController(article: article)
    navigationController?.pushViewController(articleVC, animated: true)
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }
}
