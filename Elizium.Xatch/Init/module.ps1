if ($Loopz -and $Loopz.Signals) {
  [System.Collections.Hashtable]$XatchSignals = @{
    'mac'     = @{
      'OK-C'        = @('🆗', '☑️')
      'OVERWRITE-C' = @('Overwrite', '🌀')
    };
    'default' = @{
      'OK-C'        = @('🆗', '☑️')
      'OVERWRITE-C' = @('Overwrite', '♨️')
    };
  }

  if ([System.Collections.Hashtable]$selectedSignals = Resolve-ByPlatform -Hash $XatchSignals) {
    $selectedSignals.GetEnumerator() | ForEach-Object {
      $Loopz.Signals[$_.Key] = $_.Value;
    }
  }
}
