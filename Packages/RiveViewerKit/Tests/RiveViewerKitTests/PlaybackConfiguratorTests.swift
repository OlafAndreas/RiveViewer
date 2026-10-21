import Foundation
import Testing
@testable import RiveViewerKit

struct PlaybackConfiguratorTests {
    @Test func configuresStateMachine() throws {
        let file = try RiveFileLoader.load(url: Fixture.url("runtime_nested_inputs"))
        let model = try PlaybackConfigurator.makeModel(file: file, selection: .stateMachine(artboard: "CircleOuter", name: "CircleStateMachine"))
        #expect(model.artboard.name() == "CircleOuter")
        #expect(model.stateMachine?.name() == "CircleStateMachine")
        #expect(model.animation == nil)
    }

    @Test func configuresAnimation() throws {
        let file = try RiveFileLoader.load(url: Fixture.url("artboard_animations"))
        let model = try PlaybackConfigurator.makeModel(file: file, selection: .animation(artboard: "Star", name: "Animation 1"))
        #expect(model.artboard.name() == "Star")
        #expect(model.animation?.name() == "Animation 1")
    }

    @Test func badNamesThrow() throws {
        let file = try RiveFileLoader.load(url: Fixture.url("artboard_animations"))
        #expect(throws: RiveViewerError.artboardNotFound("Nope")) {
            try PlaybackConfigurator.makeModel(file: file, selection: .animation(artboard: "Nope", name: "x"))
        }
        #expect(throws: RiveViewerError.animationNotFound(artboard: "Star", name: "x")) {
            try PlaybackConfigurator.makeModel(file: file, selection: .animation(artboard: "Star", name: "x"))
        }
    }
}
