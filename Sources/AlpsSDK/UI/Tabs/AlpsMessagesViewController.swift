import UIKit

class AlpsMessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient

  private let tableView = UITableView()
  private let emptyStateLabel = UILabel()
  private var conversations: [ConversationSummary] = []
  private var isLoading = false

  init(config: AlpsConfig, apiClient: AlpsAPIClient) {
    self.config = config
    self.apiClient = apiClient
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupUI()
    loadConversations()
  }

  private func setupUI() {
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    emptyStateLabel.text = "No conversations yet.\nStart one to get help!"
    emptyStateLabel.numberOfLines = 2
    emptyStateLabel.textAlignment = .center
    emptyStateLabel.textColor = .systemGray
    emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
    emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(emptyStateLabel)

    NSLayoutConstraint.activate([
      emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])

    emptyStateLabel.isHidden = true
  }

  private func loadConversations() {
    guard let email = config.visitorEmail else {
      showEmptyState()
      return
    }

    isLoading = true
    apiClient.fetchCustomerConversations(email: email) { [weak self] result in
      DispatchQueue.main.async {
        self?.isLoading = false
        switch result {
        case .success(let response):
          self?.conversations = response.conversations.sorted { a, b in
            let dateA = a.lastMessageAt ?? a.createdAt
            let dateB = b.lastMessageAt ?? b.createdAt
            return dateA > dateB
          }
          self?.tableView.reloadData()
          if self?.conversations.isEmpty ?? true {
            self?.showEmptyState()
          } else {
            self?.emptyStateLabel.isHidden = true
          }
        case .failure(let error):
          print("[MessagesVC] Failed to load conversations: \(error)")
          self?.showEmptyState()
        }
      }
    }
  }

  private func showEmptyState() {
    emptyStateLabel.isHidden = false
    tableView.isHidden = true
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    conversations.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let conv = conversations[indexPath.row]

    var config = cell.defaultContentConfiguration()
    config.text = conv.lastMessage?.content ?? "No messages"
    config.secondaryText = formatDate(conv.lastMessageAt ?? conv.createdAt)
    config.textProperties.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    config.secondaryTextProperties.font = UIFont.systemFont(ofSize: 12)
    config.secondaryTextProperties.color = .systemGray

    cell.contentConfiguration = config
    return cell
  }

  // MARK: - UITableViewDelegate

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let conv = conversations[indexPath.row]
    openThread(conversationId: conv.id)
  }

  private func openThread(conversationId: String) {
    config.conversationId = conversationId
    AlpsVisitorStore.saveConversationId(conversationId, for: config.widgetKey)

    let threadVC = AlpsThreadViewController(
      config: config,
      apiClient: apiClient,
      conversationId: conversationId
    )

    if let nav = navigationController ?? (parent?.navigationController) {
      nav.pushViewController(threadVC, animated: true)
    }
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
