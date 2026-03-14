import SwiftUI

struct PlaylistDetailView: View {
    @EnvironmentObject var dataService: SongDataService
    let playlist: Playlist
    @State private var showAddSongs = false

    private var currentPlaylist: Playlist {
        dataService.playlists.first(where: { $0.id == playlist.id }) ?? playlist
    }

    private var songs: [Song] {
        dataService.playlistSongs(currentPlaylist)
    }

    var body: some View {
        Group {
            if songs.isEmpty {
                VStack(spacing: DS.Spacing.m) {
                    Spacer()
                    EmptyStateView(
                        icon: "music.note",
                        title: "Liste Bos",
                        message: "Bu listeye henuz sarki eklenmemis.",
                        actionTitle: "Sarki Ekle",
                        action: { showAddSongs = true }
                    )
                    Spacer()
                }
            } else {
                List {
                    ForEach(songs) { song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            SongRowView(song: song)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                dataService.removeSongFromPlaylist(songId: song.id, playlistId: playlist.id)
                            } label: {
                                Label("Cikar", systemImage: "minus.circle")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(currentPlaylist.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSongs = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSongs) {
            AddSongsToPlaylistView(playlistId: playlist.id)
        }
    }
}

// MARK: - Add Songs Sheet
struct AddSongsToPlaylistView: View {
    @EnvironmentObject var dataService: SongDataService
    @Environment(\.dismiss) var dismiss
    let playlistId: UUID
    @State private var searchText = ""

    private var currentPlaylist: Playlist? {
        dataService.playlists.first(where: { $0.id == playlistId })
    }

    private var searchResults: [Song] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return Array(dataService.songs.prefix(50))
        }
        return dataService.searchSongs(query: searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(searchResults) { song in
                    let isAdded = currentPlaylist?.songIds.contains(song.id) ?? false
                    Button {
                        if isAdded {
                            dataService.removeSongFromPlaylist(songId: song.id, playlistId: playlistId)
                        } else {
                            dataService.addSongToPlaylist(songId: song.id, playlistId: playlistId)
                        }
                    } label: {
                        HStack {
                            SongRowView(song: song)
                            Spacer()
                            Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                                .foregroundColor(isAdded ? DS.Color.accent : .secondary)
                                .font(.title3)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Sarki ara...")
            .navigationTitle("Sarki Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") { dismiss() }
                }
            }
        }
    }
}
