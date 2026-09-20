# AerialDesk

**Animated desktop wallpaper for macOS — any video, on any display, without locking your screen.**

macOS plays its beautiful "Aerial" videos only on the lock screen. AerialDesk brings
motion to your *desktop*: looping, muted video windows placed between the wallpaper and
your desktop icons. Clicks fall through, desktop icons stay visible, Mission Control
works, and nothing ever gets in your way.

- 🎬 **Any video works** — pick any `.mov` / `.mp4` / `.m4v`, or let AerialDesk discover
  the aerial videos your Mac already downloaded (nothing is bundled, nothing is downloaded)
- 🖥 **Per-display control** — play on one external display only, or all of them;
  hot-plugging a display just works
- 🫥 **Invisible by design** — click-through windows below your icons and windows;
  no Dock icon, lives in the menu bar
- 🔋 **Light** — hardware-decoded (HEVC) playback, muted and looped; stop it any time
  from the menu bar
- 🔒 **Private** — zero network requests, zero analytics, no permissions requested
  (no Screen Recording, no Accessibility)

## Requirements

macOS 13 (Ventura) or later. Universal binary (Apple Silicon + Intel).

## Install

1. Grab `AerialDesk-<version>.zip` from [Releases](../../releases)
2. Unzip and move `AerialDesk.app` to `/Applications`
3. First launch: right-click the app → **Open** (macOS Gatekeeper, the app is ad-hoc
   signed), or run `xattr -cr /Applications/AerialDesk.app`

A menu bar icon appears — click **▶ Play on Desktop** and your Mac's newest aerial
video starts animating your desktop.

### Build from source

```bash
git clone <this repo>
cd aerialdesk
./build.sh          # → dist/AerialDesk.app (universal binary)
```

## Usage

Click the menu bar icon:

- **▶ Play on Desktop / ⏹ Stop Playback** — master switch (persisted across launches)
- **Displays** — "All Displays" or tick individual displays; the last remaining display
  can't be unticked (use Stop instead)
- **Video Source** — discovered aerials (newest first), system-bundled videos, or
  *Choose Other Video…* for any file on disk
- **Launch at Login** — macOS-native login item (requires the bundled .app)

### CLI

```bash
AerialDesk --list-screens                    # print displays (id, name, size)
AerialDesk --video ~/clip.mp4 --screens 1,2  # debug: force playback for this session
```

## FAQ

**Why doesn't my desktop aerial move by itself?**
That's Apple's power-saving policy: aerial videos play on the lock screen only.
AerialDesk reuses those exact videos on your desktop.

**Will it drain my battery?**
Video is hardware-decoded (Apple Silicon media engine), so CPU usage stays low, but
continuous playback does consume more power than a static wallpaper. Stop playback from
the menu bar when on battery, or play on a single external display.

**Aerials are missing from the Video Source list.**
AerialDesk only finds videos your Mac has already cached (Settings → Wallpaper →
choose an aerial once). No downloads happen inside AerialDesk — that's Apple's content.

**Two wallpaper apps at once?**
Don't stack AerialDesk with another video-wallpaper tool — you'd get two overlapping
video layers. Stop the other one first.

**Does it need Screen Recording or Accessibility permission?**
No. It only places ordinary (click-through) windows on the desktop layer.

## License

[MIT](LICENSE). Apple's aerial videos remain Apple's property — AerialDesk neither
bundles nor downloads them; it only plays files already present on your Mac.

---

中文文档：[README.zh-CN.md](README.zh-CN.md)
