import Foundation
import Testing
@testable import RiveViewerKit

/// Crafted inputs: the reader must throw, never trap.
struct RiveBinaryReaderHostileTests {
    /// "RIVE", version 7.0, file id 0, then `table` (key list + 0 + packed field types), then `body`.
    private static func file(table: [UInt8] = [0], body: [UInt8]) -> Data {
        Data(Array("RIVE".utf8) + [7, 0, 0] + table + body)
    }

    private static func varuint(_ value: UInt64) -> [UInt8] {
        var v = value
        var out: [UInt8] = []
        repeat {
            var byte = UInt8(v & 0x7F)
            v >>= 7
            if v != 0 { byte |= 0x80 }
            out.append(byte)
        } while v != 0
        return out
    }

    @Test func varuintLongerThanTenBytesThrows() {
        var reader = RiveBinaryReader(data: Self.file(body: Array(repeating: 0xFF, count: 11) + [0x01]))
        #expect(throws: RiveBinaryError.self) { try reader.readFile() }
    }

    @Test func varuintBeyondIntRangeThrows() {
        // Artboard object, Component.name (string), length 2^64 - 1.
        var reader = RiveBinaryReader(data: Self.file(body: [1, 4] + Self.varuint(UInt64.max)))
        #expect(throws: RiveBinaryError.self) { try reader.readFile() }
    }

    @Test func lengthNearIntMaxThrowsTruncated() {
        var reader = RiveBinaryReader(data: Self.file(body: [1, 4] + Self.varuint(UInt64(Int.max - 1))))
        #expect(throws: RiveBinaryError.self) { try reader.readFile() }
    }

    @Test func schemaTypeWinsOverAMistypedTableEntry() throws {
        // The table claims key 4 (Component.name) is a uint; the runtime ignores that and reads a string.
        let table: [UInt8] = [4, 0] + [0, 0, 0, 0]
        var reader = RiveBinaryReader(data: Self.file(table: table, body: [1, 4, 3] + Array("abc".utf8) + [0]))
        let file = try reader.readFile()
        #expect(file.objects.first?.name == "abc")
    }
}
