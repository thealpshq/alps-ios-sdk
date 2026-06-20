import UIKit

class AlpsThreadViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  let conversationId: String

  private let tableView = UITableView()
  private let inputContainer = UIView()
  private let messageInput = UITextView()
  private let sendButton = UIButton(type: .system)
  private let preChatFormView = UIView()
  private var messages: [Message] = []
  private var pusherClient: AlpsPusherClient?
  private var showPreChatForm = false

  init(
    config: AlpsConfig,
    apiClient: AlpsAPIClient,
    conversationId: String
  ) {
    self.config = config
    self.apiClient = apiClient
    self.conversationId = conversationId
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    title = "Chat"
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .close,
      target: self,
      action: #selector(didClose)
    )

    restoreVisitorIdentity()
    setupUI()
    setupKeyboardNotifications()
    setupPusher()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    pusherClient?.disconnect()
  }

  private func restoreVisitorIdentity() {
    if let stored = AlpsVisitorStore.load(widgetKey: config.widgetKey) {
      if config.visitorName == nil {
        config.visitorName = stored.name
      }
      if config.visitorEmail == nil {
        config.visitorEmail = stored.email
      }
    }

    showPreChatForm = (config.visitorName == nil || config.visitorEmail == nil)
  }

  private func setupUI() {
    if showPreChatForm {
      setupPreChatForm()
    } else {
      setupMessageThread()
    }
  }

  private func setupMessageThread() {
    // Table view for messages
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "messageCell")
    tableView.separatorStyle = .none
    tableView.backgroundColor = .white
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)

    // Input container
    inputContainer.backgroundColor = .systemGray6
    inputContainer.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(inputContainer)

    // Message input
    messageInput.font = UIFont.systemFont(ofSize: 14)
    messageInput.layer.cornerRadius = 8
    messageInput.clipsToBounds = true
    messageInput.translatesAutoresizingMaskIntoConstraints = false
    messageInput.backgroundColor = .white
    messageInput.text = "Type a message..."
    messageInput.textColor = .systemGray
    messageInput.delegate = self
    inputContainer.addSubview(messageInput)

    // Send button
    sendButton.setTitle("Send", for: .normal)
    sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    sendButton.translatesAutoresizingMaskIntoConstraints = false
    sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)
    inputContainer.addSubview(sendButton)

    // Constraints
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

      inputContainer.leftAnchor.constraint(equalTo: view.leftAnchor),
      inputContainer.rightAnchor.constraint(equalTo: view.rightAnchor),
      inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      inputContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

      messageInput.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
      messageInput.leftAnchor.constraint(equalTo: inputContainer.leftAnchor, constant: 12),
      messageInput.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8),
      messageInput.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8),
      messageInput.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

      sendButton.rightAnchor.constraint(equalTo: inputContainer.rightAnchor, constant: -12),
      sendButton.centerYAnchor.constraint(equalTo: messageInput.centerYAnchor),
      sendButton.widthAnchor.constraint(equalToConstant: 50),
    ])
  }

  private func setupPreChatForm() {
    preChatFormView.backgroundColor = .white
    preChatFormView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(preChatFormView)

    NSLayoutConstraint.activate([
      preChatFormView.topAnchor.constraint(equalTo: view.topAnchor),
      preChatFormView.leftAnchor.constraint(equalTo: view.leftAnchor),
      preChatFormView.rightAnchor.constraint(equalTo: view.rightAnchor),
      preChatFormView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    preChatFormView.addSubview(stack)

    let titleLabel = UILabel()
    titleLabel.text = "Before we chat..."
    titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
    stack.addArrangedSubview(titleLabel)

    let nameField = UITextField()
    nameField.placeholder = "Your name"
    nameField.borderStyle = .roundedRect
    nameField.translatesAutoresizingMaskIntoConstraints = false
    nameField.heightAnchor.constraint(equalToConstant: 44).isActive = true
    stack.addArrangedSubview(nameField)

    let emailField = UITextField()
    emailField.placeholder = "Your email"
    emailField.borderStyle = .roundedRect
    emailField.keyboardType = .emailAddress
    emailField.translatesAutoresizingMaskIntoConstraints = false
    emailField.heightAnchor.constraint(equalToConstant: 44).isActive = true
    stack.addArrangedSubview(emailField)

    let submitButton = UIButton(type: .system)
    submitButton.setTitle("Continue", for: .normal)
    submitButton.backgroundColor = .systemBlue
    submitButton.setTitleColor(.white, for: .normal)
    submitButton.layer.cornerRadius = 8
    submitButton.translatesAutoresizingMaskIntoConstraints = false
    submitButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    submitButton.addTarget(self, action: #selector(submitPreChatForm), for: .touchUpInside)
    stack.addArrangedSubview(submitButton)

    submitButton.tag = 1 // Store reference

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: preChatFormView.topAnchor, constant: 32),
      stack.leftAnchor.constraint(equalTo: preChatFormView.leftAnchor, constant: 16),
      stack.rightAnchor.constraint(equalTo: preChatFormView.rightAnchor, constant: -16),
    ])
  }

  @objc private func submitPreChatForm() {
    guard let nameField = view.viewWithTag(1)?.subviews[0] as? UITextField,
          let emailField = view.viewWithTag(1)?.subviews[1] as? UITextField else {
      return
    }

    let name = nameField.text ?? ""
    let email = emailField.text ?? ""

    guard !name.isEmpty, !email.isEmpty else { return }

    config.visitorName = name
    config.visitorEmail = email
    AlpsVisitorStore.save(config: config)

    preChatFormView.removeFromSuperview()
    showPreChatForm = false
    setupMessageThread()
  }

  private func setupPusher() {
    guard let pusherKey = config.pusherKey,
          let pusherCluster = config.pusherCluster else {
      return
    }

    pusherClient = AlpsPusherClient()
    pusherClient?.onMessageReceived = { [weak self] message in
      DispatchQueue.main.async {
        self?.messages.append(message)
        self?.tableView.reloadData()
        self?.scrollToBottom()
      }
    }

    pusherClient?.onConversationStatusChanged = { status in
      print("[ThreadVC] Conversation status changed: \(status)")
    }

    pusherClient?.connect(pusherKey: pusherKey, cluster: pusherCluster, conversationId: conversationId)
  }

  @objc private func didClose() {
    navigationController?.popViewController(animated: true)
  }

  @objc private func didTapSend() {
    guard let text = messageInput.text, !text.isEmpty, text != "Type a message..." else {
      return
    }

    let name = config.visitorName ?? "Guest"
    let email = config.visitorEmail ?? ""

    apiClient.sendMessage(name: name, email: email, message: text) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success(let response):
          self?.config.conversationId = response.conversationId
          AlpsVisitorStore.saveConversationId(response.conversationId, for: self?.config.widgetKey ?? "")
          self?.messages.append(response.message)
          self?.tableView.reloadData()
          self?.messageInput.text = "Type a message..."
          self?.messageInput.textColor = .systemGray
          self?.scrollToBottom()
        case .failure(let error):
          print("[ThreadVC] Failed to send message: \(error)")
        }
      }
    }
  }

  private func scrollToBottom() {
    if messages.count > 0 {
      let lastIndexPath = IndexPath(row: messages.count - 1, section: 0)
      tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
    }
  }

  private func setupKeyboardNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }

  @objc private func keyboardWillShow(notification: NSNotification) {
    scrollToBottom()
  }

  @objc private func keyboardWillHide(notification: NSNotification) {
    scrollToBottom()
  }

  // MARK: - UITextViewDelegate

  func textViewDidBeginEditing(_ textView: UITextView) {
    if textView.textColor == .systemGray {
      textView.text = nil
      textView.textColor = .black
    }
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.isEmpty {
      textView.text = "Type a message..."
      textView.textColor = .systemGray
    }
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: "messageCell")
    let message = messages[indexPath.row]

    cell.contentView.subviews.forEach { $0.removeFromSuperview() }
    cell.selectionStyle = .none
    cell.backgroundColor = .white

    let isFromCustomer = message.direction == "outbound"

    // Message bubble
    let bubbleView = UIView()
    bubbleView.backgroundColor = isFromCustomer ? .systemBlue : .systemGray6
    bubbleView.layer.cornerRadius = 12
    bubbleView.clipsToBounds = true
    bubbleView.translatesAutoresizingMaskIntoConstraints = false
    cell.contentView.addSubview(bubbleView)

    // Message label
    let label = UILabel()
    label.text = message.content
    label.textColor = isFromCustomer ? .white : .black
    label.numberOfLines = 0
    label.font = UIFont.systemFont(ofSize: 14)
    label.translatesAutoresizingMaskIntoConstraints = false
    bubbleView.addSubview(label)

    // Sender name (for agent messages)
    if !isFromCustomer, let senderName = message.senderName {
      let senderLabel = UILabel()
      senderLabel.text = senderName
      senderLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
      senderLabel.textColor = .systemGray
      senderLabel.translatesAutoresizingMaskIntoConstraints = false
      cell.contentView.insertSubview(senderLabel, belowSubview: bubbleView)

      NSLayoutConstraint.activate([
        senderLabel.bottomAnchor.constraint(equalTo: bubbleView.topAnchor, constant: -4),
        senderLabel.leftAnchor.constraint(equalTo: bubbleView.leftAnchor),
      ])
    }

    // Constraints
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
      label.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
      label.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 12),
      label.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -12),
    ])

    if isFromCustomer {
      NSLayoutConstraint.activate([
        bubbleView.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: -16),
        bubbleView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
        bubbleView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
        bubbleView.widthAnchor.constraint(lessThanOrEqualTo: cell.contentView.widthAnchor, multiplier: 0.75),
      ])
    } else {
      NSLayoutConstraint.activate([
        bubbleView.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor, constant: 16),
        bubbleView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
        bubbleView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
        bubbleView.widthAnchor.constraint(lessThanOrEqualTo: cell.contentView.widthAnchor, multiplier: 0.75),
      ])
    }

    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }
}
