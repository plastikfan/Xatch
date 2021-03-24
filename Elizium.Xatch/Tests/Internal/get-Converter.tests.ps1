
Describe 'get-Converter' {
  BeforeAll {
    if ($IsWindows) {
      . .\Internal\edit-SubtractFirst.ps1
      . .\Internal\edit-TruncateExtension.ps1
      . .\Internal\get-Converter.ps1
      . .\Internal\get-EnvironmentVariable.ps1
      . .\Internal\get-IsInstalled.ps1
      . .\Internal\invoke-ConversionBatch.ps1
      . .\Internal\xld-converter.ps1
      . .\Public\Convert-Audio.ps1
    }
    else {
      . ./Internal/edit-SubtractFirst.ps1
      . ./Internal/edit-TruncateExtension.ps1
      . ./Internal/get-Converter.ps1
      . ./Internal/get-EnvironmentVariable.ps1
      . ./Internal/get-IsInstalled.ps1
      . ./Internal/invoke-ConversionBatch.ps1
      . ./Internal/xld-converter.ps1
      . ./Public/Convert-Audio.ps1
    }

    [scriptblock]$script:testConverter = {
      param(
        [Parameter(Mandatory)]
        [string]$sourceFullName,

        [Parameter(Mandatory)]
        [string]$destinationAudioFilename,

        [Parameter(Mandatory)]
        [string]$toFormat
      )
      909;
    }
  }

  Context 'given: xld not installed' {
    BeforeEach {
      Mock get-IsInstalled {
        return $false;
      }
    }

    Context 'and WhatIf not set' {
      Context 'and: XATCH.CONVERTER environment variable set' {
        It 'should: return environment converter' {
          Mock get-EnvironmentVariable -Verifiable `
            -ParameterFilter { $Variable -eq 'XATCH.CONVERTER' } {
            $testConverter;
          }
          [System.Collections.Hashtable]$exchange = @{}
          [scriptblock]$converter = get-Converter -Exchange $exchange;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 909;
        }
      } # and: XATCH.CONVERTER environment variable set

      Context 'and: XATCH.CONVERTER environment variable not set' {
        It 'should: return dummy converter' {
          [System.Collections.Hashtable]$exchange = @{}
          [scriptblock]$converter = get-Converter -Exchange $exchange;

          $exchange['XATCH.CONVERTER.DUMMY'] | Should -BeTrue;
          if (-not(Get-Command -Name 'xld' -ErrorAction SilentlyContinue)) {
            $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 0;
          }
        }
      } # and: XATCH.CONVERTER environment variable not set
    } # and WhatIf not set

    Context 'and: WhatIf set' {
      Context 'and: XATCH.CONVERTER environment variable set' {
        It 'should: return dummy converter' {
          Mock get-EnvironmentVariable -Verifiable `
            -ParameterFilter { $Variable -eq 'XATCH.CONVERTER' } {
            $testConverter;
          }

          [System.Collections.Hashtable]$exchange = @{
            'WHAT-IF' = $true;
          }
          [scriptblock]$converter = get-Converter -Exchange $exchange;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 0;
          $exchange['XATCH.CONVERTER.DUMMY'] | Should -BeTrue;
        }
      } # and: XATCH.CONVERTER environment variable set

      Context 'and: XATCH.CONVERTER environment variable not set' {
        It 'should: return dummy converter' {
          [System.Collections.Hashtable]$exchange = @{
            'WHAT-IF' = $true;
          }
          [scriptblock]$converter = get-Converter -Exchange $exchange;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 0;
          $exchange['XATCH.CONVERTER.DUMMY'] | Should -BeTrue;
        }
      } # and: XATCH.CONVERTER environment variable not set
    } # and: WhatIf set
  } # given: xld not installed

  Context 'given: xld is installed' {
    BeforeAll {
      Mock get-IsInstalled {
        return $true;
      }
    }

    Context 'and WhatIf not set' {
      Context 'and: XATCH.CONVERTER environment variable set' {
        It 'should: return environment converter' {
          Mock get-EnvironmentVariable -Verifiable `
            -ParameterFilter { $Variable -eq 'XATCH.CONVERTER' } {
            $testConverter;
          }
          [System.Collections.Hashtable]$exchange = @{}
          [scriptblock]$converter = get-Converter -Exchange $exchange;

          if (-not(Get-Command -Name 'xld' -ErrorAction 'SilentlyContinue')) {
            $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 909;
          }
        } # should: return environment converter
      } # and: XATCH.CONVERTER environment variable set
    } # and WhatIf not set

    Context 'and: WhatIf set' {
      Context 'and: XATCH.CONVERTER environment variable set' {
        It 'should: override environment converter with dummy' {
          Mock get-EnvironmentVariable -Verifiable `
            -ParameterFilter { $Variable -eq 'XATCH.CONVERTER' } {
            $testConverter;
          }
          [System.Collections.Hashtable]$exchange = @{
            'WHAT-IF' = $true;
          }
          [scriptblock]$converter = get-Converter -Exchange $exchange;

          $exchange['XATCH.CONVERTER.DUMMY'] | Should -BeTrue;
          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 0;
        }
      } # and: XATCH.CONVERTER environment variable set

      Context 'and: XATCH.CONVERTER environment variable not set' {
        It 'should: return dummy converter' {
          [System.Collections.Hashtable]$exchange = @{
            'WHAT-IF' = $true;
          }
          [scriptblock]$converter = get-Converter -Exchange $exchange;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 0;
          $exchange['XATCH.CONVERTER.DUMMY'] | Should -BeTrue;
        }
      } # and: XATCH.CONVERTER environment variable not set
    } # and: WhatIf set
  } # given: xld is installed
} # get-Converter
