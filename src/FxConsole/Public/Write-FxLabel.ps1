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
