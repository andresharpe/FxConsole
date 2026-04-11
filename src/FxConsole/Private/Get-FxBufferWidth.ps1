function Get-FxBufferWidth {
    try { [Console]::BufferWidth } catch { 120 }
}
