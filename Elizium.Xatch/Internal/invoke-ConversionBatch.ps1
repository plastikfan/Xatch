
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
    [System.Collections.Hashtable]$Exchange = @{},

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
      [System.Collections.Hashtable]$exchange,

      [Parameter(Mandatory)]
      [boolean]$trigger
    )

    [string]$sourceName = $underscore.Name;
    [string]$sourceFullName = $underscore.FullName;
    [string]$toFormat = $exchange['XATCH.CONVERT.TO'];
    [System.IO.DirectoryInfo]$destinationInfo = $exchange['LOOPZ.MIRROR.DESTINATION'];
    [string]$destinationAudioFilename = ((edit-TruncateExtension -path $sourceName) + '.' + $toFormat);
    [string]$destinationAudioFullname = Join-Path -Path $destinationInfo.FullName `
      -ChildPath $destinationAudioFilename;

    [boolean]$skipped = $false;
    [boolean]$overwrite = $false;
    [string]$indicatorSignal = 'BAD-A';
    [string]$signalLabel = 'Conversion Ok';
    [boolean]$whatIf = $exchange.ContainsKey('WHAT-IF') -and $exchange['WHAT-IF'];

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
        [scriptblock]$converter = $exchange['XATCH.CONVERT.CONVERTER'];
        $invokeResult = $converter.Invoke($sourceFullName, $destinationAudioFullname, $toFormat);

        if ($invokeResult[0] -eq 0) {
          if ($exchange.ContainsKey('XATCH.CONVERTER.DUMMY')) {
            $indicatorSignal = $whatIf ? 'WHAT-IF' : ($overwrite ? 'OVERWRITE-A' : 'OK-B');
            $signalLabel = 'Dummy Ok';
          }
          elseif ($exchange.ContainsKey('XATCH.CONVERTER.ENV')) {
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
    [System.Collections.Hashtable]$signals = $exchange['LOOPZ.SIGNALS'];
    [string]$formattedSignal = Get-FormattedSignal -Name $indicatorSignal `
      -Signals $signals -CustomLabel $signalLabel -Format "   [{0}] {1}";

    $exchange['LOOPZ.WH-FOREACH-DECORATOR.MESSAGE'] = $formattedSignal;

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
      [System.Collections.Hashtable]$_exchange,

      [Parameter(Mandatory)]
      [boolean]$_trigger
    )

    [string]$fromFormat = $_exchange['XATCH.CONVERT.FROM'];
    [string]$toFormat = $_exchange['XATCH.CONVERT.TO'];
    [string]$filter = "*.{0}" -f $fromFormat;

    [System.Collections.Hashtable]$foreachAudioFileExchange = $_exchange.Clone();
    $destinationInfo = $_exchange['LOOPZ.MIRROR.DESTINATION'];

    $foreachAudioFileExchange['LOOPZ.WH-FOREACH-DECORATOR.BLOCK'] = $doAudioFileConversion;
    $foreachAudioFileExchange['LOOPZ.WH-FOREACH-DECORATOR.GET-RESULT'] = $getResult;
    $foreachAudioFileExchange['LOOPZ.WH-FOREACH-DECORATOR.PRODUCT-LABEL'] = 'To';

    $foreachAudioFileExchange['LOOPZ.HEADER-BLOCK.LINE'] = $LoopzUI.SmallUnderscoreLine;
    [string]$destinationBranch = $foreachAudioFileExchange['LOOPZ.MIRROR.BRANCH-DESTINATION'];

    [string]$directorySeparator = [System.IO.Path]::DirectorySeparatorChar;
    $destinationBranch = $destinationBranch.StartsWith($directorySeparator) `
      ? "...$($destinationBranch)" `
      : "...$($directorySeparator)$($destinationBranch)";

    $foreachAudioFileExchange['LOOPZ.SUMMARY-BLOCK.LINE'] = $LoopzUI.SmallUnderscoreLine;
    $foreachAudioFileExchange.Remove('LOOPZ.FOREACH.INDEX');
    $foreachAudioFileExchange.Remove('LOOPZ.SUMMARY-BLOCK.WIDE-ITEMS');

    [System.Collections.Hashtable]$innerTheme = $foreachAudioFileExchange['XATCH.INNER-KRAYOLA-THEME'];

    if ($innerTheme) {
      $foreachAudioFileExchange['LOOPZ.KRAYOLA-THEME'] = $innerTheme;
    }

    [PSCustomObject]$containers = @{
      Wide = [string[][]]@();
    }

    Select-SignalContainer -Containers $containers -Name 'SOURCE' -Signals $signals `
      -Value $($_sourceDirectory.FullName) -CustomLabel 'Source' -Force 'Wide';

    Select-SignalContainer -Containers $containers -Name 'DESTINATION' -Signals $signals `
      -Value $($destinationInfo.FullName) -CustomLabel 'Destination' -Force 'Wide'; # $destinationBranch

    if ($foreachAudioFileExchange.ContainsKey('LOOPZ.MIRROR.COPIED-FILES.COUNT')) {
      [int]$filesCount = $foreachAudioFileExchange['LOOPZ.MIRROR.COPIED-FILES.COUNT'];

      if ($filesCount -gt 0) {
        Select-SignalContainer -Containers $containers -Name 'COPY-B' -Signals $signals `
          -Value $foreachAudioFileExchange['LOOPZ.MIRROR.COPIED-FILES.COUNT'] `
          -CustomLabel 'Copied' -Force 'Wide';

        if ($foreachAudioFileExchange.ContainsKey('LOOPZ.MIRROR.COPIED-FILES.INCLUDES')) {
          Select-SignalContainer -Containers $containers -Name 'INCLUDE' -Signals $signals `
            -Value $foreachAudioFileExchange['LOOPZ.MIRROR.COPIED-FILES.INCLUDES'] `
            -CustomLabel 'Copied File Types' -Force 'Wide';
        }
      }
    }

    $_exchange['LOOPZ.SUMMARY-BLOCK.WIDE-ITEMS'] = $containers.Wide;
    $_exchange['LOOPZ.HEADER-BLOCK.MESSAGE'] = `
      "( $($destinationBranch) ) '$fromFormat' >>> '$toFormat'";

    Get-ChildItem -Path $_sourceDirectory.FullName -File -Filter $filter | `
      Invoke-ForeachFsItem -File -Block $LoopzHelpers.WhItemDecoratorBlock -Exchange $foreachAudioFileExchange `
      -Header $LoopzHelpers.DefaultHeaderBlock -Summary $LoopzHelpers.SimpleSummaryBlock;

    [PSCustomObject]$result = [PSCustomObject]@{
      Product = $destinationInfo;
    }

    if ($foreachAudioFileExchange.ContainsKey('LOOPZ.FOREACH.COUNT') -and
      ($foreachAudioFileExchange['LOOPZ.FOREACH.COUNT'] -gt 0)) {
      $result | Add-Member -MemberType NoteProperty -Name 'Affirm' -Value $true;
      $result | Add-Member -MemberType NoteProperty -Name 'Trigger' -Value $true;
    }
    
    $result;
  } # onSourceDirectory

  [System.Collections.Hashtable]$signals = $Exchange['LOOPZ.SIGNALS'];
  [string]$signalName = 'AUDIO';
  [string]$message = Get-FormattedSignal -Name $signalName `
    -Signals $signals -CustomLabel 'Audio Directory' -Format '   [{1}] {0}';

  [string]$directoriesSummary = Get-FormattedSignal -Name 'SUMMARY-A' `
    -Signals $signals -CustomLabel 'Conversion Summary';

  $Exchange['LOOPZ.WH-FOREACH-DECORATOR.BLOCK'] = $onSourceDirectory;
  $Exchange['LOOPZ.WH-FOREACH-DECORATOR.MESSAGE'] = $message;
  $Exchange['LOOPZ.WH-FOREACH-DECORATOR.GET-RESULT'] = $getResult;
  $Exchange['LOOPZ.WH-FOREACH-DECORATOR.PRODUCT-LABEL'] = 'Album';

  $Exchange['XATCH.CONVERT.FROM'] = $From;
  $Exchange['XATCH.CONVERT.TO'] = $To;

  $Exchange['LOOPZ.HEADER-BLOCK.CRUMB-SIGNAL'] = 'CRUMB-C';
  $Exchange['LOOPZ.HEADER-BLOCK.LINE'] = $LoopzUI.EqualsLine;

  $Exchange['LOOPZ.SUMMARY-BLOCK.LINE'] = $LoopzUI.EqualsLine;
  $Exchange['LOOPZ.SUMMARY-BLOCK.MESSAGE'] = $directoriesSummary;
  $Exchange['LOOPZ.SUMMARY-BLOCK.PROPERTIES'] = @(@('From', $From), @('To', $To));

  if ($Concise.ToBool()) {
    $Exchange['LOOPZ.WH-FOREACH-DECORATOR.IF-TRIGGERED'] = $true;
  }

  [boolean]$whatIf = $Exchange.ContainsKey('WHAT-IF') -and $Exchange['WHAT-IF'];

  $null = Invoke-MirrorDirectoryTree -Path $Source -DestinationPath $Destination `
    -CreateDirs -CopyFiles -FileIncludes $CopyFiles -FileExcludes @($From, $To) `
    -Block $LoopzHelpers.WhItemDecoratorBlock -Exchange $Exchange `
    -Header $LoopzHelpers.HeaderBlock -Summary $LoopzHelpers.SummaryBlock -WhatIf:$whatIf;
}
