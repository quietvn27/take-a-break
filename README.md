# Take a Break

A lightweight macOS menu bar app that enforces screen breaks to protect your eyes and reduce fatigue during long work sessions.

## How it works

Take a Break runs two independent break timers in the background:

| Break type | Default interval | Default duration |
|---|---|---|
| **Micro break** (eye rest) | Every 5 minutes | 15 seconds |
| **Macro break** (long break) | Every 20 minutes | 5 minutes |

When a break fires, a full-screen dark overlay covers your display. You must wait out the countdown or click the skip button to dismiss it.

**Smart scheduling:** If a micro break is due within 45 seconds of an upcoming macro break, the micro break is skipped automatically. After a macro break ends, both timers reset from zero.

## Installation

1. Open `TakeABreak.dmg`
2. Drag **TakeABreak** into the **Applications** folder
3. Launch the app — a 👁 eye icon appears in your menu bar

**First launch:** macOS Gatekeeper will block the app since it is not notarized. Right-click the app → **Open** → **Open** to bypass this once. Alternatively, run:

```bash
xattr -dr com.apple.quarantine /Applications/TakeABreak.app
```

The app registers itself to **launch at login** automatically on first run. You can toggle this in Settings.

## Usage

Click the 👁 icon in the menu bar to access controls:

| Menu item | Action |
|---|---|
| **Pause** | Stop break timers until you resume |
| **Resume** | Restart timers from zero |
| **Settings…** | Open the settings window |
| **Quit** | Exit the app |

### During a break

A full-screen overlay appears with a countdown timer. Click **Skip Break** (micro) or **Stop Break** (macro) to dismiss early and resume working.

### Settings

Open **Settings…** from the menu bar to configure durations (in seconds):

- **Micro break — Work for:** how long between eye-rest breaks (default 300s = 5 min)
- **Micro break — Break for:** duration of each eye-rest break (default 15s)
- **Macro break — Work for:** how long between long breaks (default 1200s = 20 min)
- **Macro break — Break for:** duration of each long break (default 300s = 5 min)
- **Launch at Login:** start Take a Break automatically when you log in

Changes take effect immediately — the timers restart with the new values when you click **Save**.

## Requirements

- macOS 13 Ventura or later
