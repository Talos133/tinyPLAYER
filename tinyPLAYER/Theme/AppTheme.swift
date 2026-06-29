import SwiftUI

struct AppTheme {
    let name: String
    let bgApp:         Color
    let bgPanel:       Color
    let border:        Color
    let textPrimary:   Color
    let textSecondary: Color
    let textMuted:     Color
    let accent:        Color
    let accentSoft:    Color
}

enum AppFontSize: String, CaseIterable {
    case small, medium, large

    var body:  CGFloat { switch self { case .small: 11; case .medium: 13; case .large: 15 } }
    var label: CGFloat { body - 2 }
    var title: CGFloat { body + 2 }
}
