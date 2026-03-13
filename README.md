# AIM Sound Utility

Tiny macOS menu bar app that plays custom AIM-style sounds when your Mac sleeps, wakes, locks, unlocks, or opens and closes a laptop lid.

## Features

- `aim-exit.mp3` when the Mac goes to sleep, locks, or the lid closes
- `aim-open.mp3` when the Mac wakes, unlocks, or the lid opens
- lid-close detection combines `AppleClamshellState` polling with HID lid-angle monitoring for faster close events
- duplicate open and close sounds are debounced to avoid double playback around wake and unlock transitions
- lid-close sounds are suppressed on `MacBookAir10,1` (`M1 MacBook Air`) to avoid false positives on that hardware
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
- Lid-angle monitoring uses private, reverse-engineered hardware behavior and may vary across Mac models.
- System-wide replacement of arbitrary third-party notification sounds is not implemented, because macOS does not expose a reliable public API for that.
