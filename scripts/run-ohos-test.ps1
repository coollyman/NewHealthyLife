param(
  [string]$Device = "",
  [string]$BundleName = "com.example.newhealthylife",
  [string]$ModuleName = "entry_test",
  [string]$TestRunner = "OpenHarmonyTestRunner",
  [int]$WaitSeconds = 180,
  [switch]$SkipBuild,
  [switch]$SkipInstall,
  [switch]$TailLogs
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$Hdc = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
$MainHap = Join-Path $ProjectRoot "entry\build\default\outputs\default\entry-default-signed.hap"
$TestHap = Join-Path $ProjectRoot "entry\build\default\outputs\ohosTest\entry-ohosTest-signed.hap"

if (!(Test-Path $Hdc)) {
  throw "hdc not found at fixed path: $Hdc"
}

Push-Location $ProjectRoot
try {
  if (!$SkipBuild) {
    devecocli build
    devecocli build --modules entry@ohosTest
  }

  if ([string]::IsNullOrWhiteSpace($Device)) {
    $devices = & $Hdc list targets | Where-Object { $_ -and ($_ -notmatch "^\[") -and ($_ -notmatch "Empty") }
    $serials = @($devices | ForEach-Object { ($_ -split "\s+")[0] } | Where-Object { $_ })
    if ($serials.Count -ne 1) {
      throw "Expected exactly one connected device. Found $($serials.Count). Pass -Device <serial>."
    }
    $Device = $serials[0]
  }

  if (!$SkipInstall) {
    if (!(Test-Path $MainHap)) {
      throw "Main HAP not found: $MainHap"
    }
    if (!(Test-Path $TestHap)) {
      throw "ohosTest HAP not found: $TestHap"
    }
    & $Hdc -t $Device install -r $MainHap
    & $Hdc -t $Device install -r $TestHap
  }

  & $Hdc -t $Device shell hilog -r | Out-Null
  $testOutput = & $Hdc -t $Device shell aa test -b $BundleName -m $ModuleName -s unittest $TestRunner -w $WaitSeconds 2>&1
  $testOutput | ForEach-Object { Write-Output $_ }

  $resultLine = $testOutput | Where-Object { $_ -match "OHOS_REPORT_RESULT: stream=Tests run:" } | Select-Object -Last 1
  if (!$resultLine) {
    throw "Unable to find OHOS_REPORT_RESULT in aa test output."
  }

  if ($resultLine -match "Failure:\s*(\d+),\s*Error:\s*(\d+)") {
    $failureCount = [int]$Matches[1]
    $errorCount = [int]$Matches[2]
    if ($failureCount -ne 0 -or $errorCount -ne 0) {
      throw "ohosTest failed: $resultLine"
    }
  } else {
    throw "Unable to parse ohosTest result line: $resultLine"
  }

  if ($TailLogs) {
    & $Hdc -t $Device shell hilog -x -T DeviceIntegrationTest
  }
}
finally {
  Pop-Location
}
