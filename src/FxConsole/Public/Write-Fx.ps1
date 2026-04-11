function Write-Fx {
    <#
    .SYNOPSIS
    Write a line of themed text
    .EXAMPLE
    Write-Fx 'Hello world'
    Write-Fx 'dimmed detail' Muted
    Write-Fx 'inline ' Primary -NoNewline
    #>
    param(
        [Parameter(Position = 0)][AllowEmptyString()][string]$Text = '',
        [Parameter(Position = 1)][string]$Color = 'Primary',
        [switch]$NoNewline
    )
    $c = $script:Theme[$Color]; if (-not $c) { $c = $script:Theme['Primary'] }
    $r = $script:Theme.Reset
    if ($NoNewline) { [Console]::Write("${c}${Text}${r}") } else { [Console]::WriteLine("${c}${Text}${r}") }
}

function Write-FxBlankLine {
    <# .SYNOPSIS Write one or more blank lines #>
    param([int]$Count = 1)
    for ($i = 0; $i -lt $Count; $i++) { [Console]::WriteLine() }
}
