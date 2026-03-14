import SwiftUI

struct PlaylistsView: View {
    @EnvironmentObject var dataService: SongDataService
    @State private var showNewPlaylistAlert = false
    @State private var newPlaylistName = ""
    @State private var editingPlaylist: Playlist?
    @State private var editName = ""

    var body: some View {
        Group {
            if dataService.playlists.isEmpty {
                emptyState
            } else {
                playlistList
            }
        }
        .navigationTitle("Listeler")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showNewPlaylistAlert = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Yeni Liste", isPresented: $showNewPlaylistAlert) {
            TextField("Liste adi", text: $newPlaylistName)
            Button("Olustur") {
                let name = newPlaylistName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    dataService.createPlaylist(name: name)
                    newPlaylistName = ""
                }
            }
            Button("Iptal", role: .cancel) { newPlaylistName = "" }
        }
        .alert("Listeyi Duzenle", isPresented: Binding(
            get: { editingPlaylist != nil },
            set: { if !$0 { editingPlaylist = nil } }
        )) {
            TextField("Liste adi", text: $editName)
            Button("Kaydet") {
                if let playlist = editingPlaylist {
                    let name = editName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        dataService.renamePlaylist(playlist.id, name: name)
                    }
                }
                editingPlaylist = nil
            }
            Button("Iptal", role: .cancel) { editingPlaylist = nil }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.m) {
            Spacer()
            EmptyStateView(
                icon: "music.note.list",
                title: "Henuz Liste Yok",
                message: "Kendi calma listelerinizi olusturun ve sarkilarinizi duzenleyin.",
                actionTitle: "Yeni Liste Olustur",
                action: { showNewPlaylistAlert = true }
            )
            Spacer()
        }
    }

    private var playlistList: some View {
        List {
            ForEach(dataService.playlists) { playlist in
                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                    playlistRow(playlist)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        dataService.deletePlaylist(playlist.id)
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        editName = playlist.name
                        editingPlaylist = playlist
                    } label: {
                        Label("Duzenle", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(.plain)
    }

    private func playlistRow(_ playlist: Playlist) -> some View {
        HStack(spacing: DS.Spacing.s) {
            RoundedRectangle(cornerRadius: DS.CornerRadius.small)
                .fill(DS.Color.accentGradient)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "music.note.list")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text("\(playlist.songIds.count) sarki")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, DS.Spacing.xxs)
        .contentShape(Rectangle())
    }
}
