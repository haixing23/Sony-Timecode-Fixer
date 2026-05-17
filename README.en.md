# Sony Timecode Fixer

If you've cut Sony FX-series or A7S-series footage in Final Cut Pro, you've probably hit this one: after exporting XML, the Sony MP4 start timecodes are gone. Open the project in DaVinci Resolve and you see `00:00:00:00` everywhere — nothing lines up with the DIT report, nothing matches the camera metadata, and the colorist walks over asking what happened.

[CommandPost](https://commandpost.io/) has had a fix for this for years — their Final Cut Pro Sony Timecode Toolbox does exactly this conversion. But CommandPost is a large Hammerspoon extension, and installing a whole framework just to use one tool is a lot to ask of someone who only needs the one thing.

So this project does one simple thing: **it lifts that Sony timecode fix out of the upstream and wraps it in a standalone macOS app**. Drag a `.fcpxml` or `.fcpxmld` in, get a Fixed version back in a few seconds, hand it off to FCP or DaVinci.

Files are processed locally. Nothing goes to the network.

> 中文版 README: [README.md](README.md)

## Screenshots

![Sony Timecode Fixer main window](Assets/Screenshots/home.png)

## What it fixes

- `.fcpxml` files
- `.fcpxmld` bundles (FCP's XML Bundle export, common in multi-clip projects)
- Both Sony sidecar `M01.XML` files and metadata embedded at the tail of MP4 files
- Output is named with a `- Fixed` suffix, so your original XML is never overwritten

## What it doesn't do

- **It only handles Sony footage.** ARRI, RED, Canon, and others use different metadata formats — use a tool built for those.

## Install

### For end users

Grab the latest `.dmg` from [Releases](https://github.com/haixing23/sony-timecode-fixer/releases), mount it, drag the app into Applications.

⚠️ **First launch needs a right-click → Open.** This is an indie open-source project without Apple notarization (which requires a paid Developer account), so Gatekeeper will block a normal double-click the first time. Two ways around it:

**Option A**: In Finder, right-click the app → Open → click "Open" in the warning dialog. After this, normal double-click works.

**Option B**: Run this once in Terminal:

```bash
xattr -cr /Applications/SonyTimecodeFixer.app
```

This strips the quarantine attribute and lets you launch normally afterward.

### Homebrew

If you prefer Homebrew:

```bash
brew tap haixing23/tap
brew install --cask sony-timecode-fixer
```

Homebrew Cask handles the quarantine attribute for you — no right-click needed.

## Usage

1. In FCP, select your project, then **File → Export XML...**, choose `.fcpxml` or `.fcpxml Bundle`.
2. Open Sony Timecode Fixer.
3. Drag the exported XML into the window, or onto the dock icon.
4. Pick an output location (defaults to next to the source file).
5. A few seconds later you'll have a `Project Name - Fixed.fcpxml` (or `.fcpxmld`).
6. Import the Fixed file back into FCP (File → Import → XML), or hand it off to DaVinci / Premiere.

## Build from source

```bash
make build
```

Output goes to:

```text
build/Build/Products/Release/SonyTimecodeFixer.app
```

Build a `.dmg`:

```bash
make dmg
```

Run the full packaging test before release:

```bash
make package-test
```

`package-test` builds a DMG, mounts it, checks the `.app` and `Applications` symlink, verifies the ad-hoc signature, copies the app to a temporary install directory, and confirms it stays alive for 5 seconds.

### Build requirements

- macOS 14 (Sonoma) or newer
- Apple Silicon Mac
- Xcode Command Line Tools
- `/usr/bin/python3` (ships with macOS, no separate install needed)

## Project structure

```text
Sources/SonyTimecodeFixerApp/       SwiftUI UI layer
Resources/                          plist + Python conversion core
Assets/                             SVG icon source, generated .icns, screenshots
Examples/                           Minimal FCPXML / FCPXMLD test fixtures
scripts/                            Build, dmg, smoke-test, packaging scripts
ThirdParty/CommandPostSonySource/   Upstream reference snapshot
build/                              Release app output, gitignored
dist/                               DMG output, gitignored
```

The UI is SwiftUI, but the actual work is done by a Python script (ported from CommandPost's Lua implementation). The Swift layer only handles UI, drag-and-drop, and dispatch.

## Tests

```bash
make test
```

Tests cover FCPXML / FCPXMLD parsing, Sony M01.XML matching, and timecode arithmetic. `Examples/` contains minimal fixtures that exercise the full pipeline.

Smoke-test app launch:

```bash
make smoke
```

Validate the DMG packaging flow:

```bash
make package-test
```

## Credits

Honestly, this project is mostly a standalone Mac app wrapper around [CommandPost](https://commandpost.io/)'s Sony Timecode Toolbox. The actual work — reading Sony M01.XML, parsing MP4 tail metadata, computing correct timecodes, writing everything back into FCPXML — was figured out by the CommandPost team years ago.

The reference module:

https://github.com/CommandPost/CommandPost/tree/develop/src/plugins/finalcutpro/toolbox/sonytimecode

CommandPost is MIT-licensed. Full attribution lives in `NOTICE`.

If this tool is useful to you, please also go give [CommandPost](https://github.com/CommandPost/CommandPost) a star — they're the real upstream. This project is just a lighter entry point sitting on top of their work.

## License

MIT. See `LICENSE`.
