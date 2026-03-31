param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$BridgeArgs
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $scriptDir "studio-bridge.js"

& node $scriptPath @BridgeArgs
exit $LASTEXITCODE
