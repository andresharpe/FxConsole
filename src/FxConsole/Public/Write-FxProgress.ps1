function Write-FxProgress {
    <#
    .SYNOPSIS
    Render a themed progress bar with percentage, elapsed time, and ETA.
    .DESCRIPTION
    Draws an in-place progress bar using block characters that respects the active
    theme. Tracks elapsed time automatically and estimates remaining time from the
    current percentage. Call with -Complete to clear the bar cleanly.
    .PARAMETER Activity
    Label displayed before the progress bar.
    .PARAMETER Percent
    Current progress as an integer 0-100.
    .PARAMETER Status
    Optional status text displayed after the bar (e.g. "42 of 100 files").
    .PARAMETER Complete
    Mark this activity as finished and clear its progress bar line.
    .PARAMETER BarColor
    Theme color for the filled portion of the bar.
    .PARAMETER TrackColor
    Theme color for the empty portion of the bar.
    .PARAMETER Width
    Total width of the progress bar (characters). Defaults to 30.
    .EXAMPLE
    1..100 | ForEach-Object {
        Write-FxProgress -Activity 'Downloading' -Percent $_ -Status "$_ of 100 files"
        Start-Sleep -Milliseconds 50
    }
    Write-FxProgress -Activity 'Downloading' -Complete
    .EXAMPLE
    Write-FxProgress -Activity 'Build' -Percent 75 -Status '3 of 4 steps'
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Activity,
        [Parameter(Position = 1)][ValidateRange(0,100)][int]$Percent = 0,
        [string]$Status,
        [switch]$Complete,
        [string]$BarColor = 'Primary',
        [string]$TrackColor = 'Bezel',
        [int]$Width = 30
    )

    # ── Track start times per activity ──
    if (-not $script:ProgressTimers) { $script:ProgressTimers = @{} }

    if ($Complete) {
        # Clear the line and remove the timer
        $w = Get-FxBufferWidth
        [Console]::Write("`r$(' ' * ($w - 1))`r")
        $script:ProgressTimers.Remove($Activity)
        return
    }

    # Start timer on first call for this activity
    if (-not $script:ProgressTimers.ContainsKey($Activity)) {
        $script:ProgressTimers[$Activity] = [System.Diagnostics.Stopwatch]::StartNew()
    }
    $sw = $script:ProgressTimers[$Activity]

    # ── Theme colors ──
    $bc = $script:Theme[$BarColor];   if (-not $bc) { $bc = $script:Theme['Primary'] }
    $tc = $script:Theme[$TrackColor]; if (-not $tc) { $tc = $script:Theme['Bezel'] }
    $mc = $script:Theme['Muted'];     if (-not $mc) { $mc = $tc }
    $pc = $script:Theme['Primary'];   if (-not $pc) { $pc = $bc }
    $r  = $script:Theme.Reset

    # ── Build the bar ──
    $filled = [Math]::Floor($Width * $Percent / 100)
    $empty  = $Width - $filled
    $bar = "${bc}$([string]::new([char]0x2588, $filled))${tc}$([string]::new([char]0x2591, $empty))${r}"

    # ── Time calculations ──
    $elapsed = $sw.Elapsed
    $elapsedStr = '{0:mm\:ss}' -f $elapsed
    $etaStr = ''
    if ($Percent -gt 0 -and $Percent -lt 100) {
        $totalEstimate = [TimeSpan]::FromTicks($elapsed.Ticks * 100 / $Percent)
        $remaining = $totalEstimate - $elapsed
        if ($remaining.TotalSeconds -ge 0) {
            $etaStr = " ${mc}eta ${r}${pc}$('{0:mm\:ss}' -f $remaining)${r}"
        }
    }

    # ── Compose the line ──
    $percentStr = "${pc}$($Percent.ToString().PadLeft(3))%${r}"
    $statusStr = if ($Status) { " ${mc}${Status}${r}" } else { '' }
    $line = "${mc}${Activity}${r} ${bar} ${percentStr} ${mc}${elapsedStr}${r}${etaStr}${statusStr}"

    $w = Get-FxBufferWidth
    $pad = [Math]::Max(0, $w - 1 - (Get-FxVisualWidth $line))
    [Console]::Write("`r${line}$(' ' * $pad)")
}

function Invoke-FxProgress {
    <#
    .SYNOPSIS
    Pipeline-aware progress wrapper — tracks and displays progress as items flow through.
    .DESCRIPTION
    Wraps a pipeline with an automatic progress bar. Counts items as they pass through,
    runs an optional scriptblock on each, and displays a themed progress bar.
    Requires -Total for percentage calculation; without it, shows a counter.
    .PARAMETER Activity
    Label displayed on the progress bar.
    .PARAMETER ScriptBlock
    Optional scriptblock to execute for each item. Receives the item as $_.
    If omitted, items pass through unchanged.
    .PARAMETER Total
    Total expected item count, used to calculate percentage.
    .PARAMETER InputObject
    Pipeline input.
    .EXAMPLE
    $items | Invoke-FxProgress -Activity 'Processing' -Total $items.Count -ScriptBlock {
        Start-Sleep -Milliseconds 100
    }
    .EXAMPLE
    1..50 | Invoke-FxProgress -Activity 'Copying' -Total 50
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Activity,
        [scriptblock]$ScriptBlock,
        [int]$Total = 0,
        [Parameter(ValueFromPipeline)][object]$InputObject
    )

    begin {
        $count = 0
    }

    process {
        $count++

        if ($Total -gt 0) {
            $pct = [Math]::Min(100, [int]([Math]::Floor($count * 100 / $Total)))
            Write-FxProgress -Activity $Activity -Percent $pct -Status "$count of $Total"
        } else {
            Write-FxProgress -Activity $Activity -Percent 0 -Status "$count items"
        }

        if ($ScriptBlock) {
            $InputObject | ForEach-Object $ScriptBlock
        } else {
            $InputObject
        }
    }

    end {
        Write-FxProgress -Activity $Activity -Complete
    }
}
