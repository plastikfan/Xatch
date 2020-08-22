
$global:XatchXld = @{
  Converter = [scriptblock] {
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

    Invoke-Expression -Command $command;
  }
}
