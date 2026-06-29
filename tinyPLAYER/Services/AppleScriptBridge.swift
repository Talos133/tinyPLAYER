import Foundation
import AppKit

enum AppleScriptBridge {

    // MARK: - Public interface

    /// Launches Music.app (if not running) then hides it after a short delay.
    static func launchAndHide() {
        run("tell application \"Music\" to launch")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            hideMusicApp()
        }
    }

    /// Hides Music.app if it is currently running.
    static func hideMusicApp() {
        NSWorkspace.shared.runningApplications
            .first { $0.bundleIdentifier == "com.apple.Music" }?
            .hide()
    }

    /// Sends a quit command to Music.app via AppleScript.
    static func quitMusicApp() {
        run("tell application \"Music\" to quit")
    }

    /// Removes the track with the given database ID from the user's library.
    static func removeFromLibrary(songID: String) {
        run("""
        tell application "Music"
            set matchedTracks to (tracks of library playlist 1 whose database ID is \(songID))
            if (count of matchedTracks) > 0 then
                delete (item 1 of matchedTracks)
            end if
        end tell
        """)
    }

    // MARK: - Internal (accessible via @testable import in tests)

    /// Executes an AppleScript string and returns its string result, or nil on error.
    @discardableResult
    static func run(_ script: String) -> String? {
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let descriptor = appleScript.executeAndReturnError(&error)
        guard error == nil else { return nil }
        return descriptor.stringValue
    }
}
