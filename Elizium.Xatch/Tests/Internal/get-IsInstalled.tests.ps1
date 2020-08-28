
Describe 'get-IsInstalled' -Skip {

  InModuleScope Elizium.Xatch {
    BeforeAll {
      # . ./Internal/get-IsInstalled.ps1;

      Get-Module Elizium.Xatch | Remove-Module
      Import-Module .\Output\Elizium.Xatch\Elizium.Xatch.psm1 `
        -ErrorAction 'stop' -DisableNameChecking

      [string]$script:message = "The term 'xld' is not recognized as the name of a cmdlet, ...";
    }
  
    Context 'given: not installed' {
      It 'should: return false' -Tag 'Current' {
        Mock Get-Command -Verifiable { # These mocks don't work; internal function?
          throw $message;
        }
        get-IsInstalled 'xld' | Should -BeFalse;
      }
    }

    Context 'given: is installed but not external app' {
      It 'should: return false' {
        Mock -ModuleName Elizium.Xatch Get-Command {
          return @{
            Name          = 'xld';
            ModuleName    = '';
            CommandType   = 'Cmdlet';
            Definition    = 'xld';
            ParameterSets = @{};
          }
        }
        get-IsInstalled 'xld' | Should -BeFalse;
      }
    }

    Context 'given: is installed' {
      It 'should: return true' {
        Mock -ModuleName Elizium.Xatch Get-Command {
          return @{
            Name          = 'xld';
            ModuleName    = '';
            CommandType   = 'Application';
            Definition    = '/usr/local/bin/xld';
            ParameterSets = @{};
          }
        }
        get-IsInstalled 'xld' | Should -BeTrue;
      }
    }
  }
} # get-IsInstalled
