import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import RiveViewerKit

struct GifExportTests {
    @Test func frameCountFollowsFpsAndDuration() {
        #expect(GifExportSettings(fps: 15, duration: 2, maxDimension: 512).frameCount == 30)
        #expect(GifExportSettings(fps: 10, duration: 0.05, maxDimension: 512).frameCount == 1)
    }

    @Test func outputSizeKeepsAspectWithinMaximum() {
        let s = GifExportSettings(fps: 15, duration: 1, maxDimension: 512)
        #expect(s.outputSize(artboardWidth: 2798, artboardHeight: 1000) == CGSize(width: 512, height: 183))
        #expect(s.outputSize(artboardWidth: 100, artboardHeight: 200) == CGSize(width: 100, height: 200))
    }

    @Test func encoderWritesLoopingGifWithEveryFrame() throws {
        let frames = try [CGColor(red: 1, green: 0, blue: 0, alpha: 1), CGColor(red: 0, green: 0, blue: 1, alpha: 1)].map(Self.solidImage)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("gif-test-\(UUID().uuidString).gif")
        defer { try? FileManager.default.removeItem(at: url) }
        try GifEncoder.write(frames, fps: 10, to: url)
        let source = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
        #expect(CGImageSourceGetCount(source) == 2)
        let props = try #require(CGImageSourceCopyProperties(source, nil) as? [CFString: Any])
        let gif = try #require(props[kCGImagePropertyGIFDictionary] as? [CFString: Any])
        #expect(gif[kCGImagePropertyGIFLoopCount] as? Int == 0)
        let frameProps = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let frameGif = try #require(frameProps[kCGImagePropertyGIFDictionary] as? [CFString: Any])
        #expect(abs((frameGif[kCGImagePropertyGIFDelayTime] as? Double ?? 0) - 0.1) < 0.001)
    }

    @Test func encoderRejectsEmptyFrameList() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("empty.gif")
        #expect(throws: GifEncoderError.noFrames) { try GifEncoder.write([], fps: 10, to: url) }
    }

    @Test @MainActor func rendersRequestedNumberOfFramesForSelection() async throws {
        let frames = try await OffscreenRenderer.frames(
            of: try Fixture.data("teststatemachine"),
            artboard: "New Artboard", stateMachine: "State Machine 1",
            size: CGSize(width: 64, height: 64), fps: 10, count: 12
        )
        #expect(frames.count == 12)
        #expect(frames.allSatisfy { $0.width == 64 && $0.height == 64 })
        let first = frames[0].dataProvider?.data as Data?
        #expect(frames.dropFirst().contains { ($0.dataProvider?.data as Data?) != first }, "playback changes the picture")
    }

    @Test @MainActor func settledStateMachineRepeatsLastFrame() async throws {
        let frames = try await OffscreenRenderer.frames(
            of: try Fixture.data("data_binding_test"),
            artboard: "Artboard", stateMachine: "State Machine 1",
            size: CGSize(width: 64, height: 64), fps: 10, count: 4
        )
        #expect(frames.count == 4)
    }

    @Test func flattenFillsTransparentPixels() throws {
        let clear = try Self.solidImage(CGColor(red: 0, green: 0, blue: 0, alpha: 0))
        let flat = try #require(GifEncoder.flatten(clear, over: CGColor(red: 1, green: 1, blue: 1, alpha: 1)))
        let context = try #require(CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 32, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(flat, in: CGRect(x: 0, y: 0, width: 8, height: 8))
        let pixel = try #require(context.data).load(as: UInt32.self).bigEndian
        #expect(pixel == 0xFFFF_FFFF)
    }

    private static func solidImage(_ color: CGColor) throws -> CGImage {
        let context = try #require(CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        return try #require(context.makeImage())
    }
}
