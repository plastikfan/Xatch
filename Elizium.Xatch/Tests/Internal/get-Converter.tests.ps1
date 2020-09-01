
Describe 'get-Converter' {
  BeforeAll {
    . .\Internal\get-EnvironmentVariable.ps1;
    . .\Internal\get-IsInstalled;
    . .\Internal\get-Converter.ps1;

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
    Mock -ParameterFilter { $Name -eq 'xld' } get-IsInstalled {
      return $false;
    }

    Context 'and WhatIf not set' {
      Context 'and: XATCH.CONVERTER environment variable set' {
        It 'should: return environment converter' {
          Mock get-EnvironmentVariable -Verifiable `
            -ParameterFilter { $Variable -eq 'XATCH.CONVERTER' } {
            $testConverter;
          }
          [System.Collections.Hashtable]$passThru = @{}
          [scriptblock]$converter = get-Converter -PassThru $passThru;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 909;
        }
      } # and: XATCH.CONVERTER environment variable set

      Context 'and: XATCH.CONVERTER environment variable not set' {
        It 'should: return dummy converter' {
          [System.Collections.Hashtable]$passThru = @{}
          [scriptblock]$converter = get-Converter -PassThru $passThru;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 0;
          $passThru['XATCH.CONVERTER.DUMMY'] | Should -BeTrue;
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
          [System.Collections.Hashtable]$passThru = @{
            'WHAT-IF' = $true;
          }
          [scriptblock]$converter = get-Converter -PassThru $passThru;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 0;
          $passThru['XATCH.CONVERTER.DUMMY'] | Should -BeTrue;
        }
      } # and: XATCH.CONVERTER environment variable set

      Context 'and: XATCH.CONVERTER environment variable not set' {
        It 'should: return dummy converter' {
          [System.Collections.Hashtable]$passThru = @{
            'WHAT-IF' = $true;
          }
          [scriptblock]$converter = get-Converter -PassThru $passThru;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 0;
          $passThru['XATCH.CONVERTER.DUMMY'] | Should -BeTrue;
        }
      } # and: XATCH.CONVERTER environment variable not set
    } # and: WhatIf set
  } # given: xld not installed

  Context 'given: xld is installed' {
    Mock -ParameterFilter { $Name -eq 'xld' } get-IsInstalled {
      return $true;
    }

    Context 'and WhatIf not set' {
      Context 'and: XATCH.CONVERTER environment variable set' {
        It 'should: return environment converter' {
          Mock get-EnvironmentVariable -Verifiable `
            -ParameterFilter { $Variable -eq 'XATCH.CONVERTER' } {
            $testConverter;
          }
          [System.Collections.Hashtable]$passThru = @{}
          [scriptblock]$converter = get-Converter -PassThru $passThru;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 909;
        } # should: return environment converter
      } # and: XATCH.CONVERTER environment variable set

      Context 'and: XATCH.CONVERTER environment variable not set' {
        It 'should: return dummy converter' {
          [System.Collections.Hashtable]$passThru = @{}
          [scriptblock]$converter = get-Converter -PassThru $passThru;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 0;
          $passThru['XATCH.CONVERTER.DUMMY'] | Should -BeTrue;
        }
      } # and: XATCH.CONVERTER environment variable not set
    } # and WhatIf not set

    Context 'and: WhatIf set' {
      Context 'and: XATCH.CONVERTER environment variable set' {
        It 'should: override environment converter with dummy' {
          Mock get-EnvironmentVariable -Verifiable `
            -ParameterFilter { $Variable -eq 'XATCH.CONVERTER' } {
            $testConverter;
          }
          [System.Collections.Hashtable]$passThru = @{
            'WHAT-IF' = $true;
          }
          [scriptblock]$converter = get-Converter -PassThru $passThru;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 0;
          $passThru['XATCH.CONVERTER.DUMMY'] | Should -BeTrue;
        }
      } # and: XATCH.CONVERTER environment variable set

      Context 'and: XATCH.CONVERTER environment variable not set' {
        It 'should: return dummy converter' {
          [System.Collections.Hashtable]$passThru = @{
            'WHAT-IF' = $true;
          }
          [scriptblock]$converter = get-Converter -PassThru $passThru;

          $converter.Invoke('blue-rose.flac', 'blue-rose.wav', 'wav') | Should -Be 0;
          $passThru['XATCH.CONVERTER.DUMMY'] | Should -BeTrue;
        }
      } # and: XATCH.CONVERTER environment variable not set
    } # and: WhatIf set
  } # given: xld is installed
} # get-Converter
