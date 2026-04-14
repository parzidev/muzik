import SwiftUI
import AVFoundation

// MARK: - Metronome View

struct MetronomeView: View {
    @StateObject private var metronome = MetronomeEngine()

    let timeSignatures: [(String, Int)] = [
        ("4/4", 4), ("3/4", 3), ("6/8", 6), ("2/4", 2)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                // BPM Display
                bpmDisplay

                // BPM Slider
                bpmSlider

                // Time Signature
                timeSignatureSelector

                // Beat Indicator
                beatIndicator

                // Play/Stop
                controlButton

                // Tap Tempo
                tapTempoButton

                // Preset BPMs
                presetBPMs
            }
            .padding(.vertical, DS.Spacing.l)
        }
        .navigationTitle("Metronom")
        .background(Color(uiColor: .systemGroupedBackground))
        .onDisappear {
            metronome.stop()
        }
    }

    // MARK: - BPM Display

    private var bpmDisplay: some View {
        VStack(spacing: 4) {
            Text("\(metronome.bpm)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(metronome.isPlaying ? DS.Color.accent : .primary)
                .contentTransition(.numericText())
                .animation(.snappy, value: metronome.bpm)

            Text("BPM")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .padding(.top, DS.Spacing.m)
    }

    // MARK: - BPM Slider

    private var bpmSlider: some View {
        VStack(spacing: 8) {
            Slider(value: Binding(
                get: { Double(metronome.bpm) },
                set: { metronome.bpm = Int($0) }
            ), in: 40...220, step: 1)
            .tint(DS.Color.accent)

            HStack {
                Text("40")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("220")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, DS.Spacing.l)
    }

    // MARK: - Time Signature

    private var timeSignatureSelector: some View {
        VStack(spacing: DS.Spacing.xs) {
            Text("Olucu")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(timeSignatures, id: \.0) { sig in
                    Button {
                        metronome.beatsPerMeasure = sig.1
                        metronome.timeSignatureLabel = sig.0
                    } label: {
                        Text(sig.0)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .frame(width: 56, height: 44)
                            .background(metronome.timeSignatureLabel == sig.0 ? DS.Color.accent : Color(uiColor: .secondarySystemGroupedBackground))
                            .foregroundColor(metronome.timeSignatureLabel == sig.0 ? .white : .primary)
                            .cornerRadius(DS.CornerRadius.small)
                    }
                }
            }
        }
    }

    // MARK: - Beat Indicator

    private var beatIndicator: some View {
        HStack(spacing: 12) {
            ForEach(0..<metronome.beatsPerMeasure, id: \.self) { beat in
                Circle()
                    .fill(beatColor(for: beat))
                    .frame(width: 28, height: 28)
                    .scaleEffect(metronome.isPlaying && metronome.currentBeat == beat ? 1.3 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: metronome.currentBeat)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.large)
        .padding(.horizontal, DS.Spacing.l)
    }

    private func beatColor(for beat: Int) -> Color {
        if !metronome.isPlaying {
            return beat == 0 ? DS.Color.accent.opacity(0.4) : Color(uiColor: .tertiarySystemFill)
        }
        if metronome.currentBeat == beat {
            return beat == 0 ? DS.Color.accent : .orange
        }
        return Color(uiColor: .tertiarySystemFill)
    }

    // MARK: - Control Button

    private var controlButton: some View {
        Button {
            if metronome.isPlaying {
                metronome.stop()
            } else {
                metronome.start()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                Text(metronome.isPlaying ? "Durdur" : "Basla")
            }
            .font(.title3.bold())
            .foregroundColor(.white)
            .frame(width: 180, height: 56)
            .background(metronome.isPlaying ? Color.red : DS.Color.accent)
            .cornerRadius(28)
        }
    }

    // MARK: - Tap Tempo

    private var tapTempoButton: some View {
        Button {
            metronome.tapTempo()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "hand.tap")
                Text("Tempo Tiklama")
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(DS.Color.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(DS.Color.accent.opacity(0.12))
            .cornerRadius(20)
        }
    }

    // MARK: - Preset BPMs

    private var presetBPMs: some View {
        VStack(spacing: DS.Spacing.xs) {
            Text("Hizli Secim")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            let presets: [(String, Int)] = [
                ("Largo", 50), ("Adagio", 70), ("Andante", 90),
                ("Moderato", 110), ("Allegro", 140), ("Presto", 180)
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(presets, id: \.1) { preset in
                    Button {
                        metronome.bpm = preset.1
                    } label: {
                        VStack(spacing: 2) {
                            Text(preset.0)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("\(preset.1)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(DS.CornerRadius.small)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Spacing.l)
        }
    }
}

// MARK: - Metronome Engine

class MetronomeEngine: ObservableObject {
    @Published var bpm: Int = 120 {
        didSet {
            if isPlaying { restart() }
        }
    }
    @Published var beatsPerMeasure: Int = 4 {
        didSet {
            currentBeat = 0
            if isPlaying { restart() }
        }
    }
    @Published var timeSignatureLabel: String = "4/4"
    @Published var isPlaying = false
    @Published var currentBeat: Int = 0

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var tickBuffer: AVAudioPCMBuffer?
    private var accentBuffer: AVAudioPCMBuffer?
    private var timer: Timer?
    private var tapTimes: [Date] = []

    init() {
        setupAudio()
    }

    private func setupAudio() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let engine = audioEngine, let player = playerNode else { return }
        engine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        // Generate tick sound (short sine wave click)
        tickBuffer = generateClick(frequency: 1000, duration: 0.03, amplitude: 0.5, format: format)
        accentBuffer = generateClick(frequency: 1500, duration: 0.04, amplitude: 0.8, format: format)
    }

    private func generateClick(frequency: Double, duration: Double, amplitude: Float, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(1.0 - t / duration) // Linear decay
            data[i] = amplitude * envelope * sin(Float(2.0 * .pi * frequency * t))
        }
        return buffer
    }

    func start() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine?.start()
        } catch {
            return
        }

        isPlaying = true
        currentBeat = 0
        scheduleTick()

        let interval = 60.0 / Double(bpm)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.scheduleTick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        playerNode?.stop()
        audioEngine?.stop()
        isPlaying = false
        currentBeat = 0
    }

    private func restart() {
        if isPlaying {
            stop()
            start()
        }
    }

    private func scheduleTick() {
        guard let player = playerNode else { return }

        let buffer = currentBeat == 0 ? accentBuffer : tickBuffer
        guard let buf = buffer else { return }

        if !player.isPlaying {
            player.play()
        }
        player.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)

        currentBeat = (currentBeat + 1) % beatsPerMeasure
    }

    func tapTempo() {
        let now = Date()
        tapTimes.append(now)

        // Keep only last 5 taps
        if tapTimes.count > 5 {
            tapTimes.removeFirst()
        }

        guard tapTimes.count >= 2 else { return }

        // Reset if gap > 2 seconds
        if let last = tapTimes.dropLast().last, now.timeIntervalSince(last) > 2 {
            tapTimes = [now]
            return
        }

        var intervals: [TimeInterval] = []
        for i in 1..<tapTimes.count {
            intervals.append(tapTimes[i].timeIntervalSince(tapTimes[i - 1]))
        }

        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let newBPM = Int(round(60.0 / avgInterval))
        bpm = max(40, min(220, newBPM))
    }

    deinit {
        stop()
    }
}
