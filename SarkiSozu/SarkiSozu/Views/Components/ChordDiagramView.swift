import SwiftUI

// MARK: - Chord Data Model
struct ChordData {
    /// Fret positions for each string (low E to high E). nil = muted, 0 = open
    let frets: [Int?]
    /// Starting fret (1 for open position chords)
    let baseFret: Int
    /// Optional barre across strings
    let barFret: Int?
    /// Which strings the barre covers (e.g., 1...6)
    let barStrings: ClosedRange<Int>?

    init(frets: [Int?], baseFret: Int = 1, barFret: Int? = nil, barStrings: ClosedRange<Int>? = nil) {
        self.frets = frets
        self.baseFret = baseFret
        self.barFret = barFret
        self.barStrings = barStrings
    }
}

// MARK: - Chord Database
struct ChordDatabase {
    static let chords: [String: ChordData] = [
        // Major
        "A":  ChordData(frets: [nil, 0, 2, 2, 2, 0]),
        "B":  ChordData(frets: [nil, 2, 4, 4, 4, 2], baseFret: 1, barFret: 2, barStrings: 1...5),
        "C":  ChordData(frets: [nil, 3, 2, 0, 1, 0]),
        "D":  ChordData(frets: [nil, nil, 0, 2, 3, 2]),
        "E":  ChordData(frets: [0, 2, 2, 1, 0, 0]),
        "F":  ChordData(frets: [1, 3, 3, 2, 1, 1], baseFret: 1, barFret: 1, barStrings: 0...5),
        "G":  ChordData(frets: [3, 2, 0, 0, 0, 3]),

        // Minor
        "Am": ChordData(frets: [nil, 0, 2, 2, 1, 0]),
        "Bm": ChordData(frets: [nil, 2, 4, 4, 3, 2], baseFret: 1, barFret: 2, barStrings: 1...5),
        "Cm": ChordData(frets: [nil, 3, 5, 5, 4, 3], baseFret: 3, barFret: 3, barStrings: 1...5),
        "Dm": ChordData(frets: [nil, nil, 0, 2, 3, 1]),
        "Em": ChordData(frets: [0, 2, 2, 0, 0, 0]),
        "Fm": ChordData(frets: [1, 3, 3, 1, 1, 1], baseFret: 1, barFret: 1, barStrings: 0...5),
        "Gm": ChordData(frets: [3, 5, 5, 3, 3, 3], baseFret: 3, barFret: 3, barStrings: 0...5),

        // Seventh
        "A7": ChordData(frets: [nil, 0, 2, 0, 2, 0]),
        "B7": ChordData(frets: [nil, 2, 1, 2, 0, 2]),
        "C7": ChordData(frets: [nil, 3, 2, 3, 1, 0]),
        "D7": ChordData(frets: [nil, nil, 0, 2, 1, 2]),
        "E7": ChordData(frets: [0, 2, 0, 1, 0, 0]),
        "F7": ChordData(frets: [1, 3, 1, 2, 1, 1], baseFret: 1, barFret: 1, barStrings: 0...5),
        "G7": ChordData(frets: [3, 2, 0, 0, 0, 1]),

        // Sharp/Flat variants
        "F#m": ChordData(frets: [2, 4, 4, 2, 2, 2], baseFret: 2, barFret: 2, barStrings: 0...5),
        "C#m": ChordData(frets: [nil, 4, 6, 6, 5, 4], baseFret: 4, barFret: 4, barStrings: 1...5),
        "F#":  ChordData(frets: [2, 4, 4, 3, 2, 2], baseFret: 2, barFret: 2, barStrings: 0...5),
        "Bb":  ChordData(frets: [nil, 1, 3, 3, 3, 1], baseFret: 1, barFret: 1, barStrings: 1...5),
        "Bbm": ChordData(frets: [nil, 1, 3, 3, 2, 1], baseFret: 1, barFret: 1, barStrings: 1...5),
        "Ab":  ChordData(frets: [4, 6, 6, 5, 4, 4], baseFret: 4, barFret: 4, barStrings: 0...5),
        "Eb":  ChordData(frets: [nil, nil, 1, 3, 4, 3], baseFret: 1),
        "G#m": ChordData(frets: [4, 6, 6, 4, 4, 4], baseFret: 4, barFret: 4, barStrings: 0...5),
    ]

    static func lookup(_ name: String) -> ChordData? {
        // Custom user-defined chords take precedence
        if let custom = MainActor.assumeIsolated({ CustomChordStore.shared.lookup(name) }) {
            return custom.toChordData()
        }
        if let data = chords[name] { return data }
        // Try without trailing numbers (e.g., "Am7" -> "Am")
        let base = name.replacingOccurrences(of: "[0-9]+$", with: "", options: .regularExpression)
        if let data = chords[base] { return data }
        return nil
    }
}

// MARK: - Native SwiftUI Chord Diagram View
struct ChordDiagramView: View {
    let chordName: String
    var size: ChordSize = .medium

    enum ChordSize {
        case small   // for inline/grid
        case medium  // for chord cards
        case large   // for chord library

        var width: CGFloat {
            switch self {
            case .small: return 80
            case .medium: return 100
            case .large: return 120
            }
        }

        var titleFont: Font {
            switch self {
            case .small: return .system(size: 13, weight: .bold)
            case .medium: return .system(size: 15, weight: .bold)
            case .large: return .system(size: 17, weight: .bold)
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(chordName)
                .font(size.titleFont)
                .foregroundColor(DS.Color.accent)

            if let chordData = ChordDatabase.lookup(chordName) {
                ChordFretboardView(data: chordData, width: size.width)
            } else {
                // Fallback for unknown chords
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: size.width, height: size.width * 1.2)
                    .overlay(
                        Text("?")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.medium)
    }
}

// MARK: - Fretboard Drawing
struct ChordFretboardView: View {
    let data: ChordData
    let width: CGFloat

    private let stringCount = 6
    private let fretCount = 4

    private var height: CGFloat { width * 1.2 }
    private var topMargin: CGFloat { width * 0.2 }
    private var bottomMargin: CGFloat { width * 0.08 }
    private var sideMargin: CGFloat { width * 0.12 }

    private var fretboardWidth: CGFloat { width - sideMargin * 2 }
    private var fretboardHeight: CGFloat { height - topMargin - bottomMargin }
    private var stringSpacing: CGFloat { fretboardWidth / CGFloat(stringCount - 1) }
    private var fretSpacing: CGFloat { fretboardHeight / CGFloat(fretCount) }
    private var dotRadius: CGFloat { stringSpacing * 0.32 }

    var body: some View {
        Canvas { context, canvasSize in
            let scale = canvasSize.width / width

            // Draw nut (thick bar at top) or fret number
            if data.baseFret == 1 {
                // Nut bar
                let nutRect = CGRect(
                    x: sideMargin * scale,
                    y: topMargin * scale - 2 * scale,
                    width: fretboardWidth * scale,
                    height: 4 * scale
                )
                context.fill(Path(roundedRect: nutRect, cornerRadius: 1), with: .color(.primary))
            }

            // Fret lines
            for i in 0...fretCount {
                let y = (topMargin + CGFloat(i) * fretSpacing) * scale
                let path = Path { p in
                    p.move(to: CGPoint(x: sideMargin * scale, y: y))
                    p.addLine(to: CGPoint(x: (width - sideMargin) * scale, y: y))
                }
                context.stroke(path, with: .color(Color(.separator)), lineWidth: 1)
            }

            // String lines
            for i in 0..<stringCount {
                let x = (sideMargin + CGFloat(i) * stringSpacing) * scale
                let path = Path { p in
                    p.move(to: CGPoint(x: x, y: topMargin * scale))
                    p.addLine(to: CGPoint(x: x, y: (topMargin + fretboardHeight) * scale))
                }
                context.stroke(path, with: .color(Color(.separator)), lineWidth: 1)
            }

            // Barre
            if let barFret = data.barFret, let barStrings = data.barStrings {
                let relativeFret = barFret - data.baseFret + 1
                let y = (topMargin + (CGFloat(relativeFret) - 0.5) * fretSpacing) * scale
                let x1 = (sideMargin + CGFloat(barStrings.lowerBound) * stringSpacing) * scale
                let x2 = (sideMargin + CGFloat(barStrings.upperBound) * stringSpacing) * scale
                let barRect = CGRect(
                    x: x1 - dotRadius * scale,
                    y: y - dotRadius * 0.7 * scale,
                    width: x2 - x1 + dotRadius * 2 * scale,
                    height: dotRadius * 1.4 * scale
                )
                context.fill(Path(roundedRect: barRect, cornerRadius: dotRadius * scale), with: .color(DS.Color.accent))
            }

            // Finger dots, mute (x) and open (o) markers
            for (stringIndex, fret) in data.frets.enumerated() {
                let x = (sideMargin + CGFloat(stringIndex) * stringSpacing) * scale

                if let fret = fret {
                    if fret == 0 {
                        // Open string - circle outline above nut
                        let y = (topMargin - 10) * scale
                        let r = dotRadius * 0.7 * scale
                        let circle = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                        context.stroke(circle, with: .color(.secondary), lineWidth: 1.5)
                    } else {
                        // Finger position
                        let relativeFret = fret - data.baseFret + 1
                        let y = (topMargin + (CGFloat(relativeFret) - 0.5) * fretSpacing) * scale
                        let r = dotRadius * scale

                        // Skip drawing individual dot if barre covers this position
                        if let barFret = data.barFret, let barStrings = data.barStrings,
                           fret == barFret && barStrings.contains(stringIndex) {
                            continue
                        }

                        let circle = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                        context.fill(circle, with: .color(DS.Color.accent))
                    }
                } else {
                    // Muted string - X above nut
                    let y = (topMargin - 10) * scale
                    let r = dotRadius * 0.5 * scale
                    var xPath = Path()
                    xPath.move(to: CGPoint(x: x - r, y: y - r))
                    xPath.addLine(to: CGPoint(x: x + r, y: y + r))
                    xPath.move(to: CGPoint(x: x + r, y: y - r))
                    xPath.addLine(to: CGPoint(x: x - r, y: y + r))
                    context.stroke(xPath, with: .color(.secondary), lineWidth: 1.5)
                }
            }

            // Base fret number (when not at nut position)
            if data.baseFret > 1 {
                let text = Text("\(data.baseFret)fr")
                    .font(.system(size: 9 * scale, weight: .medium))
                    .foregroundColor(.secondary)
                context.draw(
                    context.resolve(text),
                    at: CGPoint(x: (width - sideMargin + 6) * scale, y: (topMargin + fretSpacing * 0.5) * scale),
                    anchor: .leading
                )
            }
        }
        .frame(width: width, height: height)
    }
}
