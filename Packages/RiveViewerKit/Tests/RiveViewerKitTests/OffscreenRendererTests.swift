import CoreGraphics
import Foundation
import Testing
@testable import RiveViewerKit

struct OffscreenRendererTests {
    @Test @MainActor func rendersNonBlankFrame() async throws {
        let image = try await OffscreenRenderer.firstFrame(of: try Fixture.data("rating_animation"), size: CGSize(width: 128, height: 128))
        #expect(image.width == 128 && image.height == 128)
        let pixels = try #require(image.dataProvider?.data as Data?)
        let opaqueCount = stride(from: 3, to: pixels.count, by: 4).filter { pixels[$0] != 0 }.count
        #expect(opaqueCount > 0, "at least one pixel with non-zero alpha")
    }

    @Test @MainActor func usesFirstArtboardWithAStateMachine() async throws {
        // Artboard 0 ("Bubble"-style artboards elsewhere) may lack state machines; runtime_nested_inputs has one on its first artboard.
        let image = try await OffscreenRenderer.firstFrame(of: try Fixture.data("runtime_nested_inputs"), size: CGSize(width: 64, height: 64))
        #expect(image.width == 64)
    }

    @Test @MainActor func rendersArtboardWhoseStateMachineIsNotDefault() async throws {
        // teststatemachine.riv has "State Machine 1" but no default state machine flag.
        let image = try await OffscreenRenderer.firstFrame(of: try Fixture.data("teststatemachine"), size: CGSize(width: 64, height: 64))
        #expect(image.width == 64)
    }

    @Test @MainActor func animationOnlyFilesAreRejected() async throws {
        await #expect(throws: OffscreenRenderError.noStateMachine) {
            try await OffscreenRenderer.firstFrame(of: try Fixture.data("artboard_animations"), size: CGSize(width: 64, height: 64))
        }
    }
}
