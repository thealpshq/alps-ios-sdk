import UIKit

class AlpsLauncherButton: UIView {
  var onTap: (() -> Void)?

  private let button = UIButton(type: .system)
  private let badgeView = UIView()
  private let label = UILabel()
  private var launcherColor: UIColor = AlpsDesignTokens.dark

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  private func setupUI() {
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = launcherColor
    button.layer.cornerRadius = AlpsDesignTokens.radiusLauncher
    button.clipsToBounds = true

    let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
    let image = UIImage(systemName: "message.fill", withConfiguration: config)
    button.setImage(image, for: .normal)
    button.tintColor = .white

    label.text = "Chat with us"
    label.font = .systemFont(ofSize: AlpsDesignTokens.fontBody, weight: .medium)
    label.textColor = .white
    label.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView(arrangedSubviews: [button, label])
    stack.axis = .horizontal
    stack.spacing = 8
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.isUserInteractionEnabled = false

    addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor),
      stack.topAnchor.constraint(equalTo: topAnchor),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor),
      button.widthAnchor.constraint(equalToConstant: 32),
      button.heightAnchor.constraint(equalToConstant: 32),
    ])

    button.addTarget(self, action: #selector(didTap), for: .touchUpInside)

    badgeView.translatesAutoresizingMaskIntoConstraints = false
    badgeView.backgroundColor = .systemRed
    badgeView.layer.cornerRadius = 4
    badgeView.clipsToBounds = true
    badgeView.isHidden = true
    addSubview(badgeView)

    NSLayoutConstraint.activate([
      badgeView.widthAnchor.constraint(equalToConstant: 8),
      badgeView.heightAnchor.constraint(equalToConstant: 8),
      badgeView.topAnchor.constraint(equalTo: button.topAnchor, constant: -2),
      badgeView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 2),
    ])

    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.18
    layer.shadowOffset = CGSize(width: 0, height: 4)
    layer.shadowRadius = 20
  }

  func setupConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    guard let superview = superview else { return }

    NSLayoutConstraint.activate([
      rightAnchor.constraint(equalTo: superview.rightAnchor, constant: -28),
      bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -28),
      heightAnchor.constraint(equalToConstant: 48),
    ])
  }

  func updateColor(_ hexColor: String) {
    launcherColor = UIColor(hex: hexColor)
    button.backgroundColor = launcherColor
  }

  func updateText(_ text: String) {
    label.text = text
  }

  func showUnreadBadge(_ count: Int) {
    badgeView.isHidden = count == 0
  }

  @objc private func didTap() {
    onTap?()
  }
}
