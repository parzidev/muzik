import Foundation
import PDFKit
import UIKit

/// Generates exportable files (PDF, ChordPro, plain text) from a song.
enum ExportService {

    // MARK: - Plain Text

    /// Plain-text representation with chord lines above lyrics.
    static func plainText(from song: Song, blocks: [RenderBlock], currentKey: String?) -> String {
        var out = ""
        out += "\(song.sarkiadi)\n"
        out += "\(song.sanatci)\n"
        if let key = currentKey, !key.isEmpty {
            out += "Ton: \(key)"
            if let capo = song.kapo, capo != "0" {
                out += " | Kapo: \(capo)"
            }
            out += "\n"
        }
        out += String(repeating: "─", count: 40) + "\n\n"

        for block in blocks {
            switch block.type {
            case .block:
                if let chords = block.chords, !chords.isEmpty {
                    out += chords + "\n"
                }
                if let lyrics = block.lyrics, !lyrics.isEmpty {
                    out += lyrics + "\n"
                }
            case .chords:
                if let c = block.content ?? block.chords, !c.isEmpty {
                    out += c + "\n"
                }
            case .lyrics:
                if let l = block.content ?? block.lyrics, !l.isEmpty {
                    out += l + "\n"
                }
            case .meta:
                if let m = block.content, !m.isEmpty {
                    out += "\n[\(m)]\n"
                }
            case .spacer, .empty:
                out += "\n"
            }
        }
        out += "\n\n—\nSarkiSozU ile dışa aktarıldı"
        return out
    }

    // MARK: - ChordPro

    /// Basic ChordPro format: `[Chord]Lyric`.
    static func chordPro(from song: Song, blocks: [RenderBlock], currentKey: String?) -> String {
        var out = ""
        out += "{title: \(song.sarkiadi)}\n"
        out += "{artist: \(song.sanatci)}\n"
        if let key = currentKey, !key.isEmpty {
            out += "{key: \(key)}\n"
        }
        if let capo = song.kapo, capo != "0" {
            out += "{capo: \(capo)}\n"
        }
        out += "\n"

        for block in blocks {
            switch block.type {
            case .block:
                let merged = mergeChordLyricLine(chords: block.chords ?? "", lyrics: block.lyrics ?? "")
                out += merged + "\n"
            case .chords:
                if let c = block.content ?? block.chords, !c.isEmpty {
                    // chord-only line: emit as inline chords
                    let chords = c.split(separator: " ").filter { !$0.isEmpty }
                    out += chords.map { "[\($0)]" }.joined(separator: " ") + "\n"
                }
            case .lyrics:
                if let l = block.content ?? block.lyrics {
                    out += l + "\n"
                }
            case .meta:
                if let m = block.content {
                    out += "\n{comment: \(m)}\n"
                }
            case .spacer, .empty:
                out += "\n"
            }
        }
        return out
    }

    /// Merges a chord line + lyric line into ChordPro inline format.
    /// Chord positions are detected by column index in the chord line.
    private static func mergeChordLyricLine(chords: String, lyrics: String) -> String {
        guard !chords.isEmpty else { return lyrics }
        if lyrics.isEmpty {
            // chords only
            let trimmed = chords.split(separator: " ").filter { !$0.isEmpty }
            return trimmed.map { "[\($0)]" }.joined(separator: " ")
        }

        let chordChars = Array(chords)
        let lyricChars = Array(lyrics)
        let maxLen = max(chordChars.count, lyricChars.count)

        // Find chord tokens with column indices
        var chordTokens: [(col: Int, chord: String)] = []
        var i = 0
        while i < chordChars.count {
            if chordChars[i] != " " {
                var tok = ""
                let start = i
                while i < chordChars.count && chordChars[i] != " " {
                    tok += String(chordChars[i])
                    i += 1
                }
                chordTokens.append((start, tok))
            } else {
                i += 1
            }
        }

        var result = ""
        var col = 0
        var tokenIdx = 0
        while col < maxLen {
            // insert chord(s) at this column
            while tokenIdx < chordTokens.count && chordTokens[tokenIdx].col == col {
                result += "[\(chordTokens[tokenIdx].chord)]"
                tokenIdx += 1
            }
            if col < lyricChars.count {
                result += String(lyricChars[col])
            } else if tokenIdx < chordTokens.count {
                // lyric ended but chords remain — pad with spaces so remaining chords emit
                result += " "
            }
            col += 1
        }
        // Any trailing chords
        while tokenIdx < chordTokens.count {
            result += "[\(chordTokens[tokenIdx].chord)]"
            tokenIdx += 1
        }
        return result
    }

    // MARK: - PDF

    /// Generates a multi-page PDF with the song's chords + lyrics.
    static func pdf(from song: Song, blocks: [RenderBlock], currentKey: String?) -> Data {
        let pageWidth: CGFloat = 595.2   // A4 @ 72dpi
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 48
        let contentWidth = pageWidth - margin * 2

        let format = UIGraphicsPDFRendererFormat()
        let metaData: [CFString: Any] = [
            kCGPDFContextTitle: "\(song.sarkiadi) — \(song.sanatci)",
            kCGPDFContextAuthor: song.sanatci,
            kCGPDFContextCreator: "SarkiSozU"
        ]
        format.documentInfo = metaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.label
        ]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let metaAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let chordAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor(red: 0.357, green: 0.373, blue: 0.780, alpha: 1.0) // DS.accent
        ]
        let lyricAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.label
        ]
        let sectionAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor(red: 0.357, green: 0.373, blue: 0.780, alpha: 1.0)
        ]
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.tertiaryLabel
        ]

        let lineHeight: CGFloat = 15
        let sectionSpacing: CGFloat = 10

        return renderer.pdfData { ctx in
            var y: CGFloat = margin
            var pageNum = 1
            ctx.beginPage()

            // Title
            let titleStr = NSAttributedString(string: song.sarkiadi, attributes: titleAttrs)
            titleStr.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 24))
            y += 26

            let artistStr = NSAttributedString(string: song.sanatci, attributes: subtitleAttrs)
            artistStr.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 18))
            y += 22

            var metaParts: [String] = []
            if let key = currentKey, !key.isEmpty { metaParts.append("Ton: \(key)") }
            if let capo = song.kapo, capo != "0" { metaParts.append("Kapo: \(capo)") }
            if !metaParts.isEmpty {
                let meta = NSAttributedString(string: metaParts.joined(separator: "  ·  "), attributes: metaAttrs)
                meta.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 14))
                y += 18
            }

            // Divider
            UIColor.separator.setStroke()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: y))
            path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            path.lineWidth = 0.5
            path.stroke()
            y += 14

            func checkPageBreak(_ needed: CGFloat) {
                if y + needed > pageHeight - margin - 20 {
                    // footer
                    let footer = NSAttributedString(string: "SarkiSozU · Sayfa \(pageNum)", attributes: footerAttrs)
                    footer.draw(at: CGPoint(x: margin, y: pageHeight - margin))
                    ctx.beginPage()
                    pageNum += 1
                    y = margin
                }
            }

            // Body
            for block in blocks {
                switch block.type {
                case .block:
                    if let chords = block.chords, !chords.isEmpty {
                        checkPageBreak(lineHeight * 2)
                        NSAttributedString(string: chords, attributes: chordAttrs).draw(
                            in: CGRect(x: margin, y: y, width: contentWidth, height: lineHeight)
                        )
                        y += lineHeight
                    }
                    if let lyrics = block.lyrics, !lyrics.isEmpty {
                        checkPageBreak(lineHeight)
                        NSAttributedString(string: lyrics, attributes: lyricAttrs).draw(
                            in: CGRect(x: margin, y: y, width: contentWidth, height: lineHeight)
                        )
                        y += lineHeight
                    }
                case .chords:
                    if let c = block.content ?? block.chords, !c.isEmpty {
                        checkPageBreak(lineHeight)
                        NSAttributedString(string: c, attributes: chordAttrs).draw(
                            in: CGRect(x: margin, y: y, width: contentWidth, height: lineHeight)
                        )
                        y += lineHeight
                    }
                case .lyrics:
                    if let l = block.content ?? block.lyrics, !l.isEmpty {
                        checkPageBreak(lineHeight)
                        NSAttributedString(string: l, attributes: lyricAttrs).draw(
                            in: CGRect(x: margin, y: y, width: contentWidth, height: lineHeight)
                        )
                        y += lineHeight
                    }
                case .meta:
                    if let m = block.content, !m.isEmpty {
                        checkPageBreak(sectionSpacing + lineHeight)
                        y += sectionSpacing / 2
                        NSAttributedString(string: m, attributes: sectionAttrs).draw(
                            in: CGRect(x: margin, y: y, width: contentWidth, height: lineHeight)
                        )
                        y += lineHeight + 2
                    }
                case .spacer, .empty:
                    y += sectionSpacing
                }
            }

            // Final footer
            let footer = NSAttributedString(string: "SarkiSozU · Sayfa \(pageNum)", attributes: footerAttrs)
            footer.draw(at: CGPoint(x: margin, y: pageHeight - margin))
        }
    }

    // MARK: - File writing

    /// Writes data to a temp file suitable for share sheet. Returns the URL.
    static func writeToTemp(data: Data, filename: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
        let safeName = filename.replacingOccurrences(of: "/", with: "_")
        let url = dir.appendingPathComponent(safeName)
        try? FileManager.default.removeItem(at: url)
        try data.write(to: url)
        return url
    }

    static func writeToTemp(string: String, filename: String) throws -> URL {
        guard let data = string.data(using: .utf8) else {
            throw NSError(domain: "ExportService", code: 1)
        }
        return try writeToTemp(data: data, filename: filename)
    }

    /// Safe filename from song.
    static func filename(for song: Song, ext: String) -> String {
        let base = "\(song.sanatci) - \(song.sarkiadi)"
        let safe = base.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return "\(safe).\(ext)"
    }
}
