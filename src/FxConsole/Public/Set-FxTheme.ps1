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
        $autoPath = Join-Path $script:ModuleRoot 'theme-config.json'
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
