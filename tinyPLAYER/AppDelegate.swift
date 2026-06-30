import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Services (owned by AppDelegate for lifetime management)

    var panel:         FloatingPanel!
    var windowManager: WindowManager!
    var musicService:  MusicService!
    var themeManager:  ThemeManager!
    var scoreStore:    ScoreStore!
    var radioService:  RadioService!

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {

        // Hide from Dock — accessory-style app
        NSApplication.shared.setActivationPolicy(.accessory)

        // CoreData stack
        let container = PersistenceController.shared.container

        // Services
        themeManager = ThemeManager()
        musicService  = MusicService()
        scoreStore    = ScoreStore(context: container.viewContext)
        radioService  = RadioService()

        // Window + window manager
        panel         = FloatingPanel()
        windowManager = WindowManager(panel: panel)

        // Root SwiftUI view
        let root = RootView()
            .environmentObject(musicService)
            .environmentObject(themeManager)
            .environmentObject(scoreStore)
            .environmentObject(radioService)
            .environmentObject(windowManager)

        panel.contentView = NSHostingView(rootView: root)
        panel.center()
        panel.makeKeyAndOrderFront(nil)

        // Launch Music.app in the background and hide it
        AppleScriptBridge.launchAndHide()

        // Request MusicKit authorization (triggers system prompt on first launch)
        Task { await musicService.requestAuthorization() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "tinyplayer_quit_music_on_exit") {
            AppleScriptBridge.quitMusicApp()
        }
    }
}
