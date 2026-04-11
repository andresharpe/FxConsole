function Invoke-FxScript {
    <#
    .SYNOPSIS
    Run a script block with console setup (UTF-8, hidden cursor, auto-restore).
    Wraps the try/finally boilerplate so scripts stay clean.
    .EXAMPLE
    Invoke-FxScript {
        Write-FxBanner 'My Tool'
        Write-FxShimmer 'Working...' -Frames 20
        Write-FxStep 'Done' -Done
    }
    #>
    param(
        [Parameter(Mandatory, Position = 0)][scriptblock]$ScriptBlock
    )
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $script:OutputEncoding = [System.Text.Encoding]::UTF8

    # Suppress PowerShell's native Write-Progress — it's buggy, slow, and
    # accumulates on screen. Restore on exit so we don't leak into the caller.
    $savedProgress = $global:ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'

    try {
        [Console]::CursorVisible = $false
        & $ScriptBlock
    } finally {
        [Console]::CursorVisible = $true
        $global:ProgressPreference = $savedProgress
    }
}
