import Foundation
import RiveRuntime
import Testing
@testable import RiveViewerKit

struct RiveFileLoaderTests {
    @Test func loadsFixtureFromURL() throws {
        let file = try RiveFileLoader.load(url: Fixture.url("teststatemachine"))
        #expect(file.artboardCount() == 1)
    }

    @Test func loadsFixtureFromData() throws {
        let file = try RiveFileLoader.load(data: try Fixture.data("artboard_animations"))
        #expect(file.artboardNames() == ["Square", "Circle", "Star"])
    }

    @Test func garbageDataThrowsCannotLoad() {
        #expect(throws: RiveViewerError.self) {
            try RiveFileLoader.load(data: Data("not a rive file".utf8))
        }
    }

    @Test func missingFileThrowsUnreadable() {
        let url = URL(fileURLWithPath: "/nonexistent/x.riv")
        #expect(throws: RiveViewerError.unreadableFile(url)) {
            try RiveFileLoader.load(url: url)
        }
    }
}
