import AppKit
import SwiftUI

@MainActor
final class WindowManager: NSObject, ObservableObject, NSWindowDelegate {

    @Published private(set) var mode: WindowMode = .normal

    private let panel:         FloatingPanel
    private let edgeThreshold: CGFloat = 20
    private let tuckedSliver:  CGFloat = 12

    private let modeKey     = "tinyplayer_windowmode"
    private let positionKey = "tinyplayer_position"

    init(panel: FloatingPanel) {
        self.panel = panel
        super.init()
        panel.delegate = self
        restoreState()
    }

    // MARK: Public

    func toggleMiniNormal() {
        switch mode {
        case .normal: transition(to: .mini)
        case .mini:   transition(to: .normal)
        case .tucked: break
        }
    }

    func untuck() {
        guard case .tucked = mode else { return }
        transition(to: .normal)
    }

    // MARK: NSWindowDelegate

    func windowDidMove(_ notification: Notification) {
        checkEdgeSnap()
        persistState()
    }

    // MARK: Private

    private func transition(to newMode: WindowMode) {
        mode = newMode
        let size: NSSize
        switch newMode {
        case .normal:  size = NSSize(width: 360, height: 360)
        case .mini:    size = NSSize(width: 145, height: 72)
        case .tucked:  size = panel.frame.size
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setContentSize(size)
        }
        persistState()
    }

    private func checkEdgeSnap() {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let f  = panel.frame
        let sv = screen.visibleFrame
        let t  = edgeThreshold

        if      f.minX <= sv.minX + t   { snap(to: .leading) }
        else if f.maxX >= sv.maxX - t   { snap(to: .trailing) }
        else if f.maxY >= sv.maxY - t   { snap(to: .top) }
        else if f.minY <= sv.minY + t   { snap(to: .bottom) }
    }

    private func snap(to edge: ScreenEdge) {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let sv     = screen.visibleFrame
        var origin = panel.frame.origin
        let w      = panel.frame.width
        let h      = panel.frame.height

        switch edge {
        case .leading:  origin.x = sv.minX - (w - tuckedSliver)
        case .trailing: origin.x = sv.maxX - tuckedSliver
        case .top:      origin.y = sv.maxY - tuckedSliver
        case .bottom:   origin.y = sv.minY - (h - tuckedSliver)
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrameOrigin(origin)
        }
        mode = .tucked(edge)
        persistState()
    }

    private func persistState() {
        let modeStr: String
        switch mode {
        case .normal:        modeStr = "normal"
        case .mini:          modeStr = "mini"
        case .tucked(let e): modeStr = "tucked_\(e.rawValue)"
        }
        UserDefaults.standard.set(modeStr, forKey: modeKey)
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: positionKey)
    }

    private func restoreState() {
        if let posStr = UserDefaults.standard.string(forKey: positionKey) {
            let rect = NSRectFromString(posStr)
            if rect != .zero { panel.setFrameOrigin(rect.origin) }
        }
        guard let modeStr = UserDefaults.standard.string(forKey: modeKey) else { return }
        switch modeStr {
        case "mini": mode = .mini
        case let s where s.hasPrefix("tucked_"):
            if let edge = ScreenEdge(rawValue: String(s.dropFirst(7))) { mode = .tucked(edge) }
        default: mode = .normal
        }
    }
}
