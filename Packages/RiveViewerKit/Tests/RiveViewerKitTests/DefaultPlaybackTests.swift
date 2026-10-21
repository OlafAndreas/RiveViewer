import Foundation
import Testing
@testable import RiveViewerKit

struct DefaultPlaybackTests {
    @Test func prefersDefaultStateMachineOfFirstArtboardWithOne() throws {
        let s = RiveFileInspector.summarize(try RiveFileLoader.load(url: Fixture.url("runtime_nested_inputs")))
        #expect(DefaultPlayback.selection(for: s) == .stateMachine(artboard: "MainArtboard", name: "MainStateMachine"))
    }

    @Test func fallsBackToFirstStateMachineWhenNoDefault() throws {
        let s = RiveFileInspector.summarize(try RiveFileLoader.load(url: Fixture.url("teststatemachine")))
        #expect(DefaultPlayback.selection(for: s) == .stateMachine(artboard: "New Artboard", name: "State Machine 1"))
    }

    @Test func fallsBackToLongestAnimationWhenNoStateMachines() throws {
        let s = RiveFileInspector.summarize(try RiveFileLoader.load(url: Fixture.url("artboard_animations")))
        #expect(DefaultPlayback.selection(for: s) == .animation(artboard: "Square", name: "rollaround"))
    }

    @Test func skipsArtboardsWithoutStateMachines() {
        let empty = ArtboardSummary(index: 0, name: "Bubble", width: 10, height: 10, defaultStateMachineName: nil, defaultViewModelName: nil, stateMachines: [], animations: [AnimationSummary(name: "a", fps: 60, durationFrames: 60, workArea: nil, loop: .loop)])
        let main = ArtboardSummary(index: 1, name: "Main", width: 10, height: 10, defaultStateMachineName: nil, defaultViewModelName: nil, stateMachines: [StateMachineSummary(name: "Motion", layerCount: 1, inputs: [])], animations: [])
        let s = RiveFileSummary(runtimeVersion: "7.4", defaultArtboardName: "Bubble", artboards: [empty, main], viewModels: [])
        #expect(DefaultPlayback.selection(for: s) == .stateMachine(artboard: "Main", name: "Motion"))
    }

    @Test func nothingToPlayGivesNil() {
        let ab = ArtboardSummary(index: 0, name: "A", width: 1, height: 1, defaultStateMachineName: nil, defaultViewModelName: nil, stateMachines: [], animations: [])
        #expect(DefaultPlayback.selection(for: RiveFileSummary(runtimeVersion: "7.4", defaultArtboardName: "A", artboards: [ab], viewModels: [])) == nil)
    }

    @Test func fallbackAnimationIsLongest() throws {
        let s = RiveFileInspector.summarize(try RiveFileLoader.load(url: Fixture.url("rating_animation")))
        #expect(DefaultPlayback.fallbackAnimation(for: s.artboards[0]) == "Example")
    }

    @Test func selectionIdentityIncludesArtboard() {
        #expect(PlaybackSelection.animation(artboard: "Circle", name: "Animation 1") != .animation(artboard: "Star", name: "Animation 1"))
        #expect(PlaybackSelection.animation(artboard: "Circle", name: "Animation 1").hashValue != PlaybackSelection.animation(artboard: "Star", name: "Animation 1").hashValue)
    }

    @Test func reconcileKeepsExistingAndReplacesMissing() throws {
        let s = RiveFileInspector.summarize(try RiveFileLoader.load(url: Fixture.url("artboard_animations")))
        let keep = PlaybackSelection.animation(artboard: "Star", name: "Animation 1")
        #expect(DefaultPlayback.reconcile(keep, in: s) == keep)
        #expect(DefaultPlayback.reconcile(.stateMachine(artboard: "Square", name: "Gone"), in: s) == .animation(artboard: "Square", name: "rollaround"))
        #expect(DefaultPlayback.reconcile(nil, in: s) == .animation(artboard: "Square", name: "rollaround"))
    }
}

struct PlaybackSelectionDescriptionTests {
    @Test func logDescriptions() {
        #expect(PlaybackSelection.animation(artboard: "Square", name: "rollaround").logDescription == "animation(Square/rollaround)")
        #expect(PlaybackSelection.stateMachine(artboard: "New Artboard", name: "State Machine 1").logDescription == "stateMachine(New Artboard/State Machine 1)")
    }
}

struct FallbackSelectionTests {
    private func artboard(_ name: String, index: Int, animations: [AnimationSummary], stateMachines: [String] = []) -> ArtboardSummary {
        ArtboardSummary(index: index, name: name, width: 10, height: 10, defaultStateMachineName: nil, defaultViewModelName: nil,
                        stateMachines: stateMachines.map { StateMachineSummary(name: $0, layerCount: 1, inputs: []) }, animations: animations)
    }

    @Test func prefersAnimationOnTheSameArtboard() {
        let long = AnimationSummary(name: "long", fps: 60, durationFrames: 600, workArea: nil, loop: .loop)
        let own = AnimationSummary(name: "own", fps: 60, durationFrames: 60, workArea: nil, loop: .loop)
        let s = RiveFileSummary(runtimeVersion: "7.4", defaultArtboardName: "A", artboards: [
            artboard("A", index: 0, animations: [long]),
            artboard("Main", index: 1, animations: [own], stateMachines: ["SM"]),
        ], viewModels: [])
        #expect(DefaultPlayback.fallbackSelection(after: .stateMachine(artboard: "Main", name: "SM"), in: s) == .animation(artboard: "Main", name: "own"))
    }

    @Test func crossesArtboardsWhenTheStateMachineArtboardHasNoTimelines() {
        let anim = AnimationSummary(name: "Bubble", fps: 60, durationFrames: 120, workArea: nil, loop: .loop)
        let s = RiveFileSummary(runtimeVersion: "7.4", defaultArtboardName: "Main", artboards: [
            artboard("Main", index: 0, animations: [], stateMachines: ["SM"]),
            artboard("Bubble_1", index: 1, animations: [anim]),
        ], viewModels: [])
        #expect(DefaultPlayback.fallbackSelection(after: .stateMachine(artboard: "Main", name: "SM"), in: s) == .animation(artboard: "Bubble_1", name: "Bubble"))
    }

    @Test func noTimelinesAnywhereGivesNil() {
        let s = RiveFileSummary(runtimeVersion: "7.4", defaultArtboardName: "Main", artboards: [artboard("Main", index: 0, animations: [], stateMachines: ["SM"])], viewModels: [])
        #expect(DefaultPlayback.fallbackSelection(after: .stateMachine(artboard: "Main", name: "SM"), in: s) == nil)
    }
}
