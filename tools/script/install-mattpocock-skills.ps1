# install-mattpocock-skills.ps1
# 一键把项目 .agents/skills/ 镜像到用户级 ~/.agents/skills/
# 参考 mattpocock/skills/scripts/link-skills.sh（Win 等价）

# 硬编码路径 (PS5 here-string 单引号问题: 用 "..." 字符串)
$src = "E:\BaiduNetdiskDownload\BVNY\.agents\skills"
$dst = Join-Path $env:USERPROFILE ".agents\skills"

# 1. 校验源
if (-not (Test-Path $src)) {
    Write-Host "源目录不存在: $src"
    exit 1
}

# 2. 建目标目录 (分步: 先 .agents, 再 .agents\skills)
$dstRoot = Split-Path -Parent $dst
if (-not (Test-Path $dstRoot)) {
    New-Item -ItemType Directory -Path $dstRoot | Out-Null
}
if (-not (Test-Path $dst)) {
    New-Item -ItemType Directory -Path $dst | Out-Null
}

# 3. 复制 skills
$skills = Get-ChildItem $src -Directory -ErrorAction SilentlyContinue
if ($null -eq $skills) {
    Write-Host "源目录为空: $src"
    exit 0
}

foreach ($skill in $skills) {
    $target = Join-Path $dst $skill.Name
    if (Test-Path $target) {
        Remove-Item -Recurse -Force $target
    }
    Copy-Item -Recurse -Force $skill.FullName $target
    Write-Host ("installed: {0} -> {1}" -f $skill.Name, $target)
}

Write-Host ""
Write-Host ("完成. 用户级 skills: {0}" -f $dst)
Write-Host "重启 DSH web 加载新 catalog."