function Get-FxTheme      { $script:Theme }
function Get-FxThemeRgb   { $script:ThemeRgb }
function Get-FxPresetName { $script:PresetDisplayName }

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
