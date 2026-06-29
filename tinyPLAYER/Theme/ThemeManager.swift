import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var current:  AppTheme    = Palettes.greek
    @Published private(set) var fontSize: AppFontSize = .medium

    private let paletteKey  = "tinyplayer_palette"
    private let fontSizeKey = "tinyplayer_fontsize"

    init() {
        if let name = UserDefaults.standard.string(forKey: paletteKey),
           let match = Palettes.all.first(where: { $0.name == name }) {
            current = match
        }
        if let raw  = UserDefaults.standard.string(forKey: fontSizeKey),
           let size = AppFontSize(rawValue: raw) {
            fontSize = size
        }
    }

    func apply(palette: AppTheme) {
        current = palette
        UserDefaults.standard.set(palette.name, forKey: paletteKey)
    }

    func apply(fontSize: AppFontSize) {
        self.fontSize = fontSize
        UserDefaults.standard.set(fontSize.rawValue, forKey: fontSizeKey)
    }
}
