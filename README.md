# AIM Sound Utility

Tiny macOS menu bar app that plays custom AIM-style sounds when your Mac sleeps or wakes.

## Features

- `aim-exit.mp3` when the Mac is going to sleep
- `aim-open.mp3` when the Mac wakes
- optional lid open/closed inference using `AppleClamshellState`
- left-click menu bar icon toggles sounds on or off
- right-click menu bar icon shows status and `Quit`

## Install

### Option 1: Terminal

1. Install Xcode or the Command Line Tools.
2. In this folder, run:

```bash
swift run
```

The app will launch in the menu bar.

### Option 2: Xcode

1. Open this folder as a Swift package in Xcode.
2. Run the `AIMSoundUtility` target.

## Notes

- This is a side-loaded utility for `macOS 13+`.
- System-wide replacement of arbitrary third-party notification sounds is not implemented, because macOS does not expose a reliable public API for that.
