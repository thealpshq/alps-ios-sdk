import UIKit

class AlpsConversationCell: UITableViewCell {
  private let avatarView = UIImageView()
  private let titleLabel = UILabel()
  private let timeLabel = UILabel()
  private let messageLabel = UILabel()
  private let unreadBadge = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupCell()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupCell() {
    backgroundColor = .white
    selectionStyle = .gray

    avatarView.layer.cornerRadius = 19
    avatarView.clipsToBounds = true
    avatarView.contentMode = .scaleAspectFill
    avatarView.backgroundColor = AlpsDesignTokens.avatarBg
    avatarView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(avatarView)

    titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    titleLabel.textColor = AlpsDesignTokens.textMid
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(titleLabel)

    timeLabel.font = UIFont.systemFont(ofSize: 12)
    timeLabel.textColor = AlpsDesignTokens.textLight
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(timeLabel)

    messageLabel.font = UIFont.systemFont(ofSize: 12)
    messageLabel.textColor = AlpsDesignTokens.textBody
    messageLabel.numberOfLines = 1
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(messageLabel)

    unreadBadge.backgroundColor = AlpsDesignTokens.accent
    unreadBadge.layer.cornerRadius = 4
    unreadBadge.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(unreadBadge)

    NSLayoutConstraint.activate([
      avatarView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
      avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatarView.widthAnchor.constraint(equalToConstant: 38),
      avatarView.heightAnchor.constraint(equalToConstant: 38),

      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(lessThanOrEqualTo: unreadBadge.leftAnchor, constant: -8),

      timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
      timeLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 12),

      messageLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
      messageLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 12),
      messageLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12),
      messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

      unreadBadge.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12),
      unreadBadge.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
      unreadBadge.widthAnchor.constraint(equalToConstant: 8),
      unreadBadge.heightAnchor.constraint(equalToConstant: 8),
    ])
  }

  func configure(with conversation: ConversationSummary) {
    titleLabel.text = "Conversation"

    let dateFormatter = ISO8601DateFormatter()
    if let date = dateFormatter.date(from: conversation.lastMessageAt ?? conversation.createdAt) {
      let relativeFormatter = RelativeDateTimeFormatter()
      timeLabel.text = relativeFormatter.localizedString(for: date, relativeTo: Date())
    } else {
      timeLabel.text = ""
    }

    let preview = (conversation.lastMessage?.content ?? "No messages").prefix(60)
    messageLabel.text = String(preview)

    unreadBadge.isHidden = true
  }
}
