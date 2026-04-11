@{
    RootModule        = 'FxConsole.psm1'
    ModuleVersion     = '1.2.0'
    GUID              = 'b4e8d9f2-5c3a-4e7b-9d1f-2a6c4b8e0f13'
    Author            = 'dotbot'
    Description       = 'Theme-aware terminal output for PowerShell 7+ — spinners, tables, cards, steps, and color presets'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Set-FxTheme', 'Get-FxTheme', 'Get-FxThemeRgb', 'Get-FxPresetName', 'Get-FxPresets', 'Get-FxSpinners', 'Get-FxBullets'
        'Format-Fx'
        'Write-Fx', 'Write-FxBlankLine', 'Write-FxLabel', 'Write-FxHeader', 'Write-FxSeparator', 'Write-FxStatus'
        'Write-FxStep', 'Complete-FxSection', 'Write-FxShimmer', 'Invoke-FxJob'
        'Write-FxBanner', 'Write-FxCard', 'Write-FxPanel'
        'Write-FxTable', 'Write-FxGrid'
        'Write-FxProgress', 'Invoke-FxProgress'
        'Invoke-FxScript'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
}
