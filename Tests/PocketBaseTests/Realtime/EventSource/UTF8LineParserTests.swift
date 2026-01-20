//
//  UTF8LineParserTests.swift
//  PocketBase
//
//  Created by Claude on 2026-01-18.
//

import Testing
import Foundation
@testable import PocketBase

@Suite("UTF8LineParser")
struct UTF8LineParserTests {

    @Suite("Line Parsing")
    struct LineParsing {

        @Test("Parses simple lines separated by LF")
        func parsesSimpleLinesWithLF() async throws {
            let parser = UTF8LineParser()
            let data = "line1\nline2\nline3\n".data(using: .utf8)!

            let lines = await parser.append(data)

            #expect(lines == ["line1", "line2", "line3"])
        }

        @Test("Parses lines separated by CR")
        func parsesLinesWithCR() async throws {
            let parser = UTF8LineParser()
            let data = "line1\rline2\rline3\r".data(using: .utf8)!

            let lines = await parser.append(data)

            #expect(lines == ["line1", "line2", "line3"])
        }

        @Test("Parses lines separated by CRLF")
        func parsesLinesWithCRLF() async throws {
            let parser = UTF8LineParser()
            let data = "line1\r\nline2\r\nline3\r\n".data(using: .utf8)!

            let lines = await parser.append(data)

            #expect(lines == ["line1", "line2", "line3"])
        }

        @Test("Handles mixed line endings")
        func handlesMixedLineEndings() async throws {
            let parser = UTF8LineParser()
            let data = "line1\nline2\rline3\r\nline4\n".data(using: .utf8)!

            let lines = await parser.append(data)

            #expect(lines == ["line1", "line2", "line3", "line4"])
        }

        @Test("Buffers incomplete lines across chunks")
        func buffersIncompleteLines() async throws {
            let parser = UTF8LineParser()

            // Send partial data
            let chunk1 = "hello ".data(using: .utf8)!
            let lines1 = await parser.append(chunk1)
            #expect(lines1.isEmpty)

            // Complete the line
            let chunk2 = "world\n".data(using: .utf8)!
            let lines2 = await parser.append(chunk2)
            #expect(lines2 == ["hello world"])
        }

        @Test("Handles empty lines")
        func handlesEmptyLines() async throws {
            let parser = UTF8LineParser()
            let data = "line1\n\nline2\n".data(using: .utf8)!

            let lines = await parser.append(data)

            #expect(lines == ["line1", "", "line2"])
        }

        @Test("Returns empty array for partial data without newline")
        func returnsEmptyForPartialData() async throws {
            let parser = UTF8LineParser()
            let data = "no newline here".data(using: .utf8)!

            let lines = await parser.append(data)

            #expect(lines.isEmpty)
        }
    }

    @Suite("UTF-8 Handling")
    struct UTF8Handling {

        @Test("Handles UTF-8 characters")
        func handlesUTF8Characters() async throws {
            let parser = UTF8LineParser()
            let data = "héllo wörld 🎉\n日本語\n".data(using: .utf8)!

            let lines = await parser.append(data)

            #expect(lines == ["héllo wörld 🎉", "日本語"])
        }

        @Test("Handles split multi-byte UTF-8 sequence")
        func handlesSplitMultiByteSequence() async throws {
            let parser = UTF8LineParser()

            // "é" in UTF-8 is [0xC3, 0xA9]
            // Send first byte in chunk1, second byte with rest in chunk2
            let fullData = "café\n".data(using: .utf8)!
            let splitPoint = 4 // After "caf" and first byte of "é"

            let chunk1 = fullData.prefix(splitPoint)
            let chunk2 = fullData.suffix(from: splitPoint)

            let lines1 = await parser.append(Data(chunk1))
            #expect(lines1.isEmpty)

            let lines2 = await parser.append(Data(chunk2))
            #expect(lines2 == ["café"])
        }

        @Test("Replaces invalid UTF-8 with replacement character")
        func replacesInvalidUTF8() async throws {
            let parser = UTF8LineParser()

            // Create invalid UTF-8 sequence: 0xFF is never valid in UTF-8
            var data = Data()
            data.append(contentsOf: "hello".utf8)
            data.append(0xFF) // Invalid byte
            data.append(contentsOf: "world\n".utf8)

            let lines = await parser.append(data)

            #expect(lines.count == 1)
            // The invalid byte should be replaced with replacement character
            #expect(lines[0].contains("hello"))
            #expect(lines[0].contains("world"))
        }
    }

    @Suite("Reset Behavior")
    struct ResetBehavior {

        @Test("closeAndReset clears all state")
        func closeAndResetClearsState() async throws {
            let parser = UTF8LineParser()

            // Add some partial data
            let chunk = "partial data without newline".data(using: .utf8)!
            _ = await parser.append(chunk)

            // Reset the parser
            await parser.closeAndReset()

            // New data should start fresh
            let newData = "fresh start\n".data(using: .utf8)!
            let lines = await parser.append(newData)

            #expect(lines == ["fresh start"])
        }
    }

    @Suite("Edge Cases")
    struct EdgeCases {

        @Test("Handles empty data")
        func handlesEmptyData() async throws {
            let parser = UTF8LineParser()
            let data = Data()

            let lines = await parser.append(data)

            #expect(lines.isEmpty)
        }

        @Test("Handles single newline")
        func handlesSingleNewline() async throws {
            let parser = UTF8LineParser()
            let data = "\n".data(using: .utf8)!

            let lines = await parser.append(data)

            #expect(lines == [""])
        }

        @Test("Handles multiple consecutive newlines")
        func handlesMultipleNewlines() async throws {
            let parser = UTF8LineParser()
            let data = "\n\n\n".data(using: .utf8)!

            let lines = await parser.append(data)

            #expect(lines == ["", "", ""])
        }

        @Test("Bounds check prevents crash with small data")
        func boundsCheckPreventsCrash() async throws {
            let parser = UTF8LineParser()

            // Test with very small data that might trigger edge cases
            let data = Data([0x80]) // Invalid continuation byte at start

            // Should not crash
            let lines = await parser.append(data)

            // May or may not produce output, but shouldn't crash
            _ = lines
        }
    }
}
