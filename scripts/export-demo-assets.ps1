param(
  [string]$Device = "",
  [string]$BundleName = "com.example.newhealthylife",
  [string]$OutputDir = "artifacts/demo-assets",
  [switch]$SkipBuild,
  [switch]$SkipInstall,
  [switch]$FreshInstall
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$OutputPath = Join-Path $ProjectRoot $OutputDir
$FramePath = Join-Path $OutputPath "frames"

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

function Save-Capture {
  param([string]$Name, [string]$Title, [string]$Description)
  $remotePng = "/data/local/tmp/$Name.png"
  $remoteJson = "/data/local/tmp/$Name.json"
  $localPng = Join-Path $FramePath "$Name.png"
  $localJson = Join-Path $FramePath "$Name.json"

  Invoke-Hdc -HdcArgs @("shell", "uitest", "screenCap", "-p", $remotePng) | Out-Null
  Invoke-Hdc -HdcArgs @("file", "recv", $remotePng, $localPng) | Out-Null
  Invoke-Hdc -HdcArgs @("shell", "uitest", "dumpLayout", "-p", $remoteJson) | Out-Null
  Invoke-Hdc -HdcArgs @("file", "recv", $remoteJson, $localJson) | Out-Null

  $script:Frames += [ordered]@{
    name = $Name
    title = $Title
    description = $Description
    image = "frames/$Name.png"
    layout = "frames/$Name.json"
  }
  Write-Output "Captured $Name - $Title"
}

function Click-Point {
  param([int]$X, [int]$Y, [int]$DelayMs = 900)
  Invoke-Hdc -HdcArgs @("shell", "uitest", "uiInput", "click", "$X", "$Y") | Out-Null
  Start-Sleep -Milliseconds $DelayMs
}

function Swipe {
  param([int]$FromX, [int]$FromY, [int]$ToX, [int]$ToY, [int]$DelayMs = 900)
  Invoke-Hdc -HdcArgs @("shell", "uitest", "uiInput", "swipe", "$FromX", "$FromY", "$ToX", "$ToY", "600") | Out-Null
  Start-Sleep -Milliseconds $DelayMs
}

function Back {
  param([int]$DelayMs = 900)
  Invoke-Hdc -HdcArgs @("shell", "uitest", "uiInput", "keyEvent", "Back") | Out-Null
  Start-Sleep -Milliseconds $DelayMs
}

function Click-Tab {
  param([int]$Index)
  $x = [int](220 + (335 * $Index))
  Click-Point $x 2650
}

function Go-Home {
  for ($i = 0; $i -lt 3; $i++) {
    Back 350
  }
  Click-Tab 0
  Start-Sleep -Milliseconds 500
}

function Open-AddTask {
  Go-Home
  Click-Point 660 2460
}

function Write-DemoHtml {
  $cards = foreach ($frame in $script:Frames) {
    @"
      <section class="shot" id="$($frame.name)">
        <div class="copy">
          <p class="step">$($frame.name)</p>
          <h2>$($frame.title)</h2>
          <p>$($frame.description)</p>
          <a href="$($frame.layout)">布局文件</a>
        </div>
        <img src="$($frame.image)" alt="$($frame.title)">
      </section>
"@
  }
  $slides = foreach ($frame in $script:Frames) {
    @"
          <img src="$($frame.image)" alt="$($frame.title)">
"@
  }

  $html = @"
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>NewHealthyLife 功能测试录屏素材</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #f5f7fb; color: #17202a; }
    header { padding: 40px 32px 24px; max-width: 1120px; margin: 0 auto; }
    h1 { margin: 0 0 12px; font-size: 32px; }
    header p { margin: 0; color: #5f6b7a; line-height: 1.7; }
    .player { max-width: 1120px; margin: 0 auto 28px; padding: 0 32px; display: grid; grid-template-columns: 360px 1fr; gap: 24px; align-items: center; }
    .phone { width: 320px; border-radius: 28px; overflow: hidden; background: #111; box-shadow: 0 22px 70px rgba(20, 29, 43, .22); }
    .phone img { display: none; width: 100%; }
    .phone img.active { display: block; }
    .panel { background: white; border-radius: 8px; padding: 24px; box-shadow: 0 14px 42px rgba(20, 29, 43, .08); }
    .panel a { color: #1c6bff; text-decoration: none; }
    .grid { max-width: 1120px; margin: 0 auto; padding: 0 32px 48px; display: grid; gap: 20px; }
    .shot { display: grid; grid-template-columns: 1fr 280px; gap: 20px; background: white; border-radius: 8px; padding: 20px; align-items: start; box-shadow: 0 10px 32px rgba(20, 29, 43, .06); }
    .shot img { width: 280px; border-radius: 8px; border: 1px solid #e1e7ef; }
    .step { color: #1c6bff; font-weight: 700; margin: 0 0 8px; }
    .shot h2 { margin: 0 0 10px; font-size: 20px; }
    .shot p { color: #5f6b7a; line-height: 1.7; }
    .shot a { color: #1c6bff; text-decoration: none; }
    @media (max-width: 820px) {
      .player, .shot { grid-template-columns: 1fr; }
      .phone, .shot img { width: 100%; max-width: 360px; }
    }
  </style>
</head>
<body>
  <header>
    <h1>NewHealthyLife 功能测试录屏素材</h1>
    <p>自动操作设备生成的关键截图、布局文件和网页播放版。页面顶部会循环播放截图序列，可作为没有 MP4 时的录屏替代素材。</p>
  </header>
  <main>
    <section class="player">
      <div class="phone" id="player">
$slides
      </div>
      <div class="panel">
        <h2>素材说明</h2>
        <p>截图目录：<code>frames/</code></p>
        <p>GIF 动图：<a href="demo-recording.gif">demo-recording.gif</a></p>
        <p>每张截图都带有同名布局文件，方便定位页面文本和控件。</p>
      </div>
    </section>
    <section class="grid">
$cards
    </section>
  </main>
  <script>
    const slides = Array.from(document.querySelectorAll('#player img'));
    let index = 0;
    if (slides.length > 0) {
      slides[0].classList.add('active');
      setInterval(() => {
        slides[index].classList.remove('active');
        index = (index + 1) % slides.length;
        slides[index].classList.add('active');
      }, 1400);
    }
  </script>
</body>
</html>
"@
  Set-Content -Path (Join-Path $OutputPath "index.html") -Value $html -Encoding UTF8
}

function Write-DemoGif {
  $python = @"
from pathlib import Path
from PIL import Image

out = Path(r"$OutputPath")
frames_dir = out / "frames"
files = sorted(frames_dir.glob("*.png"))
images = []
for path in files:
    img = Image.open(path).convert("RGB")
    target_width = 420
    ratio = target_width / img.width
    target_height = int(img.height * ratio)
    images.append(img.resize((target_width, target_height), Image.Resampling.LANCZOS))

if images:
    images[0].save(
        out / "demo-recording.gif",
        save_all=True,
        append_images=images[1:],
        duration=1200,
        loop=0,
        optimize=True
    )
"@
  $pythonPath = Join-Path $OutputPath "make_gif.py"
  Set-Content -Path $pythonPath -Value $python -Encoding UTF8
  python $pythonPath
}

New-Item -ItemType Directory -Force -Path $FramePath | Out-Null
$script:Frames = @()
$script:Hdc = Resolve-Hdc
$script:Device = Resolve-Device

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

  Go-Home
  Save-Capture "00-home-dashboard" "首页总览" "展示今日目标进度、周日历、任务列表和底部导航。"
  Swipe 640 2200 640 1450
  Save-Capture "01-home-task-list" "任务列表" "展示更多已启用习惯和完成状态。"

  Open-AddTask
  Save-Capture "02-add-task-presets" "添加任务" "展示创建自定义习惯入口和 7 个预设习惯列表。"

  Click-Point 520 430
  Save-Capture "03-custom-task-form" "自定义习惯表单" "展示名称、图标、类型、目标、单位和执行星期配置。"
  Go-Home

  Open-AddTask
  Click-Point 640 1010
  Save-Capture "04-edit-water-task" "预设任务编辑" "展示喝水目标配置、启停开关和完成按钮。"
  Go-Home

  Open-AddTask
  Click-Point 640 2140
  Save-Capture "05-edit-run-reminder" "跑步提醒配置" "展示跑步任务编辑页和提醒相关配置入口。"
  Go-Home

  Click-Point 990 1235
  Save-Capture "06-month-view" "月视图" "展示月历、完成状态圆点和日期选择入口。"
  Go-Home

  Click-Tab 1
  Save-Capture "07-achievement" "成就页" "展示连续天数、最高连续天数、徽章和周复盘区域。"
  Swipe 640 2250 640 1250
  Save-Capture "08-achievement-detail" "成就详情" "展示单项达成、超额达成等更多成就内容。"

  Click-Tab 2
  Save-Capture "09-mine" "我的页面" "展示头像、昵称、等级、资料摘要和入口列表。"
  Click-Point 640 430
  Save-Capture "10-profile-edit" "个人资料编辑" "展示头像、昵称、性别、生日、身高和体重编辑项。"
  Back

  Write-DemoHtml
  Write-DemoGif

  Write-Output "Demo assets exported: $OutputPath"
}
finally {
  Pop-Location
}
