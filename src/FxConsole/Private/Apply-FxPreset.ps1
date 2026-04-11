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
