import SwiftUI
import Combine

// MARK: - UI Models
extension Song {
    var displayName: String { sarkiadi }
    var displayArtist: String { sanatci }
    var displayKey: String { orjinal_ton ?? "-" }
    var hasChords: Bool { !(chords.isEmpty) }
}

// MARK: - Song Repository Protocol
protocol SongRepository {
    func getAllSongs() -> [Song]
    func getPopularSongs() -> [Song]
    func getRecentSongs() -> [Song]
    func searchSongs(query: String) -> [Song]
    func toggleFavorite(songId: Int)
    func isFavorite(songId: Int) -> Bool
    func addToRecent(song: Song)
}

// MARK: - Mock Repository
class MockSongRepository: SongRepository {
    static let shared = MockSongRepository()
    
    private var songs: [Song] = (1...10).map { i in
        Song(
            id: i,
            sanatci: "Sanatçı \(i)",
            sarkiadi: "Şarkı Adı \(i)",
            orjinal_ton: ["Am", "Em", "G"].randomElement(),
            kayitli_ton: nil,
            kolay_akor_ton: nil,
            kapo: "0",
            ritimler: [],
            scrape_status: "success",
            lyrics_data: LyricsData(
                original_key: "Am",
                lines: [
                    RenderBlock(type: .block, chords: "Am      G", lyrics: "Deneme satiri \(i)", content: nil, chords_extracted: ["Am", "G"]),
                    RenderBlock(type: .spacer, chords: nil, lyrics: nil, content: nil, chords_extracted: nil),
                    RenderBlock(type: .meta, chords: nil, lyrics: nil, content: "Nakarat", chords_extracted: nil)
                ]
            )
        )
    }
    
    private var favorites: Set<Int> = []
    private var recents: [Int] = []
    
    func getAllSongs() -> [Song] { songs }
    func getPopularSongs() -> [Song] { Array(songs.prefix(5)) }
    func getRecentSongs() -> [Song] { recents.compactMap { id in songs.first(where: { $0.id == id }) } }
    
    func searchSongs(query: String) -> [Song] {
        guard !query.isEmpty else { return [] }
        return songs.filter {
            $0.sarkiadi.localizedCaseInsensitiveContains(query) ||
            $0.sanatci.localizedCaseInsensitiveContains(query)
        }
    }
    
    func toggleFavorite(songId: Int) {
        if favorites.contains(songId) { favorites.remove(songId) } else { favorites.insert(songId) }
    }
    
    func isFavorite(songId: Int) -> Bool { favorites.contains(songId) }
    
    func addToRecent(song: Song) {
        if let idx = recents.firstIndex(of: song.id) { recents.remove(at: idx) }
        recents.insert(song.id, at: 0)
        if recents.count > 10 { recents.removeLast() }
    }
}

// MARK: - View Models

class HomeViewModel: ObservableObject {
    @Published var recentSongs: [Song] = []
    @Published var popularSongs: [Song] = []
    
    private var dataService: SongDataService
    private var cancellables = Set<AnyCancellable>()
    
    init(dataService: SongDataService) {
        self.dataService = dataService
        
        // React to data changes
        dataService.$songs
            .receive(on: RunLoop.main) // Ensure we get the value AFTER it's set
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
            
        loadData()
    }
    
    func loadData() {
        self.popularSongs = dataService.popularSongs()
        self.recentSongs = dataService.recentSongs()
    }
}

class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [Song] = []
    @Published var recentSearches: [String] = []
    
    // Filter State
    @Published var selectedKey: String = "Tümü"
    @Published var selectedCapo: Int = 0
    @Published var favoritesOnly: Bool = false
    
    private var service: SongDataService
    private var cancellables = Set<AnyCancellable>()
    
    init(service: SongDataService) {
        self.service = service
        self.recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let results = service.songs.filter { song in
            let matchesQuery = song.sarkiadi.localizedCaseInsensitiveContains(query) ||
                               song.sanatci.localizedCaseInsensitiveContains(query)
            
            let matchesKey = selectedKey == "Tümü" || (song.orjinal_ton == selectedKey)
            // Capo check: simplified since kapo is now String
            let matchesCapo = selectedCapo == 0 || (song.kapo == String(selectedCapo))
            let matchesFav = !favoritesOnly || service.favorites.contains(song.id)
            
            return matchesQuery && matchesKey && matchesCapo && matchesFav
        }
        
        self.searchResults = Array(results.prefix(50))
    }
    
    func addRecentSearch(_ query: String) {
        guard !query.isEmpty else { return }
        if !recentSearches.contains(query) {
            recentSearches.insert(query, at: 0)
            if recentSearches.count > 10 { recentSearches.removeLast() }
            UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
        }
    }
    
    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }
    
    var isFiltering: Bool {
        selectedKey != "Tümü" || selectedCapo != 0 || favoritesOnly
    }
}

class SongDetailViewModel: ObservableObject {
    @Published var song: Song
    @Published var transposeAmount: Int = 0
    @Published var currentCapo: Int = 0
    @Published var mode: DisplayMode = .lyricsAndChords
    @Published var isAutoScrolling: Bool = false
    @Published var scrollSpeed: Double = 3.0
    @Published var selectedChord: String? = nil

    enum DisplayMode: String, CaseIterable, Identifiable {
        case lyricsAndChords = "Söz & Akor"
        case cards = "Akor Kartları"
        case rhythm = "Ritim"
        var id: String { self.rawValue }
    }

    private let originalCapo: Int

    init(song: Song) {
        self.song = song
        let capo = Int(song.kapo ?? "0") ?? 0
        self.originalCapo = capo
        self.currentCapo = capo
    }

    // MARK: - Effective transpose (manual transpose + capo difference)

    /// Total semitones to shift chords: manual transpose + capo change from original
    var effectiveTranspose: Int {
        transposeAmount + (currentCapo - originalCapo)
    }

    /// Current key after transpose
    var currentKey: String? {
        guard let key = song.orjinal_ton, !key.isEmpty else { return nil }
        let transposed = MusicTheory.transposeChord(key, semitones: effectiveTranspose)
        return transposed
    }

    /// Whether the key has changed from original
    var keyChanged: Bool {
        effectiveTranspose != 0
    }

    // MARK: - Transposed blocks

    var transposedBlocks: [RenderBlock] {
        guard let blocks = song.lyrics_data?.lines else { return [] }
        let shift = effectiveTranspose
        if shift == 0 { return blocks }

        return blocks.map { block in
            guard (block.type == .block || block.type == .chords) else {
                return block
            }

            let chordText: String?
            if block.type == .block {
                chordText = block.chords
            } else {
                chordText = block.content ?? block.chords
            }

            guard let chordsLine = chordText, !chordsLine.isEmpty else {
                return block
            }

            let transposedChords = MusicTheory.transposeLine(chordsLine, semitones: shift)
            let transposedExtracted = block.chords_extracted?.map {
                MusicTheory.transposeChord($0, semitones: shift)
            }

            return RenderBlock(
                type: block.type,
                chords: block.type == .block ? transposedChords : block.chords,
                lyrics: block.lyrics,
                content: block.type == .chords ? transposedChords : block.content,
                chords_extracted: transposedExtracted
            )
        }
    }

    /// All unique chords used, after transpose
    var transposedChords: [String] {
        let shift = effectiveTranspose
        return song.chords.map { MusicTheory.transposeChord($0, semitones: shift) }
    }

    func toggleAutoScroll() {
        isAutoScrolling.toggle()
    }
}

class SettingsViewModel: ObservableObject {
    @AppStorage("darkMode") var darkMode: Bool = false
    @AppStorage("fontSize") var fontSize: Double = 16.0
    @AppStorage("scrollSpeed") var scrollSpeed: Double = 3.0
    
    func resetToDefaults() {
        fontSize = 16.0
        scrollSpeed = 3.0
        darkMode = false
    }
}
