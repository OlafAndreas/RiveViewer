import RiveViewerKit
import SwiftUI

struct InputsSection: View {
    @Bindable var controller: PlayerController

    var body: some View {
        Section("Inputs") {
            if controller.inputs.isEmpty {
                Text("This state machine has no inputs.")
                    .foregroundStyle(.secondary)
            }
            ForEach(controller.inputs) { input in
                InputRow(input: input)
            }
        }
    }
}

private struct InputRow: View {
    @Bindable var input: LiveInput
    @State private var sliderRange: ClosedRange<Float> = 0...100

    var body: some View {
        switch input.kind {
        case .boolean:
            Toggle(input.name, isOn: $input.boolValue)
        case .number:
            LabeledContent(input.name) {
                HStack {
                    TextField("Value", value: $input.numberValue, format: .number)
                        .labelsHidden()
                        .frame(minWidth: 64, idealWidth: 72)
                    Slider(value: $input.numberValue, in: sliderRange)
                        .frame(minWidth: 80)
                }
            }
            .onAppear { widenRange(for: input.numberValue) }
            .onChange(of: input.numberValue) { _, value in widenRange(for: value) }
        case .trigger:
            LabeledContent(input.name) {
                Button("Fire") { input.fire() }
            }
        }
    }

    private func widenRange(for value: Float) {
        let lower = min(sliderRange.lowerBound, value)
        let upper = max(sliderRange.upperBound, value)
        if lower != sliderRange.lowerBound || upper != sliderRange.upperBound {
            sliderRange = lower...upper
        }
    }
}
