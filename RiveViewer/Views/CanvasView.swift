import RiveRuntime
import RiveViewerKit
import SwiftUI

/// The Rive view over a selectable backdrop, with the transport bar underneath.
struct CanvasView: View {
    @Bindable var controller: PlayerController
    @FocusState private var canvasFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                backdrop
                if let viewModel = controller.viewModel {
                    RiveViewRepresentable(viewModel: viewModel)
                        .id(ObjectIdentifier(viewModel))
                }
            }
            .simultaneousGesture(TapGesture().onEnded { canvasFocused = true })
            Divider()
            TransportBar(controller: controller)
        }
        // Space toggles playback only while the canvas has focus, so text fields in the inspector keep their spaces.
        .focusable()
        .focused($canvasFocused)
        .focusEffectDisabled()
        .onKeyPress(.space) {
            controller.togglePlay()
            return .handled
        }
        .onAppear { canvasFocused = true }
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
