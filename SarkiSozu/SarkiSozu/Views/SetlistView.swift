import SwiftUI

// MARK: - Setlist / Concert Mode

struct SetlistView: View {
    @EnvironmentObject var dataService: SongDataService
    @Environment(\.dismiss) var dismiss
    let songs: [Song]
    let startIndex: Int

    @State private var currentIndex: Int
    @State private var showControls = true
    @State private var transposeAmount: Int = 0
    @State private var isAutoScrolling = false
    @State private var scrollSpeed: Double = 3.0
    @State private var scrollProxy: ScrollViewProxy?

    init(songs: [Song], startIndex: Int = 0) {
        self.songs = songs
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    private var currentSong: Song {
        songs[currentIndex]
    }

    private var fontSize: CGFloat { 16 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Song content with swipe
            TabView(selection: $currentIndex) {
                ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                    setlistSongView(song: song)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentIndex) { _, _ in
                transposeAmount = 0
            }

            // Top & bottom controls overlay
            if showControls {
                VStack {
                    // Top bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text(currentSong.sarkiadi)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(currentSong.sanatci)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()

                        // Song counter
                        Text("\(currentIndex + 1)/\(songs.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 40, height: 40)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .background(
                        LinearGradient(colors: [.black.opacity(0.8), .clear],
                                       startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                    )

                    Spacer()

                    // Bottom controls
                    HStack(spacing: 24) {
                        // Previous
                        Button(action: { if currentIndex > 0 { withAnimation { currentIndex -= 1 } } }) {
                            Image(systemName: "backward.fill")
                                .font(.title2)
                                .foregroundColor(currentIndex > 0 ? .white : .white.opacity(0.3))
                        }
                        .disabled(currentIndex == 0)

                        // Transpose
                        HStack(spacing: 12) {
                            Button(action: { transposeAmount -= 1 }) {
                                Image(systemName: "minus")
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }

                            Text(transposeAmount == 0 ? "0" : (transposeAmount > 0 ? "+\(transposeAmount)" : "\(transposeAmount)"))
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 36)

                            Button(action: { transposeAmount += 1 }) {
                                Image(systemName: "plus")
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                        .foregroundColor(.white)

                        // Next
                        Button(action: { if currentIndex < songs.count - 1 { withAnimation { currentIndex += 1 } } }) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .foregroundColor(currentIndex < songs.count - 1 ? .white : .white.opacity(0.3))
                        }
                        .disabled(currentIndex >= songs.count - 1)
                    }
                    .padding()
                    .background(
                        LinearGradient(colors: [.clear, .black.opacity(0.8)],
                                       startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                    )
                }
            }
        }
        .statusBarHidden(true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls.toggle()
            }
        }
    }

    // MARK: - Song View for Setlist

    private func setlistSongView(song: Song) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Chords summary
                let chords = song.chords.map { MusicTheory.transposeChord($0, semitones: transposeAmount) }
                if !chords.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(chords, id: \.self) { chord in
                                Text(chord)
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.1))
                                    .foregroundColor(Color(hex: "8B8FFF"))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                    }
                }

                // Lyrics + chords
                if let lines = song.lyrics_data?.lines {
                    let blocks = transposeAmount == 0 ? lines : lines.map { block -> RenderBlock in
                        guard block.type == .chords || block.type == .block else { return block }
                        let chordText = block.type == .block ? block.chords : block.content
                        guard let ct = chordText, !ct.isEmpty else { return block }
                        let transposed = MusicTheory.transposeLine(ct, semitones: transposeAmount)
                        return RenderBlock(
                            type: block.type,
                            chords: block.type == .block ? transposed : block.chords,
                            lyrics: block.lyrics,
                            content: block.type == .chords ? transposed : block.content,
                            chords_extracted: block.chords_extracted
                        )
                    }

                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        setlistBlockView(block)
                    }
                }

                Spacer(minLength: 120)
            }
            .padding(.top, 60)
        }
    }

    @ViewBuilder
    private func setlistBlockView(_ block: RenderBlock) -> some View {
        switch block.type {
        case .empty, .spacer:
            Color.clear.frame(height: 20)
        case .meta:
            if let content = block.content {
                HStack {
                    Rectangle()
                        .fill(Color(hex: "8B8FFF"))
                        .frame(width: 3, height: 18)
                        .cornerRadius(1.5)
                    Text(content)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "8B8FFF"))
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        case .chords:
            if let content = block.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "8B8FFF"))
                    .padding(.horizontal)
                    .padding(.top, 12)
            }
        case .lyrics:
            if let content = block.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal)
                    .padding(.top, 1)
            }
        case .block:
            VStack(alignment: .leading, spacing: 1) {
                if let chords = block.chords, !chords.isEmpty {
                    Text(chords)
                        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "8B8FFF"))
                        .padding(.top, 12)
                }
                if let lyrics = block.lyrics, !lyrics.isEmpty {
                    Text(lyrics)
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.horizontal)
        }
    }
}
