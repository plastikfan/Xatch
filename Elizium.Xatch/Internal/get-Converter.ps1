
function get-Converter {
  [OutputType([scriptblock])]
  param(
    [Parameter()]
    [System.Collections.Hashtable]$PassThru
  )
  [scriptblock]$block = $null;
  [boolean]$dummy = $false;

  $environmentConverter = [System.Environment]::GetEnvironmentVariable('XATCH.CONVERTER');
  if ($environmentConverter -and ($environmentConverter -is [scriptblock])) {
    $block = $environmentConverter;
  } else {
    $block = (get-IsInstalled -Name 'xld') ? $XatchXld.Converter : $XatchXld.DummyConverter;
  }

  if ($passThru.ContainsKey('WHAT-IF')) {
    $block = $XatchXld.DummyConverter;
    $dummy = $true;
  }

  if ($dummy) {
    $PassThru['XATCH.CONVERTER.DUMMY'] = $true;
  }

  $block;
}
