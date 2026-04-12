function Invoke-FxJob {
    <#
    .SYNOPSIS
    Run a scriptblock in the background while showing a shimmer spinner.
    Returns the scriptblock output when complete.
    .EXAMPLE
    $result = Invoke-FxJob 'Counting commits' {
        git rev-list --count --all
    }
    Write-FxStep "Counting commits  $(Format-Fx $result Muted)" -Done
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Text,
        [Parameter(Mandatory, Position = 1)][scriptblock]$ScriptBlock,
        [string]$Prefix = "",
        [double]$Intensity = 0.55,
        [string]$Color = 'Primary'
    )
    $rgb = $script:ThemeRgb[$Color]; if (-not $rgb) { $rgb = $script:ThemeRgb['Primary'] }
    $acc = $script:ThemeRgb['Secondary']; if (-not $acc) { $acc = $rgb }
    $pad = [Math]::Min((Get-FxBufferWidth) - 1, $Text.Length + $Prefix.Length + 8)
    $rain = $script:PresetName -eq 'rainbow'

    # Wrap the user's scriptblock so $ProgressPreference is silenced inside the
    # runspace. Without this, any Invoke-WebRequest / Copy-Item / etc. call in
    # the job emits native Write-Progress which flickers cursor state underneath
    # our shimmer. The runspace does not inherit the parent's preference.
    $wrapped = [scriptblock]::Create(@"
`$ProgressPreference = 'SilentlyContinue'
& { $ScriptBlock }
"@)

    $ps = [PowerShell]::Create()
    [void]$ps.AddScript($wrapped)
    $handle = $ps.BeginInvoke()

    $f = 0
    while (-not $handle.IsCompleted) {
        Render-ShimmerFrame -Text $Text -Prefix $Prefix -Frame $f -Intensity $Intensity `
            -BaseR $rgb[0] -BaseG $rgb[1] -BaseB $rgb[2] `
            -AccR $acc[0] -AccG $acc[1] -AccB $acc[2] -Rainbow $rain -Pad $pad
        Start-Sleep -Milliseconds 55
        $f++
    }

    $result = $ps.EndInvoke($handle)
    if ($ps.HadErrors) { $ps.Streams.Error | ForEach-Object { Write-Warning $_ } }
    $ps.Dispose()
    $result
}
