import UIKit

class AlpsLauncherButton: UIView {
  var onTap: (() -> Void)?

  private let button = UIButton(type: .system)
  private let badgeView = UIView()
  private let label = UILabel()
  private var launcherColor: UIColor = .systemBlue

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  private func setupUI() {
    // Button
    button.translatesAutoresizingMaskIntoConstraints = false
    button.layer.cornerRadius = 28 / 2
    button.clipsToBounds = true
    button.backgroundColor = launcherColor
    button.setTitle("💬", for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.setTitleColor(.white, for: .normal)

    button.addTarget(self, action: #selector(didTap), for: .touchUpInside)

    addSubview(button)
    NSLayoutConstraint.activate([
      button.widthAnchor.constraint(equalToConstant: 56),
      button.heightAnchor.constraint(equalToConstant: 56),
    ])

    // Badge
    badgeView.translatesAutoresizingMaskIntoConstraints = false
    badgeView.backgroundColor = .systemRed
    badgeView.layer.cornerRadius = 8
    badgeView.clipsToBounds = true
    badgeView.isHidden = true
    addSubview(badgeView)

    NSLayoutConstraint.activate([
      badgeView.widthAnchor.constraint(equalToConstant: 16),
      badgeView.heightAnchor.constraint(equalToConstant: 16),
      badgeView.topAnchor.constraint(equalTo: button.topAnchor, constant: -4),
      badgeView.rightAnchor.constraint(equalTo: button.rightAnchor, constant: 4),
    ])

    // Shadow
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.15
    layer.shadowOffset = CGSize(width: 0, height: 2)
    layer.shadowRadius = 4
  }

  func setupConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    guard let superview = superview else { return }

    NSLayoutConstraint.activate([
      rightAnchor.constraint(equalTo: superview.rightAnchor, constant: -20),
      bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -28),
      widthAnchor.constraint(equalToConstant: 64),
      heightAnchor.constraint(equalToConstant: 64),
    ])
  }

  func updateColor(_ hexColor: String) {
    let color = UIColor(hex: hexColor) ?? .systemBlue
    launcherColor = color
    button.backgroundColor = color
  }

  func updateText(_ text: String) {
    button.setTitle(text, for: .normal)
  }

  func showUnreadBadge(_ count: Int) {
    badgeView.isHidden = count == 0
    if count > 0 {
      let badgeLabel = UILabel()
      badgeLabel.text = count > 9 ? "9+" : "\(count)"
      badgeLabel.textColor = .white
      badgeLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
      badgeLabel.textAlignment = .center
      badgeLabel.translatesAutoresizingMaskIntoConstraints = false
      badgeView.addSubview(badgeLabel)

      NSLayoutConstraint.activate([
        badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
        badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
      ])
    }
  }

  @objc private func didTap() {
    onTap?()
  }
}

// MARK: - Color Helper

extension UIColor {
  convenience init?(hex: String) {
    var hexString = hex.trimmingCharacters(in: .whitespaces)
    if hexString.hasPrefix("#") {
      hexString.removeFirst()
    }

    guard hexString.count == 6 else { return nil }

    let scanner = Scanner(string: hexString)
    var rgb: UInt64 = 0

    guard scanner.scanHexInt64(&rgb) else { return nil }

    let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
    let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
    let b = CGFloat(rgb & 0xFF) / 255.0

    self.init(red: r, green: g, blue: b, alpha: 1.0)
  }
}
