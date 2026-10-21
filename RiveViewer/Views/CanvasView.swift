import RiveRuntime
import RiveViewerKit
import SwiftUI

/// The Rive view with its playback toolbar.
struct CanvasView: View {
    @Bindable var controller: PlayerController

    var body: some View {
        ZStack {
            CheckerboardBackground()
            if let viewModel = controller.viewModel {
                RiveViewRepresentable(viewModel: viewModel)
                    .id(ObjectIdentifier(viewModel))
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    controller.togglePlay()
                } label: {
                    Label(controller.isPlaying ? "Pause" : "Play", systemImage: controller.isPlaying ? "pause.fill" : "play.fill")
                }
                .help(controller.isPlaying ? "Pause (Space)" : "Play (Space)")
                Button {
                    controller.restart()
                } label: {
                    Label("Restart", systemImage: "backward.end.fill")
                }
                .help("Restart (⌘0)")
            }
        }
    }
}
