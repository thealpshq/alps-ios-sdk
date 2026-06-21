import UIKit

class AlpsThreadViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  let conversationId: String

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
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "messageCell")
    tableView.separatorStyle = .none
    tableView.backgroundColor = .white
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)

    inputContainer.backgroundColor = .white
    inputContainer.translatesAutoresizingMaskIntoConstraints = false
    inputContainer.layer.borderWidth = 1.5
    inputContainer.layer.borderColor = AlpsDesignTokens.border.cgColor
    view.addSubview(inputContainer)

    messageInput.font = UIFont.systemFont(ofSize: 13)
    messageInput.layer.cornerRadius = AlpsDesignTokens.radiusInput
    messageInput.clipsToBounds = true
    messageInput.translatesAutoresizingMaskIntoConstraints = false
    messageInput.backgroundColor = AlpsDesignTokens.searchBg
    messageInput.textColor = AlpsDesignTokens.textMid
    messageInput.delegate = self
    messageInput.isScrollEnabled = false
    inputContainer.addSubview(messageInput)

    emojiButton.setTitle("😀", for: .normal)
    emojiButton.translatesAutoresizingMaskIntoConstraints = false
    emojiButton.widthAnchor.constraint(equalToConstant: 28).isActive = true
    inputContainer.addSubview(emojiButton)

    attachmentButton.translatesAutoresizingMaskIntoConstraints = false
    let attachConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
    let attachImage = UIImage(systemName: "paperclip", withConfiguration: attachConfig)
    attachmentButton.setImage(attachImage, for: .normal)
    attachmentButton.tintColor = AlpsDesignTokens.textBody
    attachmentButton.widthAnchor.constraint(equalToConstant: 28).isActive = true
    inputContainer.addSubview(attachmentButton)

    sendButton.translatesAutoresizingMaskIntoConstraints = false
    let sendConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
    let sendImage = UIImage(systemName: "arrow.up", withConfiguration: sendConfig)
    sendButton.setImage(sendImage, for: .normal)
    sendButton.tintColor = .white
    sendButton.backgroundColor = AlpsDesignTokens.accent
    sendButton.layer.cornerRadius = 16
    sendButton.clipsToBounds = true
    sendButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
    sendButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
    sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)
    inputContainer.addSubview(sendButton)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

      inputContainer.leftAnchor.constraint(equalTo: view.leftAnchor),
      inputContainer.rightAnchor.constraint(equalTo: view.rightAnchor),
      inputContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),

      messageInput.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 12),
      messageInput.leftAnchor.constraint(equalTo: inputContainer.leftAnchor, constant: 12),
      messageInput.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -12),
      messageInput.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
      messageInput.heightAnchor.constraint(lessThanOrEqualToConstant: 96),

      emojiButton.leftAnchor.constraint(equalTo: messageInput.rightAnchor, constant: 8),
      emojiButton.centerYAnchor.constraint(equalTo: messageInput.centerYAnchor),

      attachmentButton.leftAnchor.constraint(equalTo: emojiButton.rightAnchor, constant: 8),
      attachmentButton.centerYAnchor.constraint(equalTo: messageInput.centerYAnchor),

      sendButton.leftAnchor.constraint(equalTo: attachmentButton.rightAnchor, constant: 8),
      sendButton.centerYAnchor.constraint(equalTo: messageInput.centerYAnchor),
      sendButton.rightAnchor.constraint(equalTo: inputContainer.rightAnchor, constant: -12),
    ])

    inputBottomConstraint = inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    inputBottomConstraint?.isActive = true
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
    titleLabel.text = "Before we chat..."
    titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
    titleLabel.textColor = AlpsDesignTokens.textMid
    stack.addArrangedSubview(titleLabel)

    nameField = UITextField()
    nameField!.placeholder = "Your name"
    nameField!.borderStyle = .roundedRect
    nameField!.translatesAutoresizingMaskIntoConstraints = false
    nameField!.heightAnchor.constraint(equalToConstant: 44).isActive = true
    stack.addArrangedSubview(nameField!)

    emailField = UITextField()
    emailField!.placeholder = "Your email"
    emailField!.borderStyle = .roundedRect
    emailField!.keyboardType = .emailAddress
    emailField!.translatesAutoresizingMaskIntoConstraints = false
    emailField!.heightAnchor.constraint(equalToConstant: 44).isActive = true
    stack.addArrangedSubview(emailField!)

    let submitButton = UIButton(type: .system)
    submitButton.setTitle("Continue", for: .normal)
    submitButton.backgroundColor = AlpsDesignTokens.accent
    submitButton.setTitleColor(.white, for: .normal)
    submitButton.layer.cornerRadius = 8
    submitButton.translatesAutoresizingMaskIntoConstraints = false
    submitButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    submitButton.addTarget(self, action: #selector(submitPreChatForm), for: .touchUpInside)
    stack.addArrangedSubview(submitButton)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 32),
      stack.leftAnchor.constraint(equalTo: overlay.leftAnchor, constant: 16),
      stack.rightAnchor.constraint(equalTo: overlay.rightAnchor, constant: -16),
    ])
  }

  @objc private func submitPreChatForm() {
    let name = nameField?.text ?? ""
    let email = emailField?.text ?? ""

    guard !name.isEmpty, !email.isEmpty else { return }

    config.visitorName = name
    config.visitorEmail = email
    AlpsVisitorStore.save(config: config)

    view.subviews.forEach { $0.removeFromSuperview() }
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
          self?.tableView.reloadData()
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
    let cell = UITableViewCell(style: .default, reuseIdentifier: "messageCell")
    let message = messages[indexPath.row]

    cell.contentView.subviews.forEach { $0.removeFromSuperview() }
    cell.selectionStyle = .none
    cell.backgroundColor = .white

    let isFromCustomer = message.direction == "outbound"

    let bubbleView = UIView()
    bubbleView.clipsToBounds = true
    bubbleView.translatesAutoresizingMaskIntoConstraints = false
    cell.contentView.addSubview(bubbleView)

    if isFromCustomer {
      bubbleView.backgroundColor = AlpsDesignTokens.searchBg
      bubbleView.layer.cornerRadius = 16
    } else {
      bubbleView.backgroundColor = AlpsDesignTokens.accent
      bubbleView.layer.cornerRadius = 8
    }

    let label = UILabel()
    label.text = message.content
    label.textColor = isFromCustomer ? AlpsDesignTokens.dark : .white
    label.numberOfLines = 0
    label.font = UIFont.systemFont(ofSize: 13)
    label.translatesAutoresizingMaskIntoConstraints = false
    bubbleView.addSubview(label)

    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
      label.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
      label.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 14),
      label.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -14),
    ])

    if isFromCustomer {
      NSLayoutConstraint.activate([
        bubbleView.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: -16),
        bubbleView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
        bubbleView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
        bubbleView.widthAnchor.constraint(lessThanOrEqualTo: cell.contentView.widthAnchor, multiplier: 0.75),
      ])
    } else {
      if let senderName = message.senderName {
        let senderLabel = UILabel()
        senderLabel.text = senderName
        senderLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        senderLabel.textColor = AlpsDesignTokens.textMid
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.insertSubview(senderLabel, belowSubview: bubbleView)

        NSLayoutConstraint.activate([
          senderLabel.bottomAnchor.constraint(equalTo: bubbleView.topAnchor, constant: -4),
          senderLabel.leftAnchor.constraint(equalTo: bubbleView.leftAnchor),
        ])
      }

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
