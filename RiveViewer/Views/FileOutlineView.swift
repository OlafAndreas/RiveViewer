import RiveViewerKit
import SwiftUI

/// Sidebar: every artboard with its state machines and animations, plus the file's view models.
struct FileOutlineView: View {
    @Bindable var controller: PlayerController

    var body: some View {
        List(selection: $controller.selection) {
            if let summary = controller.summary {
                ForEach(summary.artboards) { artboard in
                    Section("\(artboard.name) · \(Int(artboard.width.rounded()))×\(Int(artboard.height.rounded()))") {
                        ForEach(artboard.stateMachines, id: \.name) { stateMachine in
                            row(
                                title: stateMachine.name,
                                subtitle: "^[\(stateMachine.inputs.count) input](inflect: true)",
                                systemImage: "point.3.connected.trianglepath.dotted"
                            )
                            .tag(PlaybackSelection.stateMachine(artboard: artboard.name, name: stateMachine.name))
                        }
                        ForEach(artboard.animations, id: \.name) { animation in
                            row(
                                title: animation.name,
                                subtitle: TimeFormatting.seconds(animation.effectiveDurationSeconds),
                                systemImage: "film"
                            )
                            .tag(PlaybackSelection.animation(artboard: artboard.name, name: animation.name))
                        }
                        if artboard.stateMachines.isEmpty && artboard.animations.isEmpty {
                            Text("No state machines or animations")
                                .foregroundStyle(.secondary)
                                .selectionDisabled()
                        }
                    }
                }
                if !summary.viewModels.isEmpty {
                    Section("View models") {
                        ForEach(summary.viewModels, id: \.name) { viewModel in
                            row(
                                title: viewModel.name,
                                subtitle: "^[\(viewModel.properties.count) property](inflect: true) · ^[\(viewModel.instanceNames.count) instance](inflect: true)",
                                systemImage: "tablecells"
                            )
                            .selectionDisabled()
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 220, ideal: 280)
    }

    private func row(title: String, subtitle: LocalizedStringKey, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
    }

    private func row(title: String, subtitle: String, systemImage: String) -> some View {
        row(title: title, subtitle: LocalizedStringKey(subtitle), systemImage: systemImage)
    }
}
