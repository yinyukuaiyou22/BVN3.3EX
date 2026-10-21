# 推送到 GitHub 操作手册（2026-10-11）

> **为什么需要你手动执行**：当前 AI 会话的沙箱无法创建信号管道
> （`couldn't create signal pipe, Win32 error 5`），所有 git 写操作
> （fetch / rebase / push / rm --cached）都失败；且 push 需要交互式输入 GitHub 凭据。
> 请在**普通 PowerShell**（非受限会话）里执行下面的命令。

## 当前状态（已核实）

```
本地 master:   f81b4ab  ahead 4  (4 个未推送提交)
远端 origin:   e3b6f43  behind 2 (远端有 2 个本地缺失的提交)
```

远端那 2 个提交是：

| commit | 内容 | 关键影响 |
|---|---|---|
| `cf48010` | 发布外置资源兼容层与 Android 使用文档 | **把 CLAUDE.md 从 1450 行删到 47 行** |
| `e3b6f43` | docs: 完善外置资源新增能力与手动配置说明 | README.md +25 行外置资源说明 |

**远端 master 上的 CLAUDE.md 现在是 47 行（4196 字节）残缺版；你本地是重建后的版本。**
两者必须合并且以本地版为准（远端是残缺的），不能直接强推。

## 本次改动后的文件行数（2026-10-11 核验）

| 文件 | 改前 | 现在 |
|---|---|---|
| `AGENTS.md` | 770 行 | **110 行** |
| `doc/runtime-pitfalls.md` | —（新建） | **400 行** |
| `CLAUDE.md` | — | **104 行** |
| `.gitignore` | 81 行 | **141 行** |

## 代理

已确认可用，**无需额外配置**：

```
http.proxy  = http://127.0.0.1:7890
https.proxy = http://127.0.0.1:7890
```

（Clash 的 7890 / 7891 端口均已开放）

---

## 执行步骤（按顺序复制粘贴）

### 第 -1 步：进项目目录（**必须先做**）

```powershell
cd E:\BaiduNetdiskDownload\BVNY
```

> PowerShell 默认停在 `C:\WINDOWS\system32`，直接跑 git 会报
> `fatal: not a git repository`。**每条命令前都要先 cd 到这里。**
> 用 `git rev-parse --short HEAD` 确认，应返回 `f81b4ab`。

### 第 0 步：建立回滚点

```powershell
git branch backup/pre-push-2026-10-11
```

万一后面搞砸：

```powershell
git reset --hard backup/pre-push-2026-10-11
```

### 第 1 步：取远端最新

```powershell
git fetch origin master
```

### 第 2 步：把你的 4 个提交接到远端之后

```powershell
git rebase origin/master
```

**大概率会在 CLAUDE.md 和 README.md 报冲突。** 这是预期的。

### 第 3 步：解冲突（关键）

冲突时执行这条，**保留你本地的完整版**（远端是残缺的 47 行）：

```powershell
git checkout --ours CLAUDE.md README.md
git add CLAUDE.md README.md
```

如果还有其他文件冲突，用 `git status` 查看，同样用 `--ours` 保留本地版。

> `--ours` = 你的版本；`--theirs` = 远端版本。这里**必须用 `--ours`**。

### 第 4 步：继续 rebase

```powershell
git rebase --continue
```

如果再次提示冲突，重复第 3、4 步直到完成。

### 第 5 步：（可选但推荐）清掉误入库的 40.7 MB

```powershell
git rm -r --cached tools/platform-tools android-platform-33
git rm --cached BVNscripts/scripts/launch.as.bak
git rm --cached BVNscripts/scripts/net/play5d/game/bvn/ui/SetBtnGroup.pcode
```

> `.gitignore` 里已写规则，但**已跟踪文件不会被 .gitignore 自动清除**，
> 必须 `git rm --cached` 才生效（本地文件保留）。

### 第 6 步：验证将要推送的内容

```powershell
git diff --stat origin/master..master
git log --oneline origin/master..master
```

确认：
- 提交数是预期的（4 个 + 可选的清理提交）
- **不含** `android.jar`、`platform-tools/`、`session*.jsonl`、`.backup/`
- **不含** 密码、私钥、p12 证书路径

### 第 7 步：推送

```powershell
git push origin master
```

凭据提示时输入 GitHub 用户名 + **Personal Access Token**（不是账户密码）。
Token 需要有 `repo` 权限，在 GitHub → Settings → Developer settings →
Personal access tokens 生成。

---

## 推送后自检

```powershell
git status
```

应显示 `nothing to commit, working tree clean`（或仅剩未跟踪文件）。

到 GitHub 网页确认 https://github.com/yinyukuaiyou22/BVN3.3EX
检查 CLAUDE.md 是**完整版**（含「ANE 现状」「文档地图」「外部资源契约」等章节），而非 47 行。

---

## 本次会话已完成的工作

| 项目 | 状态 |
|---|---|
| `.gitignore` 清理（81 → 141 行，纯追加） | ✅ 已写入 |
| 拦住 319 MB 的 `config/backup/` | ✅ 未入库 |
| 拦住 5.3 MB 的 `session (1).jsonl` | ✅ 未入库 |
| `AGENTS.md` 重写 770 → 110 行 | ✅ 已写入 |
| 新建 `doc/runtime-pitfalls.md`（370 行） | ✅ 已写入 |
| `CLAUDE.md` 修复 2 处失效指针 | ✅ 已写入 |
| `doc/README.md` 加索引 | ✅ 已写入 |
| 文件快照备份 | ✅ `_pre_rebase_snapshot/` |

**以上均未提交，等你执行上述步骤后一次性推送。**
