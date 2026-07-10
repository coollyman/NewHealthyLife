param(
  [string]$Device = "",
  [string]$BundleName = "com.example.newhealthylife",
  [string]$OutputDir = "artifacts/ui-smoke",
  [switch]$SkipBuild,
  [switch]$SkipInstall,
  [switch]$FreshInstall
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$OutputPath = Join-Path $ProjectRoot $OutputDir

function Resolve-Hdc {
  $candidates = @()
  if ($env:DEVECO_SDK_HOME) {
    $candidates += (Join-Path $env:DEVECO_SDK_HOME "default\openharmony\toolchains\hdc.exe")
  }

  $localProperties = Join-Path $ProjectRoot "local.properties"
  if (Test-Path $localProperties) {
    $sdkLine = Get-Content $localProperties | Where-Object { $_ -match "^sdk\.dir=" } | Select-Object -First 1
    if ($sdkLine) {
      $sdkDir = ($sdkLine -replace "^sdk\.dir=", "") -replace "\\:", ":"
      $candidates += (Join-Path $sdkDir "default\openharmony\toolchains\hdc.exe")
    }
  }

  $pathHdc = Get-Command hdc.exe -ErrorAction SilentlyContinue
  if ($pathHdc) {
    $candidates += $pathHdc.Source
  }

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return (Resolve-Path $candidate).Path
    }
  }

  throw "hdc.exe not found. Set DEVECO_SDK_HOME or check local.properties sdk.dir."
}

function Invoke-Hdc {
  param([string[]]$HdcArgs)
  & $script:Hdc -t $script:Device @HdcArgs
  if ($LASTEXITCODE -ne 0) {
    throw "hdc failed: $($HdcArgs -join ' ')"
  }
}

function Resolve-Device {
  if (![string]::IsNullOrWhiteSpace($Device)) {
    return $Device
  }

  $devices = & $script:Hdc list targets | Where-Object { $_ -and ($_ -notmatch "^\[") -and ($_ -notmatch "Empty") }
  $serials = @($devices | ForEach-Object { ($_ -split "\s+")[0] } | Where-Object { $_ })
  if ($serials.Count -ne 1) {
    throw "Expected exactly one connected device. Found $($serials.Count). Pass -Device <serial>."
  }
  return $serials[0]
}

function Save-Screen {
  param([string]$Name)
  $remote = "/data/local/tmp/$Name.png"
  $local = Join-Path $OutputPath "$Name.png"
  Invoke-Hdc -HdcArgs @("shell", "uitest", "screenCap", "-p", $remote) | Out-Null
  Invoke-Hdc -HdcArgs @("file", "recv", $remote, $local) | Out-Null
}

function Save-Layout {
  param([string]$Name)
  $remote = "/data/local/tmp/$Name.json"
  $local = Join-Path $OutputPath "$Name.json"
  Invoke-Hdc -HdcArgs @("shell", "uitest", "dumpLayout", "-p", $remote) | Out-Null
  Invoke-Hdc -HdcArgs @("file", "recv", $remote, $local) | Out-Null
  return $local
}

function Get-RootBounds {
  param([string]$LayoutFile)
  $raw = Get-Content -Raw -Encoding UTF8 $LayoutFile
  if ($raw -notmatch '"bounds":"\[(\d+),(\d+)\]\[(\d+),(\d+)\]"') {
    throw "Unable to parse root bounds from $LayoutFile"
  }
  return @{
    Width = [int]$Matches[3] - [int]$Matches[1]
    Height = [int]$Matches[4] - [int]$Matches[2]
  }
}

function Assert-LayoutContains {
  param([string]$LayoutFile, [string]$Text)
  $raw = Get-Content -Raw -Encoding UTF8 $LayoutFile
  if (!$raw.Contains($Text)) {
    throw "Expected layout '$LayoutFile' to contain text '$Text'."
  }
}

function TextFromHex {
  param([string[]]$CodePoints)
  return -join ($CodePoints | ForEach-Object { [char][Convert]::ToInt32($_, 16) })
}

function Click-Point {
  param([int]$X, [int]$Y)
  Invoke-Hdc -HdcArgs @("shell", "uitest", "uiInput", "click", "$X", "$Y") | Out-Null
  Start-Sleep -Milliseconds 800
}

function Click-Tab {
  param([int]$Index, [hashtable]$Bounds)
  $x = [int](($Bounds.Width / 6) * (2 * $Index + 1))
  $y = [int]($Bounds.Height - 155)
  Click-Point $x $y
}

New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

$script:Hdc = Resolve-Hdc
$script:Device = Resolve-Device
$TextHome = TextFromHex @("9996", "9875")
$TextTaskList = TextFromHex @("4EFB", "52A1", "5217", "8868")
$TextAddTask = TextFromHex @("6DFB", "52A0", "4EFB", "52A1")
$TextCreateCustom = TextFromHex @("521B", "5EFA", "81EA", "5B9A", "4E49", "4E60", "60EF")
$TextAchievement = TextFromHex @("6210", "5C31")
$TextMine = TextFromHex @("6211", "7684")
$TextProfile = TextFromHex @("4E2A", "4EBA", "8D44", "6599")

Push-Location $ProjectRoot
try {
  if (!$SkipBuild) {
    devecocli build
  }

  if (!$SkipInstall) {
    $runArgs = @("run", "--module", "entry", "--device", $script:Device)
    if ($FreshInstall) {
      $runArgs += "--uninstall"
    } elseif ($SkipBuild) {
      $runArgs += "--skip-build"
    }
    & devecocli @runArgs
    if ($LASTEXITCODE -ne 0) {
      throw "devecocli run failed."
    }
  }

  Start-Sleep -Seconds 2

  $initialLayout = Save-Layout "00-initial"
  $bounds = Get-RootBounds $initialLayout
  Save-Screen "00-initial"

  Click-Tab 0 $bounds
  $homeLayout = Save-Layout "01-home"
  Save-Screen "01-home"
  Assert-LayoutContains $homeLayout $TextHome
  Assert-LayoutContains $homeLayout $TextTaskList

  $addX = [int]($bounds.Width / 2)
  $addY = [int]($bounds.Height - 465)
  Click-Point $addX $addY
  $addLayout = Save-Layout "02-add-task"
  Save-Screen "02-add-task"
  Assert-LayoutContains $addLayout $TextAddTask
  Assert-LayoutContains $addLayout $TextCreateCustom
  Invoke-Hdc -HdcArgs @("shell", "uitest", "uiInput", "keyEvent", "Back") | Out-Null
  Start-Sleep -Milliseconds 800

  Click-Tab 1 $bounds
  $achievementLayout = Save-Layout "03-achievement"
  Save-Screen "03-achievement"
  Assert-LayoutContains $achievementLayout $TextAchievement

  Click-Tab 2 $bounds
  $mineLayout = Save-Layout "04-mine"
  Save-Screen "04-mine"
  Assert-LayoutContains $mineLayout $TextMine
  Assert-LayoutContains $mineLayout $TextProfile

  Write-Output "UI smoke passed. Artifacts: $OutputPath"
}
finally {
  Pop-Location
}
