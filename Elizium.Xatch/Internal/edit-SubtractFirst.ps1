<#
.NAME
    Edit-SubtractFirst

.SYNOPSIS
    Given a target string, returns the result of removing a string from it
#>
function Edit-SubtractFirst {
  param
  (
    [String]$target,
    [String]$subtract
  )

  $result = $target;

  if (($subtract.Length -gt 0) -and ($target.Contains($subtract))) {
    $len = $subtract.Length;
    $foundAt = $target.IndexOf($subtract);

    if ($foundAt -eq 0) {
      $result = $target.Substring($len);
    } else {
      $result = $target.Substring(0, $foundAt);
      $result += $target.Substring($foundAt + $len);
    }
  }

  return $result;
}
