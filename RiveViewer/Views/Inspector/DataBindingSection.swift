import RiveViewerKit
import SwiftUI

struct DataBindingSection: View {
    @Bindable var controller: PlayerController

    var body: some View {
        Section {
            if controller.dataBindingRoots.isEmpty {
                Text(controller.currentArtboard?.defaultViewModelName == nil
                     ? "This artboard has no default view model."
                     : "The bound view model has no properties.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(controller.dataBindingRoots) { node in
                    DataBindingRow(node: node, controller: controller)
                }
            }
        } header: {
            HStack {
                Text("Data binding")
                Spacer()
                if let name = controller.boundViewModelName {
                    Text("\(name) · \(controller.boundInstance?.name ?? "")")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct DataBindingRow: View {
    let node: DataBindingNode
    let controller: PlayerController

    private var historyExpanded: Binding<Bool> {
        Binding(
            get: { !controller.collapsedHistories.contains(node.path) },
            set: { expanded in
                if expanded { controller.collapsedHistories.remove(node.path) } else { controller.collapsedHistories.insert(node.path) }
            }
        )
    }

    var body: some View {
        let _ = controller.dataBindingRevision
        switch node.type {
        case .string:
            TextField(node.name, text: Binding(
                get: { node.stringProperty?.value ?? "" },
                set: { node.stringProperty?.value = $0; controller.dataBindingDidChange() }
            ))
        case .number:
            VStack(alignment: .leading, spacing: 4) {
                LabeledContent(node.name) {
                    TextField("Value", value: Binding(
                        get: { node.numberProperty?.value ?? 0 },
                        set: { node.numberProperty?.value = $0; controller.dataBindingDidChange() }
                    ), format: .number)
                    .labelsHidden()
                    .frame(minWidth: 64, idealWidth: 96)
                }
                DisclosureGroup(isExpanded: historyExpanded) {
                    NumberHistoryChart(history: controller.numberHistories[node.path] ?? ValueHistory())
                } label: {
                    Text("History")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        case .boolean:
            Toggle(node.name, isOn: Binding(
                get: { node.booleanProperty?.value ?? false },
                set: { node.booleanProperty?.value = $0; controller.dataBindingDidChange() }
            ))
        case .color:
            ColorPicker(node.name, selection: Binding(
                get: { Color(nsColor: node.colorProperty?.value ?? .black) },
                set: { node.colorProperty?.value = NSColor($0); controller.dataBindingDidChange() }
            ))
        case .enum:
            Picker(node.name, selection: Binding(
                get: { node.enumProperty?.value ?? "" },
                set: { node.enumProperty?.value = $0; controller.dataBindingDidChange() }
            )) {
                ForEach(node.enumProperty?.values ?? [], id: \.self) { value in
                    Text(value).tag(value)
                }
            }
        case .trigger:
            LabeledContent(node.name) {
                Button("Fire") {
                    node.triggerProperty?.trigger()
                    controller.dataBindingDidChange()
                }
            }
        case .viewModel:
            DisclosureGroup(node.name) {
                ForEach(node.children ?? []) { child in
                    DataBindingRow(node: child, controller: controller)
                }
            }
        default:
            LabeledContent(node.name) {
                HStack(spacing: 6) {
                    Text(node.type.displayName)
                    Text("read-only")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.quaternary, in: Capsule())
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}
