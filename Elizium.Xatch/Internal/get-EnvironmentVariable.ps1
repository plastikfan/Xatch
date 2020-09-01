
function get-EnvironmentVariable {
  param(
    [Parameter()]
    [string]$Variable 
  )

  [System.Environment]::GetEnvironmentVariable($Variable);
}
