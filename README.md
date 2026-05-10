# Take a Break

A lightweight macOS menu bar app that enforces screen breaks to protect your eyes and reduce fatigue during long work sessions.

## How it works

Take a Break runs two independent break timers in the background:

| Break type | Default interval | Default duration |
|---|---|---|
| **Micro break** (eye rest) | Every 15 minutes | 15 seconds |
| **Macro break** (long break) | Every 60 minutes | 5 minutes |

When a break fires, a full-screen overlay covers your display. You must wait out the countdown or click the skip button to dismiss it.

**Smart scheduling:** If a micro break is due within 45 seconds of an upcoming macro break, the micro break is skipped automatically. After a macro break ends, both timers reset from zero.

## Installation

1. Open `TakeABreak.dmg`
2. Drag **TakeABreak** into the **Applications** folder
3. Launch the app — a eye icon appears in your menu bar

**First launch:** macOS Gatekeeper will block the app since it is not notarized. Right-click the app → **Open** → **Open** to bypass this once. Alternatively, run:

```bash
xattr -dr com.apple.quarantine /Applications/TakeABreak.app
```

The app registers itself to **launch at login** automatically on first run. You can toggle this in Settings.

## Usage

Click the eye icon in the menu bar to open Settings, where you can:

- Toggle breaks **On / Off** with a single switch
- See a **live countdown** to the next micro and macro break
- Adjust all durations
- Choose the overlay style

### During a break

A full-screen overlay appears with a countdown timer. Click **Skip Break** (micro) or **Stop Break** (macro) to dismiss early and resume working.

### Settings

Open **Settings…** from the menu bar to configure:

| Setting | Default | Unit |
|---|---|---|
| Micro break — Work for | 15 | minutes |
| Micro break — Break for | 15 | seconds |
| Macro break — Work for | 60 | minutes |
| Macro break — Break for | 5 | minutes |

- **Overlay style:** Choose between **Simple** (solid dark overlay) or **Animation** (animated overlay)
- **On/Off toggle:** Pause all breaks without quitting the app

Changes take effect immediately when you click **Save**.

## Requirements

- macOS 13 Ventura or later

## Build from source

```bash
git clone https://github.com/your-username/take-a-break.git
cd take-a-break
open TakeABreak.xcodeproj
```

Build and run with **Cmd+R** in Xcode, or build a distributable DMG:

```bash
./build_dmg.sh
```
