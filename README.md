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
2. Double click `build-local-dmg.command` to build a local installer DMG
3. Open `dist/macos-soundboard-unsigned.dmg`, then drag `macOS Soundboard.app` to Applications
4. Launch the app and use the menu bar options `Choose Exit mp3`, `Choose Open mp3`, and `Choose Message mp3` to assign your sound files

### Option 2: Build zip

1. Download this repo into a local folder
2. Double click `build-local-zip.command` to build a local app zip
3. Open `dist/macos-soundboard-unsigned.zip`, then move `macOS Soundboard.app` to Applications
4. Launch the app and use the menu bar options `Choose Exit mp3`, `Choose Open mp3`, and `Choose Message mp3` to assign your sound files

### Option 3: Terminal

1. Install Command Line Tools or Xcode.
2. In the folder, run:

```bash
swift run
```

3. Launch the app and use the menu bar options `Choose Exit mp3`, `Choose Open mp3`, and `Choose Message mp3` to assign your sound files

## Avoid Double Notification Sounds

This app doesn't suppress the original notification sounds from your apps, so you'll need to open `System Settings > Notifications`, choose each app you care about, and turn off `Play sound for notification`.

## Install Notes

- Playing notification sounds requires Accessibility access so the app can inspect Notification UI
- Lid-angle monitoring leverages private, reverse-engineered hardware behavior discovered by [@samhenrigold](https://github.com/samhenrigold/LidAngleSensor). Lid close/sleep sounds do not work for M1 Air and M1 Pro models.
- This is a side-loaded utility for `macOS 13+`.
