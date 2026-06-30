import SwiftUI

/// A 12pt sliver shown when the floating panel is edge-tucked.
/// Displays a chevron button that, when tapped, calls `onPeek` to un-tuck the window.
struct TuckedView: View {

    let edge:   ScreenEdge
    let onPeek: () -> Void

    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        Button(action: onPeek) {
            Image(systemName: chevronSystemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.current.accent)
                .frame(width: 12, height: 48)
                .background(theme.current.bgPanel.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .background(theme.current.bgApp)
    }

    /// SF Symbol name for the directional chevron.
    /// The arrow points in the direction the user should "pull" the window to reveal it.
    var chevronSystemName: String {
        switch edge {
        case .leading:  return "chevron.right"
        case .trailing: return "chevron.left"
        case .top:      return "chevron.down"
        case .bottom:   return "chevron.up"
        }
    }
}
