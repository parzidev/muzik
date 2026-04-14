import SwiftUI

// MARK: - "Bunu Çalabilir misin?" Mode

struct CanIPlayView: View {
    @EnvironmentObject var dataService: SongDataService
    @State private var selectedChords: Set<String> = []
    @State private var showResults = false

    private let chordGroups: [(String, [String])] = [
        ("Temel Majör", ["C", "D", "E", "F", "G", "A", "B"]),
        ("Temel Minör", ["Am", "Dm", "Em", "Bm", "Cm", "Fm", "Gm"]),
        ("Diyez / Bemol", ["F#m", "C#m", "G#m", "F#", "Bb", "Eb", "Ab", "D#m"]),
        ("Yedili", ["A7", "B7", "C7", "D7", "E7", "F7", "G7"]),
    ]

    private var matchingSongs: [SongMatch] {
        guard !selectedChords.isEmpty else { return [] }

        return dataService.songs.compactMap { song in
            let songChords = Set(song.chords)
            guard !songChords.isEmpty else { return nil }

            let unknownChords = songChords.subtracting(selectedChords)
            let knownCount = songChords.intersection(selectedChords).count
            let matchPercent = Double(knownCount) / Double(songChords.count)

            // Show songs where user knows at least 50% of chords
            guard matchPercent >= 0.5 else { return nil }

            return SongMatch(
                song: song,
                matchPercent: matchPercent,
                unknownChords: Array(unknownChords).sorted(),
                totalChords: songChords.count
            )
        }
        .sorted { $0.matchPercent > $1.matchPercent }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !showResults {
                chordSelectionView
            } else {
                resultsView
            }
        }
        .navigationTitle("Çalabilir misin?")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Chord Selection

    private var chordSelectionView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DS.Spacing.l) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "hand.raised.fingers.spread")
                            .font(.system(size: 40))
                            .foregroundColor(DS.Color.accent)

                        Text("Bildiğin akorları seç")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text("Sana çalabileceğin şarkıları bulalım")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, DS.Spacing.m)

                    // Chord groups
                    ForEach(chordGroups, id: \.0) { group in
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(group.0)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            chordRow(chords: group.1)
                        }
                    }

                    // Quick select buttons
                    HStack(spacing: 12) {
                        Button("Başlangıç Seti") {
                            selectedChords = ["C", "G", "D", "Am", "Em"]
                        }
                        .buttonStyle(QuickSelectStyle(isActive: selectedChords == ["C", "G", "D", "Am", "Em"]))

                        Button("Orta Seviye") {
                            selectedChords = ["C", "G", "D", "A", "E", "Am", "Dm", "Em", "F", "Bm"]
                        }
                        .buttonStyle(QuickSelectStyle(isActive: false))

                        Button("Temizle") {
                            selectedChords.removeAll()
                        }
                        .buttonStyle(QuickSelectStyle(isActive: false))
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 100)
            }

            // Bottom bar
            VStack(spacing: 0) {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(selectedChords.count) akor seçildi")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if !selectedChords.isEmpty {
                            Text(selectedChords.sorted().joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Button {
                        withAnimation { showResults = true }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Şarkı Bul")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(selectedChords.isEmpty ? Color.gray : DS.Color.accent)
                        .cornerRadius(DS.CornerRadius.medium)
                    }
                    .disabled(selectedChords.isEmpty)
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
            }
        }
    }

    private func chordRow(chords: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chords, id: \.self) { chord in
                    let isSelected = selectedChords.contains(chord)
                    Button {
                        if isSelected {
                            selectedChords.remove(chord)
                        } else {
                            selectedChords.insert(chord)
                        }
                    } label: {
                        Text(chord)
                            .font(.system(size: 15, weight: .semibold))
                            .frame(minWidth: 44, minHeight: 44)
                            .background(isSelected ? DS.Color.accent : Color(uiColor: .secondarySystemGroupedBackground))
                            .foregroundColor(isSelected ? .white : .primary)
                            .cornerRadius(DS.CornerRadius.small)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 0) {
            // Back + stats header
            HStack {
                Button {
                    withAnimation { showResults = false }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Akor Seçimi")
                    }
                    .font(.subheadline)
                    .foregroundColor(DS.Color.accent)
                }

                Spacer()

                let fullMatch = matchingSongs.filter { $0.matchPercent >= 1.0 }.count
                let partial = matchingSongs.filter { $0.matchPercent < 1.0 }.count
                Text("\(fullMatch) tam, \(partial) kısmi eşleşme")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            if matchingSongs.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "music.note.list",
                    title: "Şarkı Bulunamadı",
                    message: "Seçtiğin akorlarla eşleşen şarkı yok. Daha fazla akor eklemeyi dene.",
                    actionTitle: "Akorlara Dön",
                    action: { withAnimation { showResults = false } }
                )
                Spacer()
            } else {
                List {
                    // Full matches first
                    let fullMatches = matchingSongs.filter { $0.matchPercent >= 1.0 }
                    if !fullMatches.isEmpty {
                        Section {
                            ForEach(fullMatches) { match in
                                NavigationLink(destination: SongDetailView(song: match.song)) {
                                    songMatchRow(match)
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("Tam Çalabilirsin (\(fullMatches.count))")
                            }
                        }
                    }

                    // Partial matches
                    let partialMatches = matchingSongs.filter { $0.matchPercent < 1.0 }.prefix(50)
                    if !partialMatches.isEmpty {
                        Section {
                            ForEach(partialMatches) { match in
                                NavigationLink(destination: SongDetailView(song: match.song)) {
                                    songMatchRow(match)
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: "star.leadinghalf.filled")
                                    .foregroundColor(.orange)
                                Text("Neredeyse (\(partialMatches.count))")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private func songMatchRow(_ match: SongMatch) -> some View {
        HStack(spacing: 12) {
            // Match percentage circle
            ZStack {
                Circle()
                    .stroke(Color(uiColor: .tertiarySystemFill), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: match.matchPercent)
                    .stroke(match.matchPercent >= 1.0 ? Color.green : Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(match.matchPercent * 100))")
                    .font(.system(size: 11, weight: .bold))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(match.song.sarkiadi)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(match.song.sanatci)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if !match.unknownChords.isEmpty {
                    HStack(spacing: 4) {
                        Text("Eksik:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        ForEach(match.unknownChords.prefix(3), id: \.self) { chord in
                            Text(chord)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                        if match.unknownChords.count > 3 {
                            Text("+\(match.unknownChords.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Models

struct SongMatch: Identifiable {
    let song: Song
    let matchPercent: Double
    let unknownChords: [String]
    let totalChords: Int
    var id: Int { song.id }
}

// MARK: - Quick Select Button Style

struct QuickSelectStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isActive ? DS.Color.accent.opacity(0.15) : Color(uiColor: .tertiarySystemFill))
            .foregroundColor(isActive ? DS.Color.accent : .secondary)
            .cornerRadius(20)
    }
}
