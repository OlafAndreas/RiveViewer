import RiveViewerKit
import SwiftUI

/// Every object in the file, nested by parent, with its raw properties.
struct ObjectsSection: View {
    @Bindable var controller: PlayerController
    @State private var isExpanded = false

    var body: some View {
        Section("Objects") {
            if let error = controller.rawFileError {
                Text("Structure unavailable: \(error)")
                    .foregroundStyle(.secondary)
            } else if let file = controller.rawFile {
                DisclosureGroup(isExpanded: $isExpanded) {
                    List(controller.objectRoots, children: \.children) { node in
                        ObjectRow(object: node.object)
                    }
                    .frame(minHeight: 200, idealHeight: 320, maxHeight: 480)
                } label: {
                    Text("^[\(file.objects.count) object](inflect: true) · format \(file.majorVersion).\(file.minorVersion)")
                }
            } else {
                Text("Reading file structure…")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ObjectRow: View {
    let object: RiveObject

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(object.typeName)
                    .fontWeight(.medium)
                if let name = object.name {
                    Text("“\(name)”")
                        .foregroundStyle(.secondary)
                }
            }
            if !object.properties.isEmpty {
                Text(object.properties.map { "\($0.name.split(separator: ".").last ?? "key"): \($0.displayValue)" }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .help(object.properties.map { "\($0.name): \($0.displayValue)" }.joined(separator: "\n"))
    }
}
