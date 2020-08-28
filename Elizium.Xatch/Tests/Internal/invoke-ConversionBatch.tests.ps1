
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
      # [string]$command = ("xld -f '{0}' -o '{1}' '{2}'" `
      #     -f $toFormat, $destinationAudioFilename, $sourceFullName);
      # Write-Host "COMMAND: >>> $command";

      # Write-RawPairsInColour (, @( @('destination audio file', 'Yellow'), @($destinationAudioFilename, 'Red') ));
    }
  }

  Context 'given: blah' {
    It 'should: ' {
      [System.Collections.Hashtable]$PassThru = @{
        'XATCH.CONVERT.CONVERTER' = $converter;
      }

      [System.Collections.Hashtable]$generalTheme = Get-KrayolaTheme;
      $passThru['LOOPZ.KRAYOLA-THEME'] = $generalTheme;
      # $passThru['LOOPZ.WH-FOREACH-DECORATOR.IF-TRIGGERED'] = $true;

      [System.Collections.Hashtable]$innerTheme = $generalTheme.Clone();
      $innerTheme['FORMAT'] = '"<%KEY%>" -> "<%VALUE%>"';
      $innerTheme['MESSAGE-SUFFIX'] = ' | ';
      $innerTheme['MESSAGE-COLOURS'] = @('Green');
      $innerTheme['META-COLOURS'] = @('DarkMagenta');
      $innerTheme['VALUE-COLOURS'] = @('Blue');
      $innerTheme['AFFIRM-COLOURS'] = @('Red');
      $innerTheme['OPEN'] = '(';
      $innerTheme['CLOSE'] = ')';

      $PassThru['XATCH.INNER-KRAYOLA-THEME'] = $innerTheme;

      invoke-ConversionBatch -Source $sourcePath -Destination $destinationPath `
        -From 'flac' -To 'wav' -PassThru $PassThru -WhatIf;
    }
  }
}
