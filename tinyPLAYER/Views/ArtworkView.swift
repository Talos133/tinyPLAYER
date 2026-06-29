import SwiftUI

struct ArtworkView: View {
    let url:  URL?
    let size: CGFloat
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                    default:                placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(theme.current.bgPanel)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.3))
                    .foregroundStyle(theme.current.textMuted)
            )
    }
}
