function Write-FxCard {
    <#
    .SYNOPSIS
    Draw a bordered card with optional title
    .EXAMPLE
    Write-FxCard 'Status' -Lines @(
        "$(Format-Fx 'Build:' Muted) $(Format-Fx 'passing' Success)"
        "$(Format-Fx 'Tests:' Muted) $(Format-Fx '142/142' Success)"
    )
    #>
    param(
        [string]$Title = "",
        [string[]]$Lines = @(),
        [int]$Width = 40,
        [ValidateSet('Rounded','Square','Double','Heavy')][string]$BorderStyle = 'Rounded',
        [string]$BorderColor = 'PrimaryDim',
        [string]$TitleColor = 'Primary'
    )
    $bc = $script:Theme[$BorderColor]; $tc = $script:Theme[$TitleColor]; $r = $script:Theme.Reset
    $box = $script:BoxChars[$BorderStyle]; $inner = $Width - 2; $content = $inner - 2

    if ($Title) {
        $tt = " $Title "; $rem = [Math]::Max(0, $inner - (Get-FxVisualWidth $tt) - 1)
        [Console]::WriteLine("${bc}$($box.TL)$($box.H)${r}${tc}${tt}${r}${bc}$([string]::new($box.H,$rem))$($box.TR)${r}")
    } else {
        [Console]::WriteLine("${bc}$($box.TL)$([string]::new($box.H,$inner))$($box.TR)${r}")
    }
    foreach ($line in $Lines) {
        [Console]::WriteLine("${bc}$($box.V)${r} $(Get-FxPaddedText $line $content) ${bc}$($box.V)${r}")
    }
    [Console]::WriteLine("${bc}$($box.BL)$([string]::new($box.H,$inner))$($box.BR)${r}")
}
