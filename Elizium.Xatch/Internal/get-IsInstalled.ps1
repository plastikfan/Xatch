
function get-IsInstalled {
  [OutputType([boolean])]
  param(
    [Parameter()]
    [ValidateScript( { -not([string]::IsNullOrWhiteSpace($_)) })]
    [string]$Name
  )
  [boolean]$result = $true;

  try {
    $command = Get-Command -Name $Name -ShowCommandInfo -ErrorAction SilentlyContinue;

    if ($command -and ($command.CommandType -ne 'Application')) {
      $result = $false;
    }
  }
  catch {
    $result = $false;
  }
  $result;
}
