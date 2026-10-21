import RiveRuntime
import RiveViewerKit
import SwiftUI

/// The Rive view over a selectable backdrop, with the transport bar underneath.
struct CanvasView: View {
    @Bindable var controller: PlayerController

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                backdrop
                if let viewModel = controller.viewModel {
                    RiveViewRepresentable(viewModel: viewModel)
                        .id(ObjectIdentifier(viewModel))
                }
            }
            Divider()
            TransportBar(controller: controller)
        }
        .toolbar {
            CanvasToolbar(controller: controller)
        }
    }

    @ViewBuilder
    private var backdrop: some View {
        switch controller.background {
        case .checkerboard: CheckerboardBackground()
        case .dark: Color(white: 0.12)
        case .light: Color.white
        }
    }
}
