import Foundation
import RiveRuntime

/// Loads `.riv` files with the classic RiveRuntime API. CDN asset loading is always disabled.
public enum RiveFileLoader {
    public static func load(url: URL) throws -> RiveFile {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw RiveViewerError.unreadableFile(url)
        }
        return try load(data: data)
    }

    public static func load(data: Data) throws -> RiveFile {
        do {
            return try RiveFile(data: data, loadCdn: false)
        } catch {
            throw RiveViewerError.cannotLoad(error.localizedDescription)
        }
    }
}
