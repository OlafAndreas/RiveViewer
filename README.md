# RiveViewer

A macOS inspector for Rive (`.riv`) animation files, plus Quick Look extensions so Finder plays them with the space bar and shows them as icons.

Requires macOS 14 or later. Built with Xcode 27, Swift 6, the official [Rive Apple runtime](https://github.com/rive-app/rive-ios) 6.28.1 and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## What it does

**Inspector app** (`RiveViewer.app`, document based: File ▸ Open, Open Recent, drag onto the Dock icon, Finder "Open With"):

- Sidebar: every artboard with its size, its state machines (input count) and its timeline animations (duration), plus the file's data-binding view models.
- Canvas: the running artboard over a checkerboard, dark or light backdrop, with fit and alignment menus and an FPS counter.
- Transport: play/pause, restart, frame stepping, loop mode (one shot, loop, ping-pong) and a scrubber for animations; elapsed time and a "Settled" badge for state machines.
- Inspector pane: selection details (fps, frames, work area, loop, layers); live state-machine inputs (toggles, number fields with sliders, trigger buttons); the artboard's default data-binding view model with editors for strings, numbers, booleans, colours, enums and triggers, nested view models expanded, and a rolling 10-second history graph under every numeric property; text runs found in the file (editable for the current artboard) and a manual lookup for nested paths; an event log of state changes, Rive events and playback; and the raw object tree of the file with every property.
- Reload (`⌘R`) re-reads the file from disk and keeps the selection when it still exists.

**Quick Look preview** (`RiveQuickLook.appex`): press space on a `.riv` in Finder and it plays. The preview runs the file's default state machine; if that settles (input-driven files settle at once, files with an intro after it ends) it switches to the artboard's longest animation and loops it, so the panel keeps moving whenever the file has any animation.

**Thumbnails** (`RiveThumbnail.appex`): Finder, Open dialogs and Spotlight show the first frame of the first artboard that has a state machine as the file's icon. Files with only timeline animations keep the generic icon (the offscreen renderer needs a state machine).

### Keyboard

| Keys | Action |
| --- | --- |
| Space | Play / pause |
| `⌘0` | Restart |
| `⌥←` / `⌥→` | Step one frame back / forward (animations) |
| `⌘R` | Reload the file from disk |

## Building

| Command | What it does |
| --- | --- |
| `make project` | Generates `RiveViewer.xcodeproj` from `project.yml` (the project file is not committed). |
| `make build` | Debug build of the app and both extensions into `./build`. |
| `make test` | Runs the `RiveViewerKit` unit tests with `swift test`. |
| `make install` | Release build, copies `RiveViewer.app` to `~/Applications` and registers it with LaunchServices, PlugInKit and Quick Look. |
| `make register APP=path/to/RiveViewer.app` | Registers an already built app bundle (the Debug build by default). |
| `make preview FILE=some.riv` | Opens a Quick Look panel for a file with `qlmanage`. |

Builds are ad-hoc signed ("sign to run locally"). To sign with your own team, follow the comment at the top of `project.yml`.

## Quick Look registration

Quick Look only uses the extensions after the containing app has been registered once (`make install` or `make register`). After rebuilding, run `qlmanage -r` (part of both targets) so Quick Look drops its cached generator list. Thumbnails are cached by the system; if an icon looks stale, `qlmanage -r cache` clears the cache.

Everything logs to the unified log under the subsystem `no.olafandreas.RiveViewer` (categories `player`, `quicklook`, `thumbnail`):

```sh
/usr/bin/log show --last 2m --predicate 'subsystem == "no.olafandreas.RiveViewer"'
```

## Layout

- `Packages/RiveViewerKit` — shared Swift package: file loading, a value-type summary of artboards, state machines, inputs, animations and view models, the rules for what to play by default, Quick Look sizing, frame arithmetic, a parser for the `.riv` container (object tree and text-run list, with type and property names generated from the runtime's headers by `Scripts/generate-rive-schema.sh`), an offscreen first-frame renderer and the rolling value history. Unit tested with fixtures from the rive-ios repository (MIT, see `Tests/RiveViewerKitTests/Fixtures/LICENSE-rive-ios.txt`).
- `RiveViewer` — the SwiftUI inspector app.
- `RiveQuickLook` — the Quick Look preview extension.
- `RiveThumbnail` — the Quick Look thumbnail extension.
- `Scripts/generate-rive-schema.sh` — regenerates `RiveSchema.swift` from a rive-runtime checkout.
- `Scripts/render-app-icon.swift` — draws the app icon; regenerate the asset catalog sizes with `swift Scripts/render-app-icon.swift RiveViewer/Assets.xcassets/AppIcon.appiconset` and `sips -z`.

## Known limits

- The runtime API cannot list text runs; the inspector lists them by parsing the file container instead. Files written with a newer Rive format than the generated schema knows show "Structure unavailable" in the Objects section while everything else keeps working.
- Thumbnails need a state machine in the file.
- Numeric input values and data-binding numbers are typed in your locale; technical readouts (times, frames, chart labels) use a dot decimal separator.
