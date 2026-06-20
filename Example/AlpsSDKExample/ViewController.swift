import UIKit
import AlpsSDK

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    let label = UILabel()
    label.text = "Alps SDK Example"
    label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)

    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      stack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 40),
      stack.widthAnchor.constraint(equalToConstant: 240),
    ])

    let showButton = UIButton(type: .system)
    showButton.setTitle("Show Chat", for: .normal)
    showButton.backgroundColor = .systemBlue
    showButton.setTitleColor(.white, for: .normal)
    showButton.layer.cornerRadius = 8
    showButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    showButton.addTarget(self, action: #selector(didTapShow), for: .touchUpInside)
    stack.addArrangedSubview(showButton)

    let identifyButton = UIButton(type: .system)
    identifyButton.setTitle("Identify as User", for: .normal)
    identifyButton.backgroundColor = .systemGreen
    identifyButton.setTitleColor(.white, for: .normal)
    identifyButton.layer.cornerRadius = 8
    identifyButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    identifyButton.addTarget(self, action: #selector(didTapIdentify), for: .touchUpInside)
    stack.addArrangedSubview(identifyButton)

    let logoutButton = UIButton(type: .system)
    logoutButton.setTitle("Logout", for: .normal)
    logoutButton.backgroundColor = .systemRed
    logoutButton.setTitleColor(.white, for: .normal)
    logoutButton.layer.cornerRadius = 8
    logoutButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
    stack.addArrangedSubview(logoutButton)
  }

  @objc private func didTapShow() {
    Alps.show()
  }

  @objc private func didTapIdentify() {
    Alps.identify(name: "Test User", email: "test@example.com")
  }

  @objc private func didTapLogout() {
    Alps.logout()
  }
}
