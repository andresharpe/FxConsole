function Write-FxTable {
    <#
    .SYNOPSIS
    Render a themed table with auto-calculated column widths and ANSI-aware sizing.
    .DESCRIPTION
    Renders data as a bordered table that respects the active theme. Column widths
    are calculated from content (including ANSI-colored text), borders use the
    active theme's box drawing characters, and headers get a separator row.
    .PARAMETER Headers
    Array of column header strings.
    .PARAMETER Rows
    Array of row arrays. Each row is an array of cell values matching the headers.
    .PARAMETER InputObject
    Pipeline input — objects whose properties become columns. Use with or without -Headers.
    .PARAMETER Alignment
    Array of alignment values per column: 'Left', 'Right', or 'Center'. Defaults to Left.
    .PARAMETER BorderStyle
    Box drawing style: Rounded, Square, Double, Heavy, Minimal, None.
    .PARAMETER Compact
    Reduce cell padding from 1 space to 0.
    .PARAMETER HeaderColor
    Theme color name for header text.
    .PARAMETER BorderColor
    Theme color name for border characters.
    .PARAMETER PassThru
    Return rendered lines as strings instead of writing to console.
    .EXAMPLE
    Write-FxTable -Headers @('Name','Status','Size') -Rows @(
        ,@('api-server', (Format-Fx 'running' Success), '142 MB')
        ,@('worker',     (Format-Fx 'stopped' Error),   '89 MB')
    )
    .EXAMPLE
    Get-Process | Select-Object Name,CPU,WorkingSet | Write-FxTable -Compact
    #>
    [CmdletBinding()]
    param(
        [string[]]$Headers,
        [array]$Rows,
        [Parameter(ValueFromPipeline)][object]$InputObject,
        [string[]]$Alignment,
        [ValidateSet('Rounded','Square','Double','Heavy','Minimal','None')]
        [string]$BorderStyle = 'Rounded',
        [switch]$Compact,
        [string]$HeaderColor = 'Primary',
        [string]$BorderColor = 'Bezel',
        [switch]$PassThru
    )

    begin {
        $pipelineObjects = [System.Collections.Generic.List[object]]::new()
    }

    process {
        if ($InputObject) { $pipelineObjects.Add($InputObject) }
    }

    end {
        # ── Resolve data from pipeline or parameters ──
        if ($pipelineObjects.Count -gt 0) {
            # Pipeline input: extract headers from properties if not provided
            if (-not $Headers) {
                $Headers = @($pipelineObjects[0].PSObject.Properties.Name)
            }
            $Rows = @(foreach ($obj in $pipelineObjects) {
                ,@(foreach ($h in $Headers) {
                    $val = $obj.$h
                    if ($null -eq $val) { '' } else { [string]$val }
                })
            })
        }

        if (-not $Headers -or $Headers.Count -eq 0) {
            Write-Warning 'Write-FxTable: no headers provided and no pipeline input.'
            return
        }
        if (-not $Rows) { $Rows = @() }

        # Normalize rows — unwrap the extra nesting from ,@() syntax
        $normalizedRows = [System.Collections.Generic.List[object]]::new()
        foreach ($row in $Rows) {
            if ($row -is [array] -and $row.Count -eq 1 -and $row[0] -is [array]) {
                $normalizedRows.Add($row[0])
            } else {
                $normalizedRows.Add($row)
            }
        }
        $Rows = $normalizedRows

        $colCount = $Headers.Count
        $pad = if ($Compact) { 0 } else { 1 }
        $padStr = ' ' * $pad

        # ── Calculate column widths (ANSI-aware) ──
        $colWidths = [int[]]::new($colCount)
        for ($c = 0; $c -lt $colCount; $c++) {
            $colWidths[$c] = Get-FxVisualWidth $Headers[$c]
        }
        foreach ($row in $Rows) {
            for ($c = 0; $c -lt $colCount; $c++) {
                $cellText = if ($c -lt $row.Count) { [string]$row[$c] } else { '' }
                $w = Get-FxVisualWidth $cellText
                if ($w -gt $colWidths[$c]) { $colWidths[$c] = $w }
            }
        }

        # ── Resolve alignment ──
        $colAlign = [string[]]::new($colCount)
        for ($c = 0; $c -lt $colCount; $c++) {
            $colAlign[$c] = if ($Alignment -and $c -lt $Alignment.Count) { $Alignment[$c] } else { 'Left' }
        }

        # ── Theme colors ──
        $bc = $script:Theme[$BorderColor]; if (-not $bc) { $bc = $script:Theme['Bezel'] }
        $hc = $script:Theme[$HeaderColor]; if (-not $hc) { $hc = $script:Theme['Primary'] }
        $r = $script:Theme.Reset

        # ── Output collector ──
        $output = [System.Collections.Generic.List[string]]::new()

        # ── Render helpers ──
        if ($BorderStyle -eq 'None') {
            # No borders — just padded columns
            # Header
            $headerCells = for ($c = 0; $c -lt $colCount; $c++) {
                "${padStr}$(Get-FxPaddedText $Headers[$c] $colWidths[$c] $colAlign[$c])${padStr}"
            }
            $output.Add("${hc}$($headerCells -join '  ')${r}")
            # Separator: dashes under each column
            $sepCells = for ($c = 0; $c -lt $colCount; $c++) {
                "${padStr}$([string]::new('-', $colWidths[$c]))${padStr}"
            }
            $output.Add("$($sepCells -join '  ')")
            # Rows
            foreach ($row in $Rows) {
                $cells = for ($c = 0; $c -lt $colCount; $c++) {
                    $cellText = if ($c -lt $row.Count) { [string]$row[$c] } else { '' }
                    "${padStr}$(Get-FxPaddedText $cellText $colWidths[$c] $colAlign[$c])${padStr}"
                }
                $output.Add($cells -join '  ')
            }
        }
        elseif ($BorderStyle -eq 'Minimal') {
            # Minimal: horizontal lines only, no vertical borders
            $totalWidth = ($colWidths | Measure-Object -Sum).Sum + ($colCount - 1) * (2 + $pad * 2) + $pad * 2
            $sepLine = "${bc}$([string]::new([char]0x2500, $totalWidth))${r}"

            $output.Add($sepLine)
            # Header
            $headerCells = for ($c = 0; $c -lt $colCount; $c++) {
                "${padStr}$(Get-FxPaddedText $Headers[$c] $colWidths[$c] $colAlign[$c])${padStr}"
            }
            $output.Add("${hc}$($headerCells -join '  ')${r}")
            $output.Add($sepLine)
            # Rows
            foreach ($row in $Rows) {
                $cells = for ($c = 0; $c -lt $colCount; $c++) {
                    $cellText = if ($c -lt $row.Count) { [string]$row[$c] } else { '' }
                    "${padStr}$(Get-FxPaddedText $cellText $colWidths[$c] $colAlign[$c])${padStr}"
                }
                $output.Add($cells -join '  ')
            }
            $output.Add($sepLine)
        }
        else {
            # Full bordered table
            $box = $script:BoxChars[$BorderStyle]
            $jct = $script:BoxJunctions[$BorderStyle]

            # Build horizontal rules
            $colSegments = for ($c = 0; $c -lt $colCount; $c++) {
                [string]::new($box.H, $colWidths[$c] + $pad * 2)
            }
            $topLine    = "${bc}$($box.TL)$($colSegments -join $jct.TT)$($box.TR)${r}"
            $sepLine    = "${bc}$($jct.LT)$($colSegments -join $jct.Cross)$($jct.RT)${r}"
            $bottomLine = "${bc}$($box.BL)$($colSegments -join $jct.BT)$($box.BR)${r}"

            $output.Add($topLine)

            # Header row
            $headerCells = for ($c = 0; $c -lt $colCount; $c++) {
                "${padStr}${hc}$(Get-FxPaddedText $Headers[$c] $colWidths[$c] $colAlign[$c])${r}${padStr}"
            }
            $output.Add("${bc}$($box.V)${r}$($headerCells -join "${bc}$($box.V)${r}")${bc}$($box.V)${r}")
            $output.Add($sepLine)

            # Data rows
            foreach ($row in $Rows) {
                $cells = for ($c = 0; $c -lt $colCount; $c++) {
                    $cellText = if ($c -lt $row.Count) { [string]$row[$c] } else { '' }
                    "${padStr}$(Get-FxPaddedText $cellText $colWidths[$c] $colAlign[$c])${padStr}"
                }
                $output.Add("${bc}$($box.V)${r}$($cells -join "${bc}$($box.V)${r}")${bc}$($box.V)${r}")
            }

            $output.Add($bottomLine)
        }

        # ── Output ──
        if ($PassThru) {
            $output
        } else {
            foreach ($line in $output) {
                [Console]::WriteLine($line)
            }
        }
    }
}
