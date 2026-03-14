import Foundation

struct MusicTheory {
    static let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    // Normalize flats to sharps for simplicity
    static let noteMap: [String: String] = [
        "Db": "C#", "Eb": "D#", "Fb": "E", "Gb": "F#",
        "Ab": "G#", "Bb": "A#", "Cb": "B"
    ]
    
    static func transposeChord(_ chord: String, semitones: Int) -> String {
        if semitones == 0 { return chord }
        
        // Find the root note of the chord
        let pattern = try! NSRegularExpression(pattern: "^([A-G][b#]?)")
        let range = NSRange(location: 0, length: chord.utf16.count)
        
        guard let match = pattern.firstMatch(in: chord, options: [], range: range),
              let rootRange = Range(match.range(at: 1), in: chord) else {
            return chord
        }
        
        let root = String(chord[rootRange])
        let normalizedRoot = noteMap[root] ?? root
        
        guard let index = notes.firstIndex(of: normalizedRoot) else {
            return chord
        }
        
        let newIndex = (index + semitones % 12 + 12) % 12
        let newRoot = notes[newIndex]
        
        return chord.replacingCharacters(in: rootRange, with: newRoot)
    }
    
    /// Transpose a whole line of chords (e.g. "Am      G      C"), preserving alignment.
    /// When a chord changes length (e.g. "C" -> "C#"), trailing spaces are adjusted
    /// to keep subsequent chords at their original positions.
    static func transposeLine(_ line: String, semitones: Int) -> String {
        if semitones == 0 { return line }

        let pattern = try! NSRegularExpression(pattern: "\\b[A-G][b#]?(?:m|maj|min|aug|dim|sus|add|[0-9])*\\b")
        let matches = pattern.matches(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))

        if matches.isEmpty { return line }

        // Extract chord info: position, original text, transposed text
        struct ChordInfo {
            let position: Int
            let original: String
            let transposed: String
        }

        var chordInfos: [ChordInfo] = []
        for match in matches {
            guard let range = Range(match.range, in: line) else { continue }
            let chord = String(line[range])
            let transposed = transposeChord(chord, semitones: semitones)
            chordInfos.append(ChordInfo(
                position: match.range.location,
                original: chord,
                transposed: transposed
            ))
        }

        // Rebuild the line: place each transposed chord at its original position,
        // with at least one space between consecutive chords
        var result = ""
        for (i, info) in chordInfos.enumerated() {
            let targetPos = info.position
            // Pad to reach the target position
            if result.count < targetPos {
                result += String(repeating: " ", count: targetPos - result.count)
            } else if i > 0 && result.count >= targetPos {
                // Ensure at least one space between chords
                if !result.hasSuffix(" ") {
                    result += " "
                }
            }
            result += info.transposed
        }

        return result
    }
}
