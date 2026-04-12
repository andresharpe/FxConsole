BeforeAll {
    Import-Module "$PSScriptRoot/../src/FxConsole/FxConsole.psd1" -Force
}

Describe 'Module Loading' {
    It 'imports without errors' {
        { Import-Module "$PSScriptRoot/../src/FxConsole/FxConsole.psd1" -Force } | Should -Not -Throw
    }

    It 'exports all expected public functions' {
        $commands = (Get-Command -Module FxConsole).Name | Sort-Object
        $commands | Should -Contain 'Set-FxTheme'
        $commands | Should -Contain 'Get-FxTheme'
        $commands | Should -Contain 'Get-FxThemeRgb'
        $commands | Should -Contain 'Get-FxPresetName'
        $commands | Should -Contain 'Get-FxPresets'
        $commands | Should -Contain 'Get-FxSpinners'
        $commands | Should -Contain 'Get-FxBullets'
        $commands | Should -Contain 'Format-Fx'
        $commands | Should -Contain 'Write-Fx'
        $commands | Should -Contain 'Write-FxBlankLine'
        $commands | Should -Contain 'Write-FxLabel'
        $commands | Should -Contain 'Write-FxHeader'
        $commands | Should -Contain 'Write-FxSeparator'
        $commands | Should -Contain 'Write-FxStatus'
        $commands | Should -Contain 'Write-FxStep'
        $commands | Should -Contain 'Complete-FxSection'
        $commands | Should -Contain 'Write-FxShimmer'
        $commands | Should -Contain 'Invoke-FxJob'
        $commands | Should -Contain 'Write-FxBanner'
        $commands | Should -Contain 'Write-FxCard'
        $commands | Should -Contain 'Write-FxPanel'
        $commands | Should -Contain 'Write-FxTable'
        $commands | Should -Contain 'Write-FxGrid'
        $commands | Should -Contain 'Write-FxProgress'
        $commands | Should -Contain 'Invoke-FxProgress'
        $commands | Should -Contain 'Invoke-FxScript'
    }

    It 'does not export private functions' {
        $commands = (Get-Command -Module FxConsole).Name
        $commands | Should -Not -Contain 'Convert-HsvToRgb'
        $commands | Should -Not -Contain 'Render-ShimmerFrame'
        $commands | Should -Not -Contain 'Import-FxPresets'
        $commands | Should -Not -Contain 'Resolve-FxPreset'
        $commands | Should -Not -Contain 'Apply-FxPreset'
        $commands | Should -Not -Contain 'Get-FxVisualWidth'
        $commands | Should -Not -Contain 'Get-FxPaddedText'
        $commands | Should -Not -Contain 'Get-FxBufferWidth'
    }
}

Describe 'Theme System' {
    BeforeEach {
        Import-Module "$PSScriptRoot/../src/FxConsole/FxConsole.psd1" -Force
    }

    Context 'Set-FxTheme' {
        It 'loads the built-in default with no arguments' {
            Set-FxTheme
            Get-FxPresetName | Should -Be 'Default'
        }

        It 'loads a named preset' {
            Set-FxTheme amber
            Get-FxPresetName | Should -Be 'Amber Classic'
        }

        It 'throws for an unknown preset' {
            { Set-FxTheme 'nonexistent' } | Should -Throw '*not found*'
        }

        It 'loads from a custom config path' {
            $configPath = "$PSScriptRoot/../src/FxConsole/theme-config.json"
            Set-FxTheme cyan -ConfigPath $configPath
            Get-FxPresetName | Should -Be 'Cyan Ice'
        }

        It 'throws for a missing config path' {
            { Set-FxTheme -ConfigPath '/nonexistent/path.json' } | Should -Throw '*not found*'
        }
    }

    Context 'Get-FxTheme' {
        BeforeEach { Set-FxTheme }

        It 'returns a hashtable with theme colors' {
            $theme = Get-FxTheme
            $theme | Should -BeOfType [hashtable]
            $theme.Keys | Should -Contain 'Primary'
            $theme.Keys | Should -Contain 'Success'
            $theme.Keys | Should -Contain 'Error'
            $theme.Keys | Should -Contain 'Reset'
        }

        It 'returns ANSI escape strings' {
            $theme = Get-FxTheme
            $theme['Primary'] | Should -Match '\x1b\['
        }
    }

    Context 'Get-FxThemeRgb' {
        BeforeEach { Set-FxTheme }

        It 'returns a hashtable with RGB arrays' {
            $rgb = Get-FxThemeRgb
            $rgb | Should -BeOfType [hashtable]
            $rgb.Keys | Should -Contain 'Primary'
            $rgb['Primary'].Count | Should -Be 3
            $rgb['Primary'][0] | Should -BeOfType [int]
        }
    }

    Context 'Get-FxPresets' {
        BeforeEach { Set-FxTheme }

        It 'returns preset objects with Id and Name' {
            $presets = Get-FxPresets
            $presets.Count | Should -BeGreaterThan 0
            $presets[0].Id | Should -Be 'default'
            $presets[0].Name | Should -Be 'Default'
        }

        It 'includes all built-in and loaded presets' {
            $ids = (Get-FxPresets).Id
            $ids | Should -Contain 'default'
            $ids | Should -Contain 'amber'
            $ids | Should -Contain 'rainbow'
        }
    }

    Context 'Get-FxSpinners' {
        It 'returns spinner objects with Id and Preview' {
            Set-FxTheme
            $spinners = Get-FxSpinners
            $spinners.Count | Should -Be 13
            ($spinners.Id) | Should -Contain 'braille'
            ($spinners.Id) | Should -Contain 'bars'
            ($spinners.Id) | Should -Contain 'classic'
        }
    }

    Context 'Get-FxBullets' {
        It 'returns bullet objects with Id, Pending, Done, Sub' {
            Set-FxTheme
            $bullets = Get-FxBullets
            $bullets.Count | Should -Be 8
            ($bullets.Id) | Should -Contain 'check'
            ($bullets.Id) | Should -Contain 'scope'
            $check = $bullets | Where-Object Id -eq 'check'
            $check.Pending | Should -Not -BeNullOrEmpty
            $check.Done | Should -Not -BeNullOrEmpty
            $check.Sub | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Theme switching preserves state' {
        It 'changes preset name when switching themes' {
            Set-FxTheme amber
            Get-FxPresetName | Should -Be 'Amber Classic'
            Set-FxTheme cyan
            Get-FxPresetName | Should -Be 'Cyan Ice'
        }

        It 'updates RGB values when switching themes' {
            Set-FxTheme amber
            $amberPrimary = (Get-FxThemeRgb)['Primary']
            Set-FxTheme cyan
            $cyanPrimary = (Get-FxThemeRgb)['Primary']
            $amberPrimary | Should -Not -Be $cyanPrimary
        }
    }
}

Describe 'Format-Fx' {
    BeforeAll { Set-FxTheme }

    It 'returns a string containing the text' {
        $result = Format-Fx 'hello' Primary
        $result | Should -Match 'hello'
    }

    It 'wraps text in ANSI escape codes' {
        $result = Format-Fx 'test' Success
        $result | Should -Match '\x1b\['
        $result | Should -Match 'test'
        # Should end with reset
        $result | Should -Match '\x1b\[0m$'
    }

    It 'defaults to Primary color' {
        $result = Format-Fx 'text'
        $primary = Format-Fx 'text' Primary
        $result | Should -Be $primary
    }

    It 'falls back to Primary for unknown color names' {
        $result = Format-Fx 'text' 'NonexistentColor'
        $primary = Format-Fx 'text' Primary
        $result | Should -Be $primary
    }
}

Describe 'Text Output Functions' {
    BeforeAll { Set-FxTheme }

    # These functions write to [Console] which we can't easily capture in Pester.
    # We test that they don't throw and accept valid parameters.

    Context 'Write-Fx' {
        It 'writes without throwing' {
            { Write-Fx 'test' } | Should -Not -Throw
        }

        It 'accepts color parameter' {
            { Write-Fx 'test' Success } | Should -Not -Throw
        }

        It 'accepts NoNewline switch' {
            { Write-Fx 'test' Primary -NoNewline } | Should -Not -Throw
        }

        It 'accepts empty string' {
            { Write-Fx '' } | Should -Not -Throw
        }
    }

    Context 'Write-FxBlankLine' {
        It 'writes without throwing' {
            { Write-FxBlankLine } | Should -Not -Throw
        }

        It 'accepts Count parameter' {
            { Write-FxBlankLine -Count 3 } | Should -Not -Throw
        }
    }

    Context 'Write-FxLabel' {
        It 'writes without throwing' {
            { Write-FxLabel 'Key' 'Value' } | Should -Not -Throw
        }

        It 'accepts ValueColor parameter' {
            { Write-FxLabel 'Status' 'OK' -ValueColor Success } | Should -Not -Throw
        }
    }

    Context 'Write-FxHeader' {
        It 'writes without throwing' {
            { Write-FxHeader 'Test Section' } | Should -Not -Throw
        }
    }

    Context 'Write-FxSeparator' {
        It 'writes without throwing' {
            { Write-FxSeparator } | Should -Not -Throw
        }

        It 'accepts Width parameter' {
            { Write-FxSeparator -Width 60 } | Should -Not -Throw
        }
    }

    Context 'Write-FxStatus' {
        It 'writes each status type without throwing' {
            @('Info', 'Success', 'Error', 'Warn', 'Process', 'Complete') | ForEach-Object {
                { Write-FxStatus 'test' $_ } | Should -Not -Throw
            }
        }

        It 'defaults to Info type' {
            { Write-FxStatus 'test' } | Should -Not -Throw
        }

        It 'rejects invalid status types' {
            { Write-FxStatus 'test' 'Invalid' } | Should -Throw
        }
    }
}

Describe 'Steps' {
    BeforeAll { Set-FxTheme }

    Context 'Write-FxStep' {
        It 'writes a pending step' {
            { Write-FxStep 'test step' } | Should -Not -Throw
        }

        It 'writes a done step' {
            { Write-FxStep 'test step' -Done } | Should -Not -Throw
        }

        It 'writes a sub step' {
            { Write-FxStep 'sub step' -Sub } | Should -Not -Throw
        }

        It 'accepts Prefix parameter' {
            { Write-FxStep 'indented' -Prefix '   ' } | Should -Not -Throw
        }
    }
}

Describe 'Structural' {
    BeforeAll { Set-FxTheme }

    Context 'Write-FxBanner' {
        It 'writes without throwing' {
            { Write-FxBanner 'TITLE' } | Should -Not -Throw
        }

        It 'accepts Subtitle' {
            { Write-FxBanner 'TITLE' -Subtitle 'v1.0' } | Should -Not -Throw
        }

        It 'accepts Width' {
            { Write-FxBanner 'TITLE' -Width 60 } | Should -Not -Throw
        }
    }

    Context 'Write-FxCard' {
        It 'writes a card with title and lines' {
            { Write-FxCard 'Status' -Lines @('Line 1', 'Line 2') } | Should -Not -Throw
        }

        It 'writes a card without title' {
            { Write-FxCard -Lines @('Content') } | Should -Not -Throw
        }

        It 'accepts all border styles' {
            @('Rounded', 'Square', 'Double', 'Heavy') | ForEach-Object {
                { Write-FxCard 'Test' -Lines @('x') -BorderStyle $_ } | Should -Not -Throw
            }
        }
    }

    Context 'Write-FxPanel' {
        It 'writes a panel with auto width' {
            { Write-FxPanel @('Line 1', 'Line 2') } | Should -Not -Throw
        }

        It 'writes a panel with explicit width' {
            { Write-FxPanel @('Line 1') -Width 50 } | Should -Not -Throw
        }

        It 'accepts border style' {
            { Write-FxPanel @('x') -BorderStyle Heavy } | Should -Not -Throw
        }
    }
}

Describe 'Invoke-FxScript' {
    BeforeAll {
        Set-FxTheme
        # Detect whether [Console]::CursorVisible is readable (not in non-TTY)
        $script:canSetCursor = $true
        try { $null = [Console]::CursorVisible } catch { $script:canSetCursor = $false }
    }

    It 'executes the script block without throwing in any environment' {
        { Invoke-FxScript { 1 + 1 } } | Should -Not -Throw
    }

    It 'propagates exceptions from the script block' {
        { Invoke-FxScript { throw 'deliberate' } } | Should -Throw 'deliberate'
    }

    It 'sets UTF-8 encoding' {
        Invoke-FxScript { }
        [Console]::OutputEncoding.WebName | Should -Be 'utf-8'
    }

    It 'restores cursor visibility on exit (TTY only)' -Skip:(-not $script:canSetCursor) {
        { Invoke-FxScript { throw 'deliberate' } } | Should -Throw 'deliberate'
        [Console]::CursorVisible | Should -Be $true
    }

    It 'restores $ProgressPreference on exit' {
        $global:ProgressPreference = 'Continue'
        Invoke-FxScript { }
        $global:ProgressPreference | Should -Be 'Continue'
    }

    It 'suppresses $ProgressPreference inside the script block' {
        $global:ProgressPreference = 'Continue'
        $inside = Invoke-FxScript { $global:ProgressPreference }
        $inside | Should -Be 'SilentlyContinue'
    }
}
