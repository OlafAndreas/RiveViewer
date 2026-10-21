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

/// Renders one frame of a `.riv` file into a `CGImage` without a window, using the runtime's command-queue renderer.
@MainActor
public enum OffscreenRenderer {
    /// The first frame of the default state machine of the first artboard that has one, fitted into `size` (points, 1x).
    public static func firstFrame(of data: Data, size: CGSize) async throws -> CGImage {
        guard let device = MTLCreateSystemDefaultDevice() else { throw OffscreenRenderError.noMetalDevice }
        let width = max(Int(size.width.rounded()), 1)
        let height = max(Int(size.height.rounded()), 1)

        let worker = Worker(device: device)
        let file = try await File(source: .data(data), worker: worker)
        let rive = try await makeRive(file: file)
        rive.stateMachine.advance(by: 0)

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: descriptor) else { throw OffscreenRenderError.textureCreationFailed }

        var configuration = RiveUIRendererConfiguration(rive: rive, drawableSize: CGSize(width: width, height: height))
        configuration.pixelFormat = .bgra8Unorm

        let renderer = rive.makeRenderer()
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
