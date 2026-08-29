import XCTest
@testable import SarkiSozu

final class MusicTheoryTests: XCTestCase {

    // MARK: - transposeChord: identity & wrap-around

    func testZeroSemitonesReturnsSameChord() {
        XCTAssertEqual(MusicTheory.transposeChord("Am", semitones: 0), "Am")
        XCTAssertEqual(MusicTheory.transposeChord("F#m7", semitones: 0), "F#m7")
    }

    func testTwelveSemitonesReturnsSameRoot() {
        XCTAssertEqual(MusicTheory.transposeChord("C", semitones: 12), "C")
        XCTAssertEqual(MusicTheory.transposeChord("Am", semitones: -12), "Am")
    }

    func testTwentyFourSemitonesReturnsSameRoot() {
        XCTAssertEqual(MusicTheory.transposeChord("G", semitones: 24), "G")
    }

    // MARK: - transposeChord: basic shifts

    func testTransposeUpOneSemitone() {
        XCTAssertEqual(MusicTheory.transposeChord("C", semitones: 1), "C#")
        XCTAssertEqual(MusicTheory.transposeChord("E", semitones: 1), "F")
        XCTAssertEqual(MusicTheory.transposeChord("B", semitones: 1), "C")
    }

    func testTransposeDownOneSemitone() {
        XCTAssertEqual(MusicTheory.transposeChord("C", semitones: -1), "B")
        XCTAssertEqual(MusicTheory.transposeChord("F", semitones: -1), "E")
    }

    func testTransposePreservesQuality() {
        XCTAssertEqual(MusicTheory.transposeChord("Am", semitones: 2), "Bm")
        XCTAssertEqual(MusicTheory.transposeChord("Cmaj7", semitones: 2), "Dmaj7")
        XCTAssertEqual(MusicTheory.transposeChord("G7", semitones: 5), "C7")
        XCTAssertEqual(MusicTheory.transposeChord("Dsus4", semitones: 2), "Esus4")
    }

    // MARK: - transposeChord: flat normalization

    func testFlatNormalizedToSharp() {
        // Bb (=A#) up 1 → B
        XCTAssertEqual(MusicTheory.transposeChord("Bb", semitones: 1), "B")
        // Eb (=D#) up 2 → F
        XCTAssertEqual(MusicTheory.transposeChord("Eb", semitones: 2), "F")
        // Ab (=G#) down 1 → G
        XCTAssertEqual(MusicTheory.transposeChord("Ab", semitones: -1), "G")
    }

    func testFlatNormalizedPreservesSuffix() {
        XCTAssertEqual(MusicTheory.transposeChord("Bbm7", semitones: 2), "Cm7")
    }

    // MARK: - transposeChord: invalid input

    func testNonChordReturnedUnchanged() {
        XCTAssertEqual(MusicTheory.transposeChord("xyz", semitones: 3), "xyz")
        XCTAssertEqual(MusicTheory.transposeChord("", semitones: 3), "")
    }

    // MARK: - transposeLine

    func testTransposeLineEmpty() {
        XCTAssertEqual(MusicTheory.transposeLine("", semitones: 2), "")
    }

    func testTransposeLineNoChords() {
        XCTAssertEqual(MusicTheory.transposeLine("hello world", semitones: 2), "hello world")
    }

    func testTransposeLineZeroSemitones() {
        let line = "Am      G       C"
        XCTAssertEqual(MusicTheory.transposeLine(line, semitones: 0), line)
    }

    func testTransposeLineBasicShift() {
        let result = MusicTheory.transposeLine("Am G C", semitones: 2)
        XCTAssertEqual(result, "Bm A D")
    }

    func testTransposeLinePreservesAlignmentSameLength() {
        // All chord lengths stay equal → alignment stays equal
        let input = "Am      G       C"
        let result = MusicTheory.transposeLine(input, semitones: 2)
        XCTAssertEqual(result, "Bm      A       D")
    }

    func testTransposeLineHandlesChordLengthGrowth() {
        // C → C# adds a char; second chord should not start before its original column
        let input = "C       G"
        let result = MusicTheory.transposeLine(input, semitones: 1)
        // Original "G" is at column 8. "C#" is 2 chars, then we need to reach col 8.
        XCTAssertEqual(result, "C#      G#")
    }

    func testTransposeLineMultipleChordsKeepsOrder() {
        let input = "C  D  E  F  G"
        let result = MusicTheory.transposeLine(input, semitones: 2)
        // C→D, D→E, E→F#, F→G, G→A
        let chords = result.split(separator: " ").filter { !$0.isEmpty }
        XCTAssertEqual(chords.map(String.init), ["D", "E", "F#", "G", "A"])
    }
}
