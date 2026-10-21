import CoreGraphics
import Foundation
import Metal
import RiveRuntime

public enum OffscreenRenderError: Error, Sendable, Equatable {
    case noMetalDevice
    case textureCreationFailed
    case drawSkipped
    case imageCreationFailed
    /// No artboard in the file has a state machine; the command-queue renderer cannot draw timeline-only artboards.
    case noStateMachine
}

/// Renders frames of a `.riv` file into `CGImage`s without a window, using the runtime's command-queue renderer.
@MainActor
public enum OffscreenRenderer {
    /// The first frame of the default state machine of the first artboard that has one, fitted into `size` (points, 1x).
    public static func firstFrame(of data: Data, size: CGSize) async throws -> CGImage {
        let session = try await Session(data: data, size: size) { file in try await makeRive(file: file) }
        session.rive.stateMachine.advance(by: 0)
        return try await session.draw()
    }

    /// `count` frames of one artboard and state machine, starting from its initial state and advancing `1 / fps`
    /// seconds between frames. Names that are `nil` pick the first artboard with a state machine and its first one.
    public static func frames(of data: Data, artboard: String?, stateMachine: String?, size: CGSize, fps: Int, count: Int) async throws -> [CGImage] {
        let session = try await Session(data: data, size: size) { file in
            guard let artboard else { return try await makeRive(file: file) }
            let board = try await file.createArtboard(artboard)
            var name = stateMachine
            if name == nil { name = try await board.getStateMachineNames().first }
            guard let name else { throw OffscreenRenderError.noStateMachine }
            return try await Rive(file: file, artboard: board, stateMachine: try await board.createStateMachine(name))
        }
        let step = 1 / Double(max(fps, 1))
        var images: [CGImage] = []
        images.reserveCapacity(max(count, 0))
        session.rive.stateMachine.advance(by: 0)
        for index in 0..<max(count, 0) {
            if index > 0 { session.rive.stateMachine.advance(by: step) }
            do {
                images.append(try await session.draw())
            } catch OffscreenRenderError.drawSkipped where !images.isEmpty {
                // The renderer skips frames in which nothing changed; the picture is the previous one.
                images.append(images[images.count - 1])
            }
        }
        return images
    }

    /// One loaded file, one render target and one renderer, reused for every frame.
    @MainActor
    private final class Session {
        let rive: Rive
        private let device: any MTLDevice
        private let texture: any MTLTexture
        private let renderer: any RiveUIRendererProtocol
        private let configuration: RiveUIRendererConfiguration
        private let width: Int
        private let height: Int

        init(data: Data, size: CGSize, makeRive: @MainActor (File) async throws -> Rive) async throws {
            guard let device = MTLCreateSystemDefaultDevice() else { throw OffscreenRenderError.noMetalDevice }
            width = max(Int(size.width.rounded()), 1)
            height = max(Int(size.height.rounded()), 1)
            let worker = Worker(device: device)
            let file = try await File(source: .data(data), worker: worker)
            rive = try await makeRive(file)

            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .shared
            guard let texture = device.makeTexture(descriptor: descriptor) else { throw OffscreenRenderError.textureCreationFailed }
            var configuration = RiveUIRendererConfiguration(rive: rive, drawableSize: CGSize(width: width, height: height))
            configuration.pixelFormat = .bgra8Unorm
            self.device = device
            self.texture = texture
            self.configuration = configuration
            self.renderer = rive.makeRenderer()
        }

        func draw() async throws -> CGImage {
            let gate = ResumeGate()
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                renderer.draw(configuration, to: texture, from: device, onDraw: { @Sendable commandBuffer in
                    commandBuffer.addCompletedHandler { @Sendable _ in gate.resume(continuation, with: nil) }
                }, onSkipped: { @Sendable in
                    gate.resume(continuation, with: OffscreenRenderError.drawSkipped)
                }, onError: { @Sendable error in
                    gate.resume(continuation, with: error)
                })
            }
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            texture.getBytes(&bytes, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
            guard let provider = CGDataProvider(data: Data(bytes) as CFData),
                  let image = CGImage(
                    width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo, provider: provider,
                    decode: nil, shouldInterpolate: true, intent: .defaultIntent
                  )
            else { throw OffscreenRenderError.imageCreationFailed }
            return image
        }
    }

    private static func makeRive(file: File) async throws -> Rive {
        for name in try await file.getArtboardNames() {
            let artboard = try await file.createArtboard(name)
            if let stateMachineName = try await artboard.getStateMachineNames().first {
                let stateMachine = try await artboard.createStateMachine(stateMachineName)
                return try await Rive(file: file, artboard: artboard, stateMachine: stateMachine)
            }
        }
        throw OffscreenRenderError.noStateMachine
    }

    /// Resumes a continuation at most once, whichever renderer callback fires first.
    private final class ResumeGate: @unchecked Sendable {
        private let lock = NSLock()
        private var resumed = false

        func resume(_ continuation: CheckedContinuation<Void, any Error>, with error: (any Error)?) {
            lock.lock()
            defer { lock.unlock() }
            guard !resumed else { return }
            resumed = true
            if let error { continuation.resume(throwing: error) } else { continuation.resume() }
        }
    }
}
