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
