# macOS Soundboard Utility

Tiny macOS menu bar app that lets you play custom sounds when your Macbook sleeps/wakes, locks/unlocks, opens/closes, and shows notification banners.

## Features

- Plays `exit.mp3` when your Mac sleeps, locks, or the lid closes
- Plays `open.mp3` when your Mac wakes, unlocks, or the lid opens
- Plays `message.mp3` for notification banners
- Lets you turn the app on or off from the menu bar
- Quick access to notification setup (allowing Accessibility)
- Bring your own soundfiles

## Install

### Option 1: Build dmg (recommended)

1. Download this repo into a local folder
2. Bring in your own mp3 files (`exit.mp3`, `open.mp3`, `message.mp3`) into the project folder
3. Double click [build-local-dmg.command](/Users/kev/Documents/mac-aim/build-local-dmg.command) to build a local installer DMG
4. Open `dist/macos-soundboard-unsigned.dmg`, then drag `macOS Soundboard.app` to Applications

### Option 2: Terminal

1. Install Xcode or the Command Line Tools.
2. Bring in your own mp3 files (`exit.mp3`, `open.mp3`, `message.mp3`) into the project folder
3. In the folder, run:

```bash
swift run
```

## Avoid Double Notification Sounds

This app doesn't suppress the original notification sounds from your apps, so you'll need to open `System Settings > Notifications`, choose each app you care about, and turn off `Play sound for notification`.

## Install Notes

- Playing notification sounds requires Accessibility access so the app can inspect Notification UI
- Lid-angle monitoring leverages private, reverse-engineered hardware behavior discovered by [@samhenrigold](https://github.com/samhenrigold/LidAngleSensor). Lid close/sleep sounds do not work for M1 Air and M1 Pro models.
- This is a side-loaded utility for `macOS 13+`.
