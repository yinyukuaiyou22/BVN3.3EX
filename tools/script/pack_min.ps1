<#
  pack_min.ps1 - 一键出「最低资源」发行包（只打包，绝不连接或安装任何设备）

  用法（在仓库根目录执行）：
    powershell -ExecutionPolicy Bypass -File tools\script\pack_min.ps1
    powershell -ExecutionPolicy Bypass -File tools\script\pack_min.ps1 -SkipBuild -SkipAssets

  参数：
    -SkipBuild    跳过 build.bat（SWF 已是最新时用）
    -SkipAssets   跳过 build_min_assets.py（min_assets 没动过时用）
    -Version      产物文件名里的版本标签；默认从 tools\Test\application.xml 读

  产物：
    tools\Test\bvn_min.apk                          固定名（供安装/上传）
    tools\Test\bvn_min_<版本>_<日期>.apk            带日期副本
#>
param(
   [switch]$SkipBuild,
   [switch]$SkipAssets,
   [string]$Version
)

$ErrorActionPreference = 'Stop'

$proj = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$test = Join-Path $proj 'tools\Test'
$adt  = Join-Path $proj 'flex4.16.1-air51.0.1.1\bin\adt.bat'
$cert = Join-Path $proj 'flex4.16.1-air51.0.1.1\bin\mycert.p12'

if (-not $env:BVN_KEYSTORE_PASS) { $env:BVN_KEYSTORE_PASS = 'yinyu7798' }

$sdk = $null
foreach ($d in 'D:\Android\SDK','C:\Android\SDK','E:\Android\SDK',$env:ANDROID_HOME) {
   if ($d -and (Test-Path (Join-Path $d 'platforms'))) { $sdk = $d; break }
}
if (-not $sdk) { throw 'Android SDK not found (looked for D:\Android\SDK and friends)' }

if (-not $Version) {
   $xml = Get-Content (Join-Path $test 'application.xml') -Raw -Encoding UTF8
   if ($xml -match '<versionNumber>([^<]+)</versionNumber>') { $Version = $Matches[1] } else { $Version = 'dev' }
}

if (-not $SkipBuild) {
   Write-Host '[1/3] build.bat ...'
   & (Join-Path $proj 'build.bat')
   if ($LASTEXITCODE -ne 0) { throw ('build failed: ' + $LASTEXITCODE) }
}

Push-Location $test
try {
   if (-not $SkipAssets) {
      Write-Host '[2/3] build_min_assets.py ...'
      & py -3 build_min_assets.py
      if ($LASTEXITCODE -ne 0) { throw ('build_min_assets failed: ' + $LASTEXITCODE) }
   }

   Write-Host '[3/3] adt package ...'
   $adtArgs = @(
      '-package','-target','apk-captive-runtime','-arch','armv8',
      '-storetype','pkcs12','-keystore',$cert,'-storepass',$env:BVN_KEYSTORE_PASS,
      'bvn_min.apk','application.xml','-platformsdk',$sdk,'-extdir',$test,
      'launch.swf','-C','min_assets',
      'assets\effect.swf','assets\movelist.jpg','assets\sounds','assets\font',
      'assets\config','assets\fighter','assets\face','assets\map','assets\bgm',
      # 图标必须显式打进包，否则 adt 报 error 303 Icon is missing from package
      '-C','.','icons'
   )
   & $adt @adtArgs
   if ($LASTEXITCODE -ne 0) { throw ('adt failed: ' + $LASTEXITCODE) }
}
finally {
   Pop-Location
}

$src = Join-Path $test 'bvn_min.apk'
$out = Join-Path $test ("bvn_min_{0}_{1}.apk" -f $Version, (Get-Date -Format 'yyyy-MM-dd'))
Copy-Item $src $out -Force

$f = Get-Item $out
Write-Host ("[OK] {0}  {1} MB  version={2}" -f $f.Name, [math]::Round($f.Length/1MB,1), $Version)
