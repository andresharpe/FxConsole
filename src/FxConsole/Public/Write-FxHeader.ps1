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
