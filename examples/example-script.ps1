# Example: how to use FxConsole in a script
param(
    [string]$Theme
)

Import-Module "$PSScriptRoot\..\src\FxConsole\FxConsole.psd1" -Force
Set-FxTheme $Theme

Invoke-FxScript {

    Write-FxBanner 'DEPLOY TOOL' -Subtitle "$(Get-FxPresetName) // v2.0"

    # ── simple text ──
    Write-FxHeader 'Configuration'
    Write-FxLabel  'Target'   'production'
    Write-FxLabel  'Region'   'eu-west-1'
    Write-FxLabel  'Dry run'  'false' -ValueColor Warning

    # ── shimmer while doing something, then mark done ──
    Write-FxHeader 'Build'
    Write-FxShimmer 'Building container image' -Frames 30 -Prefix ' ' -Intensity 0.6
    Write-FxStep    'Building container image' -Prefix ' ' -Done

    Write-FxShimmer 'Pushing to registry' -Frames 20 -Prefix ' ' -Intensity 0.6
    Write-FxStep    'Pushing to registry' -Prefix ' ' -Done

    # ── section with substeps + auto-completion ──
    Write-FxHeader 'Health Checks'
    Write-FxStep 'RUN HEALTH CHECKS'
    Write-FxStep 'API responds 200'      -Prefix '   ' -Sub
    Write-FxStep 'DB connection pool OK'  -Prefix '   ' -Sub
    Write-FxStep 'Cache hit rate > 90%'   -Prefix '   ' -Sub
    Complete-FxSection 'RUN HEALTH CHECKS' -SubCount 3

    # ── cards with formatted content ──
    Write-FxBlankLine
    Write-FxCard 'Summary' -Width 44 -Lines @(
        "$(Format-Fx 'Image:' Muted)   $(Format-Fx 'app:latest' Primary)"
        "$(Format-Fx 'Size:' Muted)    $(Format-Fx '142 MB' Primary)"
        "$(Format-Fx 'Status:' Muted)  $(Format-Fx 'deployed' Success)"
    )

    # ── status messages ──
    Write-FxBlankLine
    Write-FxStatus 'Deployment complete' Success
    Write-FxStatus 'Monitoring enabled'  Info

    # ── final panel ──
    Write-FxBlankLine
    Write-FxPanel @(
        (Format-Fx 'View logs:' Muted)
        (Format-Fx '  kubectl logs -f deploy/app' Primary)
    )
}
