import UIKit

class AlpsHomeViewController: UIViewController {
  let config: AlpsConfig
  let apiClient: AlpsAPIClient
  var widgetData: WidgetDataResponse?

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let startButton = UIButton(type: .system)
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
    // Welcome message
    if let message = widgetData?.welcomeMessage {
      let label = UILabel()
      label.text = message
      label.numberOfLines = 0
      label.font = UIFont.systemFont(ofSize: 14)
      label.textColor = .darkGray
      stackView.addArrangedSubview(label)
    }

    // Online agents
    if let agents = widgetData?.onlineAgents, !agents.isEmpty {
      let agentsLabel = UILabel()
      agentsLabel.text = "Available Agents"
      agentsLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
      agentsLabel.textColor = .systemGray
      stackView.addArrangedSubview(agentsLabel)

      for agent in agents {
        let agentView = UIView()
        agentView.backgroundColor = .systemGray6
        agentView.layer.cornerRadius = 8
        agentView.translatesAutoresizingMaskIntoConstraints = false
        agentView.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let nameLabel = UILabel()
        let fullName = "\(agent.firstName ?? "") \(agent.lastName ?? "")".trimmingCharacters(in: .whitespaces)
        nameLabel.text = fullName
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        agentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
          nameLabel.leftAnchor.constraint(equalTo: agentView.leftAnchor, constant: 12),
          nameLabel.centerYAnchor.constraint(equalTo: agentView.centerYAnchor),
        ])

        stackView.addArrangedSubview(agentView)
      }
    }

    // Start button
    startButton.setTitle("Start Conversation", for: .normal)
    startButton.backgroundColor = .systemBlue
    startButton.setTitleColor(.white, for: .normal)
    startButton.layer.cornerRadius = 8
    startButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    startButton.translatesAutoresizingMaskIntoConstraints = false
    startButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    startButton.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)

    stackView.addArrangedSubview(startButton)
  }

  @objc private func didTapStart() {
    // Navigate to messages tab (handled by parent panel)
    if let panelVC = parent as? AlpsPanelViewController {
      panelVC.switchTab(to: .messages)
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
