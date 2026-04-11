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
