
function get-Converter {
  [OutputType([scriptblock])]
  param(
    [Parameter()]
    [System.Collections.Hashtable]$Exchange
  )
  [scriptblock]$block = $null;
  [boolean]$dummy = $false;

  $environmentConverter = get-EnvironmentVariable -Variable 'XATCH.CONVERTER';
  if ($environmentConverter -and ($environmentConverter -is [scriptblock])) {
    $block = $environmentConverter;
    $Exchange['XATCH.CONVERTER.ENV'] = $true;
  } else {
    if (get-IsInstalled -Name 'xld') {
      $block = $XatchXld.Converter;
    } else {
      $block = $XatchXld.DummyConverter;
      $dummy = $true;
    }
  }

  if ($exchange.ContainsKey('WHAT-IF')) {
    $block = $XatchXld.DummyConverter;
    $dummy = $true;
  }

  if ($dummy) {
    $Exchange['XATCH.CONVERTER.DUMMY'] = $true;
  }

  $block;
}
