
Describe 'Convert-Audio' {
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
    } else {
    . ./Internal/edit-SubtractFirst.ps1
    . ./Internal/edit-TruncateExtension.ps1
    . ./Internal/get-Converter.ps1
    . ./Internal/get-EnvironmentVariable.ps1
    . ./Internal/get-IsInstalled.ps1
    . ./Internal/invoke-ConversionBatch.ps1
    . ./Internal/xld-converter.ps1
    . ./Public/Convert-Audio.ps1
    }

    [string]$script:sourcePath = './Tests/Data/batch/Audio/MINIMAL/Richie Hawtin';
    [string]$script:destinationPath = 'TestDrive:/TEST/Audio/Richie Hawtin';

    if (-not(Test-Path -Path $destinationPath)) {
      New-Item -ItemType 'Directory' -Path $destinationPath;
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
      0;
    } # testConverter

    [scriptblock]$script:failedConverter = {
      param(
        [Parameter(Mandatory)]
        [string]$sourceFullName,

        [Parameter(Mandatory)]
        [string]$destinationAudioFilename,

        [Parameter(Mandatory)]
        [string]$toFormat
      )
      1;
    } # failedConverter
  }

  Context 'given: xld is installed' -Skip {
    Context 'and WhatIf not set' {
      Context 'and: XATCH.CONVERTER environment variable set' {
        It 'should: return environment converter' {
          Mock get-EnvironmentVariable -Verifiable  {
            $testConverter;
          }
          Mock get-IsInstalled -Verifiable {
            return $true;
          }

          Mock get-Converter -Verifiable {
            $testConverter;
          }

          Convert-Audio -Source $sourcePath -Destination $destinationPath -From 'flac' -To 'wav';
        } # should: return environment converter
      } # and: XATCH.CONVERTER environment variable set

      Context 'and: XATCH.CONVERTER environment variable not set' {
        It 'should: return dummy converter' {
          # ...
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
          # ...
        }
      } # and: XATCH.CONVERTER environment variable set
    } # and: WhatIf set
  } # given: xld is installed
} # Convert-Audio

InModuleScope Elizium.Xatch {
  Describe 'Convert-Audio' {
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

      [string]$script:sourcePath = './Tests/Data/batch/Audio/MINIMAL/Richie Hawtin';
      [string]$script:destinationPath = 'TestDrive:/TEST/Audio/Richie Hawtin';

      if (-not(Test-Path -Path $destinationPath)) {
        New-Item -ItemType 'Directory' -Path $destinationPath;
      }

      Mock get-IsInstalled {
        return $false;
      }
    } # BeforeAll

    Context 'given: xld not installed' {
      # When tests are defined InModuleScope, member variables can't be defined inside BeforeAll/Each as
      # they can be without InModuleScope, so put them in a high level Context block instead.
      #
      [scriptblock]$script:testConverter = {
        param(
          [Parameter(Mandatory)]
          [string]$sourceFullName,

          [Parameter(Mandatory)]
          [string]$destinationAudioFilename,

          [Parameter(Mandatory)]
          [string]$toFormat
        )
        0;
      } # testConverter

      [scriptblock]$script:failedConverter = {
        param(
          [Parameter(Mandatory)]
          [string]$sourceFullName,

          [Parameter(Mandatory)]
          [string]$destinationAudioFilename,

          [Parameter(Mandatory)]
          [string]$toFormat
        )
        1;
      } # failedConverter

      Context 'and WhatIf not set' {
        Context 'and: XATCH.CONVERTER environment variable set' {
          It 'should: return environment converter' {
            Mock get-EnvironmentVariable -Verifiable `
              -ParameterFilter { $Variable -eq 'XATCH.CONVERTER' } {
              $testConverter;
            }
            Convert-Audio -Source $sourcePath -Destination $destinationPath -From 'flac' -To 'wav';
          }
        } # and: XATCH.CONVERTER environment variable set

        Context 'and: XATCH.CONVERTER environment variable not set' {
          It 'should: return dummy converter' {
            Convert-Audio -Source $sourcePath -Destination $destinationPath -From 'flac' -To 'wav';
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
            Convert-Audio -Source $sourcePath -Destination $destinationPath -From 'flac' -To 'wav' -WhatIf;
          }
        } # and: XATCH.CONVERTER environment variable set

        Context 'and: XATCH.CONVERTER environment variable not set' {
          It 'should: return dummy converter' {
            Convert-Audio -Source $sourcePath -Destination $destinationPath -From 'flac' -To 'wav' -WhatIf;
          }
        } # and: XATCH.CONVERTER environment variable not set

        Context 'and: converter returns error' {
          It 'should: display error state' {
            Mock get-EnvironmentVariable -Verifiable `
              -ParameterFilter { $Variable -eq 'XATCH.CONVERTER' } {
              $failedConverter;
            }
            Convert-Audio -Source $sourcePath -Destination $destinationPath -From 'flac' -To 'wav' -WhatIf;
          }
        }
      } # and: WhatIf set  
    } # given: xld not installed
  } # Convert-Audio
} # InModuleScope

InModuleScope Elizium.Xatch {
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
    } else {
    . ./Internal/edit-SubtractFirst.ps1
    . ./Internal/edit-TruncateExtension.ps1
    . ./Internal/get-Converter.ps1
    . ./Internal/get-EnvironmentVariable.ps1
    . ./Internal/get-IsInstalled.ps1
    . ./Internal/invoke-ConversionBatch.ps1
    . ./Internal/xld-converter.ps1
    . ./Public/Convert-Audio.ps1
    }

    [string]$script:sourcePath = './Tests/Data/batch/Audio/MINIMAL/Richie Hawtin';
    [string]$script:destinationPath = 'TestDrive:/TEST/Audio/Richie Hawtin';

    if (-not(Test-Path -Path $destinationPath)) {
      New-Item -ItemType 'Directory' -Path $destinationPath;
    }

    Mock get-IsInstalled -Verifiable {
      return $true;
    }
  }

  Context 'System Integration' -Skip {
    Context 'given: xld installed' {
      Context 'and WhatIf set' {
        Context 'and: XATCH.CONVERTER environment variable not set' {
          It 'should: fail gracefully and report error state' {
            Convert-Audio -Source $sourcePath -Destination $destinationPath -From 'flac' -To 'wav' -WhatIf;
          }
        } # and: XATCH.CONVERTER environment variable not set
      }

      Context 'and WhatIf not set' {
        Context 'and: XATCH.CONVERTER environment variable not set' {
          It 'should: fail gracefully and report error state' -Tag 'Integration' {
            Convert-Audio -Source $sourcePath -Destination $destinationPath -From 'flac' -To 'wav';
          }
        } # and: XATCH.CONVERTER environment variable not set

        Context 'and: XATCH.CONVERTER environment variable set' {
          It 'should: environment converter should override' {
            Mock get-Converter -Verifiable {
              [scriptblock]$testConverter = {
                param(
                  [Parameter(Mandatory)]
                  [string]$sourceFullName,

                  [Parameter(Mandatory)]
                  [string]$destinationAudioFilename,

                  [Parameter(Mandatory)]
                  [string]$toFormat
                )
                0;
              } # testConverter
              $testConverter;
            }
            Convert-Audio -Source $sourcePath -Destination $destinationPath -From 'flac' -To 'wav';
          } # should: environment converter should override
        } # and: XATCH.CONVERTER environment variable set
      } # and WhatIf not set
    } # given: xld installed
  } # System Integration
} # InModuleScope
