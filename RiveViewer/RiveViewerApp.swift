import SwiftUI

@main
struct RiveViewerApp: App {
    var body: some Scene {
        DocumentGroup(viewing: RiveDocument.self) { file in
            DocumentRoot(data: file.document.data, fileURL: file.fileURL)
        }
        .commands {
            PlayerCommands()
        }
    }
}

/// Owns the controller for one window; it is created once, in `task`.
private struct DocumentRoot: View {
    let data: Data
    let fileURL: URL?
    @State private var controller: PlayerController?

    var body: some View {
        Group {
            if let controller {
                DocumentView(controller: controller)
            } else {
                ProgressView()
            }
        }
        .task {
            if controller == nil {
                controller = PlayerController(data: data, fileURL: fileURL)
            }
        }
    }
}

private struct PlayerControllerKey: FocusedValueKey {
    typealias Value = PlayerController
}

extension FocusedValues {
    var playerController: PlayerController? {
        get { self[PlayerControllerKey.self] }
        set { self[PlayerControllerKey.self] = newValue }
    }
}

struct PlayerCommands: Commands {
    @FocusedValue(\.playerController) private var controller

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button("Reload") { controller?.reload() }
                .keyboardShortcut("r")
                .disabled(controller == nil)
        }
        CommandMenu("Playback") {
            Button(controller?.isPlaying == true ? "Pause" : "Play") { controller?.togglePlay() }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(controller?.viewModel == nil)
            Button("Restart") { controller?.restart() }
                .keyboardShortcut("0")
                .disabled(controller?.viewModel == nil)
            Divider()
            Button("Step Backward") { controller?.step(frames: -1) }
                .keyboardShortcut(.leftArrow, modifiers: .option)
                .disabled(controller?.currentAnimation == nil)
            Button("Step Forward") { controller?.step(frames: 1) }
                .keyboardShortcut(.rightArrow, modifiers: .option)
                .disabled(controller?.currentAnimation == nil)
        }
    }
}
