import Foundation
import SwiftUI

class SongDataService: ObservableObject {
    static let shared = SongDataService()
    
    @Published var songs: [Song] = []
    @Published var favorites: Set<Int> = []
    @Published var recentlyViewed: [Int] = []
    @Published var playlists: [Playlist] = []
    @Published var isLoading = true

    @AppStorage("darkMode") var darkMode = false
    @AppStorage("fontSize") var fontSize: Int = 16
    @AppStorage("scrollSpeed") var scrollSpeed: Int = 3

    private let favoritesKey = "favorites"
    private let recentKey = "recentlyViewed"
    private let playlistsKey = "playlists"

    init() {
        loadFavorites()
        loadRecent()
        loadPlaylists()
        loadSongs()
    }

    func loadSongs() {
        NSLog("SongDataService: Starting loadSongs...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            NSLog("SongDataService: Looking for cleaned_songs.json...")
            var fileURL = Bundle.main.url(forResource: "cleaned_songs", withExtension: "json")
            
            if fileURL == nil {
                NSLog("SongDataService: 'cleaned_songs.json' not found. Trying 'cleaned_songs.jsonl'...")
                fileURL = Bundle.main.url(forResource: "cleaned_songs", withExtension: "jsonl")
            }

            guard let url = fileURL else {
                NSLog("SongDataService: CRITICAL ERROR - Could not find cleaned_songs.json in Bundle!")
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                return
            }
            
            NSLog("SongDataService: Found file at \(url.path)")

            do {
                let data = try Data(contentsOf: url)
                NSLog("SongDataService: Read \(data.count) bytes")
                guard let content = String(data: data, encoding: .utf8) else {
                    NSLog("SongDataService: Failed to convert data to UTF-8 string")
                    DispatchQueue.main.async {
                        self?.isLoading = false
                    }
                    return
                }
                
                // Handle different line endings (\r\n or \n)
                let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                NSLog("SongDataService: Read \(lines.count) non-empty lines")
                
                var loadedSongs: [Song] = []
                let decoder = JSONDecoder()
                
                for (index, line) in lines.enumerated() {
                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let lineData = trimmedLine.data(using: .utf8) {
                        do {
                            let song = try decoder.decode(Song.self, from: lineData)
                            loadedSongs.append(song)
                        } catch {
                            if index < 5 {
                                NSLog("SongDataService: Error decoding line \(index): \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                NSLog("SongDataService: Successfully decoded \(loadedSongs.count) songs.")
                
                DispatchQueue.main.async {
                    self?.songs = loadedSongs.sorted { $0.sarkiadi < $1.sarkiadi }
                    self?.isLoading = false
                }
            } catch {
                NSLog("SongDataService: Failed to read file: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            }
        }
    }

    func searchSongs(query: String) -> [Song] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return [] }
        return songs.filter {
            $0.sarkiadi.lowercased().contains(q) ||
            $0.sanatci.lowercased().contains(q)
        }
    }

    func popularSongs() -> [Song] {
        Array(songs.prefix(15))
    }

    func recentSongs() -> [Song] {
        let recent = recentlyViewed.compactMap { id in songs.first { $0.id == id } }
        if recent.isEmpty {
            return Array(songs.shuffled().prefix(10))
        }
        return Array(recent.prefix(10))
    }

    func favoriteSongs() -> [Song] {
        favorites.compactMap { id in songs.first { $0.id == id } }
    }

    // MARK: - Favorites
    func toggleFavorite(_ songId: Int) {
        if favorites.contains(songId) {
            favorites.remove(songId)
        } else {
            favorites.insert(songId)
        }
        saveFavorites()
    }

    func isFavorite(_ songId: Int) -> Bool {
        favorites.contains(songId)
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)
    }

    private func loadFavorites() {
        let saved = UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? []
        favorites = Set(saved)
    }

    // MARK: - Recently Viewed
    func addToRecent(_ songId: Int) {
        recentlyViewed.removeAll { $0 == songId }
        recentlyViewed.insert(songId, at: 0)
        // Keep only last 30
        if recentlyViewed.count > 30 {
            recentlyViewed = Array(recentlyViewed.prefix(30))
        }
        UserDefaults.standard.set(recentlyViewed, forKey: recentKey)
    }

    private func loadRecent() {
        recentlyViewed = UserDefaults.standard.array(forKey: recentKey) as? [Int] ?? []
    }

    // MARK: - Playlists

    func createPlaylist(name: String) {
        let playlist = Playlist(name: name)
        playlists.append(playlist)
        savePlaylists()
    }

    func deletePlaylist(_ id: UUID) {
        playlists.removeAll { $0.id == id }
        savePlaylists()
    }

    func renamePlaylist(_ id: UUID, name: String) {
        if let index = playlists.firstIndex(where: { $0.id == id }) {
            playlists[index].name = name
            savePlaylists()
        }
    }

    func addSongToPlaylist(songId: Int, playlistId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            if !playlists[index].songIds.contains(songId) {
                playlists[index].songIds.append(songId)
                savePlaylists()
            }
        }
    }

    func removeSongFromPlaylist(songId: Int, playlistId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index].songIds.removeAll { $0 == songId }
            savePlaylists()
        }
    }

    func playlistSongs(_ playlist: Playlist) -> [Song] {
        playlist.songIds.compactMap { id in songs.first { $0.id == id } }
    }

    private func savePlaylists() {
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: playlistsKey)
        }
    }

    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let saved = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = saved
        }
    }
}
