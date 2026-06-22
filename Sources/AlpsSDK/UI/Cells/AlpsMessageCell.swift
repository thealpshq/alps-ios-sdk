import UIKit

class AlpsMessageCell: UITableViewCell {
  private let bubbleView = UIView()
  private let messageLabel = UILabel()
  private let timestampLabel = UILabel()
  private let avatarView = UIImageView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupCell()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    bubbleView.removeFromSuperview()
    messageLabel.removeFromSuperview()
    timestampLabel.removeFromSuperview()
    avatarView.removeFromSuperview()
    setupCell()
  }

  private func setupCell() {
    backgroundColor = .white
    selectionStyle = .none

    bubbleView.translatesAutoresizingMaskIntoConstraints = false
    bubbleView.clipsToBounds = true
    contentView.addSubview(bubbleView)

    messageLabel.numberOfLines = 0
    messageLabel.font = UIFont.systemFont(ofSize: 13)
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    bubbleView.addSubview(messageLabel)

    timestampLabel.font = UIFont.systemFont(ofSize: 11)
    timestampLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(timestampLabel)

    avatarView.layer.cornerRadius = 13
    avatarView.clipsToBounds = true
    avatarView.contentMode = .scaleAspectFill
    avatarView.backgroundColor = AlpsDesignTokens.avatarBg
    avatarView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(avatarView)
  }

  func configure(with message: Message) {
    let isFromCustomer = message.direction == "outbound"

    bubbleView.layer.cornerRadius = isFromCustomer ? 16 : 4
    if isFromCustomer {
      bubbleView.backgroundColor = AlpsDesignTokens.searchBg
      messageLabel.textColor = AlpsDesignTokens.dark
      timestampLabel.textColor = AlpsDesignTokens.textLight
    } else {
      bubbleView.backgroundColor = AlpsDesignTokens.accent
      messageLabel.textColor = .white
      timestampLabel.textColor = AlpsDesignTokens.textBody
    }

    messageLabel.text = message.content

    let dateFormatter = ISO8601DateFormatter()
    if let date = dateFormatter.date(from: message.createdAt) {
      let timeFormatter = DateFormatter()
      timeFormatter.timeStyle = .short
      timestampLabel.text = timeFormatter.string(from: date)
    } else {
      timestampLabel.text = ""
    }

    avatarView.isHidden = isFromCustomer

    NSLayoutConstraint.deactivateAll(contentView.constraints.filter { constraint in
      constraint.firstItem === bubbleView || constraint.secondItem === bubbleView ||
      constraint.firstItem === messageLabel || constraint.secondItem === messageLabel ||
      constraint.firstItem === timestampLabel || constraint.secondItem === timestampLabel ||
      constraint.firstItem === avatarView || constraint.secondItem === avatarView
    })

    NSLayoutConstraint.activate([
      messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
      messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
      messageLabel.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 14),
      messageLabel.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -14),
    ])

    if isFromCustomer {
      NSLayoutConstraint.activate([
        bubbleView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
        bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

        timestampLabel.rightAnchor.constraint(equalTo: bubbleView.rightAnchor),
        timestampLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
      ])
    } else {
      NSLayoutConstraint.activate([
        avatarView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
        avatarView.topAnchor.constraint(equalTo: bubbleView.topAnchor),
        avatarView.widthAnchor.constraint(equalToConstant: 26),
        avatarView.heightAnchor.constraint(equalToConstant: 26),

        bubbleView.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 8),
        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
        bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

        timestampLabel.leftAnchor.constraint(equalTo: bubbleView.leftAnchor),
        timestampLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
      ])
    }
  }
}

extension NSLayoutConstraint {
  static func deactivateAll(_ constraints: [NSLayoutConstraint]) {
    NSLayoutConstraint.deactivate(constraints)
  }
}
