
$script:AudioFormats = @('wav', 'aif', 'raw_big', 'raw_little', 'mp3', 'aac', 'flac', 'alac', 'vorbis', 'wavpack', 'opus');

function Convert-Audio {
  <#
.SEE
  https://tmkk.undo.jp/xld/index_e.html

.NAME
  Convert-Audio

.SYNOPSIS
  The entry point into the converter
.PARAMETER Source
  The root of the source tree containing audio to convert. (Must exist)

.PARAMETER Destination
  The root of the destination tree contain where output audio will be written to. This does not
  have to exist prior to running. The source tree is mirrored here in the destination tree.

.PARAMETER From
  The audio format from which to convert. See xld help for supported formats. Only the files
  that match this format will be converted.

.PARAMETER To
  The audio format to convert to. See xld help for supported formats.

.PARAMETER CopyFiles
  Denotes which other files to copy over from the source tree to the destination expressed as a
  csv of file suffixes. The copied files will not include any files whose suffix match either
  $from or $to, in order to avoid the potential for name clashes. This is really meant for
  auxiliary files like cover art jpg images and text files, or any other such meta data. The
  default is '*' meaning that all files are copied over subject to the caveats just mentioned.

.PARAMETER Skip
  Skip existing audio file version if it already exists in the destination. This makes the script
  re-runnable if for any reason, a previous run had to be aborted; leaving the destination tree
  incomplete.
#>
  [CmdletBinding(SupportsShouldProcess)]
  [Alias('cva')]
  param
  (
    [parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path -Path $_ } )]
    [String]$Source,

    [parameter(Mandatory = $true)]
    [String]$Destination,

    [parameter(Mandatory = $true)]
    [ValidateSet(
      'wav', 'aif', 'raw_big', 'raw_little', 'mp3', 'aac', 'flac', 'alac', 'vorbis', 'wavpack', 'opus'
    )]
    [String]$From,

    [parameter(Mandatory = $true)]
    [ValidateSet(
      'wav', 'aif', 'raw_big', 'raw_little', 'mp3', 'aac', 'flac', 'alac', 'vorbis', 'wavpack', 'opus'
    )]
    [String]$To,

    [parameter()]
    [String[]]$CopyFiles = @('jpg', 'jpeg', 'txt'),

    [Switch]$Skip,

    [parameter()]
    [scriptblock]$Converter
  )

  if ( !(Test-Path -Path $Destination -PathType Container) ) {
    if ($PSBoundParameters.ContainsKey('WhatIf') -and ($PSBoundParameters['WhatIf'])) {
      # WhatIf setting is inherited from the top command. If it is enabled on Convert-Audio
      # then invoking child commands like New-Item below will also run with it enabled.
      # However, the WhatIf inheritance does not apply to commands defined in another
      # module, which is why it's appropriate to pass in WHAT-IF in the Exchange to relay
      # this into commands inside Loopz.
      #
      Write-Host "Destination Path: '$Destination'"
      Write-Host "Cannot continue with WhatIf enabled, if Destination path doesn't already exist" -ForegroundColor 'Yellow';
      Write-Host "Either, rerun without WhatIf or create the destination then re-run with WhatIf" -ForegroundColor 'Yellow';

      return;
    }
    $null = New-Item -Path $Destination -ItemType 'Directory';
  }

  [System.Collections.Hashtable]$generalTheme = Get-KrayolaTheme;
  [System.Collections.Hashtable]$exchange = @{
    'LOOPZ.KRAYOLA-THEME'     = $generalTheme;
    'LOOPZ.SIGNALS'           = $(Get-Signals)
  };

  [System.Collections.Hashtable]$innerTheme = $generalTheme.Clone();
  $innerTheme['FORMAT'] = '"<%KEY%>" -> "<%VALUE%>"';
  $innerTheme['MESSAGE-SUFFIX'] = ' | ';
  $innerTheme['MESSAGE-COLOURS'] = @('Green');
  $innerTheme['META-COLOURS'] = @('DarkMagenta');
  $innerTheme['VALUE-COLOURS'] = @('Blue');
  $innerTheme['AFFIRM-COLOURS'] = @('Red');
  $innerTheme['OPEN'] = '(';
  $innerTheme['CLOSE'] = ')';

  $exchange['XATCH.INNER-KRAYOLA-THEME'] = $innerTheme;

  if ($PSBoundParameters.ContainsKey('WhatIf') -and $PSBoundParameters['WhatIf'].ToBool()) {
    $exchange['WHAT-IF'] = $true;
  }

  if (-not($Converter)) {
    $Converter = get-Converter -Exchange $exchange
  }

  $exchange['XATCH.CONVERT.CONVERTER'] = $Converter;

  $null = invoke-ConversionBatch -Source $Source -Destination $Destination `
    -From $From -To $To -CopyFiles $CopyFiles -Exchange $exchange -Skip:$Skip;
}
