import SwiftUI

struct SongsView: View {
    @EnvironmentObject var dataService: SongDataService
    @State private var searchText = ""
    
    var filteredSongs: [Song] {
        if searchText.isEmpty {
            return dataService.songs
        } else {
            return dataService.searchSongs(query: searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredSongs) { song in
                    NavigationLink(destination: SongDetailView(song: song)) {
                        SongRowView(song: song)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Şarkılar")
            .searchable(text: $searchText, prompt: "Şarkı ara")
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
}
