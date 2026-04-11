function Render-ShimmerFrame {
    param([string]$Text, [string]$Prefix, [int]$Frame, [double]$Intensity,
          [int]$BaseR, [int]$BaseG, [int]$BaseB,
          [int]$AccR, [int]$AccG, [int]$AccB,
          [bool]$Rainbow, [int]$Pad)

    $line = [System.Text.StringBuilder]::new()
    $flicker = 0.96 + (Get-Random -Minimum 0 -Maximum 5) / 100.0

    $s = $script:SpinChars[$Frame % $script:SpinChars.Length]
    $pulse = 0.85 + 0.15 * [Math]::Sin($Frame * 0.5)
    if ($Rainbow) {
        $c = Convert-HsvToRgb -H ($Frame * 12 % 360) -S 0.85 -V ($pulse * $Intensity)
        $sr = $c[0]; $sg = $c[1]; $sb = $c[2]
    } else {
        $sr = [int][Math]::Min(255, [int]($AccR * $pulse * $Intensity))
        $sg = [int][Math]::Min(255, [int]($AccG * $pulse * $Intensity))
        $sb = [int][Math]::Min(255, [int]($AccB * $pulse * $Intensity))
    }
    [void]$line.Append("$([char]27)[38;2;${sr};${sg};${sb}m${Prefix} $s $([char]27)[0m")

    for ($i = 0; $i -lt $Text.Length; $i++) {
        $wave = [Math]::Sin(($i * 0.4) + ($Frame * 0.15))
        $glow = (0.78 + 0.22 * $wave) * $flicker * $Intensity
        if ($Rainbow) {
            $c = Convert-HsvToRgb -H (($i * 18 + $Frame * 6) % 360) -S 0.85 -V $glow
            $cr = $c[0]; $cg = $c[1]; $cb = $c[2]
        } else {
            $cr = [int][Math]::Min(255, $BaseR * $glow)
            $cg = [int][Math]::Min(255, $BaseG * $glow)
            $cb = [int][Math]::Min(255, $BaseB * $glow)
        }
        [void]$line.Append("$([char]27)[38;2;${cr};${cg};${cb}m$($Text[$i])")
    }
    [void]$line.Append("$([char]27)[0m".PadRight($Pad))
    [Console]::Write("`r$($line.ToString())")
}
