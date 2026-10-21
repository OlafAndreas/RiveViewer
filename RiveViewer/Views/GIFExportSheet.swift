import AppKit
import RiveViewerKit
import SwiftUI
import UniformTypeIdentifiers

/// Options for exporting the current state machine as an animated GIF.
struct GIFExportSheet: View {
    let controller: PlayerController
    @Environment(\.dismiss) private var dismiss

    @State private var fps = 15
    @State private var duration = 3.0
    @State private var maxDimension = 512
    @State private var transparent = true
    @State private var isExporting = false
    @State private var failure: String?

    private static let sizes = [256, 512, 1024]

    private var settings: GifExportSettings {
        GifExportSettings(fps: fps, duration: duration, maxDimension: maxDimension)
    }

    private var outputSize: CGSize {
        guard let artboard = controller.currentArtboard else { return .zero }
        return settings.outputSize(artboardWidth: artboard.width, artboardHeight: artboard.height)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section {
                    Picker("Frame rate", selection: $fps) {
                        ForEach(GifExportSettings.frameRates, id: \.self) { Text("\($0) fps").tag($0) }
                    }
                    LabeledContent("Duration") {
                        Stepper(value: $duration, in: 0.5...20, step: 0.5) {
                            Text(TimeFormatting.seconds(duration)).monospacedDigit()
                        }
                    }
                    Picker("Longest side", selection: $maxDimension) {
                        ForEach(Self.sizes, id: \.self) { Text("\($0) px").tag($0) }
                    }
                    Toggle("Transparent background", isOn: $transparent)
                } footer: {
                    Text("\(Int(outputSize.width)) × \(Int(outputSize.height)) px, \(settings.frameCount) frames. Playback starts from the state machine's initial state, with inputs at their defaults.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let failure {
                    Text(failure).foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)

            HStack {
                if isExporting { ProgressView().controlSize(.small) }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Export…", action: export)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isExporting)
            }
            .padding()
        }
        .frame(minWidth: 380, idealWidth: 420)
        .navigationTitle("Export GIF")
    }

    private func export() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.gif]
        let base = (controller.fileName as NSString).deletingPathExtension
        panel.nameFieldStringValue = "\(base) – \(controller.selection?.itemName ?? "export").gif"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        isExporting = true
        failure = nil
        Task {
            do {
                try await controller.exportGIF(settings: settings, background: transparent ? nil : CGColor(gray: 1, alpha: 1), to: url)
                isExporting = false
                dismiss()
            } catch {
                isExporting = false
                failure = "Export failed: \(error.localizedDescription)"
            }
        }
    }
}
