import AppKit
import OSLog
import QuickLookThumbnailing
import RiveViewerKit

private let log = Logger(subsystem: "no.olafandreas.RiveViewer", category: "thumbnail")

/// Finder icon for `.riv` files: the first frame of the first artboard that has a state machine.
final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, (any Error)?) -> Void) {
        let url = request.fileURL
        let maximumSize = request.maximumSize
        let scale = request.scale
        let reply = ReplyBox(handler)
        Task { @MainActor in
            do {
                let data = try Data(contentsOf: url)
                let contextSize = Self.contextSize(for: data, within: maximumSize)
                let pixelSize = CGSize(width: contextSize.width * scale, height: contextSize.height * scale)
                let image = try await OffscreenRenderer.firstFrame(of: data, size: pixelSize)
                log.notice("thumbnail \(url.lastPathComponent, privacy: .public): \(image.width)x\(image.height)")
                reply.call(QLThumbnailReply(contextSize: contextSize, drawing: { @Sendable context in
                    context.draw(image, in: CGRect(x: 0, y: 0, width: context.width, height: context.height))
                    return true
                }), nil)
            } catch {
                log.error("thumbnail failed for \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
                reply.call(nil, error)
            }
        }
    }

    /// The largest size inside `maximumSize` with the rendered artboard's aspect ratio.
    private static func contextSize(for data: Data, within maximumSize: CGSize) -> CGSize {
        guard let file = try? RiveFileLoader.load(data: data) else { return maximumSize }
        let summary = RiveFileInspector.summarize(file)
        guard let artboard = summary.artboards.first(where: { !$0.stateMachines.isEmpty }), artboard.width > 0, artboard.height > 0 else {
            return maximumSize
        }
        let scale = min(maximumSize.width / artboard.width, maximumSize.height / artboard.height)
        return CGSize(width: (artboard.width * scale).rounded(.down), height: (artboard.height * scale).rounded(.down))
    }

    /// Carries Quick Look's completion handler into the main-actor task.
    private final class ReplyBox: @unchecked Sendable {
        private let handler: (QLThumbnailReply?, (any Error)?) -> Void

        init(_ handler: @escaping (QLThumbnailReply?, (any Error)?) -> Void) {
            self.handler = handler
        }

        func call(_ reply: QLThumbnailReply?, _ error: (any Error)?) {
            handler(reply, error)
        }
    }
}
