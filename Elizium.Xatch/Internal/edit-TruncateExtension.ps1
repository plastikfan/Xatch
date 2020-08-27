
# This method required because System.IO.Path.GetFileNameWithoutExtension does not seem to be available on macPS.
#
function edit-TruncateExtension {
  param
  (
    [String]$Path
  )

  $result = [String]::Empty;
  $index = $Path.LastIndexOf(".");

  if ($index -ge 0) {
    
    $result = $Path.Substring(0, $index);
  }

  return $result;
}
