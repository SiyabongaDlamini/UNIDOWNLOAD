<p align="center">
  <h1 align="center">🎬 Unidown</h1>
  <p align="center">
    <strong>A universal video downloader with a sleek native GUI — powered by yt-dlp.</strong>
  </p>
  <p align="center">
    Download videos from YouTube, Instagram, TikTok, X/Twitter, Facebook, Vimeo, Reddit, Twitch, SoundCloud, and 1000+ more sites.
  </p>
</p>

---

## ✨ Features

- 🎥 **Download from anywhere** — YouTube, Instagram, TikTok, X/Twitter, Facebook, Reddit, Vimeo, Twitch, SoundCloud, Dailymotion, Bilibili, and more
- 🖥️ **Native dark-themed GUI** — built with Swift (macOS) and CustomTkinter (Windows/cross-platform)
- 📺 **Quality selector** — choose from Best (Auto), 4K, 1080p, 720p, 480p, etc.
- 🎵 **Multiple formats** — MP4, WebM, MP3, M4A
- 🖼️ **Video preview** — see thumbnail, title, duration, and platform badge before downloading
- 📊 **Real-time progress** — progress bar with speed, ETA, and live log output
- 📁 **Custom save location** — pick any folder on your system
- 🏷️ **Metadata embedding** — automatically embeds thumbnails and metadata (when FFmpeg is available)
- ❌ **Cancel downloads** — stop any download mid-progress
- 🔄 **Auto FFmpeg detection** — finds bundled or system FFmpeg, degrades gracefully without it

---

## 📸 Supported Platforms

| Platform | Status |
|----------|--------|
| YouTube | ✅ Full support |
| Instagram | ✅ Full support |
| TikTok | ✅ Full support |
| X / Twitter | ✅ Full support |
| Facebook | ✅ Full support |
| Vimeo | ✅ Full support |
| Reddit | ✅ Full support |
| Twitch | ✅ Full support |
| SoundCloud | ✅ Full support |
| Dailymotion | ✅ Full support |
| Bilibili | ✅ Full support |
| [1000+ more](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md) | ✅ Via yt-dlp |

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

- **Python 3.9+** — [Download Python](https://www.python.org/downloads/)
- **FFmpeg** (recommended for best quality) — [Download FFmpeg](https://ffmpeg.org/download.html)
- **yt-dlp** — installed automatically via `requirements.txt`, or install with `pip install yt-dlp`

#### macOS (additional)

- **Xcode Command Line Tools** — for compiling the Swift GUI
- **yt-dlp via Homebrew** (for the native Swift app):
  ```bash
  brew install yt-dlp ffmpeg
  ```

---

### 🖥️ Running on Windows / Cross-Platform (Python GUI)

1. **Clone the repository**:
   ```bash
   git clone https://github.com/SiyabongaDlamini/UNIDOWNLOAD.git
   cd UNIDOWNLOAD
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the app**:
   ```bash
   python yt_gui.py
   ```

> **Note:** On Windows, FFmpeg is optional. Without it, Unidown will download single-stream video (lower quality). Install FFmpeg for best results and audio extraction.

---

### 🍎 Running on macOS (Native Swift GUI)

The macOS version is a native Cocoa app written in Swift that calls `yt-dlp` under the hood.

1. **Clone the repository**:
   ```bash
   git clone https://github.com/SiyabongaDlamini/UNIDOWNLOAD.git
   cd UNIDOWNLOAD
   ```

2. **Install yt-dlp and FFmpeg**:
   ```bash
   brew install yt-dlp ffmpeg
   ```

3. **Compile and run**:
   ```bash
   swiftc -O -framework Cocoa -o Unidown Unidown.swift
   ./Unidown
   ```

> **Tip:** To build a proper `.app` bundle, create your own `Info.plist` and `AppIcon.icns`, then use the standard macOS app bundle structure.

---

### 📜 Running via Terminal (Shell Script)

For a quick terminal-based download (no GUI):

```bash
chmod +x download.sh
./download.sh
```

This will prompt you for a URL and download the highest quality MP4 to `~/Downloads`.

---

## 🏗️ Building a Windows EXE

This project includes a GitHub Actions workflow that automatically builds a Windows `.exe` using PyInstaller.

**To trigger the build:**
1. Push to `main` or `master` branch
2. Or manually trigger via the **Actions** tab → **Build Windows EXE** → **Run workflow**

**To build locally on Windows:**
```bash
pip install -r requirements.txt
pip install pyinstaller
pyinstaller --noconfirm --onefile --windowed --collect-all customtkinter --collect-all imageio_ffmpeg --name "Unidown" "yt_gui.py"
```

The executable will be in the `dist/` folder.

---

## 🍴 Forking & Modifying

1. **Fork** this repository on GitHub
2. **Clone** your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/UNIDOWNLOAD.git
   cd UNIDOWNLOAD
   ```
3. **Make your changes** — the codebase is structured as follows:

### 📂 Project Structure

```
UNIDOWNLOAD/
├── yt_gui.py              # Windows/cross-platform GUI (Python + CustomTkinter)
├── Unidown.swift          # macOS native GUI (Swift + Cocoa)
├── download.sh            # Simple terminal-based downloader
├── requirements.txt       # Python dependencies
├── LICENSE                # MIT License
├── .github/
│   └── workflows/
│       └── build-windows.yml  # GitHub Actions — auto-build Windows EXE
└── .gitignore
```

### Key Files to Modify

| File | What it does | Language |
|------|-------------|----------|
| `yt_gui.py` | The full Windows/Linux GUI app — URL input, preview, quality selection, download with progress | Python |
| `Unidown.swift` | The full macOS native GUI app — same features, Cocoa UI | Swift |
| `download.sh` | Minimal terminal downloader — edit for custom yt-dlp options | Bash |
| `requirements.txt` | Python packages — add any new dependencies here | — |
| `build-windows.yml` | CI/CD pipeline — modify PyInstaller flags or add macOS builds | YAML |

### Customization Ideas

- 🎨 **Change the theme** — edit the color constants at the top of `yt_gui.py` or `Unidown.swift`
- ➕ **Add new platforms** — extend the `PLATFORM_MAP` dict in `yt_gui.py` or `platformInfo()` in Swift
- 📦 **Change default format** — modify the `format_var` default in the GUI code
- 🔧 **Add yt-dlp flags** — customize `ydl_opts` dict in `_run_download()` (Python) or `args` array in `runDownload()` (Swift)
- 🪟 **Customize the EXE build** — edit `.github/workflows/build-windows.yml`

4. **Push your changes**:
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```

---

## 📋 Requirements

### Python Dependencies (`requirements.txt`)

| Package | Purpose |
|---------|---------|
| `customtkinter` | Modern dark-themed GUI framework |
| `yt-dlp` | Core video downloading engine |
| `Pillow` | Thumbnail image processing |
| `requests` | HTTP requests for thumbnails |
| `imageio-ffmpeg` | Bundled FFmpeg for PyInstaller builds |

### System Dependencies

| Tool | Required? | Purpose |
|------|-----------|---------|
| Python 3.9+ | ✅ Yes | Runtime for `yt_gui.py` |
| FFmpeg | ⚡ Recommended | Video/audio merging, metadata embedding |
| yt-dlp (brew) | 🍎 macOS only | Required by the Swift native app |

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Siyabonga Majaha Dlamini**  
Social: `lugal_siyabonga`

---

<p align="center">
  <sub>Built with ❤️ using yt-dlp, Swift, and Python</sub>
</p>
