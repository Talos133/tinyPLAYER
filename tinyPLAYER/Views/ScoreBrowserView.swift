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

    // MARK: - Header

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

    // MARK: - Filter Bar

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
                            Text(grade.symbol)
                                .font(.system(size: 14, weight: .bold))
                            Text(grade.displayName)
                                .font(.system(size: theme.fontSize.label))
                        }
                        .foregroundStyle(active ? theme.current.bgApp : theme.current.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
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

    // MARK: - Song List

    private var songList: some View {
        let items = scores.filtered(grades: selectedGrades, sortedBy: sortOption)
        return Group {
            if items.isEmpty {
                ContentUnavailableView(
                    selectedGrades.isEmpty ? "No scored songs" : "No matches",
                    systemImage: "star.slash",
                    description: Text(
                        selectedGrades.isEmpty
                            ? "Score a song from the player to see it here."
                            : "No songs match the selected grades."
                    )
                )
            } else {
                List(items, id: \.songID) { item in
                    songRow(item)
                        .listRowBackground(theme.current.bgApp)
                        .onTapGesture {
                            // Playing by persistent song ID requires a MusicKit catalog
                            // lookup that isn't available via MusicServiceProtocol yet.
                            // Copy the song title to the pasteboard as a convenience hint.
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(
                                item.songTitle ?? "", forType: .string)
                        }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Song Row

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
                Text([item.artistName, item.albumName]
                        .compactMap { $0 }
                        .filter { !$0.isEmpty }
                        .joined(separator: " · "))
                    .font(.system(size: theme.fontSize.label))
                    .foregroundStyle(theme.current.textSecondary)
            }
            Spacer()
            Text("\(item.scoreValue)/10")
                .font(.system(size: theme.fontSize.label))
                .foregroundStyle(theme.current.textMuted)
        }
        .padding(.vertical, 4)
    }
}
