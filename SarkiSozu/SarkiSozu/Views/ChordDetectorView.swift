import SwiftUI
import AVFoundation
import Accelerate

// MARK: - Live Chord Detection View

struct ChordDetectorView: View {
    @StateObject private var detector = ChordDetectionEngine()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Detected chord
            chordDisplay

            // Confidence meter
            confidenceMeter

            Spacer()

            // Recent chords
            recentChordsSection

            // Control
            controlButton
                .padding(.bottom, DS.Spacing.l)
        }
        .navigationTitle("Akor Tespiti")
        .background(Color(uiColor: .systemGroupedBackground))
        .onDisappear {
            detector.stop()
        }
    }

    // MARK: - Chord Display

    private var chordDisplay: some View {
        VStack(spacing: DS.Spacing.m) {
            // Main chord name
            ZStack {
                Circle()
                    .stroke(detector.isListening ? DS.Color.accent.opacity(0.3) : Color(uiColor: .tertiarySystemFill), lineWidth: 4)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: detector.confidence)
                    .stroke(DS.Color.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.3), value: detector.confidence)

                VStack(spacing: 4) {
                    Text(detector.detectedChord)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(detector.detectedChord == "?" ? .secondary : .primary)
                        .animation(.easeInOut(duration: 0.15), value: detector.detectedChord)

                    if detector.chordType.isEmpty == false {
                        Text(detector.chordType)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Status
            if let error = detector.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else if detector.isListening {
                if detector.detectedChord == "?" {
                    Text("Gitar cal, akoru tanisin...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Tespit edilen notalar: \(detector.detectedNotes)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Mikrofonu baslatip gitar cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Confidence Meter

    private var confidenceMeter: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Guven")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(detector.confidence * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(detector.confidence > 0.7 ? .green : .orange)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .tertiarySystemFill))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(detector.confidence > 0.7 ? Color.green : Color.orange)
                        .frame(width: geo.size.width * detector.confidence)
                        .animation(.easeOut(duration: 0.2), value: detector.confidence)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.top, DS.Spacing.m)
    }

    // MARK: - Recent Chords

    private var recentChordsSection: some View {
        VStack(spacing: DS.Spacing.xs) {
            if !detector.recentChords.isEmpty {
                Text("Son Tespit Edilenler")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(detector.recentChords, id: \.self) { chord in
                            Text(chord)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(minWidth: 44, minHeight: 44)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(DS.CornerRadius.small)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)
                }
            }
        }
        .padding(.bottom, DS.Spacing.m)
    }

    // MARK: - Control

    private var controlButton: some View {
        Button {
            if detector.isListening {
                detector.stop()
            } else {
                detector.start()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: detector.isListening ? "stop.fill" : "mic.fill")
                Text(detector.isListening ? "Durdur" : "Dinlemeye Basla")
            }
            .font(.title3.bold())
            .foregroundColor(.white)
            .frame(width: 220, height: 56)
            .background(detector.isListening ? Color.red : DS.Color.accent)
            .cornerRadius(28)
        }
    }
}

// MARK: - Chord Detection Engine

class ChordDetectionEngine: ObservableObject {
    @Published var detectedChord: String = "?"
    @Published var chordType: String = ""
    @Published var detectedNotes: String = ""
    @Published var confidence: Double = 0
    @Published var isListening: Bool = false
    @Published var recentChords: [String] = []
    @Published var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    // Common guitar chord templates: (chord name, type label, intervals from root as semitone set)
    private let chordTemplates: [(String, String, Set<Int>)] = [
        // Major
        ("C", "Majör", [0, 4, 7]),
        ("D", "Majör", [0, 4, 7]),
        ("E", "Majör", [0, 4, 7]),
        ("F", "Majör", [0, 4, 7]),
        ("G", "Majör", [0, 4, 7]),
        ("A", "Majör", [0, 4, 7]),
        ("B", "Majör", [0, 4, 7]),
        // Minor
        ("Cm", "Minör", [0, 3, 7]),
        ("Dm", "Minör", [0, 3, 7]),
        ("Em", "Minör", [0, 3, 7]),
        ("Fm", "Minör", [0, 3, 7]),
        ("Gm", "Minör", [0, 3, 7]),
        ("Am", "Minör", [0, 3, 7]),
        ("Bm", "Minör", [0, 3, 7]),
        // 7th
        ("C7", "Yedili", [0, 4, 7, 10]),
        ("D7", "Yedili", [0, 4, 7, 10]),
        ("E7", "Yedili", [0, 4, 7, 10]),
        ("A7", "Yedili", [0, 4, 7, 10]),
        ("B7", "Yedili", [0, 4, 7, 10]),
        ("G7", "Yedili", [0, 4, 7, 10]),
    ]

    func start() {
        errorMessage = nil

        #if targetEnvironment(simulator)
        errorMessage = "Akor tespiti simulatorde calismaz.\nGercek cihazda deneyin."
        return
        #else
        let session = AVAudioSession.sharedInstance()

        guard let inputs = session.availableInputs, !inputs.isEmpty else {
            errorMessage = "Mikrofon bulunamadi."
            return
        }

        do {
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch {
            errorMessage = "Mikrofon erisimi saglanamadi."
            return
        }

        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.channelCount > 0 else {
            errorMessage = "Mikrofon formati desteklenmiyor."
            return
        }

        let bufferSize: AVAudioFrameCount = 8192

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        do {
            try engine.start()
            isListening = true
        } catch {
            errorMessage = "Ses motoru baslatilamadi."
            audioEngine = nil
        }
        #endif
    }

    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isListening = false
        detectedChord = "?"
        chordType = ""
        confidence = 0
        detectedNotes = ""
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        let sampleRate = Float(buffer.format.sampleRate)

        // Check RMS
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
        guard rms > 0.015 else {
            DispatchQueue.main.async {
                self.detectedChord = "?"
                self.chordType = ""
                self.confidence = 0
                self.detectedNotes = ""
            }
            return
        }

        // FFT to find prominent frequencies
        let notes = detectNotes(data: channelData, count: frameLength, sampleRate: sampleRate)
        guard notes.count >= 2 else { return }

        // Match against chord templates
        let (chord, type, conf) = matchChord(notes: notes)

        DispatchQueue.main.async {
            if conf > 0.4 {
                let fullChord = chord
                if self.detectedChord != fullChord {
                    self.detectedChord = fullChord
                    self.chordType = type

                    // Add to recent (avoid duplicates in sequence)
                    if self.recentChords.first != fullChord {
                        self.recentChords.insert(fullChord, at: 0)
                        if self.recentChords.count > 12 {
                            self.recentChords.removeLast()
                        }
                    }
                }
                self.confidence = conf
                self.detectedNotes = notes.map { self.noteNames[$0 % 12] }.joined(separator: " ")
            }
        }
    }

    private func detectNotes(data: UnsafePointer<Float>, count: Int, sampleRate: Float) -> [Int] {
        // Use FFT
        let log2n = vDSP_Length(log2(Float(count)))
        let fftSize = Int(1 << log2n)
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return [] }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        var realPart = [Float](repeating: 0, count: fftSize / 2)
        var imagPart = [Float](repeating: 0, count: fftSize / 2)

        // Apply Hann window
        var windowedData = [Float](repeating: 0, count: fftSize)
        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(data, 1, window, 1, &windowedData, 1, vDSP_Length(fftSize))

        windowedData.withUnsafeMutableBufferPointer { dataPtr in
            realPart.withUnsafeMutableBufferPointer { realPtr in
                imagPart.withUnsafeMutableBufferPointer { imagPtr in
                    var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                    dataPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
                    }
                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))
                }
            }
        }

        // Calculate magnitudes
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)
        realPart.withUnsafeMutableBufferPointer { realPtr in
            imagPart.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
            }
        }

        // Find peaks - convert to note chroma
        let freqResolution = sampleRate / Float(fftSize)
        var chromaEnergy = [Float](repeating: 0, count: 12)

        // Consider guitar range: ~80Hz to ~1200Hz
        let minBin = Int(80.0 / freqResolution)
        let maxBin = min(Int(1200.0 / freqResolution), fftSize / 2 - 1)

        for bin in minBin...maxBin {
            let freq = Float(bin) * freqResolution
            if freq < 60 { continue }
            let midiNote = 12 * log2(freq / 440.0) + 69
            let chromaIndex = (Int(round(midiNote)) % 12 + 12) % 12
            chromaEnergy[chromaIndex] += magnitudes[bin]
        }

        // Normalize
        let maxEnergy = chromaEnergy.max() ?? 1
        guard maxEnergy > 0 else { return [] }
        chromaEnergy = chromaEnergy.map { $0 / maxEnergy }

        // Pick notes above threshold
        var detectedNotes: [Int] = []
        for i in 0..<12 {
            if chromaEnergy[i] > 0.25 {
                detectedNotes.append(i)
            }
        }

        return detectedNotes.sorted()
    }

    private func matchChord(notes: [Int]) -> (String, String, Double) {
        let noteSet = Set(notes)
        var bestMatch = ("?", "", 0.0)

        for root in 0..<12 {
            // Check major
            let majorIntervals: Set<Int> = [0, 4, 7]
            let majorNotes = Set(majorIntervals.map { (root + $0) % 12 })
            let majorScore = Double(noteSet.intersection(majorNotes).count) / Double(majorNotes.count)
            let majorPenalty = Double(noteSet.subtracting(majorNotes).count) * 0.15
            let majorConf = max(0, majorScore - majorPenalty)

            if majorConf > bestMatch.2 {
                bestMatch = (noteNames[root], "Majör", majorConf)
            }

            // Check minor
            let minorIntervals: Set<Int> = [0, 3, 7]
            let minorNotes = Set(minorIntervals.map { (root + $0) % 12 })
            let minorScore = Double(noteSet.intersection(minorNotes).count) / Double(minorNotes.count)
            let minorPenalty = Double(noteSet.subtracting(minorNotes).count) * 0.15
            let minorConf = max(0, minorScore - minorPenalty)

            if minorConf > bestMatch.2 {
                bestMatch = (noteNames[root] + "m", "Minör", minorConf)
            }

            // Check 7th
            let dom7Intervals: Set<Int> = [0, 4, 7, 10]
            let dom7Notes = Set(dom7Intervals.map { (root + $0) % 12 })
            let dom7Score = Double(noteSet.intersection(dom7Notes).count) / Double(dom7Notes.count)
            let dom7Penalty = Double(noteSet.subtracting(dom7Notes).count) * 0.1
            let dom7Conf = max(0, dom7Score - dom7Penalty)

            if dom7Conf > bestMatch.2 {
                bestMatch = (noteNames[root] + "7", "Yedili", dom7Conf)
            }
        }

        return bestMatch
    }

    deinit {
        stop()
    }
}
