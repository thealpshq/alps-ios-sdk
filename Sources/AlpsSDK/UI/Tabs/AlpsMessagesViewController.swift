import UIKit

class AlpsMessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient

  private let tableView = UITableView()
  private let emptyStateLabel = UILabel()
  private let startButton = UIButton(type: .system)
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
    tableView.register(AlpsConversationCell.self, forCellReuseIdentifier: "cell")
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

    emptyStateLabel.text = "No conversations yet.\nStart one to get help!"
    emptyStateLabel.numberOfLines = 2
    emptyStateLabel.textAlignment = .center
    emptyStateLabel.textColor = AlpsDesignTokens.textBody
    emptyStateLabel.font = UIFont.systemFont(ofSize: 14)
    emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(emptyStateLabel)

    startButton.setTitle("Send us a message", for: .normal)
    startButton.backgroundColor = AlpsDesignTokens.accent
    startButton.setTitleColor(.white, for: .normal)
    startButton.layer.cornerRadius = 24
    startButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
    startButton.translatesAutoresizingMaskIntoConstraints = false
    startButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    startButton.addTarget(self, action: #selector(didTapStartMessage), for: .touchUpInside)
    view.addSubview(startButton)

    NSLayoutConstraint.activate([
      emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
      startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      startButton.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 24),
      startButton.widthAnchor.constraint(equalToConstant: 200),
    ])

    emptyStateLabel.isHidden = true
    startButton.isHidden = true
  }

  @objc private func didTapStartMessage() {
    let threadVC = AlpsThreadViewController(
      config: config,
      apiClient: apiClient,
      conversationId: UUID().uuidString
    )

    if let nav = navigationController ?? (parent?.navigationController) {
      nav.pushViewController(threadVC, animated: true)
    }
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
            self?.startButton.isHidden = true
            self?.tableView.isHidden = false
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
    startButton.isHidden = false
    tableView.isHidden = true
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    conversations.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AlpsConversationCell
    let conv = conversations[indexPath.row]
    cell.configure(with: conv)
    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    72
  }

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
