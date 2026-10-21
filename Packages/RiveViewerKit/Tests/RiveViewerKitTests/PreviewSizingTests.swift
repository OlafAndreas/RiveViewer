import CoreGraphics
import Testing
@testable import RiveViewerKit

struct PreviewSizingTests {
    @Test func fitsLargeArtboardsInsidePanel() {
        #expect(PreviewSizing.preferredSize(artboardWidth: 2798, artboardHeight: 1000) == CGSize(width: 1024, height: 366))
    }

    @Test func keepsMediumArtboardsAsIs() {
        #expect(PreviewSizing.preferredSize(artboardWidth: 820, artboardHeight: 460) == CGSize(width: 820, height: 460))
    }

    @Test func scalesTinyArtboardsUpToMinimum() {
        #expect(PreviewSizing.preferredSize(artboardWidth: 100, artboardHeight: 100) == CGSize(width: 320, height: 320))
    }

    @Test func minimumHeightDrivesWideTinyArtboards() {
        #expect(PreviewSizing.preferredSize(artboardWidth: 200, artboardHeight: 50) == CGSize(width: 960, height: 240))
    }

    @Test func nonPositiveFallsBack() {
        #expect(PreviewSizing.preferredSize(artboardWidth: 0, artboardHeight: 0) == CGSize(width: 640, height: 480))
    }
}
