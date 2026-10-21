import Foundation

/// What the player shows: one artboard plus either a state machine or a timeline animation.
public enum PlaybackSelection: Sendable, Hashable {
    case stateMachine(artboard: String, name: String)
    case animation(artboard: String, name: String)

    public var artboardName: String {
        switch self {
        case .stateMachine(let artboard, _), .animation(let artboard, _): return artboard
        }
    }

    public var itemName: String {
        switch self {
        case .stateMachine(_, let name), .animation(_, let name): return name
        }
    }

    public var isStateMachine: Bool {
        if case .stateMachine = self { return true }
        return false
    }

    public func exists(in summary: RiveFileSummary) -> Bool {
        guard let artboard = summary.artboard(named: artboardName) else { return false }
        switch self {
        case .stateMachine(_, let name): return artboard.stateMachine(named: name) != nil
        case .animation(_, let name): return artboard.animation(named: name) != nil
        }
    }
}

/// Rules for what to play when nobody has chosen yet, shared by the app and the Quick Look preview.
public enum DefaultPlayback {
    /// First artboard with a state machine (its default one, else its first), otherwise the first artboard
    /// with animations (its longest), otherwise `nil`.
    public static func selection(for summary: RiveFileSummary) -> PlaybackSelection? {
        if let artboard = summary.artboards.first(where: { !$0.stateMachines.isEmpty }) {
            let name = artboard.defaultStateMachineName.flatMap { artboard.stateMachine(named: $0)?.name }
                ?? artboard.stateMachines[0].name
            return .stateMachine(artboard: artboard.name, name: name)
        }
        if let artboard = summary.artboards.first(where: { !$0.animations.isEmpty }),
           let animation = fallbackAnimation(for: artboard) {
            return .animation(artboard: artboard.name, name: animation)
        }
        return nil
    }

    /// The animation with the longest effective duration; ties keep the earlier one.
    public static func fallbackAnimation(for artboard: ArtboardSummary) -> String? {
        var best: AnimationSummary?
        for animation in artboard.animations where best == nil || animation.effectiveDurationSeconds > best!.effectiveDurationSeconds {
            best = animation
        }
        return best?.name
    }

    /// Keeps `selection` when the file still contains it, otherwise picks the default.
    public static func reconcile(_ selection: PlaybackSelection?, in summary: RiveFileSummary) -> PlaybackSelection? {
        if let selection, selection.exists(in: summary) { return selection }
        return self.selection(for: summary)
    }
}
