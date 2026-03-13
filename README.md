# AIM Sound Utility

Tiny macOS menu bar app that plays custom AIM-style sounds when your Mac sleeps, wakes, locks, unlocks, opens and closes a laptop lid, and shows notification banners.

## Features

- `aim-exit.mp3` when the Mac goes to sleep, locks, or the lid closes
- `aim-open.mp3` when the Mac wakes, unlocks, or the lid opens
- `aim-message.mp3` when supported notification banners appear, including Slack
- lid-close detection combines `AppleClamshellState` polling with HID lid-angle monitoring for faster close events
- duplicate open and close sounds are debounced to avoid double playback around wake and unlock transitions
- duplicate notification banner events are deduplicated so one banner only plays one AIM sound
- lid-close sounds are suppressed on `MacBookAir10,1` (`M1 MacBook Air`) to avoid false positives on that hardware
- left-click menu bar icon toggles the app on or off
- menu bar icon switches between the on/off AIM icons and shows `Running` or `Off` on hover
- right-click menu bar icon exposes notification sound setup, laptop open/close sound toggles, and `Quit`

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
- Notification banner detection requires Accessibility access so the app can inspect Notification Center UI.
- Once Accessibility access is granted, the setup prompt disappears from the right-click menu and notification sounds show as enabled.
- Notification sound replacement is additive: the app plays `aim-message.mp3` when supported banners appear, but it does not suppress the original app or macOS notification sound.

## Avoid Double Sounds

If you want AIM-only notification audio, open `System Settings > Notifications`, choose each app you care about, and turn off `Play sound for notification`.

That works especially well for apps like Slack that already show standard macOS notification banners.

## Menu Controls

- `Notification sounds: Click to enable` opens Accessibility settings until notification banner access is granted.
- `Laptop close sound` can be enabled or disabled independently from the rest of the app.
- `Laptop open sound` can be enabled or disabled independently from the rest of the app.
