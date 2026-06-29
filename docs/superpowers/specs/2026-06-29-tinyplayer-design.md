# tinyPLAYER — Software Design Document
**Date:** 2026-06-29
**Platform:** macOS only
**Stack:** SwiftUI + AppKit + MusicKit

---

## 1. Purpose

tinyPLAYER is a compact, always-floating macOS music player that gives the user full control of their Apple Music subscription without ever seeing or interacting with Music.app. Music.app runs hidden in the background; tinyPLAYER is the sole interface.

Not commercial. Distributed free.

---

## 2. Architecture Overview

```
tinyPLAYER.app
├── SwiftUI Views           (all UI rendering)
├── AppKit Window Manager   (NSPanel, tuck-to-edge, floating level)
├── MusicService            (MusicKit SystemMusicPlayer wrapper)
├── ScoreStore              (CoreData — Greek-graded song scores)
├── RadioService            (station creation + playlist saving)
├── ThemeManager            (6 palettes + 3 font sizes, UserDefaults)
└── Music.app               (hidden, launched on startup)
```

Five concerns are strictly separated. No SwiftUI view touches MusicKit directly — all calls go through `MusicService`. No view reads CoreData directly — all score reads/writes go through `ScoreStore`.

---

## 3. Window System

### 3.1 Window Type
`NSPanel` subclass with `.floating` window level. Stays above all other app windows at all times. No standard title bar. Fully custom chrome via SwiftUI.

### 3.2 Three Window States

| State | Size (pt) | Size (cm approx) | Description |
|-------|-----------|------------------|-------------|
| Normal | 360 × 360 | ~10 × 10 | Full player with art, metadata, controls, actions |
| Mini | 145 × 72 | ~4 × 2 | Single-row compact strip |
| Tucked | 12pt sliver | — | Snapped flush to any screen edge, peek arrow visible |

**State transitions:**
- Normal ↔ Mini: double-click player or collapse button
- Mini/Normal → Tucked: drag window within 20pt of any screen edge; snaps automatically
- Tucked → Mini/Normal: click or hover the peek chevron arrow; slides out with spring animation

### 3.3 Tuck-to-Edge Behavior
- `NSWindowDelegate.windowDidMove` monitors drag-end position
- `NSEvent` global mouse monitor checks proximity to all 4 screen edges
- On snap: window animates flush to edge via `NSAnimationContext` spring
- 12pt sliver + chevron (◀ ▶ ▲ ▼ depending on edge) remains visible
- Click chevron → spring-animates back to last known position
- Persists: last state, last position, last tucked edge → `UserDefaults`

### 3.4 Dragging
- Draggable anywhere on screen by clicking and dragging the player body
- In mini mode, drag from the single-row strip
- When released near an edge, tuck logic fires automatically

---

## 4. MusicKit Integration (`MusicService`)

`MusicService` is a `@MainActor ObservableObject`. It is the single point of contact with MusicKit throughout the app.

### 4.1 Authorization
- Checked on first launch via `MusicAuthorization.request()`
- If denied: show non-dismissable prompt explaining requirement
- Status persisted by the OS (user grants once)

### 4.2 Music.app Lifecycle
- On authorized launch: `NSWorkspace.shared.launchApplication("Music")`
- Immediately hide: `NSRunningApplication.hide()` on Music.app process
- Music.app remains hidden for the entire session
- On tinyPLAYER quit: Music.app is left running (user may want it) or optionally quit — user preference in settings

### 4.3 Playback
Uses `MusicPlayer.SystemMusicPlayer.shared` for all playback:
- `play()` / `pause()` / `skipToNextEntry()` / `skipToPreviousEntry()`
- `Now Playing` state observed via `MusicPlayer.State` Combine publisher → `@Published` on `MusicService`

### 4.4 Now Playing Properties (all `@Published`)
```swift
var currentTitle:    String
var currentArtist:   String
var currentAlbum:    String
var currentYear:     Int?
var currentArtwork:  Artwork?   // MusicKit Artwork, load at needed size
var isPlaying:       Bool
var playbackProgress: Double    // 0.0–1.0
```

### 4.5 Library Management
- `MusicLibrary.shared.add(track)` — add current track to library
- `MusicLibrary.shared.remove(track)` — remove from library
- Library status of current track exposed as `@Published var inLibrary: Bool`

### 4.6 Catalog Search
- `MusicCatalogSearchRequest` for title / artist / album
- Used by Score Browser to fetch tracks matching scored song IDs
- Debounced 300ms before firing

---

## 5. Scoring System (`ScoreStore`)

### 5.1 CoreData Entity: `SongScore`

| Attribute | Type | Notes |
|-----------|------|-------|
| `songID` | String | MusicKit track ID (stable) |
| `score` | Int16 | 1–10 |
| `greekGrade` | String | Derived: "Α", "Β" … "Κ" |
| `songTitle` | String | Cached for display |
| `artistName` | String | Cached for display |
| `albumName` | String | Cached for display |
| `dateScored` | Date | Set on create, updated on change |

### 5.2 Greek Grade Mapping

| Score | Greek Letter | Symbol |
|-------|-------------|--------|
| 10 | Alpha | Α |
| 9 | Beta | Β |
| 8 | Gamma | Γ |
| 7 | Delta | Δ |
| 6 | Epsilon | Ε |
| 5 | Zeta | Ζ |
| 4 | Eta | Η |
| 3 | Theta | Θ |
| 2 | Iota | Ι |
| 1 | Kappa | Κ |

### 5.3 Scoring UI
- 10 tap targets in the player ActionBar showing Greek letters Α–Κ
- Tap to score; tap same letter again to clear score
- Current grade badge displayed next to track title
- Unscored tracks show no badge

### 5.4 Score Browser
- Accessible from gear menu or ActionBar
- Filter chips: toggle one or more Greek letters (Α / Β / Γ …)
- Sort options: Grade (desc/asc) · Date Scored · Artist · Title
- Tap any row → `MusicService.play(track)` starts that track immediately

---

## 6. Radio Station Feature (`RadioService`)

### 6.1 Auto Station (immediate)
1. User taps "Create Station" on current track
2. `RadioService` calls MusicKit station API seeded with current track
3. ~25 similar tracks loaded into `SystemMusicPlayer` queue
4. Playback continues automatically

### 6.2 Save as Playlist (optional)
1. After station generates, user is prompted: "Save as playlist?"
2. If yes: user names it
3. `MusicLibrary.shared.createPlaylist(name:)` creates playlist
4. All queued station tracks appended to it
5. Playlist available in Music.app and tinyPLAYER

### 6.3 Add to Existing Playlist
- "Add to playlist →" in ActionBar shows a list of user's existing playlists
- Tap one → `MusicLibrary.shared.add(track, to: playlist)`

---

## 7. Sharing (`NSSharingService`)

Three targets, triggered from share button in player:

| Target | Behavior |
|--------|----------|
| AirDrop | Shares Apple Music deeplink URL (`music://...`) via AirDrop picker |
| Messages | Pre-fills iMessage with track name + artist + deeplink |
| Mail | Pre-fills subject ("Check out [title]") + body with track info + link |

Deeplink constructed from MusicKit `track.url` — no additional API call needed.

---

## 8. Color Palettes & Theming (`ThemeManager`)

`ThemeManager` is a `@MainActor ObservableObject` injected as an `EnvironmentObject`. All views read colors and font sizes from it. Palette + font size persisted to `UserDefaults`.

### 8.1 Color Token Set (per palette)
```swift
struct AppTheme {
    var bgApp:         Color
    var bgPanel:       Color
    var border:        Color
    var textPrimary:   Color
    var textSecondary: Color
    var textMuted:     Color
    var accent:        Color
    var accentSoft:    Color
}
```

### 8.2 Palettes

| Palette | bgApp | accent | Character |
|---------|-------|--------|-----------|
| **Greek Aegean** | `#0d2247` | `#d4b483` | Deep navy + warm gold (from PyTeach) |
| **Forest** | `#1a2e1a` | `#7db87d` | Dark pine + leaf green |
| **Tropical Islands** | `#003d4d` | `#f4a623` | Deep teal + mango orange |
| **Nightly Urban** | `#0f0f14` | `#b388ff` | Near-black + neon violet |
| **Beach Bonfire** | `#1c1008` | `#ff6b35` | Dark ember + fire orange |
| **Morning Mountains** | `#e8eff7` | `#4a7c59` | Pale sky + pine green (light theme) |

### 8.3 Font Sizes (matching PyTeach pattern)

| Step | Base pt | Scale |
|------|---------|-------|
| Small | 11pt | 0.85× |
| Medium | 13pt | 1.0× (default) |
| Large | 15pt | 1.15× |

Applied via a custom `EnvironmentKey` (`\.appTheme`). All text: `.font(.system(size: theme.fontSize.body))`.

---

## 9. Views

### 9.1 `PlayerView` (Normal — 360×360pt)
```
┌─────────────────────────────┐
│                             │
│        ArtworkView          │  ~180pt tall, rounded corners
│      (album art image)      │  drop shadow, loads from MusicKit Artwork
│                             │
├─────────────────────────────┤
│  Song Title     [Α badge]   │  textPrimary, score badge (accent color)
│  Artist · Album · Year      │  textSecondary
├─────────────────────────────┤
│  ────────●──────────────    │  progress bar (accent color)
│     ⏮      ⏸/▶      ⏭     │  controls
├─────────────────────────────┤
│  [♥ lib] [★ score] [📻]  [↗]│  ActionBar: library · score · radio · share
├─────────────────────────────┤
│                    [⚙ gear] │  opens SettingsDrawer
└─────────────────────────────┘
```

### 9.2 `MiniPlayerView` (145×72pt)
```
┌──────────────────────────────────────────────┐
│ [art] Title · Artist     ⏮  ⏸/▶  ⏭   [Α]  │
└──────────────────────────────────────────────┘
```

### 9.3 `SettingsDrawer`
Slides up from bottom of PlayerView:
- Palette picker: 6 color swatches, tap to apply
- Font size: Small · Medium · Large segmented control
- On quit Music.app toggle
- App version

### 9.4 `ScoreBrowserView`
Full-height sheet over PlayerView:
- Greek letter filter chips (multi-select)
- Sort picker
- Scrollable list of scored songs
- Tap row → play immediately

---

## 10. Data Persistence

| Data | Storage | Key |
|------|---------|-----|
| Song scores | CoreData (`SongScore` entity) | Persistent store |
| Active palette | UserDefaults | `tinyplayer_palette` |
| Font size | UserDefaults | `tinyplayer_fontsize` |
| Window state | UserDefaults | `tinyplayer_windowstate` |
| Window position | UserDefaults | `tinyplayer_position` |
| Tucked edge | UserDefaults | `tinyplayer_tuckededge` |

---

## 11. Project Structure

```
tinyPLAYER/
├── tinyPLAYERApp.swift         @main entry, AppDelegate, Music.app hide
├── Services/
│   ├── MusicService.swift      MusicKit wrapper
│   ├── RadioService.swift      Station + playlist creation
│   └── ScoreStore.swift        CoreData CRUD
├── Windows/
│   ├── FloatingPanel.swift     NSPanel subclass
│   └── WindowManager.swift     Tuck/snap/state logic
├── Views/
│   ├── PlayerView.swift
│   ├── MiniPlayerView.swift
│   ├── ArtworkView.swift
│   ├── ControlsView.swift
│   ├── ActionBarView.swift
│   ├── SettingsDrawer.swift
│   └── ScoreBrowserView.swift
├── Theme/
│   ├── ThemeManager.swift      Palettes + font sizes
│   ├── AppTheme.swift          Color token struct
│   └── Palettes.swift          6 palette definitions
├── Model/
│   └── tinyPLAYER.xcdatamodeld CoreData schema
└── docs/
    └── superpowers/specs/
        └── 2026-06-29-tinyplayer-design.md
```

---

## 12. Out of Scope (v1)
- Windows / Linux support
- Lyrics display
- Equalizer / audio effects
- Watch / iPhone companion
- iCloud sync of scores
- Commercial distribution
