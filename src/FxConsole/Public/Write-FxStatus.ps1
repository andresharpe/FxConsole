function Write-FxStatus {
    <#
    .SYNOPSIS
    Write a status message with icon
    .EXAMPLE
    Write-FxStatus 'Build passed' Success
    Write-FxStatus 'Token missing' Error
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Message,
        [Parameter(Position = 1)]
        [ValidateSet('Info','Success','Error','Warn','Process','Complete')]
        [string]$Type = 'Info'
    )
    $icons   = @{ Info=[char]0x203A; Success=[char]0x2713; Error=[char]0x2717; Warn=[char]0x26A0; Process=[char]0x25C6; Complete=[char]0x25CF }
    $iColors = @{ Info='Secondary'; Success='Success'; Error='Error'; Warn='Warning'; Process='Primary'; Complete='Success' }
    $tColors = @{ Info='Muted'; Success='Success'; Error='Error'; Warn='Warning'; Process='Primary'; Complete='Success' }
    $ic = $script:Theme[$iColors[$Type]]; $tc = $script:Theme[$tColors[$Type]]; $r = $script:Theme.Reset
    [Console]::WriteLine("${ic}$($icons[$Type])${r} ${tc}${Message}${r}")
}
