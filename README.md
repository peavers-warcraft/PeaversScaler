# PeaversScaler

[![AddonSentry](https://addonsentry.io/api/public/repos/peavers-warcraft/PeaversScaler/badge.svg)](https://addonsentry.io/dashboard/peavers-warcraft/PeaversScaler)

A World of Warcraft addon that scales the entire UI with resolution presets, a freeform slider, and pixel-perfect mode.

## Features

<!-- peavers:features -->
- Freeform slider to scale the whole WoW UI to any value (0.25 – 1.25)
- One-click presets for 1080p, 1440p, and 4K
- Pixel-perfect mode (768 ÷ screen height) for crisp 1:1 rendering, like classic ElvUI
- Supports scales below Blizzard's 0.64 slider floor
- Completely inert until you enable it — never touches your UI without opt-in
- One-click restore that undoes everything, returning the scale you had before the addon changed anything
<!-- /peavers:features -->

## Usage

<!-- peavers:usage -->
Open the settings with `/pscaler config`, tick **Enable UI scaling**, then pick a preset, press **Set Pixel Perfect**, or drag the slider.

### Slash Commands

- `/pscaler` - Open settings
- `/pscaler pp` - Apply pixel-perfect scale for your screen
- `/pscaler set N` - Set a specific scale (e.g. `/pscaler set 0.65`)
- `/pscaler enable` / `/pscaler disable` - Toggle scaling (disable restores your original scale)
- `/pscaler restore` - Undo everything: restore the scale you had before PeaversScaler changed anything
- `/pscaler info` - Print scale diagnostics (screen size, configured vs applied scale)
<!-- /peavers:usage -->


## Installation

### Recommended: PeaversUpdater

Download and install [PeaversUpdater](https://github.com/peavers-warcraft/PeaversUpdater/releases/latest), the desktop updater for the whole Peavers collection. It installs PeaversScaler together with its required dependencies and delivers updates before they reach CurseForge.

### Alternative: CurseForge

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/peaversscaler)
2. Ensure [PeaversCommons](https://www.curseforge.com/wow/addons/peaverscommons) is also installed
3. Ensure [PeaversConfig](https://www.curseforge.com/wow/addons/peaversconfig) is also installed
4. Enable the addon on the character selection screen

---

*Part of the [Peavers](https://peavers.io) addon collection · [Report an issue](https://github.com/peavers-warcraft/PeaversScaler/issues) · [Support development on Patreon](https://www.patreon.com/Peavers)*
