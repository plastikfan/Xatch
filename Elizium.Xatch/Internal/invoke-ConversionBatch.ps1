
function invoke-ConversionBatch {
  [CmdletBinding()]
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
    [System.IO.DirectoryInfo]$destinationInfo = $passThru['LOOPZ.MIRROR.DESTINATION'];
    [string]$destinationAudioFilename = ((edit-TruncateExtension -path $sourceName) + '.' + $toFormat);
    [string]$destinationAudioFullname = Join-Path -Path $destinationInfo.FullName `
      -ChildPath $destinationAudioFilename;

    [boolean]$skipped = $false;
    [boolean]$overwrite = $false;
    [string]$indicatorSignal = 'BAD-A';
    [string]$signalLabel = 'Conversion Ok';
    [boolean]$whatIf = $passThru.ContainsKey('WHAT-IF') -and $passThru['WHAT-IF'];

    if (Test-Path -Path $destinationAudioFullname) {
      if ($Skip.ToBool()) {
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
            $indicatorSignal = $whatIf ? 'WHAT-IF' : ($overwrite ? 'OVERWRITE-A' : 'OK-B');
            $signalLabel = 'Dummy Ok';
          }
          elseif ($passThru.ContainsKey('XATCH.CONVERTER.ENV')) {
            $signalLabel = 'ENV Conversion Ok'
            $indicatorSignal = $overwrite ? 'OVERWRITE-C' : 'OK-A';
            if ($whatIf) {
              $signalLabel = 'ENV WhatIf';
            }
            elseif ($overwrite) {
              $signalLabel = 'ENV Overwrite Ok';
            }
          }
          else {
            $indicatorSignal = $overwrite ? 'OVERWRITE-B' : 'OK-C';
            if ($whatIf) {
              $signalLabel = 'WhatIf';
            }
            elseif ($overwrite) {
              $signalLabel = 'Overwrite Ok';
            }
          }
        }
        else {
          $indicatorSignal = 'FAILED-A';
          $signalLabel = 'Conversion Failed';
        }
      }
      catch {
        $indicatorSignal = 'FAILED-B';
        $signalLabel = 'Exception';
      }
    }
    else {
      $indicatorSignal = 'SKIPPED-A';
      $signalLabel = 'Conversion Skipped';
    }
    [System.Collections.Hashtable]$signals = $passThru['LOOPZ.SIGNALS'];
    [string]$formattedSignal = Get-FormattedSignal -Name $indicatorSignal `
      -Signals $signals -CustomLabel $signalLabel -Format "   [{0}] {1}";

    $passThru['LOOPZ.WH-FOREACH-DECORATOR.MESSAGE'] = $formattedSignal;

    if (Test-Path -Path $destinationAudioFullname) {
      [System.IO.FileInfo]$destinationInfo = Get-Item -Path $destinationAudioFullname;
      # -not($skipped) being used as an affirmation
      #
      [string]$size = "{0:#.##}" -f ($destinationInfo.Length / 1000000);
      $properties += , @('Size (MB)', $size, -not($skipped));
      $product = $destinationInfo;
    }
    else {
      $properties += , @('Size', '0?');
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
    [string]$toFormat = $_passThru['XATCH.CONVERT.TO'];
    [string]$filter = "*.{0}" -f $fromFormat;

    [System.Collections.Hashtable]$foreachAudioFilePassThru = $_passThru.Clone();
    $destinationInfo = $_passThru['LOOPZ.MIRROR.DESTINATION'];

    $foreachAudioFilePassThru['LOOPZ.WH-FOREACH-DECORATOR.BLOCK'] = $doAudioFileConversion;
    $foreachAudioFilePassThru['LOOPZ.WH-FOREACH-DECORATOR.GET-RESULT'] = $getResult;
    $foreachAudioFilePassThru['LOOPZ.WH-FOREACH-DECORATOR.PRODUCT-LABEL'] = 'To';

    $foreachAudioFilePassThru['LOOPZ.HEADER-BLOCK.LINE'] = $LoopzUI.SmallUnderscoreLine;
    [string]$destinationBranch = $foreachAudioFilePassThru['LOOPZ.MIRROR.BRANCH-DESTINATION'];

    [string]$directorySeparator = [System.IO.Path]::DirectorySeparatorChar;
    $destinationBranch = $destinationBranch.StartsWith($directorySeparator) `
      ? "...$($destinationBranch)" `
      : "...$($directorySeparator)$($destinationBranch)";

    $foreachAudioFilePassThru['LOOPZ.SUMMARY-BLOCK.LINE'] = $LoopzUI.SmallUnderscoreLine;
    $foreachAudioFilePassThru.Remove('LOOPZ.FOREACH.INDEX');
    $foreachAudioFilePassThru.Remove('LOOPZ.SUMMARY-BLOCK.WIDE-ITEMS');

    [System.Collections.Hashtable]$innerTheme = $foreachAudioFilePassThru['XATCH.INNER-KRAYOLA-THEME'];

    if ($innerTheme) {
      $foreachAudioFilePassThru['LOOPZ.KRAYOLA-THEME'] = $innerTheme;
    }

    [PSCustomObject]$containers = @{
      Wide = [string[][]]@();
    }

    Select-SignalContainer -Containers $containers -Name 'SOURCE' -Signals $signals `
      -Value $($_sourceDirectory.FullName) -CustomLabel 'Source' -Force 'Wide';

    Select-SignalContainer -Containers $containers -Name 'DESTINATION' -Signals $signals `
      -Value $($destinationInfo.FullName) -CustomLabel 'Destination' -Force 'Wide'; # $destinationBranch

    if ($foreachAudioFilePassThru.ContainsKey('LOOPZ.MIRROR.COPIED-FILES.COUNT')) {
      [int]$filesCount = $foreachAudioFilePassThru['LOOPZ.MIRROR.COPIED-FILES.COUNT'];

      if ($filesCount -gt 0) {
        Select-SignalContainer -Containers $containers -Name 'COPY-B' -Signals $signals `
          -Value $foreachAudioFilePassThru['LOOPZ.MIRROR.COPIED-FILES.COUNT'] `
          -CustomLabel 'Copied' -Force 'Wide';

        if ($foreachAudioFilePassThru.ContainsKey('LOOPZ.MIRROR.COPIED-FILES.INCLUDES')) {
          Select-SignalContainer -Containers $containers -Name 'INCLUDE' -Signals $signals `
            -Value $foreachAudioFilePassThru['LOOPZ.MIRROR.COPIED-FILES.INCLUDES'] `
            -CustomLabel 'Copied File Types' -Force 'Wide';
        }
      }
    }

    $_passThru['LOOPZ.SUMMARY-BLOCK.WIDE-ITEMS'] = $containers.Wide;
    $_passThru['LOOPZ.HEADER-BLOCK.MESSAGE'] = `
      "( $($destinationBranch) ) '$fromFormat' >>> '$toFormat'";

    Get-ChildItem -Path $_sourceDirectory.FullName -File -Filter $filter | `
      Invoke-ForeachFsItem -File -Block $LoopzHelpers.WhItemDecoratorBlock -PassThru $foreachAudioFilePassThru `
      -Header $LoopzHelpers.DefaultHeaderBlock -Summary $LoopzHelpers.SimpleSummaryBlock;

    [PSCustomObject]$result = [PSCustomObject]@{
      Product = $destinationInfo;
    }

    if ($foreachAudioFilePassThru.ContainsKey('LOOPZ.FOREACH.COUNT') -and
      ($foreachAudioFilePassThru['LOOPZ.FOREACH.COUNT'] -gt 0)) {
      $result | Add-Member -MemberType NoteProperty -Name 'Affirm' -Value $true;
      $result | Add-Member -MemberType NoteProperty -Name 'Trigger' -Value $true;
    }
    
    $result;
  } # onSourceDirectory

  [System.Collections.Hashtable]$signals = $PassThru['LOOPZ.SIGNALS'];
  [string]$signalName = 'AUDIO';
  [string]$message = Get-FormattedSignal -Name $signalName `
    -Signals $signals -CustomLabel 'Audio Directory' -Format '   [{1}] {0}';

  [string]$directoriesSummary = Get-FormattedSignal -Name 'SUMMARY-A' `
    -Signals $signals -CustomLabel 'Conversion Summary';

  $PassThru['LOOPZ.WH-FOREACH-DECORATOR.BLOCK'] = $onSourceDirectory;
  $PassThru['LOOPZ.WH-FOREACH-DECORATOR.MESSAGE'] = $message;
  $PassThru['LOOPZ.WH-FOREACH-DECORATOR.GET-RESULT'] = $getResult;
  $PassThru['LOOPZ.WH-FOREACH-DECORATOR.PRODUCT-LABEL'] = 'Album';

  $PassThru['XATCH.CONVERT.FROM'] = $From;
  $PassThru['XATCH.CONVERT.TO'] = $To;

  $PassThru['LOOPZ.HEADER-BLOCK.CRUMB-SIGNAL'] = 'CRUMB-C';
  $PassThru['LOOPZ.HEADER-BLOCK.LINE'] = $LoopzUI.EqualsLine;

  $PassThru['LOOPZ.SUMMARY-BLOCK.LINE'] = $LoopzUI.EqualsLine;
  $PassThru['LOOPZ.SUMMARY-BLOCK.MESSAGE'] = $directoriesSummary;
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
