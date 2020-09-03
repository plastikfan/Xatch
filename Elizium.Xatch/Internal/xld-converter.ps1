
$global:XatchXld = @{
  Converter      = [scriptblock] {
    param(
      [Parameter(Mandatory)]
      [string]$sourceFullName,

      [Parameter(Mandatory)]
      [string]$destinationAudioFilename,

      [Parameter(Mandatory)]
      [string]$toFormat
    )

    # https://www.tecmint.com/manage-linux-filenames-with-special-characters/
    # 02 - Olympic '93 (The Word mix).mp3
    #
    [string]$command = [string]::Empty;

    if ($sourceFullName.Contains("'")) {
      $command = ('xld -f "{0}" -o "{1}" "{2}"' `
          -f $toFormat, $destinationAudioFilename, $sourceFullName)
    }
    else {
      $command = ("xld -f '{0}' -o '{1}' '{2}'" `
          -f $toFormat, $destinationAudioFilename, $sourceFullName);
    }

    Invoke-Expression -Command $command;

    [int]$result = (Test-Path -Path $destinationAudioFilename) ? 0 : 1;
    Write-Debug "[*] XLD CONVERTER; running command: $command, result: $result";
    $result;
  }

  DummyConverter = [scriptblock] {
    param(
      [Parameter(Mandatory)]
      [string]$sourceFullName,

      [Parameter(Mandatory)]
      [string]$destinationAudioFilename,

      [Parameter(Mandatory)]
      [string]$toFormat
    )
    0;
  }
}
