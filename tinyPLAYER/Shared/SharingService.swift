import AppKit

enum SharingService {

    // MARK: - Public API

    /// Shows NSSharingServicePicker for AirDrop / Messages / Mail.
    static func share(title: String, artist: String, url: URL?,
                      relativeTo sourceRect: NSRect, in view: NSView) {
        let items: [Any]
        if let url = url, let songID = url.pathComponents.last, !songID.isEmpty {
            items = buildShareItems(for: songID, title: title, artist: artist)
        } else {
            items = ["\(title) — \(artist)"]
        }

        let picker = NSSharingServicePicker(items: items)
        picker.show(relativeTo: sourceRect, of: view, preferredEdge: .minY)
    }

    // MARK: - Testable helpers

    /// Constructs the share items (text + URL) for a given song.
    /// Extracted so callers can test URL/string construction without
    /// invoking NSSharingService directly.
    static func buildShareItems(for songID: String,
                                title: String,
                                artist: String) -> [Any] {
        let link     = "music://music.apple.com/song/\(songID)"
        let text     = "\(title) by \(artist) — \(link)"
        var items: [Any] = [text]
        if let url = URL(string: link) {
            items.append(url)
        }
        return items
    }
}
