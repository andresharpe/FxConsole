function Write-FxGrid {
    <#
    .SYNOPSIS
    Borderless multi-column layout for dashboard-style output.
    .DESCRIPTION
    Renders items in a grid with evenly spaced columns. Items are laid out
    left-to-right, top-to-bottom. Column widths are auto-calculated from content
    with ANSI-aware width measurement.
    .PARAMETER Items
    Array of strings (may include ANSI-colored text) to display in the grid.
    .PARAMETER Columns
    Number of columns. Defaults to 3.
    .PARAMETER Gutter
    Space between columns. Defaults to 4.
    .PARAMETER Indent
    Left indent for the grid. Defaults to 2.
    .EXAMPLE
    Write-FxGrid -Columns 3 -Items @(
        (Format-Fx 'CPU: 42%' Primary)
        (Format-Fx 'MEM: 68%' Warning)
        (Format-Fx 'DISK: 91%' Error)
    )
    #>
    param(
        [Parameter(Mandatory, Position = 0)][AllowEmptyCollection()][string[]]$Items,
        [int]$Columns = 3,
        [int]$Gutter = 4,
        [int]$Indent = 2
    )

    if ($Items.Count -eq 0) { return }
    $Columns = [Math]::Min($Columns, $Items.Count)

    # Calculate column widths from content
    $colWidths = [int[]]::new($Columns)
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $col = $i % $Columns
        $w = Get-FxVisualWidth $Items[$i]
        if ($w -gt $colWidths[$col]) { $colWidths[$col] = $w }
    }

    $indentStr = ' ' * $Indent
    $gutterStr = ' ' * $Gutter
    $rowCount = [Math]::Ceiling($Items.Count / $Columns)

    for ($row = 0; $row -lt $rowCount; $row++) {
        $cells = for ($col = 0; $col -lt $Columns; $col++) {
            $idx = $row * $Columns + $col
            if ($idx -lt $Items.Count) {
                Get-FxPaddedText $Items[$idx] $colWidths[$col]
            }
        }
        [Console]::WriteLine("${indentStr}$($cells -join $gutterStr)")
    }
}
