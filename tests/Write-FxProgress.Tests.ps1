BeforeAll {
    Import-Module "$PSScriptRoot/../src/FxConsole/FxConsole.psd1" -Force
    Set-FxTheme
}

Describe 'Write-FxProgress' {
    Context 'Basic rendering' {
        It 'renders without throwing' {
            { Write-FxProgress -Activity 'Test' -Percent 50 } | Should -Not -Throw
            Write-FxProgress -Activity 'Test' -Complete
        }

        It 'accepts 0 percent' {
            { Write-FxProgress -Activity 'Test' -Percent 0 } | Should -Not -Throw
            Write-FxProgress -Activity 'Test' -Complete
        }

        It 'accepts 100 percent' {
            { Write-FxProgress -Activity 'Test' -Percent 100 } | Should -Not -Throw
            Write-FxProgress -Activity 'Test' -Complete
        }

        It 'accepts Status text' {
            { Write-FxProgress -Activity 'Test' -Percent 25 -Status '1 of 4' } | Should -Not -Throw
            Write-FxProgress -Activity 'Test' -Complete
        }

        It 'rejects percent over 100' {
            { Write-FxProgress -Activity 'Test' -Percent 101 } | Should -Throw
        }

        It 'rejects negative percent' {
            { Write-FxProgress -Activity 'Test' -Percent -1 } | Should -Throw
        }
    }

    Context 'Complete switch' {
        It 'clears the progress line' {
            Write-FxProgress -Activity 'Cleanup' -Percent 50
            { Write-FxProgress -Activity 'Cleanup' -Complete } | Should -Not -Throw
        }
    }

    Context 'Custom parameters' {
        It 'accepts BarColor' {
            { Write-FxProgress -Activity 'Test' -Percent 50 -BarColor Success } | Should -Not -Throw
            Write-FxProgress -Activity 'Test' -Complete
        }

        It 'accepts custom Width' {
            { Write-FxProgress -Activity 'Test' -Percent 50 -Width 50 } | Should -Not -Throw
            Write-FxProgress -Activity 'Test' -Complete
        }
    }

    Context 'Timer tracking' {
        It 'tracks elapsed time across calls' {
            Write-FxProgress -Activity 'Timer' -Percent 10
            Start-Sleep -Milliseconds 100
            { Write-FxProgress -Activity 'Timer' -Percent 50 } | Should -Not -Throw
            Write-FxProgress -Activity 'Timer' -Complete
        }

        It 'tracks multiple activities independently' {
            Write-FxProgress -Activity 'A' -Percent 10
            Write-FxProgress -Activity 'B' -Percent 20
            { Write-FxProgress -Activity 'A' -Percent 50 } | Should -Not -Throw
            Write-FxProgress -Activity 'A' -Complete
            Write-FxProgress -Activity 'B' -Complete
        }
    }
}

Describe 'Invoke-FxProgress' {
    Context 'Pipeline processing' {
        It 'passes items through the pipeline' {
            $result = 1..5 | Invoke-FxProgress -Activity 'Test' -Total 5
            $result | Should -HaveCount 5
            $result[0] | Should -Be 1
            $result[-1] | Should -Be 5
        }

        It 'executes scriptblock on each item' {
            $result = 1..3 | Invoke-FxProgress -Activity 'Test' -Total 3 -ScriptBlock { $_ * 10 }
            $result | Should -HaveCount 3
            $result[0] | Should -Be 10
            $result[-1] | Should -Be 30
        }

        It 'works without -Total (counter mode)' {
            $result = 'a','b','c' | Invoke-FxProgress -Activity 'Test'
            $result | Should -HaveCount 3
        }

        It 'works without -ScriptBlock (passthrough)' {
            $result = 1..4 | Invoke-FxProgress -Activity 'Test' -Total 4
            $result | Should -Be @(1,2,3,4)
        }
    }
}
