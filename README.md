# Rectus

A tiny macOS menu bar app that reminds you to sit up straight.

Start a session from the menu bar; while it runs, a small box appears at the top of your
screen at the interval you chose ("Sit up straight — shoulders back, chest open"), with an
optional soft sound.

*Rectus* is Latin for "upright, straight". It's also the name of the *rectus abdominis*,
one of the muscles that holds your posture.

## Features

- Lives in the menu bar; while a session runs, the minutes until the next reminder show next to the icon
- Session length: 30 min, 1 hour, 2 hours, or until stopped
- Reminder interval: every 10, 15, 20 or 30 min
- Reminder: a box at the top center of the screen for 5 seconds, plus an optional sound
- The box never steals focus, so your typing doesn't jump into it
- After the Mac wakes from sleep, missed reminders don't fire back to back; you get just one
- Remembers your last settings
- No Dock icon, ~200 KB

## Install

Requires macOS 14+ and Swift 6 (Xcode, or just the Command Line Tools: `xcode-select --install`).

```bash
git clone https://github.com/Efekan18/Rectus.git
cd Rectus
./build.sh --install
```

The app is installed as `~/Applications/Rectus.app` and launched.
To start it at login: System Settings → General → Login Items → add Rectus.

During development you can run it directly with `swift run`; the debug build also offers a
1-minute interval for testing.

## Why not system notifications?

macOS doesn't grant notification permission to ad-hoc signed apps (apps without a paid
Apple Developer signature). Our own box needs no permission and still shows in Focus mode,
which is what you want from a posture reminder anyway.

## Structure

| File | Purpose |
| --- | --- |
| `Sources/Rectus/RectusApp.swift` | Entry point, menu bar icon and menu |
| `Sources/Rectus/ReminderSession.swift` | Timing: session end, next reminder |
| `Sources/Rectus/ReminderPanel.swift` | The on-screen box + sound |
| `Resources/Info.plist` | App identity; `LSUIElement` keeps it out of the Dock |
| `build.sh` | Build → package `.app` → sign → install |

## How it was made

The code was written by [Claude Code](https://claude.com/claude-code). The idea,
requirements, choice of approach, testing and daily use are mine, including a bug I found
in use: the open menu shifted every second. The reasoning behind each step is in the
commit history.

## License

[MIT](LICENSE)
