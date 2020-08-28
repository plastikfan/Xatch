
function get-Converter {
  [OutputType([scriptblock])]
  param(
    [System.Collections.Hashtable]$PassThru
  )
  [scriptblock]$block = $null;

  $environmentConverter = [System.Environment]::GetEnvironmentVariable('XATCH.CONVERTER');
  if ($environmentConverter -and ($environmentConverter -is [scriptblock])) {
    $block = $environmentConverter;
  } else {
    $block = get-IsInstalled 'xld' ? $XatchXld.Converter : $XatchXld.DummyConverter;
  }

  if ($passThru.ContainsKey('WHAT-IF')) {
    $block = $XatchXld.DummyConverter;
  }

  $block;
}
