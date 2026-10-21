import RiveViewerKit
import SwiftUI

struct DocumentView: View {
    @Bindable var controller: PlayerController
    @State private var showsInspector = true

    var body: some View {
        NavigationSplitView {
            FileOutlineView(controller: controller)
        } detail: {
            detail
        }
        .inspector(isPresented: $showsInspector) {
            Group {
                if controller.loadError == nil {
                    InspectorPane(controller: controller)
                } else {
                    ContentUnavailableView("No file loaded", systemImage: "doc.questionmark")
                }
            }
                .inspectorColumnWidth(min: 280, ideal: 340, max: 520)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showsInspector.toggle()
                } label: {
                    Label("Inspector", systemImage: "sidebar.trailing")
                }
                .help("Show or hide the inspector")
            }
        }
        .sheet(isPresented: $controller.isShowingGIFExport) {
            GIFExportSheet(controller: controller)
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
