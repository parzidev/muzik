import SwiftUI

struct SongRowView: View {
    let song: Song
    var index: Int? = nil


    var body: some View {
        HStack(spacing: 12) {
            if let index = index {
                Text("\(index)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)
            }

            // Music icon
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundColor(.white.opacity(0.8))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.sarkiadi)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Text(song.sanatci)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Display Key or First Chord
            if let ton = song.orjinal_ton, !ton.isEmpty {
                 keyBadge(text: ton)
            } else if let firstChord = song.chords.first, !firstChord.isEmpty {
                keyBadge(text: firstChord)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8) // Reduced vertical padding for tighter list
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts: [String] = []
        if let index = index { parts.append("Sıra \(index)") }
        parts.append(song.sarkiadi)
        parts.append("Sanatçı: \(song.sanatci)")
        if let ton = song.orjinal_ton, !ton.isEmpty {
            parts.append("Ton: \(ton)")
        } else if let firstChord = song.chords.first, !firstChord.isEmpty {
            parts.append("Akor: \(firstChord)")
        }
        return parts.joined(separator: ", ")
    }
    
    private func keyBadge(text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.blue)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
    }
}
