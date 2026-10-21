import Foundation

/// A named text run found in the file, with the artboard that contains it.
public struct TextRunEntry: Sendable, Equatable, Identifiable {
    public let objectId: Int
    public let name: String
    public let text: String
    public let artboardName: String?

    public var id: Int { objectId }

    public init(objectId: Int, name: String, text: String, artboardName: String?) {
        self.objectId = objectId
        self.name = name
        self.text = text
        self.artboardName = artboardName
    }
}

/// Lists the named text runs in a parsed file; the runtime API has no way to enumerate them.
public enum TextRunCatalog {
    public static let textValueRunTypeKey = 135
    public static let textPropertyKey = 268

    public static func textRuns(in file: RiveBinaryFile) -> [TextRunEntry] {
        var artboardNames: [Int: String] = [:]
        for object in file.objects where object.typeKey == RiveObject.artboardTypeKey {
            artboardNames[object.id] = object.name ?? ""
        }
        return file.objects.compactMap { object in
            guard object.typeKey == textValueRunTypeKey, let name = object.name, !name.isEmpty else { return nil }
            var text = ""
            if case .string(let value)? = object.property(textPropertyKey) { text = value }
            return TextRunEntry(objectId: object.id, name: name, text: text, artboardName: object.scopeId.flatMap { artboardNames[$0] })
        }
    }
}
