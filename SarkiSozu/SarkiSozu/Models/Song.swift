import Foundation

// MARK: - Playlist Model
struct Playlist: Codable, Identifiable {
    let id: UUID
    var name: String
    var songIds: [Int]
    var createdAt: Date

    init(name: String, songIds: [Int] = []) {
        self.id = UUID()
        self.name = name
        self.songIds = songIds
        self.createdAt = Date()
    }
}

// MARK: - Song Model
struct Song: Codable, Identifiable {
    let id: Int
    let sanatci: String
    let sarkiadi: String
    let orjinal_ton: String?
    let kayitli_ton: String?
    let kolay_akor_ton: String?
    let kapo: String?
    let ritimler: [String]?
    let scrape_status: String?
    let lyrics_data: LyricsData?
    
    // Computed helper for canonical chords
    var chords: [String] {
        var allChords: Set<String> = []
        lyrics_data?.lines?.forEach { block in
            block.chords_extracted?.forEach { allChords.insert($0) }
        }
        return Array(allChords).sorted()
    }

    // MARK: - Difficulty

    /// Automatic difficulty based on chord complexity
    var difficulty: SongDifficulty {
        let chordSet = chords
        if chordSet.isEmpty { return .unknown }

        let barreChords: Set<String> = ["F", "Fm", "F7", "Bm", "B", "B7", "Cm", "C#m", "F#m", "F#", "Gm", "G#m", "Bb", "Bbm", "Ab", "Eb", "D#m"]
        let barreCount = chordSet.filter { barreChords.contains($0) }.count
        let totalChords = chordSet.count
        let hasSharpFlat = chordSet.contains { $0.contains("#") || $0.contains("b") }

        if totalChords <= 3 && barreCount == 0 {
            return .easy
        } else if totalChords <= 5 && barreCount <= 1 {
            return .medium
        } else if barreCount >= 3 || totalChords >= 8 {
            return .expert
        } else {
            return .hard
        }
    }
}

enum SongDifficulty: String, Codable {
    case easy = "Kolay"
    case medium = "Orta"
    case hard = "Zor"
    case expert = "Uzman"
    case unknown = "?"

    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "blue"
        case .hard: return "orange"
        case .expert: return "red"
        case .unknown: return "gray"
        }
    }

    var icon: String {
        switch self {
        case .easy: return "1.circle.fill"
        case .medium: return "2.circle.fill"
        case .hard: return "3.circle.fill"
        case .expert: return "4.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

struct LyricsData: Codable {
    let original_key: String?
    let lines: [RenderBlock]?
}

struct RenderBlock: Codable, Identifiable {
    var id: UUID = UUID()
    let type: BlockType
    let chords: String?
    let lyrics: String?
    let content: String?
    let chords_extracted: [String]?
    
    enum BlockType: String, Codable {
        case block
        case spacer
        case meta
        case chords
        case lyrics
        case empty
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case chords_extracted = "chords"
        case lyrics
        case content
    }
    
    init(type: BlockType, chords: String? = nil, lyrics: String? = nil, content: String? = nil, chords_extracted: [String]? = nil) {
        self.type = type
        self.chords = chords
        self.lyrics = lyrics
        self.content = content
        self.chords_extracted = chords_extracted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)
        let type = BlockType(rawValue: typeString) ?? .block
        self.type = type
        
        let rawContent = try container.decodeIfPresent(String.self, forKey: .content)
        self.content = rawContent
        
        // Map content to specific fields based on type for convenience
        if type == .chords {
            self.chords = rawContent
            self.lyrics = nil
        } else if type == .lyrics {
            self.lyrics = rawContent
            self.chords = nil
        } else {
            self.chords = nil
            self.lyrics = try container.decodeIfPresent(String.self, forKey: .lyrics)
        }
        
        // Map the JSON "chords" (which is an array) to chords_extracted
        self.chords_extracted = try container.decodeIfPresent([String].self, forKey: .chords_extracted)
    }
}
