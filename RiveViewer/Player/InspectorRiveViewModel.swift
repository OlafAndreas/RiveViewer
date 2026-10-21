import Foundation
import RiveRuntime
import RiveViewerKit

/// A `RiveViewModel` that reports playback, frame advances, state changes and Rive events to the player controller.
/// The runtime delivers every callback on the main thread; the nonisolated overrides hop back onto the main actor.
/// `@unchecked Sendable` is sound because every stored property is main-actor isolated.
@MainActor
final class InspectorRiveViewModel: RiveViewModel, @unchecked Sendable {
    var onPlayback: ((EventLogEntry.Kind) -> Void)?
    var onAdvance: ((Double) -> Void)?
    var onStateChange: ((_ stateMachine: String, _ state: String) -> Void)?
    var onRiveEvent: ((_ name: String, _ type: Int, _ properties: [String: String]) -> Void)?

    nonisolated override func createRiveView() -> RiveView {
        let view = super.createRiveView()
        MainActor.assumeIsolated {
            view.stateMachineDelegate = self
            view.playerDelegate = self
        }
        return view
    }

    nonisolated override func setView(_ view: RiveView) {
        super.setView(view)
        MainActor.assumeIsolated {
            view.stateMachineDelegate = self
            view.playerDelegate = self
        }
    }

    // MARK: RivePlayerDelegate

    nonisolated override func player(playedWithModel riveModel: RiveModel?) {
        super.player(playedWithModel: riveModel)
        MainActor.assumeIsolated { onPlayback?(.playback("Play")) }
    }

    nonisolated override func player(pausedWithModel riveModel: RiveModel?) {
        super.player(pausedWithModel: riveModel)
        MainActor.assumeIsolated { onPlayback?(.playback("Pause")) }
    }

    nonisolated override func player(loopedWithModel riveModel: RiveModel?, type: Int) {
        super.player(loopedWithModel: riveModel, type: type)
        MainActor.assumeIsolated { onPlayback?(.playback("Loop")) }
    }

    nonisolated override func player(stoppedWithModel riveModel: RiveModel?) {
        super.player(stoppedWithModel: riveModel)
        MainActor.assumeIsolated { onPlayback?(.playback("Stop")) }
    }

    nonisolated override func player(didAdvanceby seconds: Double, riveModel: RiveModel?) {
        super.player(didAdvanceby: seconds, riveModel: riveModel)
        MainActor.assumeIsolated { onAdvance?(seconds) }
    }

    // MARK: RiveStateMachineDelegate

    @objc nonisolated func stateMachine(_ stateMachine: RiveStateMachineInstance, didChangeState stateName: String) {
        let machineName = stateMachine.name()
        MainActor.assumeIsolated { onStateChange?(machineName, stateName) }
    }

    @objc nonisolated func onRiveEventReceived(onRiveEvent riveEvent: RiveEvent) {
        let name = riveEvent.name()
        let type = riveEvent.type()
        let properties = riveEvent.properties().reduce(into: [String: String]()) { $0[$1.key] = String(describing: $1.value) }
        MainActor.assumeIsolated { onRiveEvent?(name, type, properties) }
    }
}
