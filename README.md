# FxConsole

Theme-aware terminal output for PowerShell 7+ with animated spinners, styled text, cards, step tracking, and color presets.

Zero dependencies. Works out of the box with a built-in theme, or load custom presets from JSON.

## Quick Start

```powershell
Import-Module ./src/FxConsole/FxConsole.psd1
Set-FxTheme  # uses built-in default theme

Invoke-FxScript {
    Write-FxBanner 'MY APP' -Subtitle 'v1.0.0'

    Write-FxHeader 'Setup'
    Write-FxLabel 'Platform' 'Windows 11'

    Write-FxStep 'INSTALL PACKAGES'
    Write-FxShimmer 'express' -Frames 20 -Prefix '   ' -Intensity 0.5
    Write-FxStep 'express' -Prefix '   ' -Sub
    Complete-FxSection 'INSTALL PACKAGES' -SubCount 1

    Write-FxStatus 'Build passed' Success

    Write-FxCard 'Summary' -Width 40 -Lines @(
        "$(Format-Fx 'Status:' Muted) $(Format-Fx 'Ready' Success)"
    )
}
```

## Requirements

- PowerShell 7.0+
- A terminal with true color (24-bit ANSI) support: Windows Terminal, iTerm2, most modern terminals

No external modules, no NuGet packages, no npm.

## Installation

Copy the `src/FxConsole/` directory into your project. That's it.

The directory contains the module files and `theme-config.json` for additional theme presets beyond the built-in default.

## API Reference

### Theme

| Function | Description |
|---|---|
| `Set-FxTheme [preset]` | Load a theme. No args = built-in default. Add `-ConfigPath` for custom JSON. |
| `Get-FxTheme` | Returns the active ANSI color hashtable |
| `Get-FxThemeRgb` | Returns the active RGB hashtable (for custom rendering) |
| `Get-FxPresetName` | Display name of the active preset (e.g. "Amber Classic") |
| `Get-FxPresets` | List all available presets (built-in + loaded) |
| `Get-FxSpinners` | List all spinner styles with character previews |
| `Get-FxBullets` | List all bullet styles with character previews |

### Text Output

| Function | Description |
|---|---|
| `Write-Fx 'text' [Color]` | Write a line of themed text |
| `Write-Fx 'text' Primary -NoNewline` | Write without trailing newline |
| `Write-FxBlankLine [-Count n]` | Write blank lines |
| `Write-FxLabel 'Key' 'Value'` | Write a label: value pair |
| `Write-FxHeader 'Section'` | Write a spaced uppercase section header |
| `Write-FxSeparator [-Width n]` | Write a subtle divider line |
| `Write-FxStatus 'msg' Success` | Write a status message with icon (Info/Success/Error/Warn/Process/Complete) |

### Formatting

| Function | Description |
|---|---|
| `Format-Fx 'text' Color` | Returns a colored string for inline composition |

```powershell
# Compose colored strings naturally
"$(Format-Fx 'Status:' Muted) $(Format-Fx 'Online' Success)"
```

### Steps & Animation

| Function | Description |
|---|---|
| `Write-FxStep 'text'` | In-progress marker |
| `Write-FxStep 'text' -Done` | Completed marker |
| `Write-FxStep 'text' -Sub` | Substep marker |
| `Complete-FxSection 'header' -SubCount n` | Rewrite a step header as done after substeps finish |
| `Write-FxShimmer 'text'` | Animated shimmer (decorative, fixed frames) |
| `Write-FxShimmer 'text' -Spinner arrows` | Override spinner style for one call |
| `Invoke-FxJob 'text' { scriptblock }` | Shimmer while real work runs in background |

### Structural

| Function | Description |
|---|---|
| `Write-FxBanner 'Title' [-Subtitle 'text']` | Double-bordered title box |
| `Write-FxCard 'Title' -Lines @(...)` | Bordered card with optional title |
| `Write-FxPanel @('line1', 'line2')` | Auto-width bordered panel |

### Tables & Data Display

| Function | Description |
|---|---|
| `Write-FxTable -Headers @(...) -Rows @(...)` | Bordered table with auto-calculated column widths |
| `Write-FxTable -BorderStyle Minimal` | Horizontal lines only, no vertical borders |
| `Write-FxTable -Compact` | Reduced cell padding |
| `Write-FxTable -Alignment @('Left','Right')` | Per-column alignment (Left, Right, Center) |
| `Get-Process \| Write-FxTable` | Pipeline input — property names become headers |
| `Write-FxTable ... -PassThru` | Return rendered lines as strings instead of writing |
| `Write-FxGrid -Items @(...) -Columns 3` | Borderless multi-column layout |

```powershell
# Table with colored cells
Write-FxTable -Headers @('Name','Status','Size') -Rows @(
    ,@('api-server', (Format-Fx 'running' Success), '142 MB')
    ,@('worker',     (Format-Fx 'stopped' Error),   '89 MB')
)

# Pipeline input
Get-Process | Select-Object Name,CPU,WorkingSet | Write-FxTable

# Dashboard grid
Write-FxGrid -Columns 3 -Items @(
    (Format-Fx 'CPU: 42%' Primary)
    (Format-Fx 'MEM: 68%' Warning)
    (Format-Fx 'DISK: 91%' Error)
)
```

Border styles: `Rounded` (default), `Square`, `Double`, `Heavy`, `Minimal`, `None`

### Harness

| Function | Description |
|---|---|
| `Invoke-FxScript { ... }` | Wraps script in UTF-8 + cursor visibility try/finally |

## Themes

### Built-in

The `default` theme works with no external files. Bootstrap-inspired color palette with triangles spinner and check bullets.

### JSON Presets

Drop a `theme-config.json` next to the module (or pass `-ConfigPath`) to add presets:

```json
{
  "presets": {
    "mytheme": {
      "name": "My Theme",
      "spinner": "braille",
      "bullets": "diamond",
      "primary": [100, 200, 255],
      "primary-dim": [70, 150, 200],
      "secondary": [80, 140, 200],
      "tertiary": [60, 110, 170],
      "success": [80, 220, 160],
      "success-dim": [55, 170, 120],
      "error": [230, 100, 100],
      "warning": [230, 190, 80],
      "info": [100, 160, 220],
      "muted": [120, 120, 136],
      "bezel": [55, 55, 65]
    }
  }
}
```

Preset names are validated dynamically, new presets work immediately.

### Included Presets (theme-config.json)

| Preset | Name | Spinner | Bullets |
|---|---|---|---|
| default | Default | triangles | check |
| amber | Amber Classic | bars | scope |
| green | Matrix Green | braille | check |
| cyan | Cyan Ice | orbit | diamond |
| blue | Deep Blue | quarters | square |
| purple | Violet Haze | pulse | star |
| white | Clean White | dots | minimal |
| rainbow | Prism | arrows | circle |
| barbie | Barbie | bounce | star |

### Spinners

13 built-in spinner styles. Themes reference them by name.

| Id | Characters | Description |
|---|---|---|
| arc | `◜◝◞◟` | Quarter arc sweeping around |
| arrows | `←↖↑↗→↘↓↙` | Directional compass rotation |
| bars | `▁▂▃▄▅▆▇█▇▆▅▄▃▁` | Vertical block fill wave |
| bounce | `⠁⠂⠄⡀⠄⠂` | Braille dot bouncing vertically |
| braille | `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏` | Classic braille dot spinner |
| circle | `◐◓◑◒` | Half-filled circle rotation |
| classic | `-\|/` | ASCII line rotation |
| dots | `⠈⠀⠁⠀` | Minimal braille blink |
| orbit | `⠁⠈⠐⠠⢀⡀⠄⠂` | Single dot circling braille grid |
| pipe | `┤┘┴└├┌┬┐` | Box drawing corner rotation |
| pulse | `◡⊙◠` | Pulsing lens |
| quarters | `▖▘▝▗` | Quarter block rotation |
| triangles | `◢◣◤◥` | Triangle rotation |

### Bullets

8 built-in bullet styles for step markers.

| Id | Pending | Done | Sub |
|---|---|---|---|
| scope | ○ | ◉ | - |
| check | ○ | ✓ | ▸ |
| diamond | ◇ | ◆ | ▹ |
| square | □ | ■ | ▪ |
| circle | ○ | ● | ◦ |
| star | ☆ | ★ | · |
| arrow | ▷ | ▶ | ▸ |
| minimal | · | ✓ | - |

## Examples

Run the theme demo:

```powershell
./examples/test-themes.ps1 -ShowAll      # cycle all themes
./examples/test-themes.ps1 -Preset amber # single theme
./examples/example-script.ps1            # basic usage pattern
```

## License

MIT
