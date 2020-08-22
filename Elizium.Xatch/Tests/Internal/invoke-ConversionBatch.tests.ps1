
Describe 'invoke-ConversionBatch' {
  BeforeAll {
    # Get-Module Elizium.Xatch | Remove-Module
    # Import-Module .\Output\Elizium.Xatch\Elizium.Xatch.psm1 `
    #   -ErrorAction 'stop' -DisableNameChecking

    . ./Internal/invoke-ConversionBatch.ps1;
    . ./Internal/edit-TruncateExtension.ps1;
    . ./Internal/edit-SubtractFirst.ps1;

    [string]$script:sourcePath = './Tests/Data/batch/Audio';
    [string]$script:destinationPath = 'TestDrive:/TEST/Audio';
    New-Item -ItemType 'Directory' -Path $destinationPath;

    [scriptblock]$script:converter = {
      param(
        [Parameter(Mandatory)]
        [string]$sourceFullName,

        [Parameter(Mandatory)]
        [string]$destinationAudioFilename,

        [Parameter(Mandatory)]
        [string]$toFormat
      )
      [string]$command = ("xld -f '{0}' -o '{1}' '{2}'" `
          -f $toFormat, $destinationAudioFilename, $sourceFullName);
      Write-Host "COMMAND: >>> $command";

      Write-RawPairsInColour (, @( @('destination audio file', 'Yellow'), @($destinationAudioFilename, 'Red') ));
    }
  }

  Context 'given: blah' {
    It 'should: ' -Tag 'Current' {
      [System.Collections.Hashtable]$PassThru = @{
        'XATCH.CONVERT.CONVERTER' = $converter;
      }

      invoke-ConversionBatch -Source $sourcePath -Destination $destinationPath `
        -From 'flac' -To 'wav' -PassThru $PassThru -WhatIf;
    }
  }
}
