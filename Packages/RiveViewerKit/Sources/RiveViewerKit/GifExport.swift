import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// What the user picked in the export sheet.
public struct GifExportSettings: Sendable, Equatable {
    public static let frameRates = [10, 15, 25]

    public var fps: Int
    public var duration: Double
    /// Longest side of the output in pixels; artboards are scaled down to fit, never up.
    public var maxDimension: Int

    public init(fps: Int = 15, duration: Double = 3, maxDimension: Int = 512) {
        self.fps = fps
        self.duration = duration
        self.maxDimension = maxDimension
    }

    public var frameCount: Int { max(Int((duration * Double(fps)).rounded()), 1) }

    public func outputSize(artboardWidth: Double, artboardHeight: Double) -> CGSize {
        guard artboardWidth > 0, artboardHeight > 0 else { return CGSize(width: maxDimension, height: maxDimension) }
        let scale = min(Double(maxDimension) / max(artboardWidth, artboardHeight), 1)
        return CGSize(width: (artboardWidth * scale).rounded(), height: (artboardHeight * scale).rounded())
    }
}

public enum GifEncoderError: Error, Equatable, Sendable {
    case noFrames
    case cannotCreateDestination
    case finalizeFailed
}

/// Writes frames as an endlessly looping GIF.
public enum GifEncoder {
    public static func write(_ frames: [CGImage], fps: Int, to url: URL) throws {
        guard !frames.isEmpty else { throw GifEncoderError.noFrames }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames.count, nil) else {
            throw GifEncoderError.cannotCreateDestination
        }
        CGImageDestinationSetProperties(destination, [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0],
        ] as CFDictionary)
        let delay = 1 / Double(max(fps, 1))
        let frameProperties = [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay, kCGImagePropertyGIFUnclampedDelayTime: delay],
        ] as CFDictionary
        for frame in frames {
            CGImageDestinationAddImage(destination, frame, frameProperties)
        }
        guard CGImageDestinationFinalize(destination) else { throw GifEncoderError.finalizeFailed }
    }

    /// The image composited over an opaque `color`, for GIFs without transparency.
    public static func flatten(_ image: CGImage, over color: CGColor) -> CGImage? {
        guard let context = CGContext(
            data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }
        let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        context.setFillColor(color)
        context.fill(rect)
        context.draw(image, in: rect)
        return context.makeImage()
    }
}
