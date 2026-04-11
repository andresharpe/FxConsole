# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FxConsole is a zero-dependency PowerShell 7+ module for styled terminal output — themed colors, shimmer animations, spinners, box drawing, and progress markers. All rendering uses 24-bit ANSI via `$PSStyle.Foreground.FromRgb()`.

## Running & Testing

```powershell
# Import the module
Import-Module ./FxConsole.psd1

# Run examples
./examples/example-script.ps1              # Basic usage demo
./examples/test-themes.ps1 -ShowAll        # Cycle all themes
./examples/test-themes.ps1 -Preset amber   # Single theme
```

There is no formal build, lint, or test framework yet. No Pester tests exist (planned for v2.0).

## Architecture

**Single-file module**: All logic lives in `FxConsole.psm1` (~670 lines), exporting 30 public functions and 6 internal helpers. `FxConsole.psd1` is the manifest. `theme-config.json` defines 9 color presets.

### Module State (script-scoped variables)

- `$script:Theme` / `$script:ThemeRgb` / `$script:PresetName` — active color set
- `$script:Spinners` (9 styles) / `$script:SpinChars` — spinner frame arrays
- `$script:BulletSets` / `$script:Bullets` — bullet character sets (8 styles)
- `$script:BoxChars` — box drawing character sets (Rounded, Square, Double, Heavy)

### Preset System

A built-in default (bootstrap-inspired) is defined in code. JSON presets are loaded lazily on first `Set-FxTheme` call. Each preset maps semantic color names (`Primary`, `Secondary`, `Success`, `Error`, `Muted`, etc.) to RGB values, plus a spinner style and bullet set.

The **rainbow** preset is special-cased: it uses per-character HSV hue cycling via `Convert-HsvToRgb` instead of fixed RGB colors.

### Key Internal Helpers

- `Render-ShimmerFrame` — core animation renderer with sine-wave position offsets and flicker randomization
- `Get-FxVisualWidth` — strips ANSI escapes to measure true display width (critical for box drawing and padding)
- `Get-FxPaddedText` — pads text to exact width accounting for ANSI escape sequences
- `Convert-HsvToRgb` — HSV→RGB for rainbow mode

### Animation Technique

Shimmer/spinner animations use carriage return (`\r`) for in-place line updates. `Complete-FxSection` uses ANSI cursor movement escapes (`ESC[nA` / `ESC[nB`) to rewrite previous lines. `Invoke-FxJob` spawns a `[PowerShell]::Create()` runspace and polls completion at 55ms intervals while rendering shimmer frames.

## Naming Conventions

All public functions follow `Verb-FxNoun` (e.g., `Write-FxStep`, `Set-FxTheme`, `Invoke-FxJob`). Internal helpers omit the `Fx` prefix or use non-standard verbs (e.g., `Render-ShimmerFrame`).

## Requirements

- PowerShell 7.0+ (uses `$PSStyle`)
- Terminal with 24-bit (true color) ANSI support
