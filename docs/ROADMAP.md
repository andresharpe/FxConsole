# FxConsole - Proposed Roadmap

> Inspired by Spectre.Console (.NET), Rich (Python), Bubbletea (Go), Blessed-contrib, Ink, Ora, and Listr2.
> Positioned to fill the gap between PowerShell's limited built-in output and heavy .NET wrapper modules like PwshSpectreConsole.

## Design Principles

- **Zero dependencies** - Pure PowerShell 7+, no NuGet, no npm
- **Simple by default** - One-liner for common tasks, parameters for power users
- **PowerShell idiomatic** - `Verb-FxNoun` naming, pipeline-friendly, `-Switch` parameters
- **Theme-driven** - All visual output respects the active theme
- **Graceful degradation** - Detect terminal capabilities, fall back for non-TTY environments

---

## v1.0 - Foundation (Current)

What ships today.

- [x] Theme system with built-in default + JSON presets
- [x] Dynamic preset validation (no hardcoded ValidateSet)
- [x] 9 color presets (default, amber, green, cyan, blue, purple, white, rainbow, barbie)
- [x] 9 spinner styles, 8 bullet sets, referenced by theme
- [x] `Format-Fx` for inline string composition
- [x] `Write-Fx`, `Write-FxLabel`, `Write-FxHeader`, `Write-FxSeparator`, `Write-FxStatus`
- [x] `Write-FxStep` with pending/done/sub states
- [x] `Complete-FxSection` (cursor-up rewrite, hides escape sequences)
- [x] `Write-FxShimmer` with per-call `-Spinner` override
- [x] `Invoke-FxJob` (shimmer while scriptblock runs in background runspace)
- [x] `Write-FxBanner`, `Write-FxCard`, `Write-FxPanel`
- [x] `Invoke-FxScript` harness (UTF-8, cursor visibility, try/finally)
- [x] `Write-FxBlankLine`
- [x] Rainbow hue-cycling shimmer for Prism theme

---

## v1.1 - Tables & Data Display (Done)

- [x] `Write-FxTable` — auto-calculated column widths, ANSI-aware sizing, 6 border styles, column alignment, pipeline input, compact mode, PassThru
- [x] `Write-FxGrid` — borderless multi-column dashboard layout with auto-width columns
- [x] Pester 5 test suite (76 tests)
- [x] Canonical PowerShell module layout (`src/FxConsole/Public/` + `Private/`)

---

## v1.2 - Progress Bars (Done)

- [x] `Write-FxProgress` — themed progress bar with filled/empty blocks, percentage, elapsed time, ETA, custom bar/track colors, width, status text
- [x] `Invoke-FxProgress` — pipeline-aware wrapper with automatic progress tracking, scriptblock execution, passthrough output
- [x] `Invoke-FxScript` suppresses native `Write-Progress` ($ProgressPreference) within the harness
- [x] Multiple independent activities tracked via per-activity stopwatch timers

---

## v1.3 - Interactive Prompts

No PowerShell module currently offers styled, themed prompts that integrate with a color system.

### Read-FxChoice

Single selection from a list with arrow key navigation.

```powershell
$env = Read-FxChoice 'Deploy to which environment?' @('Development','Staging','Production')
```

- Arrow key navigation with highlighted selection
- Themed colors for selection indicator
- Page size for long lists
- Search/filter as you type
- Default selection support

### Read-FxMultiChoice

Multi-selection with spacebar toggle.

```powershell
$features = Read-FxMultiChoice 'Enable which features?' @('Auth','Logging','Cache','Metrics')
```

### Read-FxConfirm

Styled yes/no confirmation.

```powershell
if (Read-FxConfirm 'Deploy to production?') { ... }
```

### Read-FxText

Styled text input with validation.

```powershell
$name = Read-FxText 'Project name' -Validate { $_ -match '^\w+$' }
$secret = Read-FxText 'API key' -Secret
```

---

## v1.4 - Live Display & Dashboards

Real-time updating widgets without scrolling. Inspired by Spectre.Console's `LiveDisplay` and Blessed-contrib's dashboard widgets.

### Invoke-FxLive

Update any renderable in-place.

```powershell
Invoke-FxLive {
    param($ctx)
    while ($true) {
        $data = Get-Metrics
        $ctx.Update(
            Write-FxTable -PassThru -Headers @('Metric','Value') -Rows @(
                ,@('CPU', "$($data.Cpu)%")
                ,@('Memory', "$($data.Mem)%")
            )
        )
        Start-Sleep -Seconds 1
    }
}
```

### Write-FxSparkline

Compact inline trend visualization.

```powershell
Write-FxSparkline -Values @(3,7,2,9,4,8,1,6) -Width 20 -Color Primary
# Output: ▃▆▂█▄▇▁▅
```

### Write-FxGauge

Percentage gauge with label.

```powershell
Write-FxGauge -Label 'CPU' -Percent 73 -Width 30
# Output: CPU [████████████████████░░░░░░░░░░] 73%
```

### Write-FxBarChart

Horizontal bar chart for comparative data.

```powershell
Write-FxBarChart @(
    @{ Label = 'TypeScript'; Value = 8200; Color = 'Info' }
    @{ Label = 'PowerShell'; Value = 12400; Color = 'Primary' }
    @{ Label = 'CSS';        Value = 3100; Color = 'Secondary' }
)
```

---

## v1.5 - Trees & Hierarchy

### Write-FxTree

Hierarchical data with guide lines. Essential for directory structures, dependency graphs, and org charts.

```powershell
Write-FxTree @{
    'src' = @{
        'components' = @('Header.tsx', 'Footer.tsx')
        'services'   = @('api.ts', 'auth.ts')
    }
    'tests' = @('unit.test.ts', 'e2e.test.ts')
}
```

- Themable guide line characters
- Collapsible nodes (interactive mode)
- Color per node/level
- From filesystem: `Get-ChildItem -Recurse | Write-FxTree`

---

## v1.6 - Task Lists

Inspired by Listr2. Structured task execution with visual tracking for install scripts, migrations, and CI/CD.

### Invoke-FxTaskList

```powershell
Invoke-FxTaskList @(
    @{ Title = 'Install dependencies';  Action = { npm install } }
    @{ Title = 'Run migrations';        Action = { dotnet ef database update } }
    @{ Title = 'Build assets';          Action = { npm run build } }
    @{ Title = 'Run tests';             Action = { dotnet test } }
)
```

- Sequential or concurrent execution modes
- Nested subtask lists
- Automatic shimmer while running, step markers on complete
- Error handling with retry support
- Skip conditions: `-Skip { Test-Path ./node_modules }`
- Rollback actions on failure
- Summary card on completion

---

## v1.7 - Markup System

Inline styling without `Format-Fx` calls. Inspired by Spectre.Console's `[bold red]text[/]` syntax.

### Write-FxMarkup

```powershell
Write-FxMarkup 'Status: [Success]online[/] | CPU: [Warning]87%[/] | [dim]last check 2m ago[/]'
```

- `[ColorName]text[/]` syntax using theme color names
- `[bold]`, `[dim]`, `[italic]`, `[underline]` decorations
- Nestable: `[bold][Primary]important[/][/]`
- Works with all Write-Fx* functions that accept text

---

## v1.8 - Terminal Capability Detection

Auto-detect what the terminal supports and degrade gracefully.

### Get-FxTerminalInfo

```powershell
$term = Get-FxTerminalInfo
# Returns: ColorDepth (1/4/8/24), Unicode, Interactive, Width, Height, Name
```

- Detect color depth from `$env:COLORTERM`, `$env:TERM`, Windows Terminal settings
- Detect Unicode support (can we render box-drawing, braille, emoji?)
- Detect TTY vs piped/redirected output
- Auto-select ASCII fallback spinners/borders when Unicode unavailable
- Auto-disable animation when output is redirected
- Respect `$env:NO_COLOR` standard

### Non-TTY Fallback

When piped or in CI:
- Spinners become static text: `[*] Loading...`
- Progress bars become percentage text: `[50%] Building...`
- Cards/panels become indented text blocks
- Colors stripped automatically

---

## v1.9 - Logging Integration

Styled logging that works for both console display and file output.

### Write-FxLog

```powershell
Write-FxLog 'Server started on port 8080' -Level Info
Write-FxLog 'Connection pool exhausted' -Level Error
Write-FxLog 'Cache miss rate: 23%' -Level Warn -Data @{ rate = 23 }
```

- Themed log levels: Debug, Info, Warn, Error, Fatal
- Timestamp formatting
- Structured data attachment (JSON in file, inline in console)
- Dual output: styled console + clean file (ANSI stripped)
- JSONL file format for machine parsing
- Log rotation by size/date
- Context tags: `-Tag 'API'`, `-Tag 'DB'`

---

## v2.0 - Advanced Features

### Write-FxCalendar

Monthly calendar with highlighted dates.

```powershell
Write-FxCalendar -Month 4 -Year 2026 -Highlight @(
    @{ Date = '2026-04-15'; Color = 'Error'; Label = 'Deadline' }
    @{ Date = '2026-04-20'; Color = 'Success'; Label = 'Release' }
)
```

### Write-FxFiglet

Large ASCII art text using FIGlet fonts.

```powershell
Write-FxFiglet 'FxConsole' -Font 'slant'
```

### Write-FxException

Pretty, readable exception rendering with colored stack traces.

```powershell
try { ... } catch { Write-FxException $_ }
```

- Colored method names, file paths, line numbers
- Collapsible stack frames
- Inner exception chain display
- Clickable file paths (terminals that support hyperlinks)

### Write-FxDiff

Side-by-side or unified diff display with syntax coloring.

```powershell
Write-FxDiff -Before $oldConfig -After $newConfig
```

### Export-FxHtml

Capture styled output and export as HTML for reports and documentation.

```powershell
$recording = Start-FxRecording
# ... run commands ...
Stop-FxRecording | Export-FxHtml -Path report.html
```

---

## Future Considerations

### PSGallery Publishing

Publish as `Install-Module FxConsole` for frictionless adoption. Requires:
- Pester test suite
- CI/CD pipeline (GitHub Actions)
- Semantic versioning
- Changelog generation

### PowerShell 5.1 Compatibility

The current module requires PS 7+ for `$PSStyle`. A compatibility layer could:
- Use raw ANSI escapes instead of `$PSStyle.Foreground.FromRgb()`
- Detect PS version and adapt
- Expand audience significantly (Windows PowerShell still widely used)

### Pipeline Integration

Make FxConsole widgets pipeline-aware:

```powershell
# Dream API
Get-Service | Where Status -eq Running | Write-FxTable -AutoColor @{
    Status = @{ Running = 'Success'; Stopped = 'Error' }
}

Get-ChildItem -Recurse | Write-FxTree
1..100 | Invoke-FxProgress -Activity 'Processing'
```

### Performance Benchmarks

Measure and optimize:
- Rendering throughput (lines/sec)
- Memory usage for large datasets
- Shimmer frame rate stability
- Background job overhead in `Invoke-FxJob`

---

## Inspiration Sources

| Library | Language | Key Insight for FxConsole |
|---|---|---|
| [Spectre.Console](https://spectreconsole.net/) | .NET | Widget variety, live display, exception rendering |
| [Rich](https://rich.readthedocs.io/) | Python | Markup syntax, logging integration, inspect command |
| [Bubbletea](https://github.com/charmbracelet/bubbletea) | Go | Elm architecture for TUI, component composition |
| [Blessed-contrib](https://github.com/yaronn/blessed-contrib) | JS | Dashboard widgets: gauges, sparklines, donuts, LCD |
| [Ink](https://github.com/vadimdemedes/ink) | JS/React | Component model, flexbox layout for terminals |
| [Ora](https://github.com/sindresorhus/ora) | JS | Spinner UX, promise integration |
| [Listr2](https://github.com/listr2/listr2) | JS | Task list rendering, concurrent execution |
| [cli-table3](https://github.com/cli-table/cli-table3) | JS | Cell spanning, word wrapping with ANSI preservation |
| [PwshSpectreConsole](https://pwshspectreconsole.com/) | PS | What works (and what's too verbose) wrapping .NET for PS |

### PowerShell Ecosystem Gap

| Capability | Native PS | PSWriteColor | PwshSpectreConsole | **FxConsole** |
|---|---|---|---|---|
| Themed colors | `$PSStyle` (basic) | Simple | Full | Full |
| Tables | `Format-Table` (buggy) | No | Yes | v1.1 |
| Progress bars | `Write-Progress` (buggy) | No | Yes | v1.2 |
| Spinners | No | No | Yes | **v1.0** |
| Interactive prompts | No | No | Yes | v1.3 |
| Live display | No | No | Yes | v1.4 |
| Task lists | No | No | No | v1.6 |
| Markup syntax | No | No | Yes | v1.7 |
| Capability detection | No | No | No | v1.8 |
| Styled logging | No | Basic | No | v1.9 |
| Zero dependencies | N/A | Yes | No (.NET) | **Yes** |
| Theme presets | No | No | No | **v1.0** |
