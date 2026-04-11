# CRT Amber Process Simulator v4.5 - PS7+ / Windows Terminal

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$spin = @('▁','▂','▃','▄','▅','▆','▇','█','▇','▆','▅','▄','▃','▁')

$steps = @(
    @{ Name = "INITIALIZING DOTBOT KERNEL";        Subs = @("Loading agent manifest","Validating config schema","Bootstrapping DI container") }
    @{ Name = "PROVISIONING WORKTREE";             Subs = @("Cloning from main","Symlinking .env","Setting branch isolation","Verifying gitignore rules") }
    @{ Name = "CONNECTING UPSTREAM SERVICES";       Subs = @("Azure OpenAI endpoint","AI Search index","Blob storage mount") }
    @{ Name = "RUNNING PREFLIGHT CHECKS";          Subs = @("Context window budget","Rate limit headroom","Audit logger online","Whisper channel open","Canary token seeded") }
    @{ Name = "AGENT ONLINE";                      Subs = @("Steering channel active","Awaiting task input") }
)

function Write-Amber {
    param([string]$Text, [double]$Brightness = 1.0, [switch]$NoNewline)
    $r = [int][Math]::Min(255, 255 * $Brightness)
    $g = [int][Math]::Min(255, 190 * $Brightness)
    $b = [int][Math]::Min(255, 50 * $Brightness)
    $out = "$([char]27)[38;2;${r};${g};${b}m${Text}$([char]27)[0m"
    if ($NoNewline) { [Console]::Write($out) } else { [Console]::WriteLine($out) }
}

function Write-Shimmer {
    param([string]$Text, [int]$Frames = 40, [string]$Prefix = "", [double]$Intensity = 1.0)
    $pad = $Text.Length + $Prefix.Length + 8
    for ($f = 0; $f -lt $Frames; $f++) {
        $line = [System.Text.StringBuilder]::new()
        $flicker = 0.96 + (Get-Random -Minimum 0 -Maximum 5) / 100.0

        $s = $spin[$f % $spin.Length]
        $pulse = 0.85 + 0.15 * [Math]::Sin($f * 0.5)
        $sr = [int][Math]::Min(255, [int](255 * $pulse * $Intensity))
        $sg = [int][Math]::Min(255, [int](210 * $pulse * $Intensity))
        $sb = [int][Math]::Min(255, [int](60  * $pulse * $Intensity))
        [void]$line.Append("$([char]27)[38;2;${sr};${sg};${sb}m${Prefix} $s $([char]27)[0m")

        for ($i = 0; $i -lt $Text.Length; $i++) {
            $wave = [Math]::Sin(($i * 0.4) + ($f * 0.15))
            $glow = (0.78 + 0.22 * $wave) * $flicker * $Intensity
            $r = [int][Math]::Min(255, 255 * $glow)
            $g = [int][Math]::Min(255, 190 * $glow)
            $b = [int][Math]::Min(255, 50 * $glow)
            [void]$line.Append("$([char]27)[38;2;${r};${g};${b}m$($Text[$i])")
        }
        [void]$line.Append("$([char]27)[0m".PadRight($pad))
        [Console]::Write("`r$($line.ToString())")
        Start-Sleep -Milliseconds 55
    }
}

function Write-Complete {
    param([string]$Text, [string]$Prefix = "", [switch]$Sub)
    if ($Sub) {
        $r = 100; $g = 75; $b = 20
        $marker = '-'
    } else {
        $r = 220; $g = 170; $b = 45
        $marker = "`u{25C9}"  # ◉ fisheye - scope reticle
    }
    [Console]::Write("`r$([char]27)[38;2;${r};${g};${b}m${Prefix} $marker ${Text}$([char]27)[0m".PadRight(80))
    [Console]::WriteLine()
}

try {
    [Console]::CursorVisible = $false
    [Console]::WriteLine()

    $bar = [string]::new([char]0x2500, 52)
    Write-Amber $bar 0.5
    Write-Amber "       DOTBOT v3 AUTONOMOUS AGENT BOOTSTRAP" 0.9
    Write-Amber $bar 0.5

    [Console]::WriteLine()
    Start-Sleep -Milliseconds 400

    for ($si = 0; $si -lt $steps.Count; $si++) {
        $step = $steps[$si]
        $num = $si + 1
        $header = "[$num/5] $($step.Name)"

        # main headings print instantly - they're labels, not processes
        Write-Complete -Text $header -Prefix ""
        Start-Sleep -Milliseconds 200

        foreach ($sub in $step.Subs) {
            $duration = Get-Random -Minimum 15 -Maximum 40
            Write-Shimmer -Text $sub -Frames $duration -Prefix "   " -Intensity 0.55
            Write-Complete -Text $sub -Prefix "   " -Sub
            Start-Sleep -Milliseconds 80
        }

        if ($si -lt $steps.Count - 1) {
            [Console]::WriteLine()
            Start-Sleep -Milliseconds 200
        }
    }

    [Console]::WriteLine()
    Write-Shimmer -Text "ALL SYSTEMS NOMINAL :: READY" -Frames 100 -Prefix " " -Intensity 1.0
    Write-Complete -Text "ALL SYSTEMS NOMINAL :: READY" -Prefix " "
    [Console]::WriteLine()
}
finally {
    [Console]::CursorVisible = $true
    Write-Amber "// end transmission" 0.4
    [Console]::WriteLine()
}