import RiveRuntime
import RiveViewerKit
import SwiftUI

/// Playback and view-option controls for the canvas window.
struct CanvasToolbar: ToolbarContent {
    @Bindable var controller: PlayerController

    var body: some ToolbarContent {
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

            if controller.currentAnimation != nil {
                Button {
                    controller.step(frames: -1)
                } label: {
                    Label("Step back", systemImage: "backward.frame.fill")
                }
                .help("Step one frame back (⌥←)")

                Button {
                    controller.step(frames: 1)
                } label: {
                    Label("Step forward", systemImage: "forward.frame.fill")
                }
                .help("Step one frame forward (⌥→)")

                Picker("Loop", selection: $controller.loopMode) {
                    ForEach(LoopMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .help("Loop mode")
            }
        }

        ToolbarItemGroup {
            Picker("Fit", selection: $controller.fit) {
                ForEach(RiveFit.pickerCases, id: \.self) { fit in
                    Text(fit.displayName).tag(fit)
                }
            }
            .help("How the artboard fits the canvas")

            Picker("Alignment", selection: $controller.alignment) {
                ForEach(RiveAlignment.pickerCases, id: \.self) { alignment in
                    Text(alignment.displayName).tag(alignment)
                }
            }
            .help("Where the artboard sits in the canvas")

            Picker("Background", selection: $controller.background) {
                ForEach(CanvasBackground.allCases) { background in
                    Text(background.displayName).tag(background)
                }
            }
            .help("Canvas background")

            Toggle(isOn: $controller.showsFPS) {
                Label("FPS", systemImage: "gauge.with.dots.needle.33percent")
            }
            .help("Show the frame-rate counter")
        }
    }
}
