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

    @Published var songNotes: [Int: String] = [:]

    private let favoritesKey = "favorites"
    private let recentKey = "recentlyViewed"
    private let playlistsKey = "playlists"
    private let notesKey = "songNotes"

    init() {
        loadFavorites()
        loadRecent()
        loadPlaylists()
        loadNotes()
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

    /// Normalizes Turkish characters for accent-insensitive search
    private func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ç", with: "c")
            .replacingOccurrences(of: "İ", with: "i")
    }

    func searchSongs(query: String) -> [Song] {
        let q = normalize(query.trimmingCharacters(in: .whitespaces))
        if q.isEmpty { return [] }
        return songs.filter {
            normalize($0.sarkiadi).contains(q) ||
            normalize($0.sanatci).contains(q)
        }
    }

    func popularSongs() -> [Song] {
        Array(songs.prefix(15))
    }

    /// All unique artists sorted
    func allArtists() -> [String] {
        let artists = Set(songs.map { $0.sanatci })
        return artists.sorted()
    }

    /// Songs by a specific artist
    func songsByArtist(_ artist: String) -> [Song] {
        songs.filter { $0.sanatci == artist }.sorted { $0.sarkiadi < $1.sarkiadi }
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

    /// Returns true if the user can add another favorite (always true for Pro users).
    @MainActor
    func canAddFavorite() -> Bool {
        if ProManager.shared.hasProAccess { return true }
        return favorites.count < ProGate.freeFavoritesLimit
    }

    func toggleFavorite(_ songId: Int) {
        if favorites.contains(songId) {
            favorites.remove(songId)
        } else {
            favorites.insert(songId)
        }
        saveFavorites()
    }

    /// Gated add: returns false if free limit reached and the song isn't already a favorite.
    @MainActor
    func tryToggleFavorite(_ songId: Int) -> Bool {
        if favorites.contains(songId) {
            favorites.remove(songId)
            saveFavorites()
            return true
        }
        if !ProManager.shared.hasProAccess && favorites.count >= ProGate.freeFavoritesLimit {
            return false
        }
        favorites.insert(songId)
        saveFavorites()
        return true
    }

    func isFavorite(_ songId: Int) -> Bool {
        favorites.contains(songId)
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)
        let snapshot = favorites
        Task { @MainActor in SyncManager.shared.publishFavorites(snapshot) }
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
        let snapshot = recentlyViewed
        Task { @MainActor in SyncManager.shared.publishRecent(snapshot) }
    }

    private func loadRecent() {
        recentlyViewed = UserDefaults.standard.array(forKey: recentKey) as? [Int] ?? []
    }

    // MARK: - Playlists

    @MainActor
    func canCreatePlaylist() -> Bool {
        if ProManager.shared.hasProAccess { return true }
        return playlists.count < ProGate.freePlaylistsLimit
    }

    func createPlaylist(name: String) {
        let playlist = Playlist(name: name)
        playlists.append(playlist)
        savePlaylists()
    }

    /// Gated create: returns false if free limit reached.
    @MainActor
    @discardableResult
    func tryCreatePlaylist(name: String) -> Bool {
        if !ProManager.shared.hasProAccess && playlists.count >= ProGate.freePlaylistsLimit {
            return false
        }
        createPlaylist(name: name)
        return true
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
            Task { @MainActor in SyncManager.shared.publishPlaylists(data) }
        }
    }

    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let saved = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = saved
        }
    }

    // MARK: - Song Notes

    func getNote(for songId: Int) -> String {
        songNotes[songId] ?? ""
    }

    func setNote(for songId: Int, note: String) {
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            songNotes.removeValue(forKey: songId)
        } else {
            songNotes[songId] = note
        }
        saveNotes()
    }

    func hasNote(for songId: Int) -> Bool {
        guard let note = songNotes[songId] else { return false }
        return !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveNotes() {
        if let data = try? JSONEncoder().encode(songNotes) {
            UserDefaults.standard.set(data, forKey: notesKey)
            let snapshot = songNotes
            Task { @MainActor in SyncManager.shared.publishNotes(snapshot) }
        }
    }

    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let saved = try? JSONDecoder().decode([Int: String].self, from: data) {
            songNotes = saved
        }
    }
}
