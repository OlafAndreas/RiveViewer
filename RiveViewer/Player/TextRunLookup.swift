import Foundation

/// A text run the user asked about by name (and optional nested-artboard path), with the value last read.
struct TextRunLookup: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var path: String
    var lastValue: String?

    var title: String { path.isEmpty ? name : "\(path)/\(name)" }
}
