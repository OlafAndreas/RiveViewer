import SwiftUI
import UniformTypeIdentifiers

/// Read-only document wrapper: the app never writes `.riv` files.
struct RiveDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.rive]

    let data: Data

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileWriteUnsupportedScheme)
    }
}
