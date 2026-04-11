function Write-FxStep {
    <#
    .SYNOPSIS
    Write a process step: in-progress, done, or substep
    .EXAMPLE
    Write-FxStep 'Installing packages'
    Write-FxStep 'express@4.18' -Sub
    Write-FxStep 'Installing packages' -Done
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Text,
        [string]$Prefix = "",
        [switch]$Sub,
        [switch]$Done,
        [string]$Color
    )
    if ($Sub) {
        $rgb = $script:ThemeRgb['Secondary']; if (-not $rgb) { $rgb = @(156,112,40) }
        $marker = $script:Bullets.Sub
    } elseif ($Done) {
        $rgb = $script:ThemeRgb[$Color ? $Color : 'Success']; if (-not $rgb) { $rgb = @(0,255,136) }
        $marker = $script:Bullets.Done
    } else {
        $rgb = $script:ThemeRgb[$Color ? $Color : 'Primary']; if (-not $rgb) { $rgb = @(232,160,48) }
        $marker = $script:Bullets.Pending
    }
    $w = Get-FxBufferWidth
    [Console]::Write("`r$([char]27)[38;2;$($rgb[0]);$($rgb[1]);$($rgb[2])m${Prefix} $marker ${Text}$([char]27)[0m".PadRight($w - 1))
    [Console]::WriteLine()
}

function Complete-FxSection {
    <#
    .SYNOPSIS
    Mark a section header as done by rewriting it in-place after substeps finish.
    .EXAMPLE
    Write-FxStep 'INSTALL PACKAGES'
    Write-FxStep 'express' -Sub
    Write-FxStep 'lodash' -Sub
    Complete-FxSection 'INSTALL PACKAGES' -SubCount 2
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Header,
        [Parameter(Mandatory)][int]$SubCount
    )
    [Console]::Write("$([char]27)[$($SubCount + 1)A")
    Write-FxStep -Text $Header -Done
    [Console]::Write("$([char]27)[${SubCount}B")
}
