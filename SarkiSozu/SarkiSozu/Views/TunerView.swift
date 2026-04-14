import SwiftUI
import AVFoundation
import Accelerate

// MARK: - Tuner View

struct TunerView: View {
    @StateObject private var tuner = TunerEngine()
    @State private var selectedTuning = 0

    let tunings: [(String, [(String, Double)])] = [
        ("Standart", [("E2", 82.41), ("A2", 110.0), ("D3", 146.83), ("G3", 196.0), ("B3", 246.94), ("E4", 329.63)]),
        ("Drop D", [("D2", 73.42), ("A2", 110.0), ("D3", 146.83), ("G3", 196.0), ("B3", 246.94), ("E4", 329.63)]),
        ("Open G", [("D2", 73.42), ("G2", 98.0), ("D3", 146.83), ("G3", 196.0), ("B3", 246.94), ("D4", 293.66)]),
        ("Open D", [("D2", 73.42), ("A2", 110.0), ("D3", 146.83), ("F#3", 185.0), ("A3", 220.0), ("D4", 293.66)]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Tuning selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<tunings.count, id: \.self) { i in
                        Button {
                            selectedTuning = i
                        } label: {
                            Text(tunings[i].0)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedTuning == i ? DS.Color.accent : Color(uiColor: .secondarySystemGroupedBackground))
                                .foregroundColor(selectedTuning == i ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, DS.Spacing.s)
            }

            Spacer()

            // Note display
            noteDisplay

            // Cents indicator
            centsIndicator

            Spacer()

            // String buttons
            stringButtons

            // Start/Stop
            controlButton
                .padding(.bottom, DS.Spacing.l)
        }
        .navigationTitle("Akort Aleti")
        .background(Color(uiColor: .systemGroupedBackground))
        .onDisappear {
            tuner.stop()
        }
    }

    // MARK: - Note Display

    private var noteDisplay: some View {
        VStack(spacing: DS.Spacing.s) {
            // Detected note
            Text(tuner.detectedNote)
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(tuner.isInTune ? .green : .primary)
                .animation(.easeInOut(duration: 0.2), value: tuner.detectedNote)

            // Frequency
            Text(String(format: "%.1f Hz", tuner.detectedFrequency))
                .font(.system(size: 17, design: .monospaced))
                .foregroundColor(.secondary)

            // Status text
            if let error = tuner.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else if tuner.isListening {
                if tuner.detectedFrequency > 0 {
                    Text(tuner.isInTune ? "Akortlu!" : tuner.tuningDirection)
                        .font(.headline)
                        .foregroundColor(tuner.isInTune ? .green : .orange)
                } else {
                    Text("Bir tel cal...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Cents Indicator

    private var centsIndicator: some View {
        VStack(spacing: 8) {
            // Gauge
            GeometryReader { geo in
                let width = geo.size.width
                let center = width / 2
                let offset = CGFloat(tuner.cents / 50.0) * (width / 2 - 20)

                ZStack {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .tertiarySystemFill))
                        .frame(height: 8)

                    // Center mark
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 3, height: 20)
                        .position(x: center, y: 10)

                    // Indicator needle
                    if tuner.isListening && tuner.detectedFrequency > 0 {
                        Circle()
                            .fill(tuner.isInTune ? Color.green : Color.orange)
                            .frame(width: 16, height: 16)
                            .shadow(color: (tuner.isInTune ? Color.green : Color.orange).opacity(0.4), radius: 6)
                            .position(x: center + offset, y: 10)
                            .animation(.easeOut(duration: 0.15), value: tuner.cents)
                    }

                    // -50 / +50 markers
                    HStack {
                        Text("-50")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("+50")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .offset(y: 18)
                }
            }
            .frame(height: 36)
            .padding(.horizontal, DS.Spacing.l)
        }
        .padding(.top, DS.Spacing.m)
    }

    // MARK: - String Buttons

    private var stringButtons: some View {
        VStack(spacing: DS.Spacing.xs) {
            Text("Teller")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                let strings = tunings[selectedTuning].1
                ForEach(0..<strings.count, id: \.self) { i in
                    let str = strings[i]
                    let noteName = String(str.0.prefix(while: { !$0.isNumber }))
                    let isClosest = tuner.isListening && tuner.closestString == i

                    VStack(spacing: 4) {
                        Circle()
                            .stroke(isClosest ? Color.green : Color(uiColor: .tertiarySystemFill), lineWidth: isClosest ? 3 : 2)
                            .background(Circle().fill(isClosest ? Color.green.opacity(0.15) : Color.clear))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(noteName)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(isClosest ? .green : .primary)
                            )

                        Text("\(Int(str.1))Hz")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.large)
        .padding(.horizontal, DS.Spacing.l)
        .padding(.bottom, DS.Spacing.m)
    }

    // MARK: - Control

    private var controlButton: some View {
        Button {
            if tuner.isListening {
                tuner.stop()
            } else {
                tuner.start(tuningStrings: tunings[selectedTuning].1)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: tuner.isListening ? "stop.fill" : "mic.fill")
                Text(tuner.isListening ? "Durdur" : "Akort Baslat")
            }
            .font(.title3.bold())
            .foregroundColor(.white)
            .frame(width: 200, height: 56)
            .background(tuner.isListening ? Color.red : DS.Color.accent)
            .cornerRadius(28)
        }
    }
}

// MARK: - Tuner Engine

class TunerEngine: ObservableObject {
    @Published var detectedNote: String = "--"
    @Published var detectedFrequency: Double = 0
    @Published var cents: Double = 0
    @Published var isInTune: Bool = false
    @Published var isListening: Bool = false
    @Published var closestString: Int = -1
    @Published var tuningDirection: String = ""
    @Published var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var tuningStrings: [(String, Double)] = []

    private let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    func start(tuningStrings: [(String, Double)]) {
        self.tuningStrings = tuningStrings
        errorMessage = nil

        #if targetEnvironment(simulator)
        errorMessage = "Akort aleti simulatorde calismaz.\nGercek cihazda deneyin."
        return
        #else
        let session = AVAudioSession.sharedInstance()

        // Check microphone availability
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

        let bufferSize: AVAudioFrameCount = 4096

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processAudio(buffer: buffer)
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
        detectedNote = "--"
        detectedFrequency = 0
        cents = 0
        closestString = -1
    }

    private func processAudio(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        let sampleRate = Float(buffer.format.sampleRate)

        // Check if signal is loud enough
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
        guard rms > 0.01 else {
            DispatchQueue.main.async {
                self.detectedFrequency = 0
                self.detectedNote = "--"
                self.closestString = -1
            }
            return
        }

        // YIN pitch detection
        let frequency = detectPitchYIN(data: channelData, count: frameLength, sampleRate: sampleRate)
        guard frequency > 60 && frequency < 1200 else { return }

        DispatchQueue.main.async {
            self.detectedFrequency = Double(frequency)
            self.updateNoteInfo(frequency: Double(frequency))
        }
    }

    private func detectPitchYIN(data: UnsafePointer<Float>, count: Int, sampleRate: Float) -> Float {
        let maxLag = count / 2
        let threshold: Float = 0.15

        // Step 1: Difference function
        var diff = [Float](repeating: 0, count: maxLag)
        for tau in 1..<maxLag {
            var sum: Float = 0
            for i in 0..<maxLag {
                let d = data[i] - data[i + tau]
                sum += d * d
            }
            diff[tau] = sum
        }

        // Step 2: Cumulative mean normalized difference
        var cmndf = [Float](repeating: 0, count: maxLag)
        cmndf[0] = 1
        var runningSum: Float = 0
        for tau in 1..<maxLag {
            runningSum += diff[tau]
            cmndf[tau] = diff[tau] * Float(tau) / runningSum
        }

        // Step 3: Absolute threshold
        var bestTau = -1
        for tau in 2..<maxLag {
            if cmndf[tau] < threshold {
                // Find local minimum
                while tau + 1 < maxLag && cmndf[tau + 1] < cmndf[tau] {
                    bestTau = tau + 1
                    break
                }
                if bestTau == -1 { bestTau = tau }
                break
            }
        }

        guard bestTau > 0 else { return 0 }

        // Parabolic interpolation
        let s0 = cmndf[max(bestTau - 1, 0)]
        let s1 = cmndf[bestTau]
        let s2 = cmndf[min(bestTau + 1, maxLag - 1)]
        let betterTau = Float(bestTau) + (s2 - s0) / (2 * (2 * s1 - s2 - s0))

        return sampleRate / betterTau
    }

    private func updateNoteInfo(frequency: Double) {
        // Find closest note
        let midiNote = 12 * log2(frequency / 440.0) + 69
        let roundedMidi = round(midiNote)
        let noteIndex = (Int(roundedMidi) % 12 + 12) % 12
        let octave = Int(roundedMidi) / 12 - 1

        detectedNote = noteNames[noteIndex]

        // Calculate cents deviation
        let exactFreq = 440.0 * pow(2.0, (roundedMidi - 69.0) / 12.0)
        cents = 1200 * log2(frequency / exactFreq)
        isInTune = abs(cents) < 5

        // Tuning direction
        if cents > 5 {
            tuningDirection = "Cok yuksek - geves"
        } else if cents < -5 {
            tuningDirection = "Cok dusuk - sik"
        }

        // Find closest tuning string
        if !tuningStrings.isEmpty {
            var minDist = Double.infinity
            var closest = 0
            for (i, str) in tuningStrings.enumerated() {
                let dist = abs(1200 * log2(frequency / str.1))
                if dist < minDist {
                    minDist = dist
                    closest = i
                }
            }
            closestString = closest
        }
    }

    deinit {
        stop()
    }
}
