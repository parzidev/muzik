import SwiftUI

// MARK: - Artist Detail View

struct ArtistDetailView: View {
    @EnvironmentObject var dataService: SongDataService
    let artistName: String

    private var songs: [Song] {
        dataService.songsByArtist(artistName)
    }

    var body: some View {
        List {
            // Artist header
            Section {
                VStack(spacing: DS.Spacing.s) {
                    ZStack {
                        Circle()
                            .fill(DS.Color.accentGradient)
                            .frame(width: 80, height: 80)
                        Text(String(artistName.prefix(1)).uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text(artistName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(songs.count) şarkı")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.m)
                .listRowBackground(Color.clear)
            }

            // Songs
            Section("Şarkılar") {
                ForEach(songs) { song in
                    NavigationLink(destination: SongDetailView(song: song)) {
                        SongRowView(song: song)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(artistName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
