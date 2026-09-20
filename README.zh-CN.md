# AerialDesk

**macOS 动态桌面壁纸——任意视频、任意屏幕，不锁屏也能动。**

macOS 的「航拍」视频只在锁屏界面播放。AerialDesk 把动态搬到**桌面**：在壁纸之上、
桌面图标之下铺一层循环播放的静音视频窗口——点击穿透、图标照常显示、调度中心正常，
完全不打扰使用。

- 🎬 **任意视频** — 可选任何 `.mov` / `.mp4` / `.m4v`，也能自动发现 Mac 已下载的系统
  航拍视频（不打包、不下载任何素材）
- 🖥 **多屏独立控制** — 只播某一块外接屏，或全部；显示器热插拔自动适应
- 🫥 **无感设计** — 点击穿透、无 Dock 图标，只住在菜单栏
- 🔋 **轻量** — 硬件解码（HEVC）、静音循环；菜单栏一键暂停
- 🔒 **隐私** — 零网络请求、零数据收集、不申请任何权限（无屏幕录制、无辅助功能）

## 系统要求

macOS 13 (Ventura) 及以上，通用二进制（Apple Silicon + Intel）。

## 安装

1. 从 [Releases](../../releases) 下载 `AerialDesk-<版本>.zip`
2. 解压，把 `AerialDesk.app` 拖进「应用程序」
3. 首次启动：右键 App → **打开**（未公证应用的 Gatekeeper 提示），或执行
   `xattr -cr /Applications/AerialDesk.app`

菜单栏出现图标后，点 **▶ Play on Desktop**，Mac 上最新的航拍视频就开始在桌面上
动起来了。

### 从源码构建

```bash
git clone <本仓库>
cd aerialdesk
./build.sh          # → dist/AerialDesk.app（通用二进制）
```

## 使用

点击菜单栏图标：

- **▶ Play on Desktop / ⏹ Stop Playback** — 总开关（重启后记住）
- **Displays** — 「All Displays」或勾选单块屏；最后一块屏不允许单独取消（想全关用停止）
- **Video Source** — 已发现的航拍（新→旧）、系统自带视频、或 *Choose Other Video…*
  选任意本地视频
- **Launch at Login** — 系统原生登录项（需使用打包好的 .app）

### 命令行

```bash
AerialDesk --list-screens                    # 列出显示器（id、名称、尺寸）
AerialDesk --video ~/clip.mp4 --screens 1,2  # 调试：本次会话强制播放
```

## 常见问题

**桌面上的航拍为什么自己不动？**
这是 Apple 的省电策略：航拍视频只在锁屏播放。AerialDesk 把同一段视频搬到桌面。

**耗电吗？**
视频走硬件解码（Apple Silicon 媒体引擎），CPU 占用很低，但持续播放肯定比静态壁纸
费电。用电池时可以从菜单栏停掉，或只播一块外接屏。

**Video Source 里没有航拍？**
AerialDesk 只发现 Mac 已缓存的视频（系统设置 → 墙纸 → 选过一次航拍即可）。
它自己不下载任何内容——那是 Apple 的版权素材。

**能和别的视频壁纸软件同时开吗？**
不能叠着用——会出现两层视频互相覆盖。先停掉另一个。

**需要屏幕录制或辅助功能权限吗？**
不需要。它只是往桌面层放普通（点击穿透）窗口。

## 许可

[MIT](LICENSE)。Apple 航拍视频版权归 Apple 所有，AerialDesk 既不附带也不下载，
只播放你 Mac 上已存在的文件。

---

English documentation: [README.md](README.md)
