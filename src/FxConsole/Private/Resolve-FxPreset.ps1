function Resolve-FxPreset {
    param([string]$Name)
    if ($script:LoadedPresets.ContainsKey($Name)) { return $script:LoadedPresets[$Name] }
    if ($script:BuiltInPresets.ContainsKey($Name)) { return $script:BuiltInPresets[$Name] }
    return $null
}
