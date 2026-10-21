import Foundation
import RiveRuntime

/// Builds a `RiveModel` configured for a `PlaybackSelection`.
public enum PlaybackConfigurator {
    public static func makeModel(file: RiveFile, selection: PlaybackSelection) throws -> RiveModel {
        let model = RiveModel(riveFile: file)
        do {
            try model.setArtboard(selection.artboardName)
        } catch {
            throw RiveViewerError.artboardNotFound(selection.artboardName)
        }
        switch selection {
        case .stateMachine(let artboard, let name):
            do {
                try model.setStateMachine(name)
            } catch {
                throw RiveViewerError.stateMachineNotFound(artboard: artboard, name: name)
            }
        case .animation(let artboard, let name):
            do {
                try model.setAnimation(name)
            } catch {
                throw RiveViewerError.animationNotFound(artboard: artboard, name: name)
            }
        }
        return model
    }
}
