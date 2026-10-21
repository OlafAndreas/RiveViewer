import RiveViewerKit
import SwiftUI

struct SelectionSection: View {
    @Bindable var controller: PlayerController

    var body: some View {
        Section("Selection") {
            if let artboard = controller.currentArtboard {
                LabeledContent("Artboard", value: artboard.name)
                LabeledContent("Size", value: "\(Int(artboard.width.rounded())) × \(Int(artboard.height.rounded()))")
            }
            if let animation = controller.currentAnimation {
                LabeledContent("Animation", value: animation.name)
                LabeledContent("FPS", value: "\(animation.fps)")
                LabeledContent("Frames", value: "\(animation.durationFrames)")
                LabeledContent("Work area", value: animation.workArea.map { "\($0.lowerBound)–\($0.upperBound)" } ?? "none")
                LabeledContent("Loop", value: animation.loop.displayName)
                LabeledContent("Duration", value: TimeFormatting.seconds(animation.effectiveDurationSeconds))
            }
            if let stateMachine = controller.currentStateMachine {
                LabeledContent("State machine", value: stateMachine.name)
                LabeledContent("Layers", value: "\(stateMachine.layerCount)")
                LabeledContent("Inputs", value: "\(stateMachine.inputs.count)")
            }
        }
    }
}
