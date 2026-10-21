import CoreGraphics

/// Chooses the Quick Look panel size for an artboard: fit inside 1024×768, but never smaller than 320×240.
public enum PreviewSizing {
    public static let maximum = CGSize(width: 1024, height: 768)
    public static let minimum = CGSize(width: 320, height: 240)
    public static let fallback = CGSize(width: 640, height: 480)

    public static func preferredSize(artboardWidth: Double, artboardHeight: Double) -> CGSize {
        guard artboardWidth > 0, artboardHeight > 0 else { return fallback }

        var scale = min(maximum.width / artboardWidth, maximum.height / artboardHeight, 1)
        var width = artboardWidth * scale
        var height = artboardHeight * scale

        if width < minimum.width || height < minimum.height {
            let up = max(minimum.width / width, minimum.height / height)
            scale *= up
            width = artboardWidth * scale
            height = artboardHeight * scale
            let refit = min(maximum.width / width, maximum.height / height, 1)
            width *= refit
            height *= refit
        }

        return CGSize(width: width.rounded(), height: height.rounded())
    }
}
