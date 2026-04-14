import SwiftUI

// MARK: - Capo Calculator

struct CapoCalculatorView: View {
    @State private var selectedChord: String = "C"
    @State private var targetChord: String = "C"

    private let allChords = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// For each capo position (0-12), show what chord shape to play
    private var capoTable: [(capo: Int, shape: String)] {
        guard let targetIndex = allChords.firstIndex(of: normalizeChord(targetChord)) else { return [] }
        return (0...12).map { capo in
            let shapeIndex = (targetIndex - capo + 12) % 12
            return (capo: capo, shape: allChords[shapeIndex])
        }
    }

    /// Find the easiest capo position (prefer open chords: C, G, D, A, E, Am, Em, Dm)
    private let easyShapes: Set<String> = ["C", "G", "D", "A", "E"]

    private var bestCapo: (capo: Int, shape: String)? {
        capoTable.first(where: { easyShapes.contains($0.shape) && $0.capo > 0 })
    }

    private func normalizeChord(_ chord: String) -> String {
        MusicTheory.noteMap[chord] ?? chord
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                // Chord pickers
                VStack(spacing: DS.Spacing.m) {
                    Text("Hangi tonda çalmak istiyorsun?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: DS.Spacing.l) {
                        VStack(spacing: 6) {
                            Text("Hedef Ton")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Menu {
                                ForEach(allChords, id: \.self) { chord in
                                    Button(chord) { targetChord = chord }
                                }
                            } label: {
                                HStack {
                                    Text(targetChord)
                                        .font(.title)
                                        .fontWeight(.bold)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .foregroundColor(DS.Color.accent)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(DS.Color.accent.opacity(0.1))
                                .cornerRadius(DS.CornerRadius.medium)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(DS.CornerRadius.large)
                .padding(.horizontal)

                // Best suggestion
                if let best = bestCapo {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("En Kolay Yol")
                                .font(.headline)
                        }

                        HStack(spacing: 4) {
                            Text("Kapo \(best.capo)")
                                .fontWeight(.bold)
                                .foregroundColor(DS.Color.accent)
                            Text("ile")
                                .foregroundColor(.secondary)
                            Text(best.shape)
                                .fontWeight(.bold)
                                .foregroundColor(DS.Color.accent)
                            Text("pozisyonu çal")
                                .foregroundColor(.secondary)
                        }
                        .font(.title3)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                            .fill(Color.yellow.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                }

                // Full capo table
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("Kapo")
                            .frame(width: 60, alignment: .leading)
                        Text("Çalacağın Pozisyon")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Zorluk")
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                    Divider()

                    ForEach(capoTable, id: \.capo) { entry in
                        let isEasy = easyShapes.contains(entry.shape)
                        let isBest = bestCapo?.capo == entry.capo && entry.capo > 0

                        HStack {
                            HStack(spacing: 4) {
                                if entry.capo == 0 {
                                    Text("Açık")
                                        .font(.subheadline)
                                } else {
                                    Text("\(entry.capo)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(width: 60, alignment: .leading)

                            HStack(spacing: 8) {
                                Text(entry.shape)
                                    .font(.system(.body, weight: .semibold))
                                    .foregroundColor(isBest ? DS.Color.accent : .primary)

                                if isBest {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            difficultyBadge(isEasy: isEasy)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(isBest ? DS.Color.accent.opacity(0.05) : Color.clear)

                        if entry.capo < 12 {
                            Divider().padding(.leading)
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(DS.CornerRadius.large)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Kapo Hesaplayıcı")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func difficultyBadge(isEasy: Bool) -> some View {
        Text(isEasy ? "Kolay" : "Zor")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isEasy ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
            .foregroundColor(isEasy ? .green : .orange)
            .cornerRadius(4)
    }
}
