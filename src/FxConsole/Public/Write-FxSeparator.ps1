function Write-FxSeparator {
    <# .SYNOPSIS Write a subtle divider line #>
    param([int]$Width = 40)
    $c = $script:Theme['Bezel']; $r = $script:Theme.Reset
    [Console]::WriteLine("${c}$([string]::new([char]0x2500, $Width))${r}")
}
