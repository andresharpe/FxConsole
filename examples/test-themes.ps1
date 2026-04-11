# Theme demo — cycles through presets showing spinners, bullets, and styled output
param(
    [string]$Preset,
    [switch]$ShowAll,
    [switch]$NoGallery
)

Import-Module "$PSScriptRoot\..\src\FxConsole\FxConsole.psd1" -Force

function Show-Demo {
    param([string]$PresetName)

    Set-FxTheme $PresetName
    Write-FxBlankLine

    # 5-second shimmer spinner
    $name = Get-FxPresetName
    Invoke-FxJob $name { Start-Sleep -Seconds 5 }
    Write-FxStep $name -Done

    Write-FxBanner $name

    # Palette
    Write-Fx '  primary    ' Primary -NoNewline;  Write-Fx ' secondary  ' Secondary -NoNewline
    Write-Fx ' tertiary   ' Tertiary -NoNewline;  Write-Fx ' primary-dim' PrimaryDim
    Write-Fx '  success    ' Success -NoNewline;   Write-Fx ' error      ' Error -NoNewline
    Write-Fx ' warning    ' Warning -NoNewline;    Write-Fx ' info       ' Info
    Write-Fx '  muted      ' Muted -NoNewline;     Write-Fx ' bezel      ' Bezel
    Write-FxBlankLine

    # Spinner preview
    Write-FxShimmer "Spinner in action" -Frames 30 -Prefix '  ' -Intensity 0.7

    # Bullets
    Write-FxStep 'Pending step'               -Prefix '  '
    Write-FxStep 'Completed step'              -Prefix '  ' -Done
    Write-FxStep 'Sub-step detail'             -Prefix '  ' -Sub
    Write-FxBlankLine

    # Quick process sim
    Write-FxStep 'INSTALL PACKAGES'
    Write-FxShimmer 'express@4.18'  -Frames 8  -Prefix '     ' -Intensity 0.45
    Write-FxStep    'express@4.18'  -Prefix '     ' -Sub
    Write-FxShimmer 'typescript'    -Frames 8  -Prefix '     ' -Intensity 0.45
    Write-FxStep    'typescript'    -Prefix '     ' -Sub
    Complete-FxSection "INSTALL PACKAGES  $(Format-Fx '2 packages' Muted)" -SubCount 2

    # Table
    Write-FxBlankLine
    Write-FxTable -Headers @('Service','Status','Uptime') -Rows @(
        ,@('api-server', (Format-Fx 'running' Success),  '14d 2h')
        ,@('worker',     (Format-Fx 'stopped' Error),    '0s')
        ,@('scheduler',  (Format-Fx 'running' Success),  '14d 2h')
    )

    # Grid
    Write-FxBlankLine
    Write-FxGrid -Columns 3 -Items @(
        "$(Format-Fx 'CPU:' Muted) $(Format-Fx '42%' Primary)"
        "$(Format-Fx 'MEM:' Muted) $(Format-Fx '68%' Warning)"
        "$(Format-Fx 'DISK:' Muted) $(Format-Fx '91%' Error)"
    )

    # Progress bar
    Write-FxBlankLine
    1..20 | ForEach-Object {
        Write-FxProgress -Activity 'Building' -Percent ($_ * 5) -Status "$_ of 20 modules"
        Start-Sleep -Milliseconds 40
    }
    Write-FxProgress -Activity 'Building' -Complete
    Write-FxStep 'Build complete' -Done

    # Card
    Write-FxBlankLine
    Write-FxCard 'Status' -Width 42 -Lines @(
        "$(Format-Fx 'Theme:' Muted)   $(Format-Fx (Get-FxPresetName) Primary)"
        "$(Format-Fx 'Status:' Muted)  $(Format-Fx 'Ready' Success)"
    )
    Write-FxBlankLine
}

Invoke-FxScript {
    Set-FxTheme

    if ($ShowAll) {
        foreach ($p in (Get-FxPresets).Id) {
            Show-Demo $p
            Start-Sleep -Milliseconds 400
        }
    } else {
        if ($Preset) { Show-Demo $Preset } else { Show-Demo 'default' }
    }

    if (-not $NoGallery) {
        # ── All spinners ──
        Set-FxTheme default
        Write-FxBlankLine
        Write-FxHeader 'Spinner Gallery'
        foreach ($s in (Get-FxSpinners)) {
            Write-FxShimmer $s.Id -Frames 25 -Prefix '    ' -Intensity 0.7 -Spinner $s.Id
            Write-FxStep $s.Id -Prefix '    ' -Done
        }

        # ── All bullets ──
        Write-FxBlankLine
        Write-FxHeader 'Bullet Gallery'
        foreach ($b in (Get-FxBullets)) {
            Write-Fx "    $(Format-Fx $b.Id.PadRight(12) Muted) $(Format-Fx "$($b.Pending) pending" Primary)   $(Format-Fx "$($b.Done) done" Success)   $(Format-Fx "$($b.Sub) sub" Secondary)"
        }
    }

    Write-FxBlankLine
    Write-Fx '// end transmission' Muted
    Write-FxBlankLine
}
