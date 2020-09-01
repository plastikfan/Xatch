
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

  [scriptblock]$getResult = {
    param($result)

    $result.GetType() -in @([System.IO.FileInfo], [System.IO.DirectoryInfo]) ? $result.Name : $result;
  }
  
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

    [boolean]$skipped = $false;
    [boolean]$overwrite = $false;
    [string]$indicator = '➖';
    [string]$state = 'Conversion Ok';
    [boolean]$whatIf = $passThru.ContainsKey('WHAT-IF') -and $passThru['WHAT-IF'];

    if (Test-Path -Path $destinationAudioFilename) {
      if ($skipExisting) {
        $skipped = $true;
      }
      else {
        $overwrite = $true;
      }
    }

    [string[][]]$properties = @();
    $product = $null;

    if (-not($skipped)) {
      try {
        [scriptblock]$converter = $passThru['XATCH.CONVERT.CONVERTER'];
        $invokeResult = $converter.Invoke($sourceFullName, $destinationAudioFullname, $toFormat);

        if ($invokeResult[0] -eq 0) {
          if ($passThru.ContainsKey('XATCH.CONVERTER.DUMMY')) {
            $indicator = '🔶';
            $state = 'Dummy Ok';
          }
          elseif ($passThru.ContainsKey('XATCH.CONVERTER.ENV')) {
            $state = 'ENV Conversion Ok'
            $indicator = $whatIf ? '💠' : ($overwrite ? '💎' : '☑️');
            if ($whatIf) {
              $state = 'ENV WhatIf';
            }
            elseif ($overwrite) {
              $state = 'ENV Overwrite Ok';
            }
          }
          else {
            $indicator = $whatIf ? '✳️' : ($overwrite ? '♻️' : '✔️');
            if ($whatIf) {
              $state = 'WhatIf';
            }
            elseif ($overwrite) {
              $state = 'Overwrite Ok';
            }
          }
        }
        else {
          $indicator = '❌';
          $state = 'Conversion Failed';
        }
      } catch {
        $indicator = '❌';
        $state = 'Conversion Failed';
      }
    }
    else {
      $indicator = '🔆';
      $state = 'Conversion Skipped';
    }

    $passThru['LOOPZ.WH-FOREACH-DECORATOR.MESSAGE'] = "   [{0}] {1}" -f $indicator, $state;

    if (Test-Path -Path $destinationAudioFilename) {
      [System.IO.FileInfo]$destinationInfo = Get-Item -Path $destinationAudioFilename;
      # -not($skipped) being used as an affirmation
      #
      $properties += , @('Size', $destinationInfo.Length, -not($skipped));
      $product = $destinationInfo;
    }
    else {
      $properties += , @('Size', '???');
      $product = $destinationAudioFilename;
    }

    [PSCustomObject]$result = [PSCustomObject]@{ Product = $product; Trigger = -not($skipped) };
    if ($properties.Length -gt 0) {
      # Since result is a PSCustomObject as opposed to hash-table, we can't simply assign
      # a value to a non-existing property; need to use Add-Member instead.
      # NoteProperty ('A property defined by a Name-Value pair') is an enum type: PSMemberTypes
      #
      $result | Add-Member -MemberType NoteProperty -Name 'Pairs' -Value (, $properties);
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

    [System.Collections.Hashtable]$foreachAudioFilePassThru = $_passThru.Clone();
    $destinationInfo = $_passThru['LOOPZ.MIRROR.DESTINATION'];

    $foreachAudioFilePassThru['LOOPZ.WH-FOREACH-DECORATOR.BLOCK'] = $doAudioFileConversion;
    $foreachAudioFilePassThru['LOOPZ.WH-FOREACH-DECORATOR.MESSAGE'] = '   [➖] Converted file';
    $foreachAudioFilePassThru['LOOPZ.WH-FOREACH-DECORATOR.GET-RESULT'] = $getResult;
    $foreachAudioFilePassThru['LOOPZ.WH-FOREACH-DECORATOR.PRODUCT-LABEL'] = 'To';

    $foreachAudioFilePassThru['LOOPZ.HEADER-BLOCK.CRUMB'] = '[🎯] ';
    $foreachAudioFilePassThru['LOOPZ.HEADER-BLOCK.LINE'] = $LoopzUI.SmallUnderscoreLine;
    $destinationBranch = $foreachAudioFilePassThru['LOOPZ.MIRROR.BRANCH-DESTINATION'];
    [string]$directorySeparator = [System.IO.Path]::DirectorySeparatorChar;
    $foreachAudioFilePassThru['LOOPZ.HEADER-BLOCK.MESSAGE'] = "...$($directorySeparator)$($destinationBranch)";

    $foreachAudioFilePassThru['LOOPZ.SUMMARY-BLOCK.LINE'] = $LoopzUI.SmallUnderscoreLine;
    $foreachAudioFilePassThru['LOOPZ.SUMMARY-BLOCK.MESSAGE'] = "   [🎶] Conversion Summary ($($destinationInfo.Name))";

    $foreachAudioFilePassThru.Remove('LOOPZ.FOREACH.INDEX');
    $foreachAudioFilePassThru.Remove('LOOPZ.SUMMARY-BLOCK.WIDE-ITEMS');

    [System.Collections.Hashtable]$innerTheme = $foreachAudioFilePassThru['XATCH.INNER-KRAYOLA-THEME'];

    if ($innerTheme) {
      $foreachAudioFilePassThru['LOOPZ.KRAYOLA-THEME'] = $innerTheme;
    }

    Get-ChildItem -Path $_sourceDirectory.FullName -File -Filter $filter | `
      Invoke-ForeachFsItem -File -Block $LoopzHelpers.WhItemDecoratorBlock -PassThru $foreachAudioFilePassThru `
      -Header $LoopzHelpers.DefaultHeaderBlock -Summary $LoopzHelpers.SimpleSummaryBlock;

    [PSCustomObject]$result = [PSCustomObject]@{
      Product = $destinationInfo;
    }

    if ($foreachAudioFilePassThru.ContainsKey('LOOPZ.FOREACH.COUNT') -and ($foreachAudioFilePassThru['LOOPZ.FOREACH.COUNT'] -gt 0)) {
      $result | Add-Member -MemberType NoteProperty -Name 'Affirm' -Value $true;
      $result | Add-Member -MemberType NoteProperty -Name 'Trigger' -Value $true;
    }
    
    $result;
  } # onSourceDirectory

  $PassThru['LOOPZ.WH-FOREACH-DECORATOR.BLOCK'] = $onSourceDirectory;
  $PassThru['LOOPZ.WH-FOREACH-DECORATOR.MESSAGE'] = '   [📁] Audio Directory';
  $PassThru['LOOPZ.WH-FOREACH-DECORATOR.GET-RESULT'] = $getResult;
  $PassThru['LOOPZ.WH-FOREACH-DECORATOR.PRODUCT-LABEL'] = 'Album';

  $PassThru['XATCH.CONVERT.FROM'] = $From;
  $PassThru['XATCH.CONVERT.TO'] = $To;

  $PassThru['LOOPZ.HEADER-BLOCK.CRUMB'] = '[🧿] ';
  $PassThru['LOOPZ.HEADER-BLOCK.LINE'] = $LoopzUI.EqualsLine;
  $PassThru['LOOPZ.HEADER-BLOCK.MESSAGE'] = "Convert from '$From' to '$To'";

  $PassThru['LOOPZ.SUMMARY-BLOCK.LINE'] = $LoopzUI.EqualsLine;
  $PassThru['LOOPZ.SUMMARY-BLOCK.MESSAGE'] = '[🧿] Directories Summary';
  $PassThru['LOOPZ.SUMMARY-BLOCK.WIDE-ITEMS'] = @(
    @('   [📁] Source', $(Convert-Path -Path $Source)),
    @('   [📁] Destination', $(Convert-Path -Path $Destination))
  );

  $PassThru['LOOPZ.SUMMARY-BLOCK.PROPERTIES'] = @(@('From', $From), @('To', $To));

  if ($Concise.ToBool()) {
    $PassThru['LOOPZ.WH-FOREACH-DECORATOR.IF-TRIGGERED'] = $true;
  }

  [boolean]$whatIf = $PassThru.ContainsKey('WHAT-IF') -and $PassThru['WHAT-IF'];

  $null = Invoke-MirrorDirectoryTree -Path $Source -DestinationPath $Destination `
    -CreateDirs -CopyFiles -FileIncludes $CopyFiles -FileExcludes @($From, $To) `
    -Block $LoopzHelpers.WhItemDecoratorBlock -PassThru $PassThru `
    -Header $LoopzHelpers.DefaultHeaderBlock -Summary $LoopzHelpers.SimpleSummaryBlock -WhatIf:$whatIf;
}
