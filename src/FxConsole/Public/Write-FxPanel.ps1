function Write-FxPanel {
    <#
    .SYNOPSIS
    Draw an auto-width bordered panel
    .EXAMPLE
    Write-FxPanel @(
        (Format-Fx 'Next steps:' Muted)
        (Format-Fx '  dotbot init' Primary)
    )
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string[]]$Lines,
        [int]$Width = 0,
        [ValidateSet('Rounded','Square','Double','Heavy')][string]$BorderStyle = 'Rounded',
        [string]$BorderColor = 'Bezel'
    )
    $bc = $script:Theme[$BorderColor]; $r = $script:Theme.Reset; $box = $script:BoxChars[$BorderStyle]
    if ($Width -eq 0) { $Width = ($Lines | ForEach-Object { Get-FxVisualWidth $_ } | Measure-Object -Maximum).Maximum + 5 }
    $inner = $Width - 2

    [Console]::WriteLine("${bc}$($box.TL)$([string]::new($box.H,$inner))$($box.TR)${r}")
    foreach ($line in $Lines) {
        [Console]::WriteLine("${bc}$($box.V)${r} $(Get-FxPaddedText " $line" ($inner-2)) ${bc}$($box.V)${r}")
    }
    [Console]::WriteLine("${bc}$($box.BL)$([string]::new($box.H,$inner))$($box.BR)${r}")
}
