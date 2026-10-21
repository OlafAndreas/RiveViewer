import Observation
import RiveViewerKit

/// One state-machine input with its current value; writes go straight to the running state machine.
@MainActor
@Observable
final class LiveInput: Identifiable {
    let summary: InputSummary

    var boolValue: Bool {
        didSet { if boolValue != oldValue { controller?.setInput(name, bool: boolValue) } }
    }

    var numberValue: Float {
        didSet { if numberValue != oldValue { controller?.setInput(name, number: numberValue) } }
    }

    @ObservationIgnored private weak var controller: PlayerController?

    init(summary: InputSummary, boolValue: Bool, numberValue: Float, controller: PlayerController) {
        self.summary = summary
        self.boolValue = boolValue
        self.numberValue = numberValue
        self.controller = controller
    }

    nonisolated var id: String { summary.name }
    var name: String { summary.name }
    var kind: InputSummary.Kind { summary.kind }

    func fire() {
        controller?.fire(name)
    }
}
