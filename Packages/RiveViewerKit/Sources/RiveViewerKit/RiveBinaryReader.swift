import Foundation

public enum RiveBinaryError: Error, Equatable, Sendable {
    case badFingerprint
    case truncated(offset: Int)
    case unknownPropertyKey(Int, offset: Int)
    /// A variable-length integer was longer than 10 bytes or does not fit in an `Int`.
    case overflow(offset: Int)
}

/// One property of a `.riv` object, typed by the file's own property table.
public struct RiveProperty: Sendable, Equatable {
    public enum Value: Sendable, Equatable {
        case uint(UInt64)
        case string(String)
        case double(Float)
        case color(UInt32)
        case bytes(Data)
    }

    public let key: Int
    public let value: Value

    public init(key: Int, value: Value) {
        self.key = key
        self.value = value
    }

    public var name: String { RiveSchema.propertyNames[key] ?? "key \(key)" }

    public var displayValue: String {
        switch value {
        case .uint(let number):
            switch RiveSchema.propertyKinds[key] {
            case "Bool": return number == 0 ? "false" : "true"
            case "Int": return "\(Int32(truncatingIfNeeded: number))"
            default: return "\(number)"
            }
        case .string(let text): return "“\(text)”"
        case .double(let number): return number.formatted(.number.precision(.fractionLength(0...3)).grouping(.never).locale(Locale(identifier: "en_US_POSIX")))
        case .color(let argb): return "#" + String(argb, radix: 16, uppercase: true).leftPadded(to: 8)
        case .bytes(let data): return "\(data.count) bytes"
        }
    }
}

/// One object in a `.riv` file. `id` is the object's ordinal in the file; `localIndex` is its index inside the
/// enclosing artboard (what `parentId` refers to), and `scopeId` is the `id` of that artboard, or `nil` for
/// file-level objects.
public struct RiveObject: Sendable, Equatable, Identifiable {
    public static let artboardTypeKey = 1
    public static let namePropertyKey = 4
    public static let parentIdPropertyKey = 5

    public let id: Int
    public let typeKey: Int
    public let localIndex: Int
    public let scopeId: Int?
    public let properties: [RiveProperty]

    public init(id: Int, typeKey: Int, localIndex: Int, scopeId: Int?, properties: [RiveProperty]) {
        self.id = id
        self.typeKey = typeKey
        self.localIndex = localIndex
        self.scopeId = scopeId
        self.properties = properties
    }

    public var typeName: String { RiveSchema.typeNames[typeKey] ?? "type \(typeKey)" }

    /// The object's name: the first string property the schema calls `…name` (components, animations and view models keep it under different keys).
    public var name: String? {
        for property in properties {
            if case .string(let text) = property.value, property.name.hasSuffix(".name") { return text }
        }
        return nil
    }

    public var parentId: Int? {
        if case .uint(let index)? = property(Self.parentIdPropertyKey) { return Int(index) }
        return nil
    }

    public func property(_ key: Int) -> RiveProperty.Value? {
        properties.first { $0.key == key }?.value
    }
}

public struct RiveBinaryFile: Sendable, Equatable {
    public let majorVersion: Int
    public let minorVersion: Int
    public let fileId: UInt64
    /// Property key → field type (0 uint, 1 string, 2 double, 3 color), as written in the file's header.
    public let fieldTypes: [Int: Int]
    public let objects: [RiveObject]
}

/// Parses the `.riv` container format: header, property table, then a flat list of typed objects.
public struct RiveBinaryReader {
    private let data: Data
    private var offset = 0

    public init(data: Data) {
        self.data = data
    }

    public mutating func readFile() throws -> RiveBinaryFile {
        offset = 0
        guard data.count >= 4, data[data.startIndex..<data.startIndex + 4].elementsEqual("RIVE".utf8) else {
            throw RiveBinaryError.badFingerprint
        }
        offset = 4
        let major = try readInt()
        let minor = try readInt()
        let fileId = try readVarUint()

        var keys: [Int] = []
        while true {
            let key = try readInt()
            if key == 0 { break }
            keys.append(key)
        }
        var fieldTypes: [Int: Int] = [:]
        var currentWord: UInt32 = 0
        var currentBit = 8
        for key in keys {
            if currentBit == 8 {
                currentWord = try readUInt32()
                currentBit = 0
            }
            fieldTypes[key] = Int((currentWord >> UInt32(currentBit)) & 3)
            currentBit += 2
        }

        var objects: [RiveObject] = []
        var scopeId: Int?
        var localIndex = 0
        while offset < data.count {
            let typeKey = try readInt()
            var properties: [RiveProperty] = []
            while true {
                let keyOffset = offset
                let key = try readInt()
                if key == 0 { break }
                guard let fieldType = RiveSchema.fieldType(forPropertyKey: key) ?? fieldTypes[key] else {
                    throw RiveBinaryError.unknownPropertyKey(key, offset: keyOffset)
                }
                properties.append(RiveProperty(key: key, value: try readValue(fieldType: fieldType)))
            }
            let id = objects.count
            if typeKey == RiveObject.artboardTypeKey {
                scopeId = id
                localIndex = 0
            }
            objects.append(RiveObject(id: id, typeKey: typeKey, localIndex: localIndex, scopeId: scopeId, properties: properties))
            localIndex += 1
        }
        return RiveBinaryFile(majorVersion: major, minorVersion: minor, fileId: fileId, fieldTypes: fieldTypes, objects: objects)
    }

    // MARK: Primitives

    private mutating func readValue(fieldType: Int) throws -> RiveProperty.Value {
        switch fieldType {
        case 0: return .uint(try readVarUint())
        case 1:
            let bytes = try readBytes(count: try readInt())
            if let text = String(data: bytes, encoding: .utf8) { return .string(text) }
            return .bytes(bytes)
        case 2: return .double(Float(bitPattern: try readUInt32()))
        default: return .color(try readUInt32())
        }
    }

    private mutating func readByte() throws -> UInt8 {
        guard offset < data.count else { throw RiveBinaryError.truncated(offset: offset) }
        let byte = data[data.startIndex + offset]
        offset += 1
        return byte
    }

    private mutating func readVarUint() throws -> UInt64 {
        let start = offset
        var result: UInt64 = 0
        for index in 0..<10 {
            let byte = try readByte()
            result |= UInt64(byte & 0x7F) << UInt64(index * 7)
            if byte & 0x80 == 0 { return result }
        }
        throw RiveBinaryError.overflow(offset: start)
    }

    private mutating func readInt() throws -> Int {
        let start = offset
        guard let value = Int(exactly: try readVarUint()) else { throw RiveBinaryError.overflow(offset: start) }
        return value
    }

    private mutating func readUInt32() throws -> UInt32 {
        let bytes = try readBytes(count: 4)
        return bytes.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self).littleEndian }
    }

    private mutating func readBytes(count: Int) throws -> Data {
        guard count >= 0, count <= data.count - offset else { throw RiveBinaryError.truncated(offset: offset) }
        let start = data.startIndex + offset
        offset += count
        return Data(data[start..<start + count])
    }
}

private extension String {
    func leftPadded(to width: Int) -> String {
        count >= width ? self : String(repeating: "0", count: width - count) + self
    }
}

extension RiveSchema {
    /// Field type (0 uint, 1 string, 2 double, 3 color) implied by the runtime's storage kind for a property key.
    public static func fieldType(forPropertyKey key: Int) -> Int? {
        switch propertyKinds[key] {
        case "Uint", "Bool", "Int", "Id": return 0
        case "String", "Bytes": return 1
        case "Double": return 2
        case "Color": return 3
        default: return nil
        }
    }
}
