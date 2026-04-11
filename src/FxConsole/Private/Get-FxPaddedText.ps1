function Get-FxPaddedText {
    param([string]$Text, [int]$Width, [string]$Align = 'Left')
    $totalPad = [Math]::Max(0, $Width - (Get-FxVisualWidth $Text))
    switch ($Align) {
        'Left'   { $Text + (' ' * $totalPad) }
        'Right'  { (' ' * $totalPad) + $Text }
        'Center' { $l = [Math]::Floor($totalPad/2); (' '*$l) + $Text + (' '*($totalPad-$l)) }
    }
}
