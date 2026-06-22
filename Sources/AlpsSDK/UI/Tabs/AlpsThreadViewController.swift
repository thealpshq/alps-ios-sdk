import UIKit

class AlpsThreadViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  let conversationId: String

  private let headerView = UIView()
  private let tableView = UITableView()
  private let inputContainer = UIView()
  private let messageInput = UITextView()
  private let sendButton = UIButton(type: .system)
  private let emojiButton = UIButton(type: .system)
  private let attachmentButton = UIButton(type: .system)

  private var nameField: UITextField?
  private var emailField: UITextField?
  private var messages: [Message] = []
  private var pusherClient: AlpsPusherClient?
  private var showPreChatForm = false
  private var inputBottomConstraint: NSLayoutConstraint?
  private var conversationStatus: String = "active"

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
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .close,
      target: self,
      action: #selector(didClose)
    )

    restoreVisitorIdentity()
    setupUI()
    setupKeyboardNotifications()
    setupPusher()
    loadMessageHistory()
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
      setupThreadUI()
    }
  }

  private func setupThreadUI() {
    setupHeader()
    setupTableView()
    setupInputBar()
    setupConstraints()
  }

  private func setupHeader() {
    headerView.backgroundColor = .white
    headerView.translatesAutoresizingMaskIntoConstraints = false
    headerView.layer.borderBottomWidth = 1
    headerView.layer.borderBottomColor = AlpsDesignTokens.border.cgColor
    view.addSubview(headerView)

    let backButton = UIButton(type: .system)
    backButton.translatesAutoresizingMaskIntoConstraints = false
    backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
    backButton.tintColor = AlpsDesignTokens.dark
    backButton.layer.borderWidth = 1.5
    backButton.layer.borderColor = AlpsDesignTokens.border.cgColor
    backButton.layer.cornerRadius = 8
    backButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
    backButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
    backButton.addTarget(self, action: #selector(didClose), for: .touchUpInside)
    headerView.addSubview(backButton)

    let avatarStack = UIStackView()
    avatarStack.axis = .horizontal
    avatarStack.alignment = .center
    avatarStack.spacing = -8
    avatarStack.translatesAutoresizingMaskIntoConstraints = false
    headerView.addSubview(avatarStack)

    let teamAvatarView = UIImageView()
    teamAvatarView.contentMode = .scaleAspectFill
    teamAvatarView.layer.cornerRadius = 14
    teamAvatarView.clipsToBounds = true
    teamAvatarView.backgroundColor = AlpsDesignTokens.avatarBg
    teamAvatarView.widthAnchor.constraint(equalToConstant: 28).isActive = true
    teamAvatarView.heightAnchor.constraint(equalToConstant: 28).isActive = true
    teamAvatarView.translatesAutoresizingMaskIntoConstraints = false
    avatarStack.addArrangedSubview(teamAvatarView)

    let infoStack = UIStackView()
    infoStack.axis = .vertical
    infoStack.spacing = 2
    infoStack.translatesAutoresizingMaskIntoConstraints = false
    headerView.addSubview(infoStack)

    let teamName = UILabel()
    teamName.text = "Support"
    teamName.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
    teamName.textColor = AlpsDesignTokens.dark
    infoStack.addArrangedSubview(teamName)

    let statusLabel = UILabel()
    statusLabel.text = "Online"
    statusLabel.font = UIFont.systemFont(ofSize: 12)
    statusLabel.textColor = AlpsDesignTokens.textLight
    infoStack.addArrangedSubview(statusLabel)

    NSLayoutConstraint.activate([
      headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
      headerView.rightAnchor.constraint(equalTo: view.rightAnchor),
      headerView.heightAnchor.constraint(equalToConstant: 64),

      backButton.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 12),
      backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

      avatarStack.leftAnchor.constraint(equalTo: backButton.rightAnchor, constant: 12),
      avatarStack.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

      infoStack.leftAnchor.constraint(equalTo: avatarStack.rightAnchor, constant: 12),
      infoStack.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
    ])
  }

  private func setupTableView() {
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(AlpsMessageCell.self, forCellReuseIdentifier: "messageCell")
    tableView.separatorStyle = .none
    tableView.backgroundColor = .white
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
  }

  private func setupInputBar() {
    inputContainer.backgroundColor = .white
    inputContainer.translatesAutoresizingMaskIntoConstraints = false
    inputContainer.layer.borderTopWidth = 1
    inputContainer.layer.borderTopColor = AlpsDesignTokens.border.cgColor
    view.addSubview(inputContainer)

    let closedNotice = UIView()
    closedNotice.backgroundColor = UIColor(hex: "#FEF3E2")
    closedNotice.layer.borderWidth = 1
    closedNotice.layer.borderColor = UIColor(hex: "#FDE4B6").cgColor
    closedNotice.translatesAutoresizingMaskIntoConstraints = false
    closedNotice.isHidden = conversationStatus == "active"
    inputContainer.addSubview(closedNotice)

    let closedLabel = UILabel()
    closedLabel.text = "This conversation has ended."
    closedLabel.font = UIFont.systemFont(ofSize: 13)
    closedLabel.textColor = UIColor(hex: "#92400E")
    closedLabel.translatesAutoresizingMaskIntoConstraints = false
    closedNotice.addSubview(closedLabel)

    NSLayoutConstraint.activate([
      closedNotice.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
      closedNotice.leftAnchor.constraint(equalTo: inputContainer.leftAnchor, constant: 12),
      closedNotice.rightAnchor.constraint(equalTo: inputContainer.rightAnchor, constant: -12),
      closedLabel.topAnchor.constraint(equalTo: closedNotice.topAnchor, constant: 8),
      closedLabel.bottomAnchor.constraint(equalTo: closedNotice.bottomAnchor, constant: -8),
      closedLabel.leftAnchor.constraint(equalTo: closedNotice.leftAnchor, constant: 8),
    ])

    messageInput.font = UIFont.systemFont(ofSize: 13)
    messageInput.translatesAutoresizingMaskIntoConstraints = false
    messageInput.backgroundColor = .white
    messageInput.textColor = AlpsDesignTokens.textMid
    messageInput.delegate = self
    messageInput.isScrollEnabled = false
    messageInput.placeholder = "Type a message..."
    messageInput.layer.borderWidth = 1.5
    messageInput.layer.borderColor = AlpsDesignTokens.border.cgColor
    messageInput.layer.cornerRadius = 12
    inputContainer.addSubview(messageInput)

    emojiButton.setTitle("😊", for: .normal)
    emojiButton.translatesAutoresizingMaskIntoConstraints = false
    emojiButton.addTarget(self, action: #selector(didTapEmoji), for: .touchUpInside)
    inputContainer.addSubview(emojiButton)

    attachmentButton.translatesAutoresizingMaskIntoConstraints = false
    let attachConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
    let attachImage = UIImage(systemName: "paperclip", withConfiguration: attachConfig)
    attachmentButton.setImage(attachImage, for: .normal)
    attachmentButton.tintColor = AlpsDesignTokens.textBody
    attachmentButton.addTarget(self, action: #selector(didTapAttach), for: .touchUpInside)
    inputContainer.addSubview(attachmentButton)

    sendButton.translatesAutoresizingMaskIntoConstraints = false
    let sendConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
    let sendImage = UIImage(systemName: "paperplane.fill", withConfiguration: sendConfig)
    sendButton.setImage(sendImage, for: .normal)
    sendButton.tintColor = .white
    sendButton.backgroundColor = AlpsDesignTokens.accent
    sendButton.layer.cornerRadius = 16
    sendButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
    sendButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
    sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)
    inputContainer.addSubview(sendButton)

    let inputBox = UIView()
    inputBox.layer.borderWidth = 1.5
    inputBox.layer.borderColor = AlpsDesignTokens.border.cgColor
    inputBox.layer.cornerRadius = 12
    inputBox.translatesAutoresizingMaskIntoConstraints = false
    inputContainer.addSubview(inputBox)

    NSLayoutConstraint.activate([
      inputBox.topAnchor.constraint(equalTo: closedNotice.isHidden ? inputContainer.topAnchor : closedNotice.bottomAnchor, constant: 12),
      inputBox.leftAnchor.constraint(equalTo: inputContainer.leftAnchor, constant: 12),
      inputBox.rightAnchor.constraint(equalTo: inputContainer.rightAnchor, constant: -12),

      messageInput.topAnchor.constraint(equalTo: inputBox.topAnchor, constant: 12),
      messageInput.leftAnchor.constraint(equalTo: inputBox.leftAnchor, constant: 12),
      messageInput.rightAnchor.constraint(equalTo: inputBox.rightAnchor, constant: -12),
      messageInput.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
      messageInput.heightAnchor.constraint(lessThanOrEqualToConstant: 96),

      emojiButton.topAnchor.constraint(equalTo: messageInput.bottomAnchor, constant: 8),
      emojiButton.leftAnchor.constraint(equalTo: inputBox.leftAnchor, constant: 10),
      emojiButton.bottomAnchor.constraint(equalTo: inputBox.bottomAnchor, constant: -10),

      attachmentButton.leftAnchor.constraint(equalTo: emojiButton.rightAnchor, constant: 8),
      attachmentButton.centerYAnchor.constraint(equalTo: emojiButton.centerYAnchor),

      sendButton.leftAnchor.constraint(equalTo: attachmentButton.rightAnchor, constant: 8),
      sendButton.centerYAnchor.constraint(equalTo: emojiButton.centerYAnchor),
      sendButton.rightAnchor.constraint(equalTo: inputBox.rightAnchor, constant: -10),
      inputBox.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -12),
    ])

    inputBottomConstraint = inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    inputBottomConstraint?.isActive = true

    updateInputState()
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

      inputContainer.leftAnchor.constraint(equalTo: view.leftAnchor),
      inputContainer.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])
  }

  private func setupPreChatForm() {
    let overlay = UIView()
    overlay.backgroundColor = .white
    overlay.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(overlay)

    NSLayoutConstraint.activate([
      overlay.topAnchor.constraint(equalTo: view.topAnchor),
      overlay.leftAnchor.constraint(equalTo: view.leftAnchor),
      overlay.rightAnchor.constraint(equalTo: view.rightAnchor),
      overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    overlay.addSubview(stack)

    let titleLabel = UILabel()
    titleLabel.text = "Before we start"
    titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
    titleLabel.textColor = AlpsDesignTokens.textMid
    stack.addArrangedSubview(titleLabel)

    let subtitleLabel = UILabel()
    subtitleLabel.text = "Tell us who you are..."
    subtitleLabel.font = UIFont.systemFont(ofSize: 13)
    subtitleLabel.textColor = AlpsDesignTokens.textBody
    stack.addArrangedSubview(subtitleLabel)

    nameField = UITextField()
    nameField!.placeholder = "Your name (optional)"
    nameField!.borderStyle = .none
    nameField!.layer.borderWidth = 1.5
    nameField!.layer.borderColor = AlpsDesignTokens.border.cgColor
    nameField!.layer.cornerRadius = 10
    nameField!.translatesAutoresizingMaskIntoConstraints = false
    nameField!.heightAnchor.constraint(equalToConstant: 44).isActive = true
    let nameLeftPad = UIView()
    nameLeftPad.widthAnchor.constraint(equalToConstant: 12).isActive = true
    nameField!.leftView = nameLeftPad
    nameField!.leftViewMode = .always
    stack.addArrangedSubview(nameField!)

    emailField = UITextField()
    emailField!.placeholder = "Your email address"
    emailField!.borderStyle = .none
    emailField!.layer.borderWidth = 1.5
    emailField!.layer.borderColor = AlpsDesignTokens.border.cgColor
    emailField!.layer.cornerRadius = 10
    emailField!.keyboardType = .emailAddress
    emailField!.translatesAutoresizingMaskIntoConstraints = false
    emailField!.heightAnchor.constraint(equalToConstant: 44).isActive = true
    let emailLeftPad = UIView()
    emailLeftPad.widthAnchor.constraint(equalToConstant: 12).isActive = true
    emailField!.leftView = emailLeftPad
    emailField!.leftViewMode = .always
    stack.addArrangedSubview(emailField!)

    let submitButton = UIButton(type: .system)
    submitButton.setTitle("Start chatting", for: .normal)
    submitButton.backgroundColor = AlpsDesignTokens.accent
    submitButton.setTitleColor(.white, for: .normal)
    submitButton.layer.cornerRadius = 10
    submitButton.translatesAutoresizingMaskIntoConstraints = false
    submitButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    submitButton.addTarget(self, action: #selector(submitPreChatForm), for: .touchUpInside)
    stack.addArrangedSubview(submitButton)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 24),
      stack.leftAnchor.constraint(equalTo: overlay.leftAnchor, constant: 20),
      stack.rightAnchor.constraint(equalTo: overlay.rightAnchor, constant: -20),
    ])
  }

  @objc private func submitPreChatForm() {
    let name = nameField?.text ?? ""
    let email = emailField?.text ?? ""

    guard !email.isEmpty else { return }

    config.visitorName = name.isEmpty ? nil : name
    config.visitorEmail = email
    AlpsVisitorStore.save(config: config)

    view.subviews.forEach { $0.removeFromSuperview() }
    showPreChatForm = false
    setupThreadUI()
  }

  @objc private func didTapEmoji() {
    print("[ThreadVC] Emoji picker - TODO")
  }

  @objc private func didTapAttach() {
    print("[ThreadVC] File attachment - TODO")
  }

  private func setupPusher() {
    guard let pusherKey = config.pusherKey,
          let pusherCluster = config.pusherCluster else {
      return
    }

    pusherClient = AlpsPusherClient(
      apiBaseURL: config.apiBaseURL,
      widgetKey: config.widgetKey
    )
    pusherClient?.onMessageReceived = { [weak self] message in
      DispatchQueue.main.async {
        self?.messages.append(message)
        self?.tableView.insertRows(at: [IndexPath(row: (self?.messages.count ?? 1) - 1, section: 0)], with: .fade)
        self?.scrollToBottom()
      }
    }

    pusherClient?.onTypingIndicator = { [weak self] senderName in
      print("[ThreadVC] \(senderName) is typing")
    }

    pusherClient?.onConversationStatusChanged = { [weak self] status in
      DispatchQueue.main.async {
        self?.conversationStatus = status
        self?.updateInputState()
      }
    }

    pusherClient?.connect(pusherKey: pusherKey, cluster: pusherCluster, conversationId: conversationId)
  }

  private func loadMessageHistory() {
    apiClient.fetchConversationMessages(conversationId: conversationId) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success(let detail):
          self?.messages = detail.messages
          self?.conversationStatus = detail.status
          self?.updateInputState()
          self?.tableView.reloadData()
          self?.scrollToBottom()
        case .failure(let error):
          print("[ThreadVC] Failed to load message history: \(error)")
        }
      }
    }
  }

  private func updateInputState() {
    let isClosed = conversationStatus != "active"
    messageInput.isUserInteractionEnabled = !isClosed
    sendButton.isUserInteractionEnabled = !isClosed
    emojiButton.isUserInteractionEnabled = !isClosed
    attachmentButton.isUserInteractionEnabled = !isClosed
    messageInput.alpha = isClosed ? 0.5 : 1.0
  }

  @objc private func didClose() {
    navigationController?.popViewController(animated: true)
  }

  @objc private func didTapSend() {
    guard let text = messageInput.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else {
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
          self?.tableView.insertRows(at: [IndexPath(row: (self?.messages.count ?? 1) - 1, section: 0)], with: .fade)
          self?.messageInput.text = ""
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
    if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
      inputBottomConstraint?.constant = -keyboardHeight
      UIView.animate(withDuration: 0.3) {
        self.view.layoutIfNeeded()
      }
    }
    scrollToBottom()
  }

  @objc private func keyboardWillHide() {
    inputBottomConstraint?.constant = 0
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
  }

  func textViewDidChange(_ textView: UITextView) {
    let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
    let maxHeight: CGFloat = 96
    textView.isScrollEnabled = size.height > maxHeight
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! AlpsMessageCell
    let message = messages[indexPath.row]
    cell.configure(with: message)
    cell.selectionStyle = .none
    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }
}
