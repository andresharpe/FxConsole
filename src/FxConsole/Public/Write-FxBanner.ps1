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
