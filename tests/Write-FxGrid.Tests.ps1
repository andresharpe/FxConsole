BeforeAll {
    Import-Module "$PSScriptRoot/../src/FxConsole/FxConsole.psd1" -Force
    Set-FxTheme

    function global:Strip-Ansi ([string]$Text) { $Text -replace '\x1b\[[0-9;]*m', '' }
}

Describe 'Write-FxGrid' {
    It 'renders items in a grid without throwing' {
        { Write-FxGrid -Items @('A','B','C') -Columns 3 } | Should -Not -Throw
    }

    It 'handles fewer items than columns' {
        { Write-FxGrid -Items @('A','B') -Columns 5 } | Should -Not -Throw
    }

    It 'handles single item' {
        { Write-FxGrid -Items @('Solo') -Columns 3 } | Should -Not -Throw
    }

    It 'handles empty items gracefully' {
        { Write-FxGrid -Items @() -Columns 3 } | Should -Not -Throw
    }

    It 'handles ANSI-colored items' {
        $items = @(
            (Format-Fx 'CPU: 42%' Primary)
            (Format-Fx 'MEM: 68%' Warning)
            (Format-Fx 'DISK: 91%' Error)
        )
        { Write-FxGrid -Items $items -Columns 3 } | Should -Not -Throw
    }

    It 'wraps to multiple rows when items exceed column count' {
        # 6 items in 3 columns = 2 rows
        { Write-FxGrid -Items @('A','B','C','D','E','F') -Columns 3 } | Should -Not -Throw
    }

    It 'accepts custom gutter width' {
        { Write-FxGrid -Items @('A','B','C') -Columns 3 -Gutter 8 } | Should -Not -Throw
    }

    It 'accepts custom indent' {
        { Write-FxGrid -Items @('A','B','C') -Columns 3 -Indent 0 } | Should -Not -Throw
    }
}
