function Convert-HsvToRgb {
    param([double]$H, [double]$S, [double]$V)
    $H = $H % 360; $c = $V * $S
    $x = $c * (1 - [Math]::Abs(($H / 60) % 2 - 1)); $m = $V - $c
    switch ([int]($H / 60)) {
        0 { $r = $c; $g = $x; $b = 0 }  1 { $r = $x; $g = $c; $b = 0 }
        2 { $r = 0; $g = $c; $b = $x }  3 { $r = 0; $g = $x; $b = $c }
        4 { $r = $x; $g = 0; $b = $c }  default { $r = $c; $g = 0; $b = $x }
    }
    @([int](($r+$m)*255), [int](($g+$m)*255), [int](($b+$m)*255))
}
