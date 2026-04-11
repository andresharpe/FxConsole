function Format-Fx {
    <#
    .SYNOPSIS
    Returns a theme-colored string for inline use
    .EXAMPLE
    "$(Format-Fx 'Status:' Muted) $(Format-Fx 'Online' Success)"
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Text,
        [Parameter(Position = 1)][string]$Color = 'Primary'
    )
    $c = $script:Theme[$Color]
    if (-not $c) { $c = $script:Theme['Primary'] }
    "${c}${Text}$($script:Theme.Reset)"
}
