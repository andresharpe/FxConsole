# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FxConsole is a zero-dependency PowerShell 7+ module for styled terminal output — themed colors, shimmer animations, spinners, tables, box drawing, and progress markers. All rendering uses 24-bit ANSI via `$PSStyle.Foreground.FromRgb()`.

## Running & Testing

```powershell
# Import the module
Import-Module ./src/FxConsole/FxConsole.psd1

# Run examples
./examples/example-script.ps1              # Basic usage demo
./examples/test-themes.ps1 -ShowAll        # Cycle all themes
./examples/test-themes.ps1 -Preset amber   # Single theme

# Run tests (Pester 5+)
Invoke-Pester ./tests                      # All tests
Invoke-Pester ./tests -Output Detailed     # Verbose output
Invoke-Pester ./tests/Write-FxTable.Tests.ps1  # Single test file
```

## Repository Layout

```
src/FxConsole/          # Module root
  FxConsole.psd1        # Manifest (version, exports)
  FxConsole.psm1        # Module state + dot-sources Public/ and Private/
  theme-config.json     # 9 color presets
  Public/               # Exported functions (one file per function group)
  Private/              # Internal helpers (not exported)
tests/                  # Pester 5 test files
examples/               # Demo scripts
docs/                   # Roadmap
```

## Architecture

The `.psm1` declares all module state (theme, spinners, bullets, box chars), then dot-sources `Private/*.ps1` and `Public/*.ps1`. Exports are discovered via AST parsing of public files — no manual export list in the .psm1.

### Module State (script-scoped variables)

- `$script:ModuleRoot` — path to module directory (used for theme-config.json discovery)
- `$script:Theme` / `$script:ThemeRgb` / `$script:PresetName` — active color set
- `$script:Spinners` (9 styles) / `$script:SpinChars` — spinner frame arrays
- `$script:BulletSets` / `$script:Bullets` — bullet character sets (8 styles)
- `$script:BoxChars` / `$script:BoxJunctions` — box drawing + table junction characters

### Preset System

A built-in default (bootstrap-inspired) is defined in code. JSON presets are loaded lazily on first `Set-FxTheme` call. Each preset maps semantic color names (`Primary`, `Secondary`, `Success`, `Error`, `Muted`, etc.) to RGB values, plus a spinner style and bullet set.

The **rainbow** preset is special-cased: it uses per-character HSV hue cycling via `Convert-HsvToRgb` instead of fixed RGB colors.

### Key Internal Helpers

- `Render-ShimmerFrame` — core animation renderer with sine-wave position offsets and flicker randomization
- `Get-FxVisualWidth` — strips ANSI escapes to measure true display width (critical for tables, box drawing, padding)
- `Get-FxPaddedText` — pads text to exact width accounting for ANSI escape sequences, supports Left/Right/Center
- `Convert-HsvToRgb` — HSV→RGB for rainbow mode

### Table Row Syntax

`Write-FxTable -Rows` uses PowerShell's `,@()` syntax to prevent array flattening. The function normalizes rows by unwrapping the extra nesting level this creates. Pipeline input is the preferred alternative.

### Animation Technique

Shimmer/spinner animations use carriage return (`\r`) for in-place line updates. `Complete-FxSection` uses ANSI cursor movement escapes (`ESC[nA` / `ESC[nB`) to rewrite previous lines. `Invoke-FxJob` spawns a `[PowerShell]::Create()` runspace and polls completion at 55ms intervals while rendering shimmer frames.

## Naming Conventions

All public functions follow `Verb-FxNoun` (e.g., `Write-FxStep`, `Set-FxTheme`, `Invoke-FxJob`). Internal helpers omit the `Fx` prefix or use non-standard verbs (e.g., `Render-ShimmerFrame`).

## Requirements

- PowerShell 7.0+ (uses `$PSStyle`)
- Terminal with 24-bit (true color) ANSI support
- Pester 5+ for running tests
