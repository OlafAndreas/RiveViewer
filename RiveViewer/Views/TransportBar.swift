import RiveViewerKit
import SwiftUI

/// Scrubber and time readout for animations; elapsed time and settled state for state machines.
struct TransportBar: View {
    @Bindable var controller: PlayerController

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { content }
            VStack(alignment: .leading, spacing: 6) { content }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    @ViewBuilder
    private var content: some View {
        if let animation = controller.currentAnimation {
            let range = animation.timeRange
            if range.upperBound > range.lowerBound {
                Slider(
                    value: Binding(get: { controller.currentTime }, set: { controller.seek(to: $0) }),
                    in: range
                ) { Text("Time") } onEditingChanged: { editing in
                    if editing { controller.pause() }
                }
                .labelsHidden()
                .frame(minWidth: 120)
            }
            Text("\(TimeFormatting.seconds(controller.currentTime)) / \(TimeFormatting.seconds(range.upperBound))")
                .monospacedDigit()
            Text("frame \(FrameStepper.frame(at: controller.currentTime, fps: animation.fps))")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        } else {
            Text(TimeFormatting.seconds(controller.elapsed))
                .monospacedDigit()
            if controller.isSettled {
                Text("Settled")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            Spacer(minLength: 0)
        }
    }
}
