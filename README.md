# RiveViewer

A macOS inspector for Rive (`.riv`) animation files, plus a Quick Look preview extension so Finder plays them when you press the space bar.

Requires macOS 14 or later. Built with Xcode 27, Swift 6, the official [Rive Apple runtime](https://github.com/rive-app/rive-ios) 6.28.1 and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Building

| Command | What it does |
| --- | --- |
| `make project` | Generates `RiveViewer.xcodeproj` from `project.yml` (the project file is not committed). |
| `make build` | Debug build of the app and the Quick Look extension into `./build`. |
| `make test` | Runs the `RiveViewerKit` unit tests with `swift test`. |
| `make install` | Release build, copies `RiveViewer.app` to `~/Applications` and registers it with LaunchServices, PlugInKit and Quick Look. |
| `make register APP=path/to/RiveViewer.app` | Registers an already built app bundle (the Debug build by default). |
| `make preview FILE=some.riv` | Opens a Quick Look panel for a file with `qlmanage`. |

Builds are ad-hoc signed ("sign to run locally"). To sign with your own team, follow the comment at the top of `project.yml`.

## Quick Look

Quick Look only uses the extension after the containing app has been registered once (`make install` or `make register`). After rebuilding, run `qlmanage -r` (part of both targets) so Quick Look drops its cached generator list.

The preview plays the file's default state machine. If that state machine settles (input-driven files settle after one frame, files with an intro after it finishes) the preview switches to the artboard's longest animation and loops it, so the panel keeps moving whenever the file contains an animation.

The extension logs to the unified log under the subsystem `no.olafandreas.RiveViewer`:

```sh
/usr/bin/log show --last 2m --predicate 'subsystem == "no.olafandreas.RiveViewer"'
```

## Layout

- `Packages/RiveViewerKit` — shared Swift package: file loading, a value-type summary of artboards, state machines, inputs, animations and view models, the rules for what to play by default, and Quick Look sizing. Unit tested with fixtures from the rive-ios repository (MIT, see `Tests/RiveViewerKitTests/Fixtures/LICENSE-rive-ios.txt`).
- `RiveViewer` — the SwiftUI inspector app.
- `RiveQuickLook` — the Quick Look preview extension.
