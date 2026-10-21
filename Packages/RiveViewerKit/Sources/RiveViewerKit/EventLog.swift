import Foundation

/// One line in the inspector's event log.
public struct EventLogEntry: Identifiable, Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case playback(String)
        case stateChange(stateMachine: String, state: String)
        case riveEvent(name: String, type: Int, properties: [String: String])
    }

    public let id: UUID
    /// Seconds into playback when the entry was recorded.
    public let elapsed: Double
    public let kind: Kind

    public init(id: UUID = UUID(), elapsed: Double, kind: Kind) {
        self.id = id
        self.elapsed = elapsed
        self.kind = kind
    }

    public var title: String {
        switch kind {
        case .playback(let name): return name
        case .stateChange(_, let state): return "State → \(state)"
        case .riveEvent(let name, _, _): return name
        }
    }

    /// Event properties as `key: value`, sorted by key; `nil` when there is nothing to show.
    public var detail: String? {
        guard case .riveEvent(_, _, let properties) = kind, !properties.isEmpty else { return nil }
        return properties.keys.sorted().map { "\($0): \(properties[$0] ?? "")" }.joined(separator: ", ")
    }
}

public enum TimeFormatting {
    private static let posix = Locale(identifier: "en_US_POSIX")

    /// `1.25 s` — two decimals, no grouping, independent of the user's locale.
    public static func seconds(_ seconds: Double) -> String {
        let number = seconds.formatted(.number.precision(.fractionLength(2)).grouping(.never).locale(posix))
        return "\(number) s"
    }
}
