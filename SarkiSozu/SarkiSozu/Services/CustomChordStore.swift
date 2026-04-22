import Foundation
import Combine

struct CustomChord: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    /// 6 strings low E to high E. -1 = muted, 0 = open, n = fret (relative to baseFret)
    var frets: [Int]
    var baseFret: Int
    var barreFret: Int?
    /// Covered string indices for barre (0 = low E ... 5 = high E)
    var barreFromString: Int?
    var barreToString: Int?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        frets: [Int] = [-1, -1, -1, -1, -1, -1],
        baseFret: Int = 1,
        barreFret: Int? = nil,
        barreFromString: Int? = nil,
        barreToString: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.frets = frets
        self.baseFret = baseFret
        self.barreFret = barreFret
        self.barreFromString = barreFromString
        self.barreToString = barreToString
        self.createdAt = createdAt
    }

    /// Convert to ChordData used by ChordDiagramView.
    func toChordData() -> ChordData {
        let mapped: [Int?] = frets.map { $0 < 0 ? nil : $0 }
        var barRange: ClosedRange<Int>? = nil
        if let from = barreFromString, let to = barreToString, from <= to {
            barRange = from...to
        }
        return ChordData(
            frets: mapped,
            baseFret: baseFret,
            barFret: barreFret,
            barStrings: barRange
        )
    }
}

@MainActor
final class CustomChordStore: ObservableObject {
    static let shared = CustomChordStore()

    @Published private(set) var chords: [CustomChord] = []

    private let storageKey = "customChords.v1"

    private init() {
        load()
    }

    // MARK: - Public API

    func add(_ chord: CustomChord) {
        chords.insert(chord, at: 0)
        save()
    }

    func update(_ chord: CustomChord) {
        if let idx = chords.firstIndex(where: { $0.id == chord.id }) {
            chords[idx] = chord
            save()
        }
    }

    func delete(_ chord: CustomChord) {
        chords.removeAll { $0.id == chord.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        chords.remove(atOffsets: offsets)
        save()
    }

    func lookup(_ name: String) -> CustomChord? {
        chords.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(chords) {
            UserDefaults.standard.set(data, forKey: storageKey)
            SyncManager.shared.publishCustomChords(data)
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([CustomChord].self, from: data) else {
            return
        }
        chords = decoded
    }

    /// Replace state from an external source (iCloud).
    func replaceAll(with newChords: [CustomChord]) {
        chords = newChords.sorted { $0.createdAt > $1.createdAt }
        if let data = try? JSONEncoder().encode(chords) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
