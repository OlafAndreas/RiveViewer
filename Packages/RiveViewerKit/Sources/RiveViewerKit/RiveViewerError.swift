import Foundation

/// Errors raised by RiveViewerKit. Every case has a human-readable description for display in a window or a preview.
public enum RiveViewerError: Error, LocalizedError, Equatable, Sendable {
    case unreadableFile(URL)
    case cannotLoad(String)
    case artboardNotFound(String)
    case stateMachineNotFound(artboard: String, name: String)
    case animationNotFound(artboard: String, name: String)
    case nothingToPlay

    public var errorDescription: String? {
        switch self {
        case .unreadableFile(let url):
            return "Could not read \(url.lastPathComponent)."
        case .cannotLoad(let message):
            return "Could not load Rive file: \(message)"
        case .artboardNotFound(let name):
            return "No artboard named “\(name)”."
        case .stateMachineNotFound(let artboard, let name):
            return "No state machine named “\(name)” in artboard “\(artboard)”."
        case .animationNotFound(let artboard, let name):
            return "No animation named “\(name)” in artboard “\(artboard)”."
        case .nothingToPlay:
            return "This file has no state machines or animations to play."
        }
    }
}
