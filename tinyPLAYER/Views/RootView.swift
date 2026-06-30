import SwiftUI

/// Root content view injected into the FloatingPanel.
/// Switches between PlayerView, MiniPlayerView, and TuckedView based on WindowManager.mode.
struct RootView: View {

    @EnvironmentObject var windows: WindowManager
    @EnvironmentObject var theme:   ThemeManager

    var body: some View {
        Group {
            switch windows.mode {
            case .normal:
                PlayerView()
            case .mini:
                MiniPlayerView()
            case .tucked(let edge):
                TuckedView(edge: edge, onPeek: { windows.untuck() })
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: windows.mode)
    }
}
