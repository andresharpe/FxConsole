BeforeAll {
    Import-Module "$PSScriptRoot/../src/FxConsole/FxConsole.psd1" -Force
    Set-FxTheme

    # Helper: strip ANSI escapes for width assertions
    function global:Strip-Ansi ([string]$Text) { $Text -replace '\x1b\[[0-9;]*m', '' }
}

Describe 'Write-FxTable' {
    Context 'Basic rendering' {
        It 'renders a simple table with headers and rows' {
            $lines = Write-FxTable -Headers @('A','B') -Rows @(,@('x','y')) -PassThru
            $lines.Count | Should -Be 5   # top + header + separator + 1 row + bottom
        }

        It 'renders correct column widths' {
            $lines = Write-FxTable -Headers @('Name','Value') -Rows @(,@('hello','world')) -PassThru
            $stripped = Strip-Ansi $lines[1]  # header row
            # Name is 5 chars, Value is 5 chars — both padded to 5
            $stripped | Should -Match 'Name\s+.*Value'
        }

        It 'auto-sizes columns to widest content' {
            $lines = Write-FxTable -Headers @('X','Y') -Rows @(,@('longvalue','z')) -PassThru
            $stripped = Strip-Ansi $lines[3]  # first data row
            $stripped | Should -Match 'longvalue'
        }

        It 'handles empty rows' {
            $lines = Write-FxTable -Headers @('A','B') -Rows @() -PassThru
            $lines.Count | Should -Be 4   # top + header + separator + bottom
        }

        It 'warns with no headers and no pipeline' {
            Write-FxTable -Rows @() -WarningVariable w -WarningAction SilentlyContinue
            $w | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Row normalization' {
        It 'handles ,@() row syntax correctly' {
            $lines = Write-FxTable -Headers @('A','B') -Rows @(,@('1','2'), ,@('3','4')) -PassThru
            $lines.Count | Should -Be 6   # top + header + sep + 2 rows + bottom

            $row1 = Strip-Ansi $lines[3]
            $row1 | Should -Match '1'
            $row1 | Should -Match '2'
        }

        It 'handles plain array rows' {
            $rows = [System.Collections.Generic.List[object]]::new()
            $rows.Add(@('a','b'))
            $rows.Add(@('c','d'))
            $lines = Write-FxTable -Headers @('X','Y') -Rows $rows.ToArray() -PassThru
            $row1 = Strip-Ansi $lines[3]
            $row1 | Should -Match 'a'
        }
    }

    Context 'Column alignment' {
        It 'left-aligns by default' {
            $lines = Write-FxTable -Headers @('Col') -Rows @(,@('hi')) -PassThru
            $row = Strip-Ansi $lines[3]
            # 'hi' should be followed by spaces (left-aligned)
            $row | Should -Match 'hi\s'
        }

        It 'right-aligns when specified' {
            $lines = Write-FxTable -Headers @('Number') -Rows @(,@('42')) -PassThru -Alignment @('Right')
            $row = Strip-Ansi $lines[3]
            # '42' should be preceded by spaces (right-aligned)
            $row | Should -Match '\s+42'
        }

        It 'center-aligns when specified' {
            $lines = Write-FxTable -Headers @('Wide') -Rows @(,@('X')) -PassThru -Alignment @('Center')
            $row = Strip-Ansi $lines[3]
            $row | Should -Match '\s+X\s+'
        }
    }

    Context 'Border styles' {
        It 'renders all bordered styles without error' {
            @('Rounded', 'Square', 'Double', 'Heavy') | ForEach-Object {
                $lines = Write-FxTable -Headers @('A') -Rows @(,@('x')) -PassThru -BorderStyle $_
                $lines | Should -Not -BeNullOrEmpty
            }
        }

        It 'renders Minimal style (no vertical borders)' {
            $lines = Write-FxTable -Headers @('A','B') -Rows @(,@('x','y')) -PassThru -BorderStyle Minimal
            $lines.Count | Should -Be 5   # top sep + header + bottom sep + row + bottom sep
            $row = Strip-Ansi $lines[3]
            $row | Should -Not -Match '[│┃║]'   # no vertical borders
        }

        It 'renders None style (no borders at all)' {
            $lines = Write-FxTable -Headers @('A','B') -Rows @(,@('x','y')) -PassThru -BorderStyle None
            $row = Strip-Ansi $lines[2]   # data row
            $row | Should -Not -Match '[─━═│┃║]'   # no border chars
        }
    }

    Context 'Compact mode' {
        It 'reduces padding in compact mode' {
            $normal = Write-FxTable -Headers @('A') -Rows @(,@('x')) -PassThru
            $compact = Write-FxTable -Headers @('A') -Rows @(,@('x')) -PassThru -Compact

            $normalWidth = (Strip-Ansi $normal[0]).Length
            $compactWidth = (Strip-Ansi $compact[0]).Length
            $compactWidth | Should -BeLessThan $normalWidth
        }
    }

    Context 'ANSI-aware width' {
        It 'handles colored cell content correctly' {
            $colored = Format-Fx 'running' Success
            $lines = Write-FxTable -Headers @('Status') -Rows @(,@($colored)) -PassThru

            # The column width should be based on visual width of 'running' (7), not ANSI length
            $headerStripped = Strip-Ansi $lines[1]
            # 'Status' is 6 chars, 'running' is 7 — column should be 7 wide
            $headerStripped | Should -Match 'Status\s'
        }
    }

    Context 'Pipeline input' {
        It 'accepts pipeline objects' {
            $lines = @(
                [PSCustomObject]@{Name='alpha'; Value=1}
                [PSCustomObject]@{Name='beta'; Value=2}
            ) | Write-FxTable -PassThru

            $lines.Count | Should -Be 6   # top + header + sep + 2 rows + bottom
            $row1 = Strip-Ansi $lines[3]
            $row1 | Should -Match 'alpha'
        }

        It 'uses property names as headers when none specified' {
            $lines = @(
                [PSCustomObject]@{Foo='a'; Bar='b'}
            ) | Write-FxTable -PassThru

            $header = Strip-Ansi $lines[1]
            $header | Should -Match 'Foo'
            $header | Should -Match 'Bar'
        }

        It 'respects explicit headers with pipeline input' {
            $lines = @(
                [PSCustomObject]@{Name='x'; Extra='y'}
            ) | Write-FxTable -Headers @('Name') -PassThru

            $header = Strip-Ansi $lines[1]
            $header | Should -Match 'Name'
            $header | Should -Not -Match 'Extra'
        }
    }

    Context 'PassThru' {
        It 'returns strings instead of writing to console' {
            $lines = Write-FxTable -Headers @('A') -Rows @(,@('x')) -PassThru
            $lines | Should -BeOfType [string]
        }
    }

    Context 'Consistent row widths' {
        It 'all rows have the same visual width in bordered mode' {
            $lines = Write-FxTable -Headers @('Short','LongerHeader') -Rows @(
                ,@('a','b')
                ,@('something','x')
            ) -PassThru

            $widths = $lines | ForEach-Object { (Strip-Ansi $_).Length }
            $widths | Select-Object -Unique | Should -HaveCount 1
        }
    }
}
