function Get-FxVisualWidth {
    param([string]$Text)
    ($Text -replace '\x1b\[[0-9;]*m', '').Length
}
