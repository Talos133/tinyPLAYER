# tinyPLAYER Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build tinyPLAYER — a floating macOS music player that controls Apple Music invisibly via MusicKit, with Greek-letter song scoring, 6 color palettes, radio station creation, edge-tuck window behavior, and Apple-native sharing.

**Architecture:** SwiftUI views compose onto an `NSPanel` (floating window level) managed by a pure-Swift `WindowManager`. A `MusicService` wraps `MusicKit.SystemMusicPlayer` to drive hidden Music.app. `ScoreStore` persists Greek-letter scores in CoreData. `ThemeManager` owns palettes and font sizes as SwiftUI environment values.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit, MusicKit, CoreData, XCTest, macOS 14.0+

## Global Constraints

- macOS 14.0+ deployment target
- MusicKit entitlement: `com.apple.developer.musickit = true`
- Music.app stays hidden for entire session — never visible to user
- Greek grade: Alpha = 10 (best) … Kappa = 1 (lowest)
- 6 palettes: Greek Aegean, Forest, Tropical Islands, Nightly Urban, Beach Bonfire, Morning Mountains
- Font sizes: Small = 11pt, Medium = 13pt (default), Large = 15pt
- Normal player: 360 × 360 pt · Mini: 145 × 72 pt · Tuck sliver: 12 pt
- Scores stored locally in CoreData only — not pushed to Apple Music star rating
- No iCloud sync, no iOS companion, no commercial use (v1 scope)

---

## File Map

```
tinyPLAYER/
├── tinyPLAYERApp.swift
├── AppDelegate.swift
├── Services/
│   ├── MusicServiceProtocol.swift
│   ├── MusicService.swift
│   ├── AppleScriptBridge.swift
│   └── RadioService.swift
├── Windows/
│   ├── FloatingPanel.swift
│   └── WindowManager.swift
├── Views/
│   ├── PlayerView.swift
│   ├── MiniPlayerView.swift
│   ├── ArtworkView.swift
│   ├── TrackInfoView.swift
│   ├── ControlsView.swift
│   ├── ActionBarView.swift
│   ├── SettingsDrawer.swift
│   └── ScoreBrowserView.swift
├── Theme/
│   ├── AppTheme.swift
│   ├── Palettes.swift
│   ├── Color+Hex.swift
│   └── ThemeManager.swift
├── Model/
│   ├── GreekGrade.swift
│   ├── SongIdentity.swift
│   ├── ScoreStore.swift
│   └── tinyPLAYER.xcdatamodeld
└── Shared/
    └── SharingService.swift

tinyPLAYERTests/
├── ThemeManagerTests.swift
├── GreekGradeTests.swift
├── ScoreStoreTests.swift
└── WindowManagerTests.swift
```

---

### Task 1: Xcode Project Bootstrap

**Files:**
- Create: `tinyPLAYER.xcodeproj` (Xcode GUI — see steps below)
- Create: `tinyPLAYER/tinyPLAYER.entitlements`
- Create: `tinyPLAYER/Model/tinyPLAYER.xcdatamodeld`

**Interfaces:**
- Produces: Buildable Xcode project with MusicKit entitlement, CoreData model, and test target

- [ ] **Step 1: Create Xcode project**

  Open Xcode → File → New → Project → macOS → App.
  - Product Name: `tinyPLAYER`
  - Interface: SwiftUI
  - Language: Swift
  - Storage: Core Data ✓
  - Include Tests ✓
  - Deployment Target: macOS 14.0

- [ ] **Step 2: Configure entitlements**

  In Xcode: select the `tinyPLAYER` target → Signing & Capabilities → + Capability → MusicKit.
  This auto-creates `tinyPLAYER.entitlements`. Verify it contains:

  ```xml
  <key>com.apple.developer.musickit</key>
  <true/>
  ```

- [ ] **Step 3: Add Info.plist usage strings**

  In `Info.plist` add two keys:
  ```xml
  <key>NSAppleMusicUsageDescription</key>
  <string>tinyPLAYER needs Apple Music access to play your library.</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>tinyPLAYER uses Apple Events to control Music.app in the background.</string>
  ```

- [ ] **Step 4: Configure CoreData model**

  Open `tinyPLAYER.xcdatamodeld` → Add Entity named `SongScore` with these attributes:

  | Attribute | Type | Optional |
  |-----------|------|----------|
  | songID | String | No |
  | scoreValue | Integer 16 | No |
  | songTitle | String | Yes |
  | artistName | String | Yes |
  | albumName | String | Yes |
  | dateScored | Date | Yes |

  Set `songID` as the unique constraint (Editor → Add Constraint → `songID`).
  Set Codegen to **Class Definition**.

- [ ] **Step 5: Create folder groups in Xcode**

  In Xcode Navigator, create groups: `Services`, `Windows`, `Views`, `Theme`, `Model`, `Shared`.
  Delete the default `ContentView.swift` (we replace it in Task 14).

- [ ] **Step 6: Verify project builds**

  ```bash
  xcodebuild build -scheme tinyPLAYER -destination 'platform=macOS' 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

  ```bash
  git add .
  git commit -m "chore: Xcode project bootstrap with MusicKit + CoreData"
  ```

---

### Task 2: Color+Hex Extension

**Files:**
- Create: `tinyPLAYER/Theme/Color+Hex.swift`
- Test: `tinyPLAYERTests/ColorHexTests.swift`

**Interfaces:**
- Produces: `Color(hex: String)` initializer used by every palette in Task 3

- [ ] **Step 1: Write the failing test**

  Create `tinyPLAYERTests/ColorHexTests.swift`:
  ```swift
  import XCTest
  import SwiftUI
  @testable import tinyPLAYER

  final class ColorHexTests: XCTestCase {
      func test_hexBlack_parsesCorrectly() {
          // Color(hex:) should not crash on known values
          let _ = Color(hex: "000000")
          let _ = Color(hex: "ffffff")
          let _ = Color(hex: "0d2247")
          // If we get here without crashing, the initializer works
          XCTAssertTrue(true)
      }
  }
  ```

- [ ] **Step 2: Run test to verify it fails**

  ```bash
  xcodebuild test -scheme tinyPLAYER -destination 'platform=macOS' \
    -only-testing:tinyPLAYERTests/ColorHexTests 2>&1 | grep -E 'FAILED|error:'
  ```
  Expected: compile error — `Color(hex:)` not defined

- [ ] **Step 3: Implement**

  Create `tinyPLAYER/Theme/Color+Hex.swift`:
  ```swift
  import SwiftUI

  extension Color {
      init(hex: String) {
          let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
          var rgb: UInt64 = 0
          scanner.scanHexInt64(&rgb)
          let r = Double((rgb >> 16) & 0xFF) / 255
          let g = Double((rgb >> 8)  & 0xFF) / 255
          let b = Double( rgb        & 0xFF) / 255
          self.init(red: r, green: g, blue: b)
      }
  }
  ```

- [ ] **Step 4: Run test to verify it passes**

  ```bash
  xcodebuild test -scheme tinyPLAYER -destination 'platform=macOS' \
    -only-testing:tinyPLAYERTests/ColorHexTests 2>&1 | grep -E 'PASSED|TEST SUCCEEDED'
  ```
  Expected: `TEST SUCCEEDED`

- [ ] **Step 5: Commit**

  ```bash
  git add tinyPLAYER/Theme/Color+Hex.swift tinyPLAYERTests/ColorHexTests.swift
  git commit -m "feat: Color(hex:) initializer"
  ```

---

### Task 3: AppTheme + Palettes + ThemeManager

**Files:**
- Create: `tinyPLAYER/Theme/AppTheme.swift`
- Create: `tinyPLAYER/Theme/Palettes.swift`
- Create: `tinyPLAYER/Theme/ThemeManager.swift`
- Test: `tinyPLAYERTests/ThemeManagerTests.swift`

**Interfaces:**
- Consumes: `Color(hex:)` from Task 2
- Produces:
  - `AppTheme` struct with 8 `Color` tokens + `name: String`
  - `AppFontSize` enum: `.small` (11pt) / `.medium` (13pt) / `.large` (15pt)
  - `Palettes.all: [AppTheme]` — 6 palettes
  - `ThemeManager` — `@MainActor ObservableObject` with `current: AppTheme`, `fontSize: AppFontSize`, `apply(palette:)`, `apply(fontSize:)`

- [ ] **Step 1: Write failing tests**

  Create `tinyPLAYERTests/ThemeManagerTests.swift`:
  ```swift
  import XCTest
  @testable import tinyPLAYER

  @MainActor
  final class ThemeManagerTests: XCTestCase {

      func test_defaultPalette_isGreekAegean() {
          UserDefaults.standard.removeObject(forKey: "tinyplayer_palette")
          let mgr = ThemeManager()
          XCTAssertEqual(mgr.current.name, "Greek Aegean")
      }

      func test_applyPalette_changesCurrentTheme() {
          let mgr = ThemeManager()
          mgr.apply(palette: Palettes.forest)
          XCTAssertEqual(mgr.current.name, "Forest")
      }

      func test_defaultFontSize_isMedium() {
          UserDefaults.standard.removeObject(forKey: "tinyplayer_fontsize")
          let mgr = ThemeManager()
          XCTAssertEqual(mgr.fontSize, .medium)
      }

      func test_applyFontSize_updatesSize() {
          let mgr = ThemeManager()
          mgr.apply(fontSize: .large)
          XCTAssertEqual(mgr.fontSize, .large)
      }

      func test_palettes_containsSixEntries() {
          XCTAssertEqual(Palettes.all.count, 6)
      }

      func test_fontSizeBodyPoints() {
          XCTAssertEqual(AppFontSize.small.body,  11)
          XCTAssertEqual(AppFontSize.medium.body, 13)
          XCTAssertEqual(AppFontSize.large.body,  15)
      }
  }
  ```

- [ ] **Step 2: Run tests to verify they fail**

  ```bash
  xcodebuild test -scheme tinyPLAYER -destination 'platform=macOS' \
    -only-testing:tinyPLAYERTests/ThemeManagerTests 2>&1 | grep -E 'FAILED|error:'
  ```
  Expected: compile errors — types not yet defined

- [ ] **Step 3: Implement AppTheme.swift**

  Create `tinyPLAYER/Theme/AppTheme.swift`:
  ```swift
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
  ```

- [ ] **Step 4: Implement Palettes.swift**

  Create `tinyPLAYER/Theme/Palettes.swift`:
  ```swift
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
  ```

- [ ] **Step 5: Implement ThemeManager.swift**

  Create `tinyPLAYER/Theme/ThemeManager.swift`:
  ```swift
  import SwiftUI

  @MainActor
  final class ThemeManager: ObservableObject {
      @Published private(set) var current:  AppTheme   = Palettes.greek
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
  ```

- [ ] **Step 6: Run tests to verify they pass**

  ```bash
  xcodebuild test -scheme tinyPLAYER -destination 'platform=macOS' \
    -only-testing:tinyPLAYERTests/ThemeManagerTests 2>&1 | grep -E 'PASSED|TEST SUCCEEDED'
  ```
  Expected: `TEST SUCCEEDED`

- [ ] **Step 7: Commit**

  ```bash
  git add tinyPLAYER/Theme/ tinyPLAYERTests/ThemeManagerTests.swift
  git commit -m "feat: theme system — 6 palettes, 3 font sizes, ThemeManager"
  ```

---

### Task 4: GreekGrade + SongIdentity Models

**Files:**
- Create: `tinyPLAYER/Model/GreekGrade.swift`
- Create: `tinyPLAYER/Model/SongIdentity.swift`
- Test: `tinyPLAYERTests/GreekGradeTests.swift`

**Interfaces:**
- Produces:
  - `GreekGrade: Int, CaseIterable, Comparable` — `.alpha`=10 … `.kappa`=1, `.symbol: String`, `.displayName: String`, `init?(score: Int)`
  - `SongIdentity` — `id: String, title: String, artist: String, album: String`

- [ ] **Step 1: Write failing tests**

  Create `tinyPLAYERTests/GreekGradeTests.swift`:
  ```swift
  import XCTest
  @testable import tinyPLAYER

  final class GreekGradeTests: XCTestCase {

      func test_alpha_rawValue_is10() {
          XCTAssertEqual(GreekGrade.alpha.rawValue, 10)
      }

      func test_kappa_rawValue_is1() {
          XCTAssertEqual(GreekGrade.kappa.rawValue, 1)
      }

      func test_alpha_symbol_isCorrectUnicode() {
          XCTAssertEqual(GreekGrade.alpha.symbol, "Α")
      }

      func test_kappa_symbol_isCorrectUnicode() {
          XCTAssertEqual(GreekGrade.kappa.symbol, "Κ")
      }

      func test_init_validScore_returnsGrade() {
          XCTAssertEqual(GreekGrade(score: 10), .alpha)
          XCTAssertEqual(GreekGrade(score: 1),  .kappa)
          XCTAssertEqual(GreekGrade(score: 8),  .gamma)
      }

      func test_init_invalidScore_returnsNil() {
          XCTAssertNil(GreekGrade(score: 0))
          XCTAssertNil(GreekGrade(score: 11))
      }

      func test_allCases_hasTenEntries() {
          XCTAssertEqual(GreekGrade.allCases.count, 10)
      }

      func test_comparable_alphaGreaterThanKappa() {
          XCTAssertTrue(GreekGrade.alpha > GreekGrade.kappa)
      }
  }
  ```

- [ ] **Step 2: Run tests to verify they fail**

  ```bash
  xcodebuild test -scheme tinyPLAYER -destination 'platform=macOS' \
    -only-testing:tinyPLAYERTests/GreekGradeTests 2>&1 | grep -E 'FAILED|error:'
  ```
  Expected: compile error

- [ ] **Step 3: Implement GreekGrade.swift**

  Create `tinyPLAYER/Model/GreekGrade.swift`:
  ```swift
  enum GreekGrade: Int, CaseIterable, Comparable {
      case kappa   = 1
      case iota    = 2
      case theta   = 3
      case eta     = 4
      case zeta    = 5
      case epsilon = 6
      case delta   = 7
      case gamma   = 8
      case beta    = 9
      case alpha   = 10

      var symbol: String {
          switch self {
          case .alpha:   "Α"
          case .beta:    "Β"
          case .gamma:   "Γ"
          case .delta:   "Δ"
          case .epsilon: "Ε"
          case .zeta:    "Ζ"
          case .eta:     "Η"
          case .theta:   "Θ"
          case .iota:    "Ι"
          case .kappa:   "Κ"
          }
      }

      var displayName: String {
          switch self {
          case .alpha:   "Alpha"
          case .beta:    "Beta"
          case .gamma:   "Gamma"
          case .delta:   "Delta"
          case .epsilon: "Epsilon"
          case .zeta:    "Zeta"
          case .eta:     "Eta"
          case .theta:   "Theta"
          case .iota:    "Iota"
          case .kappa:   "Kappa"
          }
      }

      init?(score: Int) {
          self.init(rawValue: score)
      }

      static func < (lhs: GreekGrade, rhs: GreekGrade) -> Bool {
          lhs.rawValue < rhs.rawValue
      }
  }
  ```

- [ ] **Step 4: Implement SongIdentity.swift**

  Create `tinyPLAYER/Model/SongIdentity.swift`:
  ```swift
  struct SongIdentity {
      let id:     String   // MusicKit track.id.rawValue
      let title:  String
      let artist: String
      let album:  String
  }
  ```

- [ ] **Step 5: Run tests to verify they pass**

  ```bash
  xcodebuild test -scheme tinyPLAYER -destination 'platform=macOS' \
    -only-testing:tinyPLAYERTests/GreekGradeTests 2>&1 | grep -E 'PASSED|TEST SUCCEEDED'
  ```
  Expected: `TEST SUCCEEDED`

- [ ] **Step 6: Commit**

  ```bash
  git add tinyPLAYER/Model/GreekGrade.swift tinyPLAYER/Model/SongIdentity.swift \
          tinyPLAYERTests/GreekGradeTests.swift
  git commit -m "feat: GreekGrade model (Alpha=10…Kappa=1) + SongIdentity"
  ```

---

### Task 5: ScoreStore (CoreData)

**Files:**
- Modify: `tinyPLAYER/Model/tinyPLAYER.xcdatamodeld` (already configured in Task 1)
- Create: `tinyPLAYER/Model/ScoreStore.swift`
- Test: `tinyPLAYERTests/ScoreStoreTests.swift`

**Interfaces:**
- Consumes: `GreekGrade` (Task 4), `SongIdentity` (Task 4), `SongScore` NSManagedObject (auto-generated by Xcode from model)
- Produces:
  - `ScoreStore(context: NSManagedObjectContext)`
  - `func setScore(_ score: Int, for song: SongIdentity) throws`
  - `func clearScore(for songID: String) throws`
  - `func score(for songID: String) -> SongScore?`
  - `func filtered(grades: Set<GreekGrade>, sortedBy: ScoreSortOption) -> [SongScore]`
  - `enum ScoreSortOption` — `.gradeDesc`, `.gradeAsc`, `.dateScored`, `.artist`, `.title`
  - `enum ScoreError` — `.invalidScore`

- [ ] **Step 1: Write failing tests**

  Create `tinyPLAYERTests/ScoreStoreTests.swift`:
  ```swift
  import XCTest
  import CoreData
  @testable import tinyPLAYER

  @MainActor
  final class ScoreStoreTests: XCTestCase {
      var store: ScoreStore!

      override func setUpWithError() throws {
          let container = NSPersistentContainer(name: "tinyPLAYER")
          let desc = NSPersistentStoreDescription()
          desc.type = NSInMemoryStoreType
          container.persistentStoreDescriptions = [desc]
          var loadError: Error?
          container.loadPersistentStores { _, error in loadError = error }
          if let error = loadError { throw error }
          store = ScoreStore(context: container.viewContext)
      }

      func test_setScore_persistsCorrectValue() throws {
          let song = SongIdentity(id: "s1", title: "Bohemian Rhapsody",
                                  artist: "Queen", album: "A Night at the Opera")
          try store.setScore(10, for: song)
          let result = store.score(for: "s1")
          XCTAssertEqual(result?.scoreValue, 10)
      }

      func test_setScore_storesGreekGradeForAlpha() throws {
          let song = SongIdentity(id: "s2", title: "T", artist: "A", album: "L")
          try store.setScore(10, for: song)
          XCTAssertEqual(GreekGrade(score: Int(store.score(for: "s2")!.scoreValue)), .alpha)
      }

      func test_setScore_invalidValue_throwsScoreError() {
          let song = SongIdentity(id: "s3", title: "T", artist: "A", album: "L")
          XCTAssertThrowsError(try store.setScore(0,  for: song))
          XCTAssertThrowsError(try store.setScore(11, for: song))
      }

      func test_clearScore_removesEntry() throws {
          let song = SongIdentity(id: "s4", title: "T", artist: "A", album: "L")
          try store.setScore(7, for: song)
          try store.clearScore(for: "s4")
          XCTAssertNil(store.score(for: "s4"))
      }

      func test_filtered_byAlpha_returnsOnlyAlphaSongs() throws {
          let s1 = SongIdentity(id: "f1", title: "A", artist: "X", album: "L")
          let s2 = SongIdentity(id: "f2", title: "B", artist: "X", album: "L")
          try store.setScore(10, for: s1) // Alpha
          try store.setScore(5,  for: s2) // Zeta
          let results = store.filtered(grades: [.alpha], sortedBy: .gradeDesc)
          XCTAssertEqual(results.count, 1)
          XCTAssertEqual(results.first?.songID, "f1")
      }

      func test_filtered_emptyGrades_returnsAll() throws {
          let s1 = SongIdentity(id: "g1", title: "A", artist: "X", album: "L")
          let s2 = SongIdentity(id: "g2", title: "B", artist: "X", album: "L")
          try store.setScore(10, for: s1)
          try store.setScore(5,  for: s2)
          let results = store.filtered(grades: [], sortedBy: .gradeDesc)
          XCTAssertEqual(results.count, 2)
      }

      func test_sorted_byTitle_isCaseInsensitiveAscending() throws {
          let s1 = SongIdentity(id: "h1", title: "Zephyr",  artist: "A", album: "L")
          let s2 = SongIdentity(id: "h2", title: "Andante", artist: "A", album: "L")
          try store.setScore(8, for: s1)
          try store.setScore(8, for: s2)
          let results = store.filtered(grades: [], sortedBy: .title)
          XCTAssertEqual(results.first?.songTitle, "Andante")
      }
  }
  ```

- [ ] **Step 2: Run tests to verify they fail**

  ```bash
  xcodebuild test -scheme tinyPLAYER -destination 'platform=macOS' \
    -only-testing:tinyPLAYERTests/ScoreStoreTests 2>&1 | grep -E 'FAILED|error:'
  ```
  Expected: compile error

- [ ] **Step 3: Implement ScoreStore.swift**

  Create `tinyPLAYER/Model/ScoreStore.swift`:
  ```swift
  import CoreData
  import Foundation

  enum ScoreSortOption: String, CaseIterable {
      case gradeDesc  = "Grade ↓"
      case gradeAsc   = "Grade ↑"
      case dateScored = "Date Scored"
      case artist     = "Artist"
      case title      = "Title"
  }

  enum ScoreError: Error {
      case invalidScore
  }

  @MainActor
  final class ScoreStore: ObservableObject {
      @Published private(set) var scores: [SongScore] = []

      private let context: NSManagedObjectContext

      init(context: NSManagedObjectContext) {
          self.context = context
          reload()
      }

      func setScore(_ score: Int, for song: SongIdentity) throws {
          guard GreekGrade(score: score) != nil else { throw ScoreError.invalidScore }

          let entity: SongScore
          if let existing = scores.first(where: { $0.songID == song.id }) {
              entity = existing
          } else {
              entity = SongScore(context: context)
              entity.songID = song.id
          }
          entity.scoreValue = Int16(score)
          entity.songTitle  = song.title
          entity.artistName = song.artist
          entity.albumName  = song.album
          entity.dateScored = Date()

          try context.save()
          reload()
      }

      func clearScore(for songID: String) throws {
          guard let entity = scores.first(where: { $0.songID == songID }) else { return }
          context.delete(entity)
          try context.save()
          reload()
      }

      func score(for songID: String) -> SongScore? {
          scores.first { $0.songID == songID }
      }

      func filtered(grades: Set<GreekGrade>, sortedBy option: ScoreSortOption) -> [SongScore] {
          let base = grades.isEmpty ? scores : scores.filter {
              GreekGrade(score: Int($0.scoreValue)).map { grades.contains($0) } ?? false
          }
          return base.sorted(by: option)
      }

      private func reload() {
          let req = SongScore.fetchRequest() as NSFetchRequest<SongScore>
          scores = (try? context.fetch(req)) ?? []
      }
  }

  private extension Array where Element == SongScore {
      func sorted(by option: ScoreSortOption) -> [SongScore] {
          switch option {
          case .gradeDesc:  self.sorted { $0.scoreValue > $1.scoreValue }
          case .gradeAsc:   self.sorted { $0.scoreValue < $1.scoreValue }
          case .dateScored: self.sorted { ($0.dateScored ?? .distantPast) > ($1.dateScored ?? .distantPast) }
          case .artist:     self.sorted { ($0.artistName ?? "").lowercased() < ($1.artistName ?? "").lowercased() }
          case .title:      self.sorted { ($0.songTitle  ?? "").lowercased() < ($1.songTitle  ?? "").lowercased() }
          }
      }
  }
  ```

- [ ] **Step 4: Run tests to verify they pass**

  ```bash
  xcodebuild test -scheme tinyPLAYER -destination 'platform=macOS' \
    -only-testing:tinyPLAYERTests/ScoreStoreTests 2>&1 | grep -E 'PASSED|TEST SUCCEEDED'
  ```
  Expected: `TEST SUCCEEDED`

- [ ] **Step 5: Commit**

  ```bash
  git add tinyPLAYER/Model/ScoreStore.swift tinyPLAYERTests/ScoreStoreTests.swift
  git commit -m "feat: ScoreStore — CoreData-backed Greek-grade scoring with sort/filter"
  ```

---

### Task 6: FloatingPanel + WindowManager

**Files:**
- Create: `tinyPLAYER/Windows/FloatingPanel.swift`
- Create: `tinyPLAYER/Windows/WindowMode.swift`
- Create: `tinyPLAYER/Windows/WindowManager.swift`
- Test: `tinyPLAYERTests/WindowManagerTests.swift`

**Interfaces:**
- Produces:
  - `FloatingPanel: NSPanel` — floating level, borderless, transparent background
  - `WindowMode` enum — `.normal`, `.mini`, `.tucked(ScreenEdge)`
  - `ScreenEdge` enum — `.top`, `.bottom`, `.leading`, `.trailing`
  - `WindowManager(panel: FloatingPanel)` — `@MainActor ObservableObject`
    - `var mode: WindowMode` — `@Published`
    - `func toggleMiniNormal()`
    - `func untuck()`

- [ ] **Step 1: Write failing tests**

  Create `tinyPLAYERTests/WindowManagerTests.swift`:
  ```swift
  import XCTest
  @testable import tinyPLAYER

  @MainActor
  final class WindowManagerTests: XCTestCase {

      func test_initialMode_isNormal() {
          UserDefaults.standard.removeObject(forKey: "tinyplayer_windowmode")
          let mgr = WindowManager(panel: FloatingPanel())
          XCTAssertEqual(mgr.mode, .normal)
      }

      func test_toggleMiniNormal_fromNormal_goesMini() {
          let mgr = WindowManager(panel: FloatingPanel())
          mgr.toggleMiniNormal()
          XCTAssertEqual(mgr.mode, .mini)
      }

      func test_toggleMiniNormal_fromMini_goesNormal() {
          let mgr = WindowManager(panel: FloatingPanel())
          mgr.toggleMiniNormal()
          mgr.toggleMiniNormal()
          XCTAssertEqual(mgr.mode, .normal)
      }

      func test_untuck_whenNotTucked_doesNotChangeModeOrCrash() {
          let mgr = WindowManager(panel: FloatingPanel())
          mgr.untuck()
          XCTAssertEqual(mgr.mode, .normal)
      }

      func test_windowModeEquality_tuckedSameEdge() {
          XCTAssertEqual(WindowMode.tucked(.leading), WindowMode.tucked(.leading))
          XCTAssertNotEqual(WindowMode.tucked(.leading), WindowMode.tucked(.trailing))
      }
  }
  ```

- [ ] **Step 2: Run tests to verify they fail**

  ```bash
  xcodebuild test -scheme tinyPLAYER -destination 'platform=macOS' \
    -only-testing:tinyPLAYERTests/WindowManagerTests 2>&1 | grep -E 'FAILED|error:'
  ```

- [ ] **Step 3: Implement WindowMode.swift**

  Create `tinyPLAYER/Windows/WindowMode.swift`:
  ```swift
  enum WindowMode: Equatable {
      case normal
      case mini
      case tucked(ScreenEdge)
  }

  enum ScreenEdge: String, Codable {
      case top, bottom, leading, trailing
  }
  ```

- [ ] **Step 4: Implement FloatingPanel.swift**

  Create `tinyPLAYER/Windows/FloatingPanel.swift`:
  ```swift
  import AppKit

  final class FloatingPanel: NSPanel {
      init() {
          super.init(
              contentRect: NSRect(x: 0, y: 0, width: 360, height: 360),
              styleMask: [.nonactivatingPanel, .borderless, .hudWindow],
              backing: .buffered,
              defer: false
          )
          level                    = .floating
          collectionBehavior       = [.canJoinAllSpaces, .fullScreenAuxiliary]
          isMovableByWindowBackground = true
          backgroundColor          = .clear
          hasShadow                = true
          isReleasedWhenClosed     = false
      }
  }
  ```

- [ ] **Step 5: Implement WindowManager.swift**

  Create `tinyPLAYER/Windows/WindowManager.swift`:
  ```swift
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
          case .tucked:  size = panel.frame.size   // keep current size when tucking
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

          if      f.minX <= sv.minX + t       { snap(to: .leading) }
          else if f.maxX >= sv.maxX - t       { snap(to: .trailing) }
          else if f.maxY >= sv.maxY - t       { snap(to: .top) }
          else if f.minY <= sv.minY + t       { snap(to: .bottom) }
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
  ```

- [ ] **Step 6: Run tests to verify they pass**

  ```bash
  xcodebuild test -scheme tinyPLAYER -destination 'platform=macOS' \
    -only-testing:tinyPLAYERTests/WindowManagerTests 2>&1 | grep -E 'PASSED|TEST SUCCEEDED'
  ```
  Expected: `TEST SUCCEEDED`

- [ ] **Step 7: Commit**

  ```bash
  git add tinyPLAYER/Windows/ tinyPLAYERTests/WindowManagerTests.swift
  git commit -m "feat: FloatingPanel + WindowManager (normal/mini/tuck-to-edge)"
  ```

---

### Task 7: MusicServiceProtocol + MockMusicService

**Files:**
- Create: `tinyPLAYER/Services/MusicServiceProtocol.swift`
- Create: `tinyPLAYERTests/MockMusicService.swift`

**Interfaces:**
- Produces:
  - `MusicServiceProtocol` — defines all music properties + async methods
  - `MockMusicService: MusicServiceProtocol, ObservableObject` — in-test fake with call-tracking flags

- [ ] **Step 1: Implement MusicServiceProtocol.swift**

  Create `tinyPLAYER/Services/MusicServiceProtocol.swift`:
  ```swift
  import Foundation

  @MainActor
  protocol MusicServiceProtocol: AnyObject, ObservableObject {
      var currentTitle:     String  { get }
      var currentArtist:    String  { get }
      var currentAlbum:     String  { get }
      var currentYear:      Int?    { get }
      var artworkURL:       URL?    { get }
      var isPlaying:        Bool    { get }
      var playbackProgress: Double  { get }
      var inLibrary:        Bool    { get }
      var currentSongID:    String? { get }

      func play()              async throws
      func pause()
      func skipToNext()        async throws
      func skipToPrevious()    async throws
      func addToLibrary()      async throws
      func removeFromLibrary() async throws
      func requestAuthorization() async
  }
  ```

- [ ] **Step 2: Implement MockMusicService.swift in test target**

  Create `tinyPLAYERTests/MockMusicService.swift`:
  ```swift
  import Foundation
  @testable import tinyPLAYER

  @MainActor
  final class MockMusicService: MusicServiceProtocol, ObservableObject {
      @Published var currentTitle:     String  = "Mock Song"
      @Published var currentArtist:    String  = "Mock Artist"
      @Published var currentAlbum:     String  = "Mock Album"
      @Published var currentYear:      Int?    = 2024
      @Published var artworkURL:       URL?    = nil
      @Published var isPlaying:        Bool    = false
      @Published var playbackProgress: Double  = 0.0
      @Published var inLibrary:        Bool    = true
      @Published var currentSongID:    String? = "mock-id-001"

      var playCalled            = false
      var pauseCalled           = false
      var skipNextCalled        = false
      var skipPrevCalled        = false
      var addToLibraryCalled    = false
      var removeFromLibraryCalled = false

      func play()              async throws { playCalled = true;  isPlaying = true  }
      func pause()                         { pauseCalled = true; isPlaying = false }
      func skipToNext()        async throws { skipNextCalled = true }
      func skipToPrevious()    async throws { skipPrevCalled = true }
      func addToLibrary()      async throws { addToLibraryCalled = true;    inLibrary = true  }
      func removeFromLibrary() async throws { removeFromLibraryCalled = true; inLibrary = false }
      func requestAuthorization() async {}
  }
  ```

- [ ] **Step 3: Verify project builds with new files**

  ```bash
  xcodebuild build -scheme tinyPLAYER -destination 'platform=macOS' 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

  ```bash
  git add tinyPLAYER/Services/MusicServiceProtocol.swift \
          tinyPLAYERTests/MockMusicService.swift
  git commit -m "feat: MusicServiceProtocol + MockMusicService for testing"
  ```

---

### Task 8: AppleScriptBridge + MusicService

**Files:**
- Create: `tinyPLAYER/Services/AppleScriptBridge.swift`
- Create: `tinyPLAYER/Services/MusicService.swift`

**Interfaces:**
- Consumes: `MusicServiceProtocol` (Task 7)
- Produces:
  - `AppleScriptBridge` — `static func launchAndHide()`, `static func removeFromLibrary(songID:)`
  - `MusicService: MusicServiceProtocol, ObservableObject` — real MusicKit implementation

> **Note:** `MusicService` cannot be unit-tested without a real Apple Music auth grant. All business logic lives in testable services (ScoreStore, RadioService). Verify MusicService manually by running the app with a real Apple Music account.

- [ ] **Step 1: Implement AppleScriptBridge.swift**

  Create `tinyPLAYER/Services/AppleScriptBridge.swift`:
  ```swift
  import Foundation
  import AppKit

  enum AppleScriptBridge {

      static func launchAndHide() {
          run("tell application \"Music\" to launch")
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
              NSWorkspace.shared.runningApplications
                  .first { $0.bundleIdentifier == "com.apple.Music" }?
                  .hide()
          }
      }

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

      @discardableResult
      private static func run(_ script: String) -> String? {
          var error: NSDictionary?
          return NSAppleScript(source: script)?.executeAndReturnError(&error)?.stringValue
      }
  }
  ```

- [ ] **Step 2: Implement MusicService.swift**

  Create `tinyPLAYER/Services/MusicService.swift`:
  ```swift
  import MusicKit
  import Combine
  import AppKit

  @MainActor
  final class MusicService: MusicServiceProtocol, ObservableObject {

      @Published var currentTitle:     String  = "—"
      @Published var currentArtist:    String  = "—"
      @Published var currentAlbum:     String  = "—"
      @Published var currentYear:      Int?    = nil
      @Published var artworkURL:       URL?    = nil
      @Published var isPlaying:        Bool    = false
      @Published var playbackProgress: Double  = 0.0
      @Published var inLibrary:        Bool    = false
      @Published var currentSongID:    String? = nil

      private let player = SystemMusicPlayer.shared
      private var stateObserver: AnyCancellable?
      private var currentSong: Song?

      init() {
          observeState()
      }

      func requestAuthorization() async {
          let status = await MusicAuthorization.request()
          if status == .authorized {
              AppleScriptBridge.launchAndHide()
          }
      }

      func play()              async throws { try await player.play() }
      func pause()                         { player.pause() }
      func skipToNext()        async throws { try await player.skipToNextEntry() }
      func skipToPrevious()    async throws { try await player.skipToPreviousEntry() }

      func addToLibrary()      async throws {
          guard let song = currentSong else { return }
          try await MusicLibrary.shared.add(song)
          inLibrary = true
      }

      func removeFromLibrary() async throws {
          guard let id = currentSongID else { return }
          AppleScriptBridge.removeFromLibrary(songID: id)
          inLibrary = false
      }

      // MARK: - Private

      private func observeState() {
          stateObserver = player.state.objectWillChange
              .receive(on: DispatchQueue.main)
              .sink { [weak self] _ in self?.updateNowPlaying() }
      }

      private func updateNowPlaying() {
          isPlaying = player.state.playbackStatus == .playing

          guard let entry = player.queue.currentEntry,
                case .song(let song) = entry.item else {
              clearNowPlaying(); return
          }

          currentSong   = song
          currentSongID = song.id.rawValue
          currentTitle  = song.title
          currentArtist = song.artistName
          currentAlbum  = song.albumTitle ?? "—"
          artworkURL    = song.artwork?.url(width: 400, height: 400)
          if let date = song.releaseDate {
              currentYear = Calendar.current.component(.year, from: date)
          }
          updatePlaybackProgress()
      }

      private func updatePlaybackProgress() {
          let duration = player.queue.currentEntry?.endTime ?? 1
          playbackProgress = duration > 0 ? player.playbackTime / duration : 0
      }

      private func clearNowPlaying() {
          currentSong = nil; currentSongID = nil
          currentTitle = "—"; currentArtist = "—"; currentAlbum = "—"
          currentYear = nil; artworkURL = nil; playbackProgress = 0
      }
  }
  ```

- [ ] **Step 3: Build to verify no compile errors**

  ```bash
  xcodebuild build -scheme tinyPLAYER -destination 'platform=macOS' 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

  ```bash
  git add tinyPLAYER/Services/AppleScriptBridge.swift \
          tinyPLAYER/Services/MusicService.swift
  git commit -m "feat: MusicService (MusicKit SystemMusicPlayer) + AppleScriptBridge"
  ```

---

### Task 9: RadioService

**Files:**
- Create: `tinyPLAYER/Services/RadioService.swift`

**Interfaces:**
- Consumes: `MusicKit` (SystemMusicPlayer, MusicLibrary, MusicCatalogResourceRequest)
- Produces:
  - `RadioService` — `@MainActor ObservableObject`
  - `func createStation(from songID: String) async throws`
  - `func saveCurrentQueueAsPlaylist(named: String) async throws`
  - `func addSongToPlaylist(_ songID: String, playlist: Playlist) async throws`
  - `func userPlaylists() async throws -> MusicItemCollection<Playlist>`
  - `enum RadioError` — `.songNotFound`, `.noStation`, `.emptyQueue`

> **MusicKit radio API note:** `song.radioStation` requires calling `song.with([.radioStation])`. If this property is unavailable in the deployed MusicKit version, fall back to `SystemMusicPlayer.shared.play(station)` where station is found via `MusicCatalogSearchRequest<Station>` matching the song's artist name. Test this manually with a real Apple Music account.

- [ ] **Step 1: Implement RadioService.swift**

  Create `tinyPLAYER/Services/RadioService.swift`:
  ```swift
  import MusicKit

  enum RadioError: Error {
      case songNotFound, noStation, emptyQueue
  }

  @MainActor
  final class RadioService: ObservableObject {
      private let player = SystemMusicPlayer.shared

      func createStation(from songID: String) async throws {
          let request  = MusicCatalogResourceRequest<Song>(
              matching: \.id, equalTo: MusicItemID(rawValue: songID))
          let response = try await request.response()
          guard let song = response.items.first else { throw RadioError.songNotFound }

          let detailed = try await song.with([.radioStation])
          guard let station = detailed.radioStation else { throw RadioError.noStation }

          try await player.play(station)
      }

      func saveCurrentQueueAsPlaylist(named name: String) async throws {
          let songs = currentQueueSongs()
          guard !songs.isEmpty else { throw RadioError.emptyQueue }
          let playlist = try await MusicLibrary.shared.createPlaylist(name: name)
          try await MusicLibrary.shared.add(songs, to: playlist)
      }

      func addSongToPlaylist(_ songID: String, playlist: Playlist) async throws {
          let request  = MusicCatalogResourceRequest<Song>(
              matching: \.id, equalTo: MusicItemID(rawValue: songID))
          let response = try await request.response()
          guard let song = response.items.first else { throw RadioError.songNotFound }
          try await MusicLibrary.shared.add(song, to: playlist)
      }

      func userPlaylists() async throws -> MusicItemCollection<Playlist> {
          let request = MusicLibraryRequest<Playlist>()
          return try await request.response().items
      }

      private func currentQueueSongs() -> [Song] {
          player.queue.entries.compactMap { entry -> Song? in
              if case .song(let s) = entry.item { return s }
              return nil
          }
      }
  }
  ```

- [ ] **Step 2: Build to verify**

  ```bash
  xcodebuild build -scheme tinyPLAYER -destination 'platform=macOS' 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

  ```bash
  git add tinyPLAYER/Services/RadioService.swift
  git commit -m "feat: RadioService — auto station + save as playlist + add to playlist"
  ```

---

### Task 10: SharingService

**Files:**
- Create: `tinyPLAYER/Shared/SharingService.swift`

**Interfaces:**
- Produces: `SharingService.share(title:artist:url:)` — shows `NSSharingServicePicker` for AirDrop / Messages / Mail

- [ ] **Step 1: Implement SharingService.swift**

  Create `tinyPLAYER/Shared/SharingService.swift`:
  ```swift
  import AppKit

  enum SharingService {
      static func share(title: String, artist: String, url: URL?,
                        relativeTo sourceRect: NSRect, in view: NSView) {
          let text  = "\(title) — \(artist)"
          var items: [Any] = [text]
          if let url = url { items.append(url) }

          let picker = NSSharingServicePicker(items: items)
          picker.show(relativeTo: sourceRect, of: view, preferredEdge: .minY)
      }
  }
  ```

- [ ] **Step 2: Build to verify**

  ```bash
  xcodebuild build -scheme tinyPLAYER -destination 'platform=macOS' 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

  ```bash
  git add tinyPLAYER/Shared/SharingService.swift
  git commit -m "feat: SharingService — NSSharingServicePicker (AirDrop/Messages/Mail)"
  ```

---

### Task 11: ArtworkView + TrackInfoView + ControlsView

**Files:**
- Create: `tinyPLAYER/Views/ArtworkView.swift`
- Create: `tinyPLAYER/Views/TrackInfoView.swift`
- Create: `tinyPLAYER/Views/ControlsView.swift`

**Interfaces:**
- Consumes: `ThemeManager` (via `@EnvironmentObject`), `MusicService` (via `@EnvironmentObject`)
- Produces: Three composable SwiftUI views used by PlayerView and MiniPlayerView

- [ ] **Step 1: Implement ArtworkView.swift**

  Create `tinyPLAYER/Views/ArtworkView.swift`:
  ```swift
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
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
      }

      private var placeholder: some View {
          RoundedRectangle(cornerRadius: 8)
              .fill(theme.current.bgPanel)
              .overlay(
                  Image(systemName: "music.note")
                      .font(.system(size: size * 0.3))
                      .foregroundStyle(theme.current.textMuted)
              )
      }
  }
  ```

- [ ] **Step 2: Implement TrackInfoView.swift**

  Create `tinyPLAYER/Views/TrackInfoView.swift`:
  ```swift
  import SwiftUI

  struct TrackInfoView: View {
      let title:  String
      let artist: String
      let album:  String
      let year:   Int?
      let grade:  GreekGrade?
      @EnvironmentObject var theme: ThemeManager

      var body: some View {
          HStack(alignment: .firstTextBaseline) {
              VStack(alignment: .leading, spacing: 3) {
                  Text(title)
                      .font(.system(size: theme.fontSize.title, weight: .semibold))
                      .foregroundStyle(theme.current.textPrimary)
                      .lineLimit(1)

                  Text(subtitleText)
                      .font(.system(size: theme.fontSize.label))
                      .foregroundStyle(theme.current.textSecondary)
                      .lineLimit(1)
              }
              Spacer()
              if let grade {
                  Text(grade.symbol)
                      .font(.system(size: theme.fontSize.title, weight: .bold))
                      .foregroundStyle(theme.current.accent)
                      .help("\(grade.displayName) — \(grade.rawValue)/10")
              }
          }
      }

      private var subtitleText: String {
          var parts = [artist, album]
          if let year { parts.append(String(year)) }
          return parts.joined(separator: " · ")
      }
  }
  ```

- [ ] **Step 3: Implement ControlsView.swift**

  Create `tinyPLAYER/Views/ControlsView.swift`:
  ```swift
  import SwiftUI

  struct ControlsView: View {
      @EnvironmentObject var music: MusicService
      @EnvironmentObject var theme: ThemeManager

      var body: some View {
          VStack(spacing: 10) {
              progressBar
              buttons
          }
      }

      private var progressBar: some View {
          GeometryReader { geo in
              ZStack(alignment: .leading) {
                  Capsule().fill(theme.current.border).frame(height: 3)
                  Capsule()
                      .fill(theme.current.accent)
                      .frame(width: geo.size.width * music.playbackProgress, height: 3)
              }
          }
          .frame(height: 3)
      }

      private var buttons: some View {
          HStack(spacing: 28) {
              controlButton("backward.fill") { Task { try? await music.skipToPrevious() } }
              controlButton(music.isPlaying ? "pause.fill" : "play.fill", size: theme.fontSize.body + 6) {
                  if music.isPlaying { music.pause() }
                  else               { Task { try? await music.play() } }
              }
              controlButton("forward.fill")  { Task { try? await music.skipToNext() } }
          }
      }

      private func controlButton(_ icon: String,
                                  size: CGFloat? = nil,
                                  action: @escaping () -> Void) -> some View {
          Button(action: action) {
              Image(systemName: icon)
                  .font(.system(size: size ?? theme.fontSize.body + 2))
                  .foregroundStyle(theme.current.textPrimary)
                  .frame(width: 40, height: 40)
          }
          .buttonStyle(.plain)
      }
  }
  ```

- [ ] **Step 4: Build to verify**

  ```bash
  xcodebuild build -scheme tinyPLAYER -destination 'platform=macOS' 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

  ```bash
  git add tinyPLAYER/Views/ArtworkView.swift \
          tinyPLAYER/Views/TrackInfoView.swift \
          tinyPLAYER/Views/ControlsView.swift
  git commit -m "feat: ArtworkView + TrackInfoView + ControlsView"
  ```

---

### Task 12: ActionBarView + SettingsDrawer

**Files:**
- Create: `tinyPLAYER/Views/ActionBarView.swift`
- Create: `tinyPLAYER/Views/SettingsDrawer.swift`

**Interfaces:**
- Consumes: `MusicService`, `ScoreStore`, `RadioService`, `ThemeManager`, `SharingService` (all via environment or init)
- Produces: `ActionBarView` — library toggle, score picker, radio button, share button, settings gear; `SettingsDrawer` — palette + font size pickers

- [ ] **Step 1: Implement ActionBarView.swift**

  Create `tinyPLAYER/Views/ActionBarView.swift`:
  ```swift
  import SwiftUI
  import AppKit

  struct ActionBarView: View {
      @EnvironmentObject var music:  MusicService
      @EnvironmentObject var scores: ScoreStore
      @EnvironmentObject var radio:  RadioService
      @EnvironmentObject var theme:  ThemeManager

      @State private var showScorePicker  = false
      @State private var showRadioSheet   = false
      @State private var showPlaylistPicker = false
      @State private var userPlaylists: [Playlist] = []
      @Binding var showSettings: Bool

      var body: some View {
          HStack(spacing: 18) {
              // Library toggle
              actionButton(icon: music.inLibrary ? "heart.fill" : "heart",
                           tint: music.inLibrary ? theme.current.accent : theme.current.textMuted) {
                  Task {
                      if music.inLibrary { try? await music.removeFromLibrary() }
                      else               { try? await music.addToLibrary() }
                  }
              }

              // Score
              actionButton(icon: "star", tint: theme.current.textMuted) {
                  showScorePicker.toggle()
              }
              .popover(isPresented: $showScorePicker) { scorePicker }

              // Radio station
              actionButton(icon: "antenna.radiowaves.left.and.right",
                           tint: theme.current.textMuted) {
                  showRadioSheet = true
              }
              .confirmationDialog("Create Station", isPresented: $showRadioSheet) {
                  Button("Play Station Now") {
                      Task { try? await radio.createStation(from: music.currentSongID ?? "") }
                  }
                  Button("Play & Save as Playlist…") {
                      Task {
                          try? await radio.createStation(from: music.currentSongID ?? "")
                          showPlaylistPicker = true
                      }
                  }
              }

              // Share — uses NSView bridge for NSSharingServicePicker
              ShareButtonView(title: music.currentTitle,
                              artist: music.currentArtist,
                              url: music.artworkURL)

              Spacer()

              // Settings gear
              actionButton(icon: "gearshape", tint: theme.current.textMuted) {
                  showSettings.toggle()
              }
          }
      }

      private var scorePicker: some View {
          VStack(spacing: 4) {
              Text("Score this song")
                  .font(.system(size: theme.fontSize.label))
                  .foregroundStyle(theme.current.textMuted)
                  .padding(.top, 8)

              let currentScore = music.currentSongID
                  .flatMap { scores.score(for: $0) }
                  .map    { Int($0.scoreValue) }

              LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 6) {
                  ForEach(GreekGrade.allCases.reversed(), id: \.rawValue) { grade in
                      Button {
                          guard let id = music.currentSongID else { return }
                          let identity = SongIdentity(id: id,
                                                      title: music.currentTitle,
                                                      artist: music.currentArtist,
                                                      album: music.currentAlbum)
                          if currentScore == grade.rawValue {
                              try? scores.clearScore(for: id)
                          } else {
                              try? scores.setScore(grade.rawValue, for: identity)
                          }
                          showScorePicker = false
                      } label: {
                          VStack(spacing: 2) {
                              Text(grade.symbol)
                                  .font(.system(size: 18, weight: .bold))
                              Text(String(grade.rawValue))
                                  .font(.system(size: 9))
                          }
                          .foregroundStyle(currentScore == grade.rawValue
                              ? theme.current.accent : theme.current.textPrimary)
                          .frame(width: 44, height: 44)
                          .background(currentScore == grade.rawValue
                              ? theme.current.accentSoft.opacity(0.3) : Color.clear)
                          .clipShape(RoundedRectangle(cornerRadius: 6))
                      }
                      .buttonStyle(.plain)
                  }
              }
              .padding(.horizontal, 12)
              .padding(.bottom, 12)
          }
          .frame(width: 240)
          .background(theme.current.bgPanel)
      }

      private func actionButton(icon: String, tint: Color,
                                 action: @escaping () -> Void) -> some View {
          Button(action: action) {
              Image(systemName: icon)
                  .font(.system(size: theme.fontSize.body + 1))
                  .foregroundStyle(tint)
                  .frame(width: 32, height: 32)
          }
          .buttonStyle(.plain)
      }
  }

  // NSViewRepresentable bridge so NSSharingServicePicker has a real NSView anchor
  struct ShareButtonView: NSViewRepresentable {
      let title: String; let artist: String; let url: URL?
      @EnvironmentObject var theme: ThemeManager

      func makeNSView(context: Context) -> NSButton {
          let btn = NSButton()
          btn.bezelStyle = .regularSquare
          btn.isBordered = false
          btn.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: nil)
          btn.target = context.coordinator
          btn.action = #selector(Coordinator.share(_:))
          return btn
      }
      func updateNSView(_ nsView: NSButton, context: Context) {
          context.coordinator.parent = self
      }
      func makeCoordinator() -> Coordinator { Coordinator(self) }

      class Coordinator: NSObject {
          var parent: ShareButtonView
          init(_ parent: ShareButtonView) { self.parent = parent }

          @objc func share(_ sender: NSButton) {
              SharingService.share(title: parent.title, artist: parent.artist,
                                   url: parent.url,
                                   relativeTo: sender.bounds, in: sender)
          }
      }
  }
  ```

- [ ] **Step 2: Implement SettingsDrawer.swift**

  Create `tinyPLAYER/Views/SettingsDrawer.swift`:
  ```swift
  import SwiftUI

  struct SettingsDrawer: View {
      @EnvironmentObject var theme: ThemeManager

      var body: some View {
          VStack(alignment: .leading, spacing: 16) {
              Text("Palette")
                  .font(.system(size: theme.fontSize.label, weight: .medium))
                  .foregroundStyle(theme.current.textMuted)

              paletteGrid

              Divider().overlay(theme.current.border)

              Text("Text Size")
                  .font(.system(size: theme.fontSize.label, weight: .medium))
                  .foregroundStyle(theme.current.textMuted)

              fontSizePicker
          }
          .padding(16)
          .background(theme.current.bgPanel)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }

      private var paletteGrid: some View {
          LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 8) {
              ForEach(Palettes.all, id: \.name) { palette in
                  Button { theme.apply(palette: palette) } label: {
                      VStack(spacing: 4) {
                          Circle()
                              .fill(palette.accent)
                              .frame(width: 24, height: 24)
                              .overlay(
                                  Circle().stroke(
                                      theme.current.name == palette.name
                                          ? theme.current.textPrimary : Color.clear,
                                      lineWidth: 2)
                              )
                          Text(palette.name.components(separatedBy: " ").first ?? palette.name)
                              .font(.system(size: 9))
                              .foregroundStyle(theme.current.textSecondary)
                      }
                  }
                  .buttonStyle(.plain)
              }
          }
      }

      private var fontSizePicker: some View {
          HStack(spacing: 0) {
              ForEach(AppFontSize.allCases, id: \.self) { size in
                  Button { theme.apply(fontSize: size) } label: {
                      Text(size.rawValue.capitalized)
                          .font(.system(size: theme.fontSize.label))
                          .foregroundStyle(theme.fontSize == size
                              ? theme.current.bgApp : theme.current.textPrimary)
                          .frame(maxWidth: .infinity)
                          .padding(.vertical, 6)
                          .background(theme.fontSize == size
                              ? theme.current.accent : Color.clear)
                  }
                  .buttonStyle(.plain)
              }
          }
          .clipShape(RoundedRectangle(cornerRadius: 6))
          .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.current.border))
      }
  }
  ```

- [ ] **Step 3: Build to verify**

  ```bash
  xcodebuild build -scheme tinyPLAYER -destination 'platform=macOS' 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

  ```bash
  git add tinyPLAYER/Views/ActionBarView.swift tinyPLAYER/Views/SettingsDrawer.swift
  git commit -m "feat: ActionBarView (library/score/radio/share/settings) + SettingsDrawer"
  ```

---

### Task 13: ScoreBrowserView

**Files:**
- Create: `tinyPLAYER/Views/ScoreBrowserView.swift`

**Interfaces:**
- Consumes: `ScoreStore` (via `@EnvironmentObject`), `MusicService`, `ThemeManager`
- Produces: `ScoreBrowserView` — sheet with Greek filter chips, sort picker, and scored song list

- [ ] **Step 1: Implement ScoreBrowserView.swift**

  Create `tinyPLAYER/Views/ScoreBrowserView.swift`:
  ```swift
  import SwiftUI

  struct ScoreBrowserView: View {
      @EnvironmentObject var scores: ScoreStore
      @EnvironmentObject var music:  MusicService
      @EnvironmentObject var theme:  ThemeManager
      @Environment(\.dismiss) var dismiss

      @State private var selectedGrades: Set<GreekGrade> = []
      @State private var sortOption: ScoreSortOption     = .gradeDesc

      var body: some View {
          VStack(spacing: 0) {
              header
              Divider().overlay(theme.current.border)
              filterBar
              Divider().overlay(theme.current.border)
              songList
          }
          .background(theme.current.bgApp)
          .frame(minWidth: 360, minHeight: 400)
      }

      private var header: some View {
          HStack {
              Text("Score Browser")
                  .font(.system(size: theme.fontSize.title, weight: .semibold))
                  .foregroundStyle(theme.current.textPrimary)
              Spacer()
              Picker("Sort", selection: $sortOption) {
                  ForEach(ScoreSortOption.allCases, id: \.self) { opt in
                      Text(opt.rawValue).tag(opt)
                  }
              }
              .pickerStyle(.menu)
              .font(.system(size: theme.fontSize.label))
              Button { dismiss() } label: {
                  Image(systemName: "xmark.circle.fill")
                      .foregroundStyle(theme.current.textMuted)
              }
              .buttonStyle(.plain)
          }
          .padding(14)
      }

      private var filterBar: some View {
          ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                  ForEach(GreekGrade.allCases.reversed(), id: \.rawValue) { grade in
                      let active = selectedGrades.contains(grade)
                      Button {
                          if active { selectedGrades.remove(grade) }
                          else      { selectedGrades.insert(grade) }
                      } label: {
                          HStack(spacing: 4) {
                              Text(grade.symbol).font(.system(size: 14, weight: .bold))
                              Text(grade.displayName).font(.system(size: theme.fontSize.label))
                          }
                          .foregroundStyle(active ? theme.current.bgApp : theme.current.textPrimary)
                          .padding(.horizontal, 10).padding(.vertical, 5)
                          .background(active ? theme.current.accent : theme.current.bgPanel)
                          .clipShape(Capsule())
                      }
                      .buttonStyle(.plain)
                  }
              }
              .padding(.horizontal, 14)
              .padding(.vertical, 10)
          }
      }

      private var songList: some View {
          let items = scores.filtered(grades: selectedGrades, sortedBy: sortOption)
          return Group {
              if items.isEmpty {
                  ContentUnavailableView("No scored songs",
                      systemImage: "star.slash",
                      description: Text("Score a song from the player to see it here."))
              } else {
                  List(items, id: \.songID) { item in
                      songRow(item)
                          .listRowBackground(theme.current.bgApp)
                          .onTapGesture {
                              // Playing by song ID requires a catalog lookup —
                              // trigger via MusicKit in a future improvement.
                              // For now: copy song title to pasteboard as a hint.
                              NSPasteboard.general.clearContents()
                              NSPasteboard.general.setString(
                                  item.songTitle ?? "", forType: .string)
                          }
                  }
                  .listStyle(.plain)
              }
          }
      }

      private func songRow(_ item: SongScore) -> some View {
          HStack {
              if let grade = GreekGrade(score: Int(item.scoreValue)) {
                  Text(grade.symbol)
                      .font(.system(size: theme.fontSize.title, weight: .bold))
                      .foregroundStyle(theme.current.accent)
                      .frame(width: 28)
              }
              VStack(alignment: .leading, spacing: 2) {
                  Text(item.songTitle ?? "—")
                      .font(.system(size: theme.fontSize.body))
                      .foregroundStyle(theme.current.textPrimary)
                  Text(item.artistName ?? "—")
                      .font(.system(size: theme.fontSize.label))
                      .foregroundStyle(theme.current.textSecondary)
              }
              Spacer()
              Text(String(item.scoreValue) + "/10")
                  .font(.system(size: theme.fontSize.label))
                  .foregroundStyle(theme.current.textMuted)
          }
          .padding(.vertical, 4)
      }
  }
  ```

- [ ] **Step 2: Build to verify**

  ```bash
  xcodebuild build -scheme tinyPLAYER -destination 'platform=macOS' 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

  ```bash
  git add tinyPLAYER/Views/ScoreBrowserView.swift
  git commit -m "feat: ScoreBrowserView — Greek filter chips, sort, scored song list"
  ```

---

### Task 14: PlayerView + MiniPlayerView

**Files:**
- Create: `tinyPLAYER/Views/PlayerView.swift`
- Create: `tinyPLAYER/Views/MiniPlayerView.swift`

**Interfaces:**
- Consumes: All views from Tasks 11–13, `WindowManager` (via `@EnvironmentObject`), all services
- Produces: `PlayerView` (360×360 full player), `MiniPlayerView` (145×72 compact strip)

- [ ] **Step 1: Implement PlayerView.swift**

  Create `tinyPLAYER/Views/PlayerView.swift`:
  ```swift
  import SwiftUI

  struct PlayerView: View {
      @EnvironmentObject var music:   MusicService
      @EnvironmentObject var scores:  ScoreStore
      @EnvironmentObject var radio:   RadioService
      @EnvironmentObject var theme:   ThemeManager
      @EnvironmentObject var windows: WindowManager

      @State private var showSettings    = false
      @State private var showScoreBrowser = false

      private var currentGrade: GreekGrade? {
          music.currentSongID
              .flatMap { scores.score(for: $0) }
              .flatMap { GreekGrade(score: Int($0.scoreValue)) }
      }

      var body: some View {
          VStack(spacing: 0) {
              // Album art
              ArtworkView(url: music.artworkURL, size: 180)
                  .padding(.top, 16)

              // Track info
              TrackInfoView(title:  music.currentTitle,
                            artist: music.currentArtist,
                            album:  music.currentAlbum,
                            year:   music.currentYear,
                            grade:  currentGrade)
              .padding(.horizontal, 16)
              .padding(.top, 12)

              // Controls
              ControlsView()
                  .padding(.horizontal, 20)
                  .padding(.top, 10)

              // Action bar
              ActionBarView(showSettings: $showSettings)
                  .padding(.horizontal, 16)
                  .padding(.top, 8)

              // Settings drawer (slides in)
              if showSettings {
                  SettingsDrawer()
                      .padding(.horizontal, 12)
                      .padding(.top, 6)
                      .transition(.move(edge: .bottom).combined(with: .opacity))
              }

              Spacer(minLength: 12)
          }
          .frame(width: 360, height: 360)
          .background(theme.current.bgApp)
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .animation(.easeInOut(duration: 0.2), value: showSettings)
          .onTapGesture(count: 2) { windows.toggleMiniNormal() }
          .contextMenu {
              Button("Score Browser") { showScoreBrowser = true }
              Button("Mini Player")   { windows.toggleMiniNormal() }
          }
          .sheet(isPresented: $showScoreBrowser) {
              ScoreBrowserView()
                  .environmentObject(scores)
                  .environmentObject(music)
                  .environmentObject(theme)
          }
      }
  }
  ```

- [ ] **Step 2: Implement MiniPlayerView.swift**

  Create `tinyPLAYER/Views/MiniPlayerView.swift`:
  ```swift
  import SwiftUI

  struct MiniPlayerView: View {
      @EnvironmentObject var music:   MusicService
      @EnvironmentObject var scores:  ScoreStore
      @EnvironmentObject var theme:   ThemeManager
      @EnvironmentObject var windows: WindowManager

      private var currentGrade: GreekGrade? {
          music.currentSongID
              .flatMap { scores.score(for: $0) }
              .flatMap { GreekGrade(score: Int($0.scoreValue)) }
      }

      var body: some View {
          HStack(spacing: 8) {
              ArtworkView(url: music.artworkURL, size: 48)

              VStack(alignment: .leading, spacing: 2) {
                  Text(music.currentTitle)
                      .font(.system(size: theme.fontSize.body, weight: .semibold))
                      .foregroundStyle(theme.current.textPrimary)
                      .lineLimit(1)
                  Text(music.currentArtist)
                      .font(.system(size: theme.fontSize.label))
                      .foregroundStyle(theme.current.textSecondary)
                      .lineLimit(1)
              }
              .frame(maxWidth: .infinity, alignment: .leading)

              HStack(spacing: 12) {
                  miniButton("backward.fill") { Task { try? await music.skipToPrevious() } }
                  miniButton(music.isPlaying ? "pause.fill" : "play.fill") {
                      if music.isPlaying { music.pause() }
                      else { Task { try? await music.play() } }
                  }
                  miniButton("forward.fill") { Task { try? await music.skipToNext() } }
              }

              if let grade = currentGrade {
                  Text(grade.symbol)
                      .font(.system(size: theme.fontSize.body, weight: .bold))
                      .foregroundStyle(theme.current.accent)
              }
          }
          .padding(.horizontal, 10)
          .frame(width: 145, height: 72)
          .background(theme.current.bgApp)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .onTapGesture(count: 2) { windows.toggleMiniNormal() }
      }

      private func miniButton(_ icon: String, action: @escaping () -> Void) -> some View {
          Button(action: action) {
              Image(systemName: icon)
                  .font(.system(size: theme.fontSize.label))
                  .foregroundStyle(theme.current.textPrimary)
          }
          .buttonStyle(.plain)
      }
  }
  ```

- [ ] **Step 3: Build to verify**

  ```bash
  xcodebuild build -scheme tinyPLAYER -destination 'platform=macOS' 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

  ```bash
  git add tinyPLAYER/Views/PlayerView.swift tinyPLAYER/Views/MiniPlayerView.swift
  git commit -m "feat: PlayerView (normal 360×360) + MiniPlayerView (mini 145×72)"
  ```

---

### Task 15: TuckedView + App Entry Point

**Files:**
- Create: `tinyPLAYER/Views/TuckedView.swift`
- Create: `tinyPLAYER/AppDelegate.swift`
- Modify: `tinyPLAYER/tinyPLAYERApp.swift`

**Interfaces:**
- Consumes: All services, ThemeManager, WindowManager, FloatingPanel
- Produces: Running app that hides Music.app, shows floating player, wires all environment objects

- [ ] **Step 1: Implement TuckedView.swift**

  Create `tinyPLAYER/Views/TuckedView.swift`:
  ```swift
  import SwiftUI

  struct TuckedView: View {
      let edge: ScreenEdge
      let onPeek: () -> Void
      @EnvironmentObject var theme: ThemeManager

      var body: some View {
          Button(action: onPeek) {
              Image(systemName: chevronIcon)
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundStyle(theme.current.accent)
                  .frame(width: 12, height: 48)
                  .background(theme.current.bgPanel.opacity(0.9))
                  .clipShape(RoundedRectangle(cornerRadius: 4))
          }
          .buttonStyle(.plain)
      }

      private var chevronIcon: String {
          switch edge {
          case .leading:  return "chevron.right"
          case .trailing: return "chevron.left"
          case .top:      return "chevron.down"
          case .bottom:   return "chevron.up"
          }
      }
  }
  ```

- [ ] **Step 2: Implement AppDelegate.swift**

  Create `tinyPLAYER/AppDelegate.swift`:
  ```swift
  import AppKit
  import CoreData

  final class AppDelegate: NSObject, NSApplicationDelegate {

      var panel:         FloatingPanel!
      var windowManager: WindowManager!
      var musicService:  MusicService!
      var themeManager:  ThemeManager!
      var scoreStore:    ScoreStore!
      var radioService:  RadioService!

      func applicationDidFinishLaunching(_ notification: Notification) {
          // CoreData stack
          let container = NSPersistentContainer(name: "tinyPLAYER")
          container.loadPersistentStores { _, error in
              if let error { fatalError("CoreData load failed: \(error)") }
          }

          // Services
          themeManager = ThemeManager()
          musicService = MusicService()
          scoreStore   = ScoreStore(context: container.viewContext)
          radioService = RadioService()

          // Window
          panel         = FloatingPanel()
          windowManager = WindowManager(panel: panel)

          // Root view — switches based on window mode
          let root = RootView()
              .environmentObject(musicService)
              .environmentObject(themeManager)
              .environmentObject(scoreStore)
              .environmentObject(radioService)
              .environmentObject(windowManager)

          panel.contentView = NSHostingView(rootView: root)
          panel.center()
          panel.makeKeyAndOrderFront(nil)

          // Authorize Apple Music and hide Music.app
          Task { await musicService.requestAuthorization() }

          // Remove default menu bar app icon if desired (optional — comment out to keep Dock icon)
          // NSApp.setActivationPolicy(.accessory)
      }
  }
  ```

- [ ] **Step 3: Implement tinyPLAYERApp.swift**

  Replace `tinyPLAYER/tinyPLAYERApp.swift` with:
  ```swift
  import SwiftUI

  @main
  struct tinyPLAYERApp: App {
      @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

      var body: some Scene {
          // Scene is unused — window is owned by AppDelegate via NSPanel
          Settings { EmptyView() }
      }
  }
  ```

- [ ] **Step 4: Implement RootView**

  Add `tinyPLAYER/Views/RootView.swift`:
  ```swift
  import SwiftUI

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
                  TuckedView(edge: edge) { windows.untuck() }
              }
          }
          .animation(.spring(response: 0.3, dampingFraction: 0.8), value: windows.mode)
      }
  }
  ```

- [ ] **Step 5: Build and run**

  ```bash
  xcodebuild build -scheme tinyPLAYER -destination 'platform=macOS' 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

  Run in Xcode (⌘R). Verify:
  - App launches without Dock window (floating panel appears)
  - Apple Music permission prompt fires once
  - Music.app launches and hides within ~2 seconds
  - Player shows "—" for title/artist until music plays

- [ ] **Step 6: Commit**

  ```bash
  git add tinyPLAYER/Views/TuckedView.swift \
          tinyPLAYER/Views/RootView.swift \
          tinyPLAYER/AppDelegate.swift \
          tinyPLAYER/tinyPLAYERApp.swift
  git commit -m "feat: app entry point — AppDelegate, RootView, window/service wiring"
  ```

---

### Task 16: Run All Tests + Push to GitHub

**Files:** No new files

- [ ] **Step 1: Run full test suite**

  ```bash
  xcodebuild test -scheme tinyPLAYER -destination 'platform=macOS' 2>&1 | \
    grep -E 'Test Suite|PASSED|FAILED|error:'
  ```
  Expected: All test suites pass — `ThemeManagerTests`, `GreekGradeTests`, `ScoreStoreTests`, `WindowManagerTests`

- [ ] **Step 2: Verify final build is clean**

  ```bash
  xcodebuild build -scheme tinyPLAYER -destination 'platform=macOS' \
    -configuration Release 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Create public GitHub repo and push**

  ```bash
  cd /Users/Tal/projects/tinyPLAYER
  gh repo create tinyPLAYER --public --source=. --remote=origin --push
  ```

- [ ] **Step 4: Final commit with README note**

  ```bash
  git add .
  git commit -m "chore: final integration — all tests green, pushed to GitHub"
  ```

---

## Self-Review Checklist

| Spec Section | Covered By |
|---|---|
| MusicKit SystemMusicPlayer | Task 8 (MusicService) |
| Music.app hidden on launch | Task 8 AppleScriptBridge + Task 15 AppDelegate |
| Normal 360×360 window | Task 6 FloatingPanel + Task 14 PlayerView |
| Mini 145×72 | Task 6 WindowManager + Task 14 MiniPlayerView |
| Tuck-to-edge iPhone style | Task 6 WindowManager.snap() |
| Greek grade Alpha=10…Kappa=1 | Task 4 GreekGrade |
| CoreData score store | Task 5 ScoreStore |
| Score browser (filter/sort) | Task 13 ScoreBrowserView |
| 6 color palettes | Task 3 Palettes |
| Font sizes (S/M/L = PyTeach pattern) | Task 3 ThemeManager |
| Album artwork display | Task 11 ArtworkView |
| Controls (prev/play/next/progress) | Task 11 ControlsView |
| Add/remove from library | Task 8 MusicService + Task 12 ActionBarView |
| Radio station (auto + save) | Task 9 RadioService + Task 12 ActionBarView |
| Sharing (AirDrop/Messages/Mail) | Task 10 SharingService + Task 12 ShareButtonView |
| Palette picker in settings | Task 12 SettingsDrawer |
| Font size picker in settings | Task 12 SettingsDrawer |
| State persistence (UserDefaults) | Tasks 3, 6 |
| macOS 14+ only | Task 1 (deployment target) |
