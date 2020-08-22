
function invoke-ConversionBatch {
  [CmdletBinding(SupportsShouldProcess)]
  [Alias('cva')]
  param
  (
    [parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path -Path $_ } )]
    [string]$Source,

    [parameter(Mandatory = $true)]
    [string]$Destination,

    [parameter(Mandatory = $true)]
    [string]$From,

    [parameter(Mandatory = $true)]
    [string]$To,

    [parameter()]
    [string[]]$CopyFiles = @('jpg', 'jpeg', 'txt'),

    [Parameter()]
    [System.Collections.Hashtable]$PassThru = @{},

    [switch]$Skip,
    [switch]$Concise
  )

  # Convert source audio files
  #
  [scriptblock]$script:doAudioFileConversion = {
    param(
      [Parameter(Mandatory)]
      [System.IO.FileInfo]$underscore,

      [Parameter(Mandatory)]
      [int]$index,

      [Parameter(Mandatory)]
      [System.Collections.Hashtable]$passThru,

      [Parameter(Mandatory)]
      [boolean]$trigger
    )

    [string]$sourceName = $underscore.Name;
    [string]$sourceFullName = $underscore.FullName;
    [string]$toFormat = $passThru['XATCH.CONVERT.TO'];
    [boolean]$skipExisting = $passThru.ContainsKey('XATCH.CONVERT.SKIP');
    [System.IO.DirectoryInfo]$destinationInfo = $passThru['LOOPZ.MIRROR.DESTINATION'];
    [string]$destinationAudioFilename = ((edit-TruncateExtension -path $sourceName) + '.' + $toFormat);
    [string]$destinationAudioFullname = Join-Path -Path $destinationInfo.FullName `
      -ChildPath $destinationAudioFilename;

    [boolean]$doConversion = $true;

    if (Test-Path -Path $destinationAudioFilename) {
      if ($skipExisting) {
        Write-Warning ("!!! Skipping existing file: '" + $destinationAudioFilename + "'");
        $doConversion = $false;
      }
      else {
        Write-Warning ("!!! Overwriting existing file: '" + $destinationAudioFilename + "'");
      }
    }

    [string[][]]$properties = @();
    $product = $null;
  
    if ($doConversion) {
      $converter = $passThru['XATCH.CONVERT.CONVERTER'];
      $converter.Invoke($sourceFullName, $destinationAudioFullname, $toFormat);
    }

    if (Test-Path -Path $destinationAudioFilename) {
      [System.IO.FileInfo]$destinationInfo = Get-Item -Path $destinationAudioFilename;
      # doConversion being used as an affirmation
      #
      $properties += , @('Size', $destinationInfo.Length, $doConversion);
      $product = $destinationInfo;
    }
    else {
      $properties += , @('Size', '?');
      $product = $destinationAudioFilename;
    }

    [PSCustomObject]$result = [PSCustomObject]@{ Product = $product; Trigger = $doConversion };
    if ($properties.Length -gt 0) {
      $result.Pairs = $properties;
    }

    $result;
  } # doAudioFileConversion

  [scriptblock]$script:onSourceDirectory = {
    param(
      [Parameter(Mandatory)]
      [Alias('underscore')]
      [System.IO.DirectoryInfo]$_sourceDirectory,

      [Parameter(Mandatory)]
      [int]$_index,

      [Parameter(Mandatory)]
      [System.Collections.Hashtable]$_passThru,

      [Parameter(Mandatory)]
      [boolean]$_trigger
    )

    [string]$fromFormat = $_passThru['XATCH.CONVERT.FROM'];
    [string]$filter = "*.{0}" -f $fromFormat;

    # Set up a separate passThru? and another decorator?
    #
    # $foreachPassThru = $passThru.Clone();

    Get-ChildItem -Path $_sourceDirectory.FullName -File -Filter $filter | `
      Invoke-ForeachFsItem -File -Block $doAudioFileConversion -PassThru $_passThru;

    $destinationInfo = $_passThru['LOOPZ.MIRROR.DESTINATION'];
    @{ Product = $destinationInfo }
  } # onSourceDirectory

  [scriptblock]$getResult = {
    param($result)

    $result.GetType() -in @([System.IO.FileInfo], [System.IO.DirectoryInfo]) ? $result.Name : $result;
  }

  $PassThru['LOOPZ.WH-FOREACH-DECORATOR.BLOCK'] = $onSourceDirectory;
  $PassThru['LOOPZ.WH-FOREACH-DECORATOR.MESSAGE'] = 'Audio Directory';
  $PassThru['LOOPZ.WH-FOREACH-DECORATOR.GET-RESULT'] = $getResult;
  $PassThru['XATCH.CONVERT.ROOT-SOURCE'] = $Source;
  $PassThru['XATCH.CONVERT.ROOT-DESTINATION'] = $Destination;
  $PassThru['XATCH.CONVERT.FROM'] = $From;
  $PassThru['XATCH.CONVERT.TO'] = $To;
  $PassThru['LOOPZ.SUMMARY-BLOCK.LINE'] = $LoopzUI.EqualsLine;
  $PassThru['LOOPZ.SUMMARY-BLOCK.MESSAGE'] = 'Directories Summary';

  if ($Concise.ToBool()) {
    $PassThru['LOOPZ.WH-FOREACH-DECORATOR.IF-TRIGGERED'] = $true;
  }

  Invoke-MirrorDirectoryTree -Path $Source `
    -DestinationPath $Destination -CreateDirs -CopyFiles -FileIncludes $CopyFiles -FileExcludes @($From, $To) `
    -Block $LoopzHelpers.WhItemDecoratorBlock -PassThru $PassThru `
    -Summary $LoopzHelpers.SimpleSummaryBlock -WhatIf:$whatIf;
}
