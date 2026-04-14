import SwiftUI

struct SongsView: View {
    @EnvironmentObject var dataService: SongDataService
    @State private var searchText = ""
    @State private var sortMode: SortMode = .titleAZ

    enum SortMode: String, CaseIterable {
        case titleAZ = "A-Z"
        case titleZA = "Z-A"
        case artist = "Sanatçı"
    }

    var filteredSongs: [Song] {
        let base: [Song]
        if searchText.isEmpty {
            base = dataService.songs
        } else {
            base = dataService.searchSongs(query: searchText)
        }

        switch sortMode {
        case .titleAZ:
            return base.sorted { $0.sarkiadi.localizedCompare($1.sarkiadi) == .orderedAscending }
        case .titleZA:
            return base.sorted { $0.sarkiadi.localizedCompare($1.sarkiadi) == .orderedDescending }
        case .artist:
            return base.sorted {
                if $0.sanatci == $1.sanatci {
                    return $0.sarkiadi.localizedCompare($1.sarkiadi) == .orderedAscending
                }
                return $0.sanatci.localizedCompare($1.sanatci) == .orderedAscending
            }
        }
    }

    var body: some View {
        List {
            ForEach(filteredSongs) { song in
                NavigationLink(destination: SongDetailView(song: song)) {
                    SongRowView(song: song)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Şarkılar")
        .searchable(text: $searchText, prompt: "Şarkı veya sanatçı ara")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(SortMode.allCases, id: \.self) { mode in
                        Button {
                            sortMode = mode
                        } label: {
                            HStack {
                                Text(mode.rawValue)
                                if sortMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .overlay {
            if filteredSongs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Şarkı Bulunamadı")
                        .font(.headline)
                    Text("Lütfen farklı bir arama yapın.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
