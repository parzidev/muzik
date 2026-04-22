import SwiftUI

// MARK: - Favorites View
struct FavoritesView: View {
    @EnvironmentObject var dataService: SongDataService
    @EnvironmentObject var pro: ProManager
    @State private var selectedSegment = 0 // 0: Sarklar, 1: Listeler
    @State private var showNewPlaylistAlert = false
    @State private var newPlaylistName = ""
    @State private var showPaywall = false
    @State private var paywallFeature: ProGate.Feature? = nil

    var favoriteSongs: [Song] {
        dataService.favoriteSongs()
    }

    var body: some View {
        VStack(spacing: DS.Spacing.m) {
            // Segmented Control
            Picker("Favoriler", selection: $selectedSegment) {
                Text("Sarkilar").tag(0)
                Text("Listeler").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DS.Spacing.m)
            .padding(.top, DS.Spacing.m)

            if selectedSegment == 0 {
                // MARK: Songs List
                if favoriteSongs.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "heart.slash",
                        title: "Favori Yok",
                        message: "Henuz favori sarkiniz yok. Sarki detay sayfasindan kalbe dokunarak ekleyebilirsiniz.",
                        actionTitle: "Sarki Kesfet",
                        action: {}
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(favoriteSongs) { song in
                            NavigationLink(destination: SongDetailView(song: song)) {
                                SongRowView(song: song)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    dataService.toggleFavorite(song.id)
                                } label: {
                                    Label("Kaldir", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                // MARK: Playlists
                if dataService.playlists.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "music.note.list",
                        title: "Henuz Liste Yok",
                        message: "Kendi calma listelerinizi olusturun ve sarkilarinizi duzenleyin.",
                        actionTitle: "Yeni Liste Olustur",
                        action: { showNewPlaylistAlert = true }
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(dataService.playlists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
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
                                }
                                .padding(.vertical, DS.Spacing.xxs)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    dataService.deletePlaylist(playlist.id)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Favoriler")
        .toolbar {
            if selectedSegment == 1 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.tap()
                        if dataService.canCreatePlaylist() {
                            showNewPlaylistAlert = true
                        } else {
                            paywallFeature = .playlistsLimit
                            showPaywall = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            if !pro.hasProAccess && dataService.playlists.count >= ProGate.freePlaylistsLimit {
                                Image(systemName: "crown.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
        }
        .alert("Yeni Liste", isPresented: $showNewPlaylistAlert) {
            TextField("Liste adi", text: $newPlaylistName)
            Button("Olustur") {
                let name = newPlaylistName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    if dataService.tryCreatePlaylist(name: name) {
                        HapticManager.success()
                    } else {
                        paywallFeature = .playlistsLimit
                        showPaywall = true
                    }
                    newPlaylistName = ""
                }
            }
            Button("Iptal", role: .cancel) { newPlaylistName = "" }
        }
        .paywallSheet(isPresented: $showPaywall, feature: paywallFeature)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
