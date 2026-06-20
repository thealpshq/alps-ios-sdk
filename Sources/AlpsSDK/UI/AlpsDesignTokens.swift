import UIKit

struct AlpsDesignTokens {
  // MARK: - Colors
  static let panelBg = UIColor(hex: "#FFFFFF")
  static let dark = UIColor(hex: "#18181B")
  static let border = UIColor(hex: "#E4E4E7")
  static let textMid = UIColor(hex: "#3F3F46")
  static let textBody = UIColor(hex: "#71717A")
  static let textLight = UIColor(hex: "#A1A1AA")
  static let searchBg = UIColor(hex: "#F4F4F5")
  static let avatarBg = UIColor(hex: "#D4D4D8")

  // MARK: - Border Radius
  static let radiusLauncher: CGFloat = 24
  static let radiusPanel: CGFloat = 16
  static let radiusCard: CGFloat = 8
  static let radiusButton: CGFloat = 10
  static let radiusInput: CGFloat = 12
  static let radiusBubble: CGFloat = 16

  // MARK: - Font Sizes
  static let fontCaption: CGFloat = 11
  static let fontMeta: CGFloat = 12
  static let fontBody: CGFloat = 13
  static let fontTitle: CGFloat = 14
  static let fontLarge: CGFloat = 16

  // MARK: - Spacing
  static let paddingH: CGFloat = 16
  static let paddingCard: CGFloat = 12
  static let gap: CGFloat = 8
}

extension UIColor {
  convenience init(hex: String) {
    let hexString = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    if hexString.count == 6 {
      let scanner = Scanner(string: hexString)
      var rgb: UInt64 = 0
      scanner.scanHexInt64(&rgb)
      let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
      let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
      let b = CGFloat(rgb & 0xFF) / 255.0
      self.init(red: r, green: g, blue: b, alpha: 1.0)
    } else {
      self.init(red: 0, green: 0, blue: 0, alpha: 1.0)
    }
  }
}
