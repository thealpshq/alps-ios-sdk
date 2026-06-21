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
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
    if let panelVC = parent as? AlpsPanelViewController {
      panelVC.switchTab(to: .home)
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
    let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
    let conv = conversations[indexPath.row]

    cell.contentView.subviews.forEach { $0.removeFromSuperview() }
    cell.selectionStyle = .gray
    cell.backgroundColor = .white

    let avatarView = UIView()
    avatarView.backgroundColor = AlpsDesignTokens.avatarBg
    avatarView.layer.cornerRadius = 19
    avatarView.clipsToBounds = true
    avatarView.translatesAutoresizingMaskIntoConstraints = false
    avatarView.widthAnchor.constraint(equalToConstant: 38).isActive = true
    avatarView.heightAnchor.constraint(equalToConstant: 38).isActive = true
    cell.contentView.addSubview(avatarView)

    let initials = UILabel()
    initials.text = "?"
    initials.textColor = .white
    initials.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    initials.textAlignment = .center
    initials.translatesAutoresizingMaskIntoConstraints = false
    avatarView.addSubview(initials)

    NSLayoutConstraint.activate([
      initials.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
      initials.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
    ])

    let titleLabel = UILabel()
    titleLabel.text = "Conversation"
    titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    titleLabel.textColor = AlpsDesignTokens.textMid
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    cell.contentView.addSubview(titleLabel)

    let timeLabel = UILabel()
    timeLabel.text = formatDate(conv.lastMessageAt ?? conv.createdAt)
    timeLabel.font = UIFont.systemFont(ofSize: 12)
    timeLabel.textColor = AlpsDesignTokens.textLight
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    cell.contentView.addSubview(timeLabel)

    let messageLabel = UILabel()
    let preview = (conv.lastMessage?.content ?? "No messages").prefix(60)
    messageLabel.text = String(preview)
    messageLabel.font = UIFont.systemFont(ofSize: 12)
    messageLabel.textColor = AlpsDesignTokens.textBody
    messageLabel.numberOfLines = 1
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    cell.contentView.addSubview(messageLabel)

    let unreadBadge = UIView()
    unreadBadge.backgroundColor = AlpsDesignTokens.dark
    unreadBadge.layer.cornerRadius = 4
    unreadBadge.translatesAutoresizingMaskIntoConstraints = false
    unreadBadge.widthAnchor.constraint(equalToConstant: 8).isActive = true
    unreadBadge.heightAnchor.constraint(equalToConstant: 8).isActive = true
    cell.contentView.addSubview(unreadBadge)

    NSLayoutConstraint.activate([
      avatarView.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor, constant: 12),
      avatarView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),

      titleLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
      titleLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: unreadBadge.leftAnchor, constant: -8),

      timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
      timeLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 12),

      messageLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
      messageLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 12),
      messageLabel.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: -12),
      messageLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),

      unreadBadge.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: -12),
      unreadBadge.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
    ])

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
