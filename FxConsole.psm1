# FxConsole - Theme-aware terminal output for PowerShell 7+
# Animated spinners, styled text, cards, and step tracking with color presets

# ═══════════════════════════════════════════════════════════════════
# MODULE STATE
# ═══════════════════════════════════════════════════════════════════

$script:Theme    = @{}
$script:ThemeRgb = @{}
$script:PresetName = 'amber'
$script:PresetDisplayName = 'Amber Classic'

# Active spinner and bullets (set by theme)
$script:SpinChars = @()
$script:Bullets   = @{ Pending = ''; Done = ''; Sub = '' }

# ── Spinner library ──
$script:Spinners = @{
    bars      = @([char]0x2581,[char]0x2582,[char]0x2583,[char]0x2584,[char]0x2585,[char]0x2586,[char]0x2587,[char]0x2588,[char]0x2587,[char]0x2586,[char]0x2585,[char]0x2584,[char]0x2583,[char]0x2581)
    braille   = @([char]0x280B,[char]0x2819,[char]0x2839,[char]0x2838,[char]0x283C,[char]0x2834,[char]0x2826,[char]0x2827,[char]0x2807,[char]0x280F)
    orbit     = @([char]0x2BFE,[char]0x2BFD,[char]0x2BFB,[char]0x28BF,[char]0x287F,[char]0x283F,[char]0x282F,[char]0x2837)
    dots      = @([char]0x2808,[char]0x2800,[char]0x2801,[char]0x2800)
    arrows    = @([char]0x2190,[char]0x2196,[char]0x2191,[char]0x2197,[char]0x2192,[char]0x2198,[char]0x2193,[char]0x2199)
    triangles = @([char]0x25E2,[char]0x25E3,[char]0x25E4,[char]0x25E5)
    quarters  = @([char]0x2596,[char]0x2598,[char]0x259D,[char]0x2597)
    pulse     = @([char]0x25E1,[char]0x2299,[char]0x25E0)
    classic   = @('-', '\', '|', '/')
}

# ── Bullet sets ──
$script:BulletSets = @{
    scope     = @{ Pending = [char]0x25CB; Done = [char]0x25C9; Sub = '-' }         # ○ ◉ -
    check     = @{ Pending = [char]0x25CB; Done = [char]0x2713; Sub = [char]0x25B8 } # ○ ✓ ▸
    diamond   = @{ Pending = [char]0x25C7; Done = [char]0x25C6; Sub = [char]0x25B9 } # ◇ ◆ ▹
    square    = @{ Pending = [char]0x25A1; Done = [char]0x25A0; Sub = [char]0x25AA } # □ ■ ▪
    circle    = @{ Pending = [char]0x25CB; Done = [char]0x25CF; Sub = [char]0x25E6 } # ○ ● ◦
    star      = @{ Pending = [char]0x2606; Done = [char]0x2605; Sub = [char]0x00B7 } # ☆ ★ ·
    arrow     = @{ Pending = [char]0x25B7; Done = [char]0x25B6; Sub = [char]0x25B8 } # ▷ ▶ ▸
    minimal   = @{ Pending = [char]0x00B7; Done = [char]0x2713; Sub = '-' }          # · ✓ -
}

$script:BoxChars = @{
    Rounded = @{ TL = [char]0x256D; TR = [char]0x256E; BL = [char]0x2570; BR = [char]0x256F; H = [char]0x2500; V = [char]0x2502 }
    Square  = @{ TL = [char]0x250C; TR = [char]0x2510; BL = [char]0x2514; BR = [char]0x2518; H = [char]0x2500; V = [char]0x2502 }
    Double  = @{ TL = [char]0x2554; TR = [char]0x2557; BL = [char]0x255A; BR = [char]0x255D; H = [char]0x2550; V = [char]0x2551 }
    Heavy   = @{ TL = [char]0x250F; TR = [char]0x2513; BL = [char]0x2517; BR = [char]0x251B; H = [char]0x2501; V = [char]0x2503 }
}

# ═══════════════════════════════════════════════════════════════════
# INTERNAL HELPERS
# ═══════════════════════════════════════════════════════════════════

function Convert-HsvToRgb {
    param([double]$H, [double]$S, [double]$V)
    $H = $H % 360; $c = $V * $S
    $x = $c * (1 - [Math]::Abs(($H / 60) % 2 - 1)); $m = $V - $c
    switch ([int]($H / 60)) {
        0 { $r = $c; $g = $x; $b = 0 }  1 { $r = $x; $g = $c; $b = 0 }
        2 { $r = 0; $g = $c; $b = $x }  3 { $r = 0; $g = $x; $b = $c }
        4 { $r = $x; $g = 0; $b = $c }  default { $r = $c; $g = 0; $b = $x }
    }
    @([int](($r+$m)*255), [int](($g+$m)*255), [int](($b+$m)*255))
}

function Get-FxVisualWidth {
    param([string]$Text)
    ($Text -replace '\x1b\[[0-9;]*m', '').Length
}

function Get-FxPaddedText {
    param([string]$Text, [int]$Width, [string]$Align = 'Left')
    $totalPad = [Math]::Max(0, $Width - (Get-FxVisualWidth $Text))
    switch ($Align) {
        'Left'   { $Text + (' ' * $totalPad) }
        'Right'  { (' ' * $totalPad) + $Text }
        'Center' { $l = [Math]::Floor($totalPad/2); (' '*$l) + $Text + (' '*($totalPad-$l)) }
    }
}

function Get-FxBufferWidth {
    try { [Console]::BufferWidth } catch { 120 }
}

function Render-ShimmerFrame {
    param([string]$Text, [string]$Prefix, [int]$Frame, [double]$Intensity,
          [int]$BaseR, [int]$BaseG, [int]$BaseB,
          [int]$AccR, [int]$AccG, [int]$AccB,
          [bool]$Rainbow, [int]$Pad)

    $line = [System.Text.StringBuilder]::new()
    $flicker = 0.96 + (Get-Random -Minimum 0 -Maximum 5) / 100.0

    $s = $script:SpinChars[$Frame % $script:SpinChars.Length]
    $pulse = 0.85 + 0.15 * [Math]::Sin($Frame * 0.5)
    if ($Rainbow) {
        $c = Convert-HsvToRgb -H ($Frame * 12 % 360) -S 0.85 -V ($pulse * $Intensity)
        $sr = $c[0]; $sg = $c[1]; $sb = $c[2]
    } else {
        $sr = [int][Math]::Min(255, [int]($AccR * $pulse * $Intensity))
        $sg = [int][Math]::Min(255, [int]($AccG * $pulse * $Intensity))
        $sb = [int][Math]::Min(255, [int]($AccB * $pulse * $Intensity))
    }
    [void]$line.Append("$([char]27)[38;2;${sr};${sg};${sb}m${Prefix} $s $([char]27)[0m")

    for ($i = 0; $i -lt $Text.Length; $i++) {
        $wave = [Math]::Sin(($i * 0.4) + ($Frame * 0.15))
        $glow = (0.78 + 0.22 * $wave) * $flicker * $Intensity
        if ($Rainbow) {
            $c = Convert-HsvToRgb -H (($i * 18 + $Frame * 6) % 360) -S 0.85 -V $glow
            $cr = $c[0]; $cg = $c[1]; $cb = $c[2]
        } else {
            $cr = [int][Math]::Min(255, $BaseR * $glow)
            $cg = [int][Math]::Min(255, $BaseG * $glow)
            $cb = [int][Math]::Min(255, $BaseB * $glow)
        }
        [void]$line.Append("$([char]27)[38;2;${cr};${cg};${cb}m$($Text[$i])")
    }
    [void]$line.Append("$([char]27)[0m".PadRight($Pad))
    [Console]::Write("`r$($line.ToString())")
}

# ═══════════════════════════════════════════════════════════════════
# THEME
# ═══════════════════════════════════════════════════════════════════

# Built-in default theme — no external files needed
$script:BuiltInPresets = @{
    default = @{
        name          = 'Default'
        spinner       = 'triangles'
        bullets       = 'check'
        primary       = @(59, 130, 246)      # Cleaner blue, slightly warmer than Bootstrap
        'primary-dim' = @(37, 99, 205)
        secondary     = @(148, 163, 184)     # Slate gray - more refined than Bootstrap's flat gray
        tertiary      = @(100, 116, 139)
        success       = @(34, 197, 94)       # Slightly brighter green, better dark-bg readability
        'success-dim' = @(22, 163, 74)
        error         = @(239, 68, 68)       # Balanced red, less pink than Bootstrap danger
        warning       = @(234, 179, 8)       # Slightly toned-down gold, less blow-out yellow
        info          = @(14, 165, 233)      # Sky blue - distinct from primary, less garish than Bootstrap cyan
        muted         = @(118, 131, 149)     # Slate mid
        bezel         = @(44, 49, 58)        # Slightly cooler charcoal
    }
}

# Loaded presets from JSON (merged with built-in)
$script:LoadedPresets = @{}

$script:StringFields = @('name', 'spinner', 'bullets')

function Import-FxPresets {
    param([string]$Path)
    $config = Get-Content $Path -Raw | ConvertFrom-Json
    $config.presets.PSObject.Properties | ForEach-Object {
        $preset = @{}
        $_.Value.PSObject.Properties | ForEach-Object {
            if ($_.Name -in $script:StringFields) { $preset[$_.Name] = [string]$_.Value }
            else { $preset[$_.Name] = @([int]$_.Value[0], [int]$_.Value[1], [int]$_.Value[2]) }
        }
        $script:LoadedPresets[$_.Name] = $preset
    }
}

function Resolve-FxPreset {
    param([string]$Name)
    if ($script:LoadedPresets.ContainsKey($Name)) { return $script:LoadedPresets[$Name] }
    if ($script:BuiltInPresets.ContainsKey($Name)) { return $script:BuiltInPresets[$Name] }
    return $null
}

function Apply-FxPreset {
    param([hashtable]$Preset, [string]$Name)

    $script:PresetName = $Name
    $script:PresetDisplayName = if ($Preset.name) { $Preset.name } else { $Name }
    $script:ThemeRgb = @{}; $script:Theme = @{}

    # Resolve spinner
    $spinnerName = if ($Preset.spinner) { $Preset.spinner } else { 'braille' }
    $script:SpinChars = if ($script:Spinners.ContainsKey($spinnerName)) {
        $script:Spinners[$spinnerName]
    } else { $script:Spinners['braille'] }

    # Resolve bullets
    $bulletName = if ($Preset.bullets) { $Preset.bullets } else { 'check' }
    $script:Bullets = if ($script:BulletSets.ContainsKey($bulletName)) {
        $script:BulletSets[$bulletName]
    } else { $script:BulletSets['check'] }

    # Build color tables
    foreach ($key in $Preset.Keys) {
        if ($key -in $script:StringFields) { continue }
        $pascalKey = ($key -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ''
        $rgb = $Preset[$key]
        $script:ThemeRgb[$pascalKey] = $rgb
        $script:Theme[$pascalKey] = $PSStyle.Foreground.FromRgb($rgb[0], $rgb[1], $rgb[2])
    }
    $script:Theme['Reset'] = $PSStyle.Reset
}

function Set-FxTheme {
    <#
    .SYNOPSIS
    Load a color theme. Works with no arguments (built-in default), a preset name,
    or a custom config file. Preset names are validated dynamically against available presets.
    .PARAMETER Preset
    Name of a preset. Built-in: 'default'. Additional presets come from theme-config.json
    or any file loaded via -ConfigPath.
    .PARAMETER ConfigPath
    Path to a theme-config.json file. If omitted, looks for one next to the module,
    then falls back to built-in presets only.
    .EXAMPLE
    Set-FxTheme                                          # built-in default
    Set-FxTheme amber                                    # from theme-config.json
    Set-FxTheme cyan -ConfigPath '~/myapp/themes.json'   # custom file
    #>
    param(
        [Parameter(Position = 0)][string]$Preset,
        [string]$ConfigPath
    )

    # Load presets from JSON if available
    if ($ConfigPath) {
        if (-not (Test-Path $ConfigPath)) { throw "FxConsole: config not found at $ConfigPath" }
        Import-FxPresets $ConfigPath
    } elseif ($script:LoadedPresets.Count -eq 0) {
        # Auto-discover theme-config.json next to module
        $autoPath = Join-Path $PSScriptRoot 'theme-config.json'
        if (Test-Path $autoPath) { Import-FxPresets $autoPath }
    }

    # Default preset name
    if (-not $Preset) { $Preset = 'default' }

    # Resolve and apply
    $presetData = Resolve-FxPreset $Preset
    if (-not $presetData) {
        $available = @($script:BuiltInPresets.Keys) + @($script:LoadedPresets.Keys) | Sort-Object -Unique
        throw "FxConsole: preset '$Preset' not found. Available: $($available -join ', ')"
    }

    Apply-FxPreset $presetData $Preset
}

function Get-FxPresets {
    <#
    .SYNOPSIS
    List all available theme presets (built-in + loaded from JSON)
    .EXAMPLE
    Get-FxPresets                        # shows names and display names
    Set-FxTheme (Get-FxPresets)[0].Id    # apply the first one
    #>
    $all = @{}
    foreach ($k in $script:BuiltInPresets.Keys) { $all[$k] = $script:BuiltInPresets[$k] }
    foreach ($k in $script:LoadedPresets.Keys)  { $all[$k] = $script:LoadedPresets[$k] }
    # Default first, then alphabetical
    $sorted = @('default') + ($all.Keys | Where-Object { $_ -ne 'default' } | Sort-Object)
    $sorted | Where-Object { $all.ContainsKey($_) } | ForEach-Object {
        [PSCustomObject]@{ Id = $_; Name = if ($all[$_].name) { $all[$_].name } else { $_ } }
    }
}

function Get-FxTheme      { $script:Theme }
function Get-FxThemeRgb   { $script:ThemeRgb }
function Get-FxPresetName { $script:PresetDisplayName }

function Get-FxSpinners {
    <# .SYNOPSIS List available spinner styles #>
    $script:Spinners.Keys | Sort-Object | ForEach-Object {
        [PSCustomObject]@{ Id = $_; Preview = ($script:Spinners[$_] -join ' ') }
    }
}

function Get-FxBullets {
    <# .SYNOPSIS List available bullet styles #>
    $script:BulletSets.Keys | Sort-Object | ForEach-Object {
        $b = $script:BulletSets[$_]
        [PSCustomObject]@{ Id = $_; Pending = $b.Pending; Done = $b.Done; Sub = $b.Sub }
    }
}

# ═══════════════════════════════════════════════════════════════════
# FORMATTING - returns colored strings for composition
# ═══════════════════════════════════════════════════════════════════

function Format-Fx {
    <#
    .SYNOPSIS
    Returns a theme-colored string for inline use
    .EXAMPLE
    "$(Format-Fx 'Status:' Muted) $(Format-Fx 'Online' Success)"
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Text,
        [Parameter(Position = 1)][string]$Color = 'Primary'
    )
    $c = $script:Theme[$Color]
    if (-not $c) { $c = $script:Theme['Primary'] }
    "${c}${Text}$($script:Theme.Reset)"
}

# ═══════════════════════════════════════════════════════════════════
# TEXT OUTPUT
# ═══════════════════════════════════════════════════════════════════

function Write-Fx {
    <#
    .SYNOPSIS
    Write a line of themed text
    .EXAMPLE
    Write-Fx 'Hello world'
    Write-Fx 'dimmed detail' Muted
    Write-Fx 'inline ' Primary -NoNewline
    #>
    param(
        [Parameter(Position = 0)][AllowEmptyString()][string]$Text = '',
        [Parameter(Position = 1)][string]$Color = 'Primary',
        [switch]$NoNewline
    )
    $c = $script:Theme[$Color]; if (-not $c) { $c = $script:Theme['Primary'] }
    $r = $script:Theme.Reset
    if ($NoNewline) { [Console]::Write("${c}${Text}${r}") } else { [Console]::WriteLine("${c}${Text}${r}") }
}

function Write-FxBlankLine {
    <# .SYNOPSIS Write one or more blank lines #>
    param([int]$Count = 1)
    for ($i = 0; $i -lt $Count; $i++) { [Console]::WriteLine() }
}

function Write-FxLabel {
    <#
    .SYNOPSIS
    Write a label: value pair
    .EXAMPLE
    Write-FxLabel 'Version' 'v4.2.1'
    Write-FxLabel 'Status' 'Online' -ValueColor Success
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Label,
        [Parameter(Mandatory, Position = 1)][string]$Value,
        [string]$ValueColor = 'Primary'
    )
    $lc = $script:Theme['Muted']; $vc = $script:Theme[$ValueColor]
    if (-not $vc) { $vc = $script:Theme['Primary'] }
    $r = $script:Theme.Reset
    [Console]::WriteLine("${lc}${Label}: ${r}${vc}${Value}${r}")
}

function Write-FxHeader {
    <#
    .SYNOPSIS
    Write a spaced uppercase section header
    .EXAMPLE
    Write-FxHeader 'Prerequisites'
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Text,
        [string]$Color = 'PrimaryDim'
    )
    $c = $script:Theme[$Color]; if (-not $c) { $c = $script:Theme['Primary'] }
    $r = $script:Theme.Reset
    $spaced = ($Text.ToUpper().ToCharArray() -join ' ')
    [Console]::WriteLine()
    [Console]::WriteLine("${c}$([char]0x2500)$([char]0x2500) ${spaced} $([char]0x2500)$([char]0x2500)${r}")
    [Console]::WriteLine()
}

function Write-FxSeparator {
    <# .SYNOPSIS Write a subtle divider line #>
    param([int]$Width = 40)
    $c = $script:Theme['Bezel']; $r = $script:Theme.Reset
    [Console]::WriteLine("${c}$([string]::new([char]0x2500, $Width))${r}")
}

function Write-FxStatus {
    <#
    .SYNOPSIS
    Write a status message with icon
    .EXAMPLE
    Write-FxStatus 'Build passed' Success
    Write-FxStatus 'Token missing' Error
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Message,
        [Parameter(Position = 1)]
        [ValidateSet('Info','Success','Error','Warn','Process','Complete')]
        [string]$Type = 'Info'
    )
    $icons   = @{ Info=[char]0x203A; Success=[char]0x2713; Error=[char]0x2717; Warn=[char]0x26A0; Process=[char]0x25C6; Complete=[char]0x25CF }
    $iColors = @{ Info='Secondary'; Success='Success'; Error='Error'; Warn='Warning'; Process='Primary'; Complete='Success' }
    $tColors = @{ Info='Muted'; Success='Success'; Error='Error'; Warn='Warning'; Process='Primary'; Complete='Success' }
    $ic = $script:Theme[$iColors[$Type]]; $tc = $script:Theme[$tColors[$Type]]; $r = $script:Theme.Reset
    [Console]::WriteLine("${ic}$($icons[$Type])${r} ${tc}${Message}${r}")
}

# ═══════════════════════════════════════════════════════════════════
# STEPS & ANIMATION
# ═══════════════════════════════════════════════════════════════════

function Write-FxStep {
    <#
    .SYNOPSIS
    Write a process step: in-progress (○), done (◉), or substep (-)
    .EXAMPLE
    Write-FxStep 'Installing packages'
    Write-FxStep 'express@4.18' -Sub
    Write-FxStep 'Installing packages' -Done
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Text,
        [string]$Prefix = "",
        [switch]$Sub,
        [switch]$Done,
        [string]$Color
    )
    if ($Sub) {
        $rgb = $script:ThemeRgb['Secondary']; if (-not $rgb) { $rgb = @(156,112,40) }
        $marker = $script:Bullets.Sub
    } elseif ($Done) {
        $rgb = $script:ThemeRgb[$Color ? $Color : 'Success']; if (-not $rgb) { $rgb = @(0,255,136) }
        $marker = $script:Bullets.Done
    } else {
        $rgb = $script:ThemeRgb[$Color ? $Color : 'Primary']; if (-not $rgb) { $rgb = @(232,160,48) }
        $marker = $script:Bullets.Pending
    }
    $w = Get-FxBufferWidth
    [Console]::Write("`r$([char]27)[38;2;$($rgb[0]);$($rgb[1]);$($rgb[2])m${Prefix} $marker ${Text}$([char]27)[0m".PadRight($w - 1))
    [Console]::WriteLine()
}

function Complete-FxSection {
    <#
    .SYNOPSIS
    Mark a section header as done by rewriting it in-place after substeps finish.
    Handles cursor movement so scripts never need raw escape codes.
    .EXAMPLE
    Write-FxStep 'INSTALL PACKAGES'
    Write-FxStep 'express' -Sub
    Write-FxStep 'lodash' -Sub
    Complete-FxSection 'INSTALL PACKAGES' -SubCount 2
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Header,
        [Parameter(Mandatory)][int]$SubCount
    )
    [Console]::Write("$([char]27)[$($SubCount + 1)A")
    Write-FxStep -Text $Header -Done
    [Console]::Write("$([char]27)[${SubCount}B")
}

function Write-FxShimmer {
    <#
    .SYNOPSIS
    Animated shimmer effect for a fixed number of frames (decorative delay)
    .PARAMETER Spinner
    Override the spinner style for this call (e.g. 'arrows', 'braille')
    .EXAMPLE
    Write-FxShimmer 'Loading config' -Frames 30 -Intensity 0.5
    Write-FxShimmer 'With arrows' -Spinner arrows
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Text,
        [int]$Frames = 40,
        [string]$Prefix = "",
        [double]$Intensity = 1.0,
        [string]$Color = 'Primary',
        [string]$Spinner
    )
    # Temporarily swap spinner if overridden
    $savedSpinChars = $null
    if ($Spinner -and $script:Spinners.ContainsKey($Spinner)) {
        $savedSpinChars = $script:SpinChars
        $script:SpinChars = $script:Spinners[$Spinner]
    }

    $rgb = $script:ThemeRgb[$Color]; if (-not $rgb) { $rgb = $script:ThemeRgb['Primary'] }
    $acc = $script:ThemeRgb['Secondary']; if (-not $acc) { $acc = $rgb }
    $pad = [Math]::Min((Get-FxBufferWidth) - 1, $Text.Length + $Prefix.Length + 8)
    $rain = $script:PresetName -eq 'rainbow'

    for ($f = 0; $f -lt $Frames; $f++) {
        Render-ShimmerFrame -Text $Text -Prefix $Prefix -Frame $f -Intensity $Intensity `
            -BaseR $rgb[0] -BaseG $rgb[1] -BaseB $rgb[2] `
            -AccR $acc[0] -AccG $acc[1] -AccB $acc[2] -Rainbow $rain -Pad $pad
        Start-Sleep -Milliseconds 55
    }

    # Restore spinner
    if ($savedSpinChars) { $script:SpinChars = $savedSpinChars }
}

function Invoke-FxJob {
    <#
    .SYNOPSIS
    Run a scriptblock in the background while showing a shimmer spinner.
    Returns the scriptblock output when complete.
    .EXAMPLE
    $result = Invoke-FxJob 'Counting commits' {
        git rev-list --count --all
    }
    Write-FxStep "Counting commits  $(Format-Fx $result Muted)" -Done
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Text,
        [Parameter(Mandatory, Position = 1)][scriptblock]$ScriptBlock,
        [string]$Prefix = "",
        [double]$Intensity = 0.55,
        [string]$Color = 'Primary'
    )
    $rgb = $script:ThemeRgb[$Color]; if (-not $rgb) { $rgb = $script:ThemeRgb['Primary'] }
    $acc = $script:ThemeRgb['Secondary']; if (-not $acc) { $acc = $rgb }
    $pad = [Math]::Min((Get-FxBufferWidth) - 1, $Text.Length + $Prefix.Length + 8)
    $rain = $script:PresetName -eq 'rainbow'

    $ps = [PowerShell]::Create()
    [void]$ps.AddScript($ScriptBlock)
    $handle = $ps.BeginInvoke()

    $f = 0
    while (-not $handle.IsCompleted) {
        Render-ShimmerFrame -Text $Text -Prefix $Prefix -Frame $f -Intensity $Intensity `
            -BaseR $rgb[0] -BaseG $rgb[1] -BaseB $rgb[2] `
            -AccR $acc[0] -AccG $acc[1] -AccB $acc[2] -Rainbow $rain -Pad $pad
        Start-Sleep -Milliseconds 55
        $f++
    }

    $result = $ps.EndInvoke($handle)
    if ($ps.HadErrors) { $ps.Streams.Error | ForEach-Object { Write-Warning $_ } }
    $ps.Dispose()
    $result
}

# ═══════════════════════════════════════════════════════════════════
# STRUCTURAL - banners, cards, panels
# ═══════════════════════════════════════════════════════════════════

function Write-FxBanner {
    <#
    .SYNOPSIS
    Write a double-bordered title box
    .EXAMPLE
    Write-FxBanner 'MY APP' -Subtitle 'v2.0.0'
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Title,
        [string]$Subtitle = "",
        [int]$Width = 44
    )
    $pc = $script:Theme['Primary']; $dc = $script:Theme['PrimaryDim']; $r = $script:Theme.Reset
    $inner = $Width - 2; $content = $inner - 4

    [Console]::WriteLine()
    [Console]::WriteLine("${pc}$([char]0x2554)$([string]::new([char]0x2550, $inner))$([char]0x2557)${r}")
    [Console]::WriteLine("${pc}$([char]0x2551)${r}  ${pc}$(Get-FxPaddedText $Title $content)${r}  ${pc}$([char]0x2551)${r}")
    if ($Subtitle) {
        [Console]::WriteLine("${pc}$([char]0x2551)${r}  ${dc}$(Get-FxPaddedText $Subtitle $content)${r}  ${pc}$([char]0x2551)${r}")
    }
    [Console]::WriteLine("${pc}$([char]0x255A)$([string]::new([char]0x2550, $inner))$([char]0x255D)${r}")
    [Console]::WriteLine()
}

function Write-FxCard {
    <#
    .SYNOPSIS
    Draw a bordered card with optional title
    .EXAMPLE
    Write-FxCard 'Status' -Lines @(
        "$(Format-Fx 'Build:' Muted) $(Format-Fx 'passing' Success)"
        "$(Format-Fx 'Tests:' Muted) $(Format-Fx '142/142' Success)"
    )
    #>
    param(
        [string]$Title = "",
        [string[]]$Lines = @(),
        [int]$Width = 40,
        [ValidateSet('Rounded','Square','Double','Heavy')][string]$BorderStyle = 'Rounded',
        [string]$BorderColor = 'PrimaryDim',
        [string]$TitleColor = 'Primary'
    )
    $bc = $script:Theme[$BorderColor]; $tc = $script:Theme[$TitleColor]; $r = $script:Theme.Reset
    $box = $script:BoxChars[$BorderStyle]; $inner = $Width - 2; $content = $inner - 2

    if ($Title) {
        $tt = " $Title "; $rem = [Math]::Max(0, $inner - (Get-FxVisualWidth $tt) - 1)
        [Console]::WriteLine("${bc}$($box.TL)$($box.H)${r}${tc}${tt}${r}${bc}$([string]::new($box.H,$rem))$($box.TR)${r}")
    } else {
        [Console]::WriteLine("${bc}$($box.TL)$([string]::new($box.H,$inner))$($box.TR)${r}")
    }
    foreach ($line in $Lines) {
        [Console]::WriteLine("${bc}$($box.V)${r} $(Get-FxPaddedText $line $content) ${bc}$($box.V)${r}")
    }
    [Console]::WriteLine("${bc}$($box.BL)$([string]::new($box.H,$inner))$($box.BR)${r}")
}

function Write-FxPanel {
    <#
    .SYNOPSIS
    Draw an auto-width bordered panel
    .EXAMPLE
    Write-FxPanel @(
        (Format-Fx 'Next steps:' Muted)
        (Format-Fx '  dotbot init' Primary)
    )
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string[]]$Lines,
        [int]$Width = 0,
        [ValidateSet('Rounded','Square','Double','Heavy')][string]$BorderStyle = 'Rounded',
        [string]$BorderColor = 'Bezel'
    )
    $bc = $script:Theme[$BorderColor]; $r = $script:Theme.Reset; $box = $script:BoxChars[$BorderStyle]
    if ($Width -eq 0) { $Width = ($Lines | ForEach-Object { Get-FxVisualWidth $_ } | Measure-Object -Maximum).Maximum + 4 }
    $inner = $Width - 2

    [Console]::WriteLine("${bc}$($box.TL)$([string]::new($box.H,$inner))$($box.TR)${r}")
    foreach ($line in $Lines) {
        [Console]::WriteLine("${bc}$($box.V)${r} $(Get-FxPaddedText " $line" ($inner-1)) ${bc}$($box.V)${r}")
    }
    [Console]::WriteLine("${bc}$($box.BL)$([string]::new($box.H,$inner))$($box.BR)${r}")
}

# ═══════════════════════════════════════════════════════════════════
# SCRIPT HARNESS
# ═══════════════════════════════════════════════════════════════════

function Invoke-FxScript {
    <#
    .SYNOPSIS
    Run a script block with console setup (UTF-8, hidden cursor, auto-restore).
    Wraps the try/finally boilerplate so scripts stay clean.
    .EXAMPLE
    Invoke-FxScript {
        Write-FxBanner 'My Tool'
        Write-FxShimmer 'Working...' -Frames 20
        Write-FxStep 'Done' -Done
    }
    #>
    param(
        [Parameter(Mandatory, Position = 0)][scriptblock]$ScriptBlock
    )
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $script:OutputEncoding = [System.Text.Encoding]::UTF8
    try {
        [Console]::CursorVisible = $false
        & $ScriptBlock
    } finally {
        [Console]::CursorVisible = $true
    }
}

# ═══════════════════════════════════════════════════════════════════
# EXPORTS
# ═══════════════════════════════════════════════════════════════════

Export-ModuleMember -Function @(
    # Theme
    'Set-FxTheme', 'Get-FxTheme', 'Get-FxThemeRgb', 'Get-FxPresetName', 'Get-FxPresets', 'Get-FxSpinners', 'Get-FxBullets'
    # Formatting
    'Format-Fx'
    # Text output
    'Write-Fx', 'Write-FxBlankLine', 'Write-FxLabel', 'Write-FxHeader', 'Write-FxSeparator', 'Write-FxStatus'
    # Steps & animation
    'Write-FxStep', 'Complete-FxSection', 'Write-FxShimmer', 'Invoke-FxJob'
    # Structural
    'Write-FxBanner', 'Write-FxCard', 'Write-FxPanel'
    # Harness
    'Invoke-FxScript'
)
