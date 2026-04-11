function Write-FxShimmer {
    <#
    .SYNOPSIS
    Animated shimmer effect for a fixed number of frames (decorative delay)
    .PARAMETER Spinner
    Override the spinner style for this call (e.g. 'arrows', 'braille')
    .EXAMPLE
    Write-FxShimmer 'Loading config' -Frames 30 -Intensity 0.5
    Write-FxShimmer 'With arrows' -Spinner arrows
    #>
    param(
        [Parameter(Mandatory, Position = 0)][string]$Text,
        [int]$Frames = 40,
        [string]$Prefix = "",
        [double]$Intensity = 1.0,
        [string]$Color = 'Primary',
        [string]$Spinner
    )
    # Temporarily swap spinner if overridden
    $savedSpinChars = $null
    if ($Spinner -and $script:Spinners.ContainsKey($Spinner)) {
        $savedSpinChars = $script:SpinChars
        $script:SpinChars = $script:Spinners[$Spinner]
    }

    $rgb = $script:ThemeRgb[$Color]; if (-not $rgb) { $rgb = $script:ThemeRgb['Primary'] }
    $acc = $script:ThemeRgb['Secondary']; if (-not $acc) { $acc = $rgb }
    $pad = [Math]::Min((Get-FxBufferWidth) - 1, $Text.Length + $Prefix.Length + 8)
    $rain = $script:PresetName -eq 'rainbow'

    for ($f = 0; $f -lt $Frames; $f++) {
        Render-ShimmerFrame -Text $Text -Prefix $Prefix -Frame $f -Intensity $Intensity `
            -BaseR $rgb[0] -BaseG $rgb[1] -BaseB $rgb[2] `
            -AccR $acc[0] -AccG $acc[1] -AccB $acc[2] -Rainbow $rain -Pad $pad
        Start-Sleep -Milliseconds 55
    }

    # Restore spinner
    if ($savedSpinChars) { $script:SpinChars = $savedSpinChars }
}
