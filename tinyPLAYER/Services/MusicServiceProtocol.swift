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
