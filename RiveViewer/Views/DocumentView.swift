import RiveViewerKit
import SwiftUI

struct DocumentView: View {
    @Bindable var controller: PlayerController

    var body: some View {
        NavigationSplitView {
            FileOutlineView(controller: controller)
        } detail: {
            detail
        }
        .focusedSceneValue(\.playerController, controller)
    }

    @ViewBuilder
    private var detail: some View {
        if let error = controller.loadError {
            ErrorView(error: error) { controller.reload() }
        } else if controller.summary == nil {
            ProgressView()
        } else if controller.selection == nil {
            ContentUnavailableView(
                "Nothing to play",
                systemImage: "film",
                description: Text(RiveViewerError.nothingToPlay.errorDescription ?? "")
            )
        } else {
            CanvasView(controller: controller)
        }
    }
}
