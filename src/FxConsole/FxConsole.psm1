# FxConsole - Theme-aware terminal output for PowerShell 7+
# Animated spinners, styled text, cards, tables, and step tracking with color presets

# ═══════════════════════════════════════════════════════════════════
# MODULE STATE
# ═══════════════════════════════════════════════════════════════════

$script:ModuleRoot = $PSScriptRoot
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
    orbit     = @([char]0x2801,[char]0x2808,[char]0x2810,[char]0x2820,[char]0x2880,[char]0x2840,[char]0x2804,[char]0x2802)  # ⠁⠈⠐⠠⢀⡀⠄⠂ — single dot circling braille grid
    dots      = @([char]0x2808,[char]0x2800,[char]0x2801,[char]0x2800)
    arrows    = @([char]0x2190,[char]0x2196,[char]0x2191,[char]0x2197,[char]0x2192,[char]0x2198,[char]0x2193,[char]0x2199)
    triangles = @([char]0x25E2,[char]0x25E3,[char]0x25E4,[char]0x25E5)
    quarters  = @([char]0x2596,[char]0x2598,[char]0x259D,[char]0x2597)
    pulse     = @([char]0x25E1,[char]0x2299,[char]0x25E0)
    classic   = @('-', '\', '|', '/')
    circle    = @([char]0x25D0,[char]0x25D3,[char]0x25D1,[char]0x25D2)              # ◐◓◑◒ — half-filled circle rotation
    arc       = @([char]0x25DC,[char]0x25DD,[char]0x25DE,[char]0x25DF)              # ◜◝◞◟ — quarter arc sweeping around
    bounce    = @([char]0x2801,[char]0x2802,[char]0x2804,[char]0x2840,[char]0x2804,[char]0x2802)  # ⠁⠂⠄⡀⠄⠂ — braille dot bouncing vertically
    pipe      = @([char]0x2524,[char]0x2518,[char]0x2534,[char]0x2514,[char]0x251C,[char]0x250C,[char]0x252C,[char]0x2510)  # ┤┘┴└├┌┬┐ — box corner rotation
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

# ── Table-specific box junction characters ──
$script:BoxJunctions = @{
    Rounded = @{ LT = [char]0x251C; RT = [char]0x2524; TT = [char]0x252C; BT = [char]0x2534; Cross = [char]0x253C }
    Square  = @{ LT = [char]0x251C; RT = [char]0x2524; TT = [char]0x252C; BT = [char]0x2534; Cross = [char]0x253C }
    Double  = @{ LT = [char]0x2560; RT = [char]0x2563; TT = [char]0x2566; BT = [char]0x2569; Cross = [char]0x256C }
    Heavy   = @{ LT = [char]0x2523; RT = [char]0x252B; TT = [char]0x2533; BT = [char]0x253B; Cross = [char]0x254B }
}

# ── Built-in default theme ──
$script:BuiltInPresets = @{
    default = @{
        name          = 'Default'
        spinner       = 'triangles'
        bullets       = 'check'
        primary       = @(59, 130, 246)
        'primary-dim' = @(37, 99, 205)
        secondary     = @(148, 163, 184)
        tertiary      = @(100, 116, 139)
        success       = @(34, 197, 94)
        'success-dim' = @(22, 163, 74)
        error         = @(239, 68, 68)
        warning       = @(234, 179, 8)
        info          = @(14, 165, 233)
        muted         = @(118, 131, 149)
        bezel         = @(44, 49, 58)
    }
}

$script:LoadedPresets = @{}
$script:StringFields = @('name', 'spinner', 'bullets')

# ═══════════════════════════════════════════════════════════════════
# DOT-SOURCE FUNCTION FILES
# ═══════════════════════════════════════════════════════════════════

# Private functions (internal helpers)
foreach ($file in (Get-ChildItem -Path "$PSScriptRoot/Private" -Filter '*.ps1' -ErrorAction SilentlyContinue)) {
    . $file.FullName
}

# Public functions (exported)
$publicFunctions = @()
foreach ($file in (Get-ChildItem -Path "$PSScriptRoot/Public" -Filter '*.ps1' -ErrorAction SilentlyContinue)) {
    . $file.FullName
    # Collect function names defined in each file
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
    $publicFunctions += $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false).Name
}

# ═══════════════════════════════════════════════════════════════════
# EXPORTS
# ═══════════════════════════════════════════════════════════════════

Export-ModuleMember -Function $publicFunctions
