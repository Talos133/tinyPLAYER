import SwiftUI

enum Palettes {
    static let greek = AppTheme(
        name: "Greek Aegean",
        bgApp:         Color(hex: "0d2247"),
        bgPanel:       Color(hex: "162f5c"),
        border:        Color(hex: "2a4a7a"),
        textPrimary:   Color(hex: "f5f2ea"),
        textSecondary: Color(hex: "c4d4e8"),
        textMuted:     Color(hex: "6a8aaa"),
        accent:        Color(hex: "d4b483"),
        accentSoft:    Color(hex: "9a7a4a")
    )
    static let forest = AppTheme(
        name: "Forest",
        bgApp:         Color(hex: "1a2e1a"),
        bgPanel:       Color(hex: "243824"),
        border:        Color(hex: "3a5a3a"),
        textPrimary:   Color(hex: "e8f5e8"),
        textSecondary: Color(hex: "b0d0b0"),
        textMuted:     Color(hex: "6a8a6a"),
        accent:        Color(hex: "7db87d"),
        accentSoft:    Color(hex: "4a784a")
    )
    static let tropical = AppTheme(
        name: "Tropical Islands",
        bgApp:         Color(hex: "003d4d"),
        bgPanel:       Color(hex: "004d5f"),
        border:        Color(hex: "006070"),
        textPrimary:   Color(hex: "f0f9fb"),
        textSecondary: Color(hex: "b0e0ea"),
        textMuted:     Color(hex: "609aaa"),
        accent:        Color(hex: "f4a623"),
        accentSoft:    Color(hex: "c07810")
    )
    static let urban = AppTheme(
        name: "Nightly Urban",
        bgApp:         Color(hex: "0f0f14"),
        bgPanel:       Color(hex: "1a1a22"),
        border:        Color(hex: "2a2a38"),
        textPrimary:   Color(hex: "f0f0f8"),
        textSecondary: Color(hex: "b0b0c8"),
        textMuted:     Color(hex: "606080"),
        accent:        Color(hex: "b388ff"),
        accentSoft:    Color(hex: "7a50cc")
    )
    static let bonfire = AppTheme(
        name: "Beach Bonfire",
        bgApp:         Color(hex: "1c1008"),
        bgPanel:       Color(hex: "2a1a0c"),
        border:        Color(hex: "4a2a18"),
        textPrimary:   Color(hex: "f5ede0"),
        textSecondary: Color(hex: "d0b898"),
        textMuted:     Color(hex: "906040"),
        accent:        Color(hex: "ff6b35"),
        accentSoft:    Color(hex: "c04020")
    )
    static let mountains = AppTheme(
        name: "Morning Mountains",
        bgApp:         Color(hex: "e8eff7"),
        bgPanel:       Color(hex: "ffffff"),
        border:        Color(hex: "c0d0e0"),
        textPrimary:   Color(hex: "1a2a3a"),
        textSecondary: Color(hex: "4a6a8a"),
        textMuted:     Color(hex: "8aaaba"),
        accent:        Color(hex: "4a7c59"),
        accentSoft:    Color(hex: "7aac89")
    )
    static let all: [AppTheme] = [greek, forest, tropical, urban, bonfire, mountains]
}
