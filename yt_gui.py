"""
Unidown — Universal Video Downloader (Windows / Cross-platform)
Matches the macOS Swift UI: dark theme, thumbnail preview, quality/format
selectors, save-path picker, progress bar, and real-time log output.
"""

import customtkinter as ctk
import threading
import os
import sys
import re
import json
import subprocess
import shutil
from io import BytesIO

import yt_dlp
import requests
from PIL import Image

# ═══════════════════════════════════════════════════════════════
# Theme (matches the Swift Theme struct exactly)
# ═══════════════════════════════════════════════════════════════

BG_COLOR      = "#121217"
CARD_COLOR    = "#1C1C24"
BORDER_COLOR  = "#333333"
ACCENT_COLOR  = "#665CF2"
ACCENT_DK     = "#4D3FCC"
SUCCESS_COLOR = "#33D499"
ERROR_COLOR   = "#F87070"
TXT1          = "#FFFFFF"
TXT2          = "#8C8C8C"
TXT3          = "#616161"
LOG_GREEN     = "#8CD28C"


ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

# ═══════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════

PLATFORM_MAP = {
    "youtube.com":    ("YouTube",     "#FF2E2E"),
    "youtu.be":       ("YouTube",     "#FF2E2E"),
    "instagram.com":  ("Instagram",   "#E03D99"),
    "tiktok.com":     ("TikTok",      "#00F5D4"),
    "twitter.com":    ("X / Twitter", "#73ADFF"),
    "x.com":          ("X / Twitter", "#73ADFF"),
    "facebook.com":   ("Facebook",    "#4266F5"),
    "fb.watch":       ("Facebook",    "#4266F5"),
    "vimeo.com":      ("Vimeo",       "#1AB8E0"),
    "reddit.com":     ("Reddit",      "#FF7300"),
    "twitch.tv":      ("Twitch",      "#9252FF"),
    "soundcloud.com": ("SoundCloud",  "#FF5400"),
    "dailymotion":    ("Dailymotion", "#009EE0"),
    "bilibili.com":   ("Bilibili",    "#00BBDE"),
}


def platform_info(url: str):
    u = url.lower()
    for key, (name, color) in PLATFORM_MAP.items():
        if key in u:
            return name, color
    return "Web", TXT2


def fmt_duration(s: int) -> str:
    if s <= 0:
        return "Unknown"
    h, rem = divmod(s, 3600)
    m, sec = divmod(rem, 60)
    if h > 0:
        return f"{h}:{m:02d}:{sec:02d}"
    return f"{m}:{sec:02d}"


def height_label(h: int) -> str:
    if h >= 2160:
        return "4K (2160p)"
    return f"{h}p"


def extract_height(q: str) -> int:
    for val in [2160, 1440, 1080, 720, 480, 360, 240, 144]:
        if str(val) in q:
            return val
    return 9999


def get_ffmpeg_location() -> str | None:
    """Find a usable FFmpeg binary — bundled (imageio_ffmpeg) or system.
    Returns the exact executable path so yt-dlp can use it directly."""
    # 1. Try PyInstaller bundled binaries (_MEIPASS)
    if hasattr(sys, "_MEIPASS"):
        return sys._MEIPASS

    # 2. Try imageio_ffmpeg
    try:
        import imageio_ffmpeg
        ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
        if ffmpeg_exe and os.path.isfile(ffmpeg_exe):
            return ffmpeg_exe
    except Exception:
        pass

    # 3. Try shutil.which — works on Windows, macOS, Linux
    which_result = shutil.which("ffmpeg")
    if which_result:
        return which_result

    # 4. Check common macOS/Linux locations
    for p in ["/usr/local/bin/ffmpeg", "/opt/homebrew/bin/ffmpeg",
              os.path.expanduser("~/.local/bin/ffmpeg")]:
        if os.path.isfile(p):
            return p

    # 5. Check common Windows locations
    if sys.platform == "win32":
        for p in [
            os.path.join(os.environ.get("LOCALAPPDATA", ""), "ffmpeg", "bin", "ffmpeg.exe"),
            os.path.join(os.environ.get("ProgramFiles", ""), "ffmpeg", "bin", "ffmpeg.exe"),
            os.path.join(os.environ.get("ProgramFiles(x86)", ""), "ffmpeg", "bin", "ffmpeg.exe"),
        ]:
            if p and os.path.isfile(p):
                return p

    return None

def has_ffmpeg() -> bool:
    """Quick check if FFmpeg is available anywhere."""
    return get_ffmpeg_location() is not None


# ═══════════════════════════════════════════════════════════════
# yt-dlp Logger Adapter
# ═══════════════════════════════════════════════════════════════

class YTDLPLogger:
    """Routes yt-dlp log messages to the GUI log widget."""
    def __init__(self, callback):
        self._cb = callback

    def debug(self, msg):
        self._cb(msg + "\n")

    def warning(self, msg):
        self._cb("Warning: " + msg + "\n")

    def error(self, msg):
        self._cb("Error: " + msg + "\n")


# ═══════════════════════════════════════════════════════════════
# Main Application
# ═══════════════════════════════════════════════════════════════

class UnidownApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("Unidown")
        self.geometry("760x780")
        self.minsize(620, 600)
        self.configure(fg_color=BG_COLOR)
        
        # Set window icon
        icon_path = os.path.join(getattr(sys, '_MEIPASS', os.path.dirname(os.path.abspath(__file__))), "AppIcon.ico")
        if os.path.exists(icon_path):
            self.iconbitmap(icon_path)

        # ── State ──
        self.fetched_url = ""
        self.is_fetching = False
        self.is_downloading = False
        self.current_process = None
        self.available_heights: list[int] = []
        self.save_path = os.path.join(os.path.expanduser("~"), "Downloads")
        self.thumb_ctk_image = None  # hold reference so GC doesn't eat it

        self._build_ui()

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # UI Construction
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _build_ui(self):
        # ── Header row ──
        header = ctk.CTkFrame(self, fg_color="transparent")
        header.pack(fill="x", padx=24, pady=(24, 0))

        title_col = ctk.CTkFrame(header, fg_color="transparent")
        title_col.pack(side="left", fill="y")

        ctk.CTkLabel(title_col, text="Unidown",
                     font=ctk.CTkFont(size=26, weight="bold"),
                     text_color=TXT1).pack(anchor="w")
        ctk.CTkLabel(title_col, text="Download videos from anywhere",
                     font=ctk.CTkFont(size=13),
                     text_color=TXT2).pack(anchor="w")

        # Right side — about button & donate button
        btn_frame = ctk.CTkFrame(header, fg_color="transparent")
        btn_frame.pack(side="right")

        ctk.CTkButton(btn_frame, text="Donate", width=60, height=26,
                      fg_color=ACCENT_COLOR, hover_color=ACCENT_DK,
                      border_width=0, text_color=TXT1, font=ctk.CTkFont(size=11, weight="bold"),
                      command=self._donate_pressed).pack(side="left", padx=(0, 8))

        ctk.CTkButton(btn_frame, text="About", width=60, height=26,
                      fg_color=CARD_COLOR, hover_color=BORDER_COLOR,
                      border_width=1, border_color=BORDER_COLOR,
                      text_color=TXT1, font=ctk.CTkFont(size=11),
                      command=self._about_pressed).pack(side="left")

        # ── URL Card ──
        url_card = ctk.CTkFrame(self, fg_color=CARD_COLOR, corner_radius=12,
                                border_width=1, border_color=BORDER_COLOR)
        url_card.pack(fill="x", padx=24, pady=(16, 0))

        self.url_entry = ctk.CTkEntry(url_card,
                                      placeholder_text="Paste any video URL here...",
                                      fg_color="transparent", border_width=0,
                                      font=ctk.CTkFont(size=14),
                                      text_color=TXT1)
        self.url_entry.pack(side="left", fill="x", expand=True, padx=14, pady=10)
        self.url_entry.bind("<Return>", lambda e: self._fetch_pressed())

        self.fetch_btn = ctk.CTkButton(url_card, text="Fetch", width=100,
                                       height=36, corner_radius=8,
                                       fg_color=ACCENT_COLOR,
                                       hover_color=ACCENT_DK,
                                       font=ctk.CTkFont(size=14, weight="bold"),
                                       command=self._fetch_pressed)
        self.fetch_btn.pack(side="right", padx=10, pady=7)

        # ── Preview Card ──
        self.preview_card = ctk.CTkFrame(self, fg_color=CARD_COLOR,
                                         corner_radius=12, border_width=1,
                                         border_color=BORDER_COLOR, height=140)
        self.preview_card.pack(fill="x", padx=24, pady=(12, 0))
        self.preview_card.pack_propagate(False)

        # Placeholder text (visible when nothing fetched)
        self.placeholder_lbl = ctk.CTkLabel(
            self.preview_card,
            text="Paste a URL above and click Fetch to preview",
            font=ctk.CTkFont(size=14), text_color=TXT3)
        self.placeholder_lbl.place(relx=0.5, rely=0.5, anchor="center")

        # Thumbnail (hidden initially)
        self.thumb_label = ctk.CTkLabel(self.preview_card, text="",
                                        fg_color="#262626", corner_radius=8,
                                        width=192, height=110)
        self.thumb_label.place(x=14, y=14)
        self.thumb_label.lower()  # hide behind placeholder

        # Video title
        self.vid_title_lbl = ctk.CTkLabel(
            self.preview_card, text="", font=ctk.CTkFont(size=15, weight="bold"),
            text_color=TXT1, wraplength=400, justify="left", anchor="w")
        self.vid_title_lbl.place(x=220, y=14)

        # Video info (duration, formats)
        self.vid_info_lbl = ctk.CTkLabel(
            self.preview_card, text="", font=ctk.CTkFont(size=12),
            text_color=TXT2, anchor="w")
        self.vid_info_lbl.place(x=220, y=70)

        # Platform badge
        self.platform_lbl = ctk.CTkLabel(
            self.preview_card, text="", font=ctk.CTkFont(size=11, weight="bold"),
            text_color=ACCENT_COLOR, corner_radius=4, fg_color="transparent",
            anchor="w")
        self.platform_lbl.place(x=220, y=100)

        # Initially hide detail labels
        for w in (self.vid_title_lbl, self.vid_info_lbl, self.platform_lbl):
            w.lower()

        # ── Options Row (Quality & Format) ──
        opts_row = ctk.CTkFrame(self, fg_color="transparent")
        opts_row.pack(fill="x", padx=24, pady=(14, 0))

        ctk.CTkLabel(opts_row, text="Quality",
                     font=ctk.CTkFont(size=12, weight="bold"),
                     text_color=TXT2).pack(side="left")

        self.quality_var = ctk.StringVar(value="Best (Auto)")
        self.quality_menu = ctk.CTkOptionMenu(
            opts_row, variable=self.quality_var,
            values=["Best (Auto)"],
            width=170, height=30,
            fg_color=CARD_COLOR, button_color=BORDER_COLOR,
            button_hover_color="#444444",
            dropdown_fg_color=CARD_COLOR)
        self.quality_menu.pack(side="left", padx=(8, 24))

        ctk.CTkLabel(opts_row, text="Format",
                     font=ctk.CTkFont(size=12, weight="bold"),
                     text_color=TXT2).pack(side="left")

        self.format_var = ctk.StringVar(value="MP4 (Video)")
        self.format_menu = ctk.CTkOptionMenu(
            opts_row, variable=self.format_var,
            values=["MP4 (Video)", "WebM (Video)", "MP3 (Audio)", "M4A (Audio)"],
            width=170, height=30,
            fg_color=CARD_COLOR, button_color=BORDER_COLOR,
            button_hover_color="#444444",
            dropdown_fg_color=CARD_COLOR,
            command=self._format_changed)
        self.format_menu.pack(side="left", padx=(8, 0))

        # ── Save Location Row ──
        save_row = ctk.CTkFrame(self, fg_color="transparent")
        save_row.pack(fill="x", padx=24, pady=(10, 0))

        ctk.CTkLabel(save_row, text="Save to",
                     font=ctk.CTkFont(size=12, weight="bold"),
                     text_color=TXT2).pack(side="left")

        self.save_path_lbl = ctk.CTkLabel(
            save_row, text=self.save_path, font=ctk.CTkFont(size=12),
            text_color=TXT2, fg_color=CARD_COLOR, corner_radius=6,
            anchor="w", padx=8, height=28)
        self.save_path_lbl.pack(side="left", fill="x", expand=True, padx=(8, 8))

        ctk.CTkButton(save_row, text="Browse", width=80, height=28,
                      fg_color=CARD_COLOR, hover_color=BORDER_COLOR,
                      border_width=1, border_color=BORDER_COLOR,
                      text_color=TXT1, font=ctk.CTkFont(size=12),
                      command=self._browse_pressed).pack(side="right")

        # ── Download Button ──
        self.dl_btn = ctk.CTkButton(
            self, text="⬇  Download", height=46,
            fg_color=ACCENT_COLOR, hover_color=ACCENT_DK,
            font=ctk.CTkFont(size=16, weight="bold"),
            command=self._download_pressed)
        self.dl_btn.pack(fill="x", padx=24, pady=(14, 0))

        # ── Progress Bar ──
        self.progress_bar = ctk.CTkProgressBar(self, height=6,
                                                fg_color=BORDER_COLOR,
                                                progress_color=ACCENT_COLOR)
        self.progress_bar.set(0)
        self.progress_bar.pack(fill="x", padx=24, pady=(8, 0))
        self.progress_bar.pack_forget()  # hidden initially

        # ── Progress / Status Label ──
        self.progress_lbl = ctk.CTkLabel(self, text="Ready",
                                         font=ctk.CTkFont(size=12),
                                         text_color=TXT3, anchor="w")
        self.progress_lbl.pack(fill="x", padx=24, pady=(4, 0))

        # ── Log Area ──
        ctk.CTkLabel(self, text="Output Log",
                     font=ctk.CTkFont(size=11, weight="bold"),
                     text_color=TXT3).pack(anchor="w", padx=24, pady=(8, 2))

        self.log_area = ctk.CTkTextbox(
            self, fg_color="#17171C", border_color=BORDER_COLOR,
            border_width=1, corner_radius=8,
            font=ctk.CTkFont(family="Courier", size=12),
            text_color=LOG_GREEN, activate_scrollbars=True)
        self.log_area.pack(fill="both", expand=True, padx=24, pady=(0, 8))

        # ── Version Label ──
        ctk.CTkLabel(self, text="v2.0.0", font=ctk.CTkFont(size=10),
                     text_color=TXT3).pack(anchor="e", padx=24, pady=(0, 8))

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Log Helpers
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _append_log(self, text: str):
        self.log_area.insert("end", text)
        self.log_area.see("end")

    def _append_log_safe(self, text: str):
        """Thread-safe version — schedules on main thread."""
        self.after(0, self._append_log, text)

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # About
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _about_pressed(self):
        win = ctk.CTkToplevel(self)
        win.title("About Unidown")
        win.geometry("360x220")
        win.configure(fg_color=BG_COLOR)
        win.resizable(False, False)
        win.grab_set()

        ctk.CTkLabel(win, text="Unidown v2.0.0",
                     font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=TXT1).pack(pady=(24, 6))
        ctk.CTkLabel(win, text="A universal video downloader\npowered by yt-dlp.",
                     font=ctk.CTkFont(size=13), text_color=TXT2,
                     justify="center").pack()
        ctk.CTkLabel(win, text="Developed by Siyabonga Majaha Dlamini\nSocial: lugal_siyabonga",
                     font=ctk.CTkFont(size=12), text_color=TXT3,
                     justify="center").pack(pady=(10, 0))
        ctk.CTkLabel(win, text="Thank you for your support!",
                     font=ctk.CTkFont(size=12), text_color=SUCCESS_COLOR).pack(pady=(8, 0))

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Donate
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _donate_pressed(self):
        import webbrowser
        webbrowser.open("https://www.buymeacoffee.com/lugalsiyabonga")

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Browse
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _browse_pressed(self):
        from tkinter import filedialog
        folder = filedialog.askdirectory(initialdir=self.save_path,
                                         title="Select Download Folder")
        if folder:
            self.save_path = folder
            self.save_path_lbl.configure(text=folder)

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Format Changed
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _format_changed(self, choice: str):
        is_audio = "Audio" in choice
        if is_audio:
            self.quality_var.set("Best (Auto)")
            self.quality_menu.configure(state="disabled")
        else:
            self.quality_menu.configure(state="normal")

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Fetch
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _fetch_pressed(self):
        url = self.url_entry.get().strip()
        if not url:
            self._append_log("❌ Error: Please enter a valid URL.\n")
            return
        if self.is_fetching:
            return

        self.is_fetching = True
        self.fetched_url = url
        self.log_area.delete("1.0", "end")

        # Reset preview
        self.placeholder_lbl.configure(text="⏳ Fetching video info...")
        self.placeholder_lbl.lift()
        for w in (self.vid_title_lbl, self.vid_info_lbl, self.platform_lbl):
            w.lower()
        self.thumb_label.lower()

        self.fetch_btn.configure(state="disabled", text="Fetching...")
        self.url_entry.configure(state="disabled")
        self.progress_lbl.configure(text="Fetching...")

        p_name, p_color = platform_info(url)
        self._append_log(f"🔗 Fetching from {p_name}: {url}\n")

        threading.Thread(target=self._run_fetch,
                         args=(url, p_name, p_color), daemon=True).start()

    def _run_fetch(self, url: str, platform: str, p_color: str):
        try:
            ydl_opts = {
                'quiet': True,
                'no_warnings': True,
                'skip_download': True,
                'noplaylist': True,
            }

            ffmpeg_loc = get_ffmpeg_location()
            if ffmpeg_loc:
                ydl_opts['ffmpeg_location'] = ffmpeg_loc

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=False)

            if info is None:
                raise Exception("Could not extract video info.")

            title = info.get("title", "Unknown Title")
            duration = int(info.get("duration", 0) or 0)
            thumb_url = info.get("thumbnail", "")
            formats = info.get("formats", [])

            # Gather heights
            heights = set()
            for f in formats:
                vc = f.get("vcodec", "none")
                if vc and vc != "none":
                    h = f.get("height")
                    if h and h > 0:
                        heights.add(h)
            sorted_heights = sorted(heights, reverse=True)

            # Download thumbnail
            thumb_image = None
            if thumb_url:
                try:
                    resp = requests.get(thumb_url, timeout=10)
                    resp.raise_for_status()
                    img = Image.open(BytesIO(resp.content))
                    img = img.resize((192, 110), Image.LANCZOS)
                    thumb_image = ctk.CTkImage(light_image=img, dark_image=img,
                                               size=(192, 110))
                except Exception:
                    pass

            # Update UI on main thread
            self.after(0, self._show_preview, title, duration, formats,
                       sorted_heights, thumb_image, platform, p_color)

        except Exception as e:
            self._append_log_safe(f"❌ Failed to fetch video info: {e}\n")
            self.after(0, self._fetch_failed)

    def _show_preview(self, title, duration, formats, sorted_heights,
                      thumb_image, platform, p_color):
        self._append_log(f"✅ Found: {title}\n")
        self._append_log(f"   Duration: {fmt_duration(duration)} • Formats: {len(formats)}\n\n")

        # Thumbnail
        if thumb_image:
            self.thumb_ctk_image = thumb_image  # prevent GC
            self.thumb_label.configure(image=thumb_image, text="")
        else:
            self.thumb_label.configure(image=None, text="No\nPreview")
        self.thumb_label.lift()

        # Details
        self.vid_title_lbl.configure(text=title)
        self.vid_title_lbl.lift()

        self.vid_info_lbl.configure(
            text=f"Duration: {fmt_duration(duration)} • {len(formats)} formats available")
        self.vid_info_lbl.lift()

        self.platform_lbl.configure(text=f"  {platform}  ", text_color=p_color)
        self.platform_lbl.lift()

        self.placeholder_lbl.lower()

        # Populate quality dropdown
        self.available_heights = sorted_heights
        q_values = ["Best (Auto)"] + [height_label(h) for h in sorted_heights]
        self.quality_menu.configure(values=q_values)
        self.quality_var.set("Best (Auto)")

        self._set_fetching(False)
        self.progress_lbl.configure(text="Ready to download")

    def _fetch_failed(self):
        self.placeholder_lbl.configure(
            text="❌ Could not fetch video info. Check the URL and try again.")
        self.placeholder_lbl.lift()
        self._set_fetching(False)
        self.progress_lbl.configure(text="Fetch failed")

    def _set_fetching(self, active: bool):
        self.is_fetching = active
        self.fetch_btn.configure(
            state="disabled" if active else "normal",
            text="Fetching..." if active else "Fetch")
        self.url_entry.configure(state="disabled" if active else "normal")

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Download
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _download_pressed(self):
        if self.is_downloading:
            # Cancel
            if self.current_process:
                try:
                    self.current_process.terminate()
                except Exception:
                    pass
                self.current_process = None
            self._set_downloading(False)
            self._append_log("\n⛔ Download cancelled.\n")
            self.progress_lbl.configure(text="Cancelled")
            return

        if not self.fetched_url:
            self._append_log("❌ Please fetch a video first before downloading.\n")
            return

        self._set_downloading(True)
        self.progress_bar.set(0)
        self.progress_bar.pack(fill="x", padx=24, pady=(8, 0),
                               before=self.progress_lbl)
        self.progress_lbl.configure(text="Starting download...",
                                     text_color=TXT3)
        self._append_log("⬇ Starting download...\n")

        threading.Thread(target=self._run_download, daemon=True).start()

    def _run_download(self):
        url = self.fetched_url
        sel_format = self.format_var.get()
        sel_quality = self.quality_var.get()
        dest = self.save_path

        # Check FFmpeg availability up front
        ffmpeg_loc = get_ffmpeg_location()
        ffmpeg_available = ffmpeg_loc is not None

        if not ffmpeg_available:
            self._append_log_safe(
                "⚠️  FFmpeg not found — using single-stream mode "
                "(quality may be lower).\n"
                "   Install FFmpeg for best results: "
                "https://ffmpeg.org/download.html\n\n")

        ydl_opts = {
            'outtmpl': os.path.join(dest, '%(title)s.%(ext)s'),
            'logger': YTDLPLogger(self._append_log_safe),
            'progress_hooks': [self._progress_hook],
            'writethumbnail': False,
            'noplaylist': True,          # ALWAYS download single video
            'postprocessors': [],
        }

        # FFmpeg location — critical for Windows merging
        if ffmpeg_available:
            ydl_opts['ffmpeg_location'] = ffmpeg_loc

        if "MP3" in sel_format:
            if ffmpeg_available:
                ydl_opts['format'] = 'bestaudio/best'
                ydl_opts['postprocessors'].append({
                    'key': 'FFmpegExtractAudio',
                    'preferredcodec': 'mp3',
                })
            else:
                # Without FFmpeg, grab best audio and save as-is
                ydl_opts['format'] = 'bestaudio/best'
            self._append_log_safe("   Format: MP3 (Audio Only)\n")
        elif "M4A" in sel_format:
            if ffmpeg_available:
                ydl_opts['format'] = 'bestaudio/best'
                ydl_opts['postprocessors'].append({
                    'key': 'FFmpegExtractAudio',
                    'preferredcodec': 'm4a',
                })
            else:
                ydl_opts['format'] = 'bestaudio[ext=m4a]/bestaudio/best'
            self._append_log_safe("   Format: M4A (Audio Only)\n")
        else:
            ext = "webm" if "WebM" in sel_format else "mp4"
            if ffmpeg_available:
                # With FFmpeg: merge best video + best audio
                if sel_quality == "Best (Auto)":
                    ydl_opts['format'] = 'bv*+ba/b'
                else:
                    h = extract_height(sel_quality)
                    ydl_opts['format'] = f'bv*[height<={h}]+ba/b[height<={h}]'
                ydl_opts['merge_output_format'] = ext
            else:
                # Without FFmpeg: use a single pre-muxed stream (no merge)
                if ext == "mp4":
                    if sel_quality == "Best (Auto)":
                        ydl_opts['format'] = 'best[ext=mp4]/best'
                    else:
                        h = extract_height(sel_quality)
                        ydl_opts['format'] = f'best[ext=mp4][height<={h}]/best[height<={h}]/best'
                else:
                    if sel_quality == "Best (Auto)":
                        ydl_opts['format'] = 'best[ext=webm]/best'
                    else:
                        h = extract_height(sel_quality)
                        ydl_opts['format'] = f'best[ext=webm][height<={h}]/best[height<={h}]/best'
            self._append_log_safe(
                f"   Format: {ext.upper()} • Quality: {sel_quality}\n")

        # Embed thumbnail & metadata only if FFmpeg is available
        if ffmpeg_available:
            ydl_opts['writethumbnail'] = True
            ydl_opts['postprocessors'].append({'key': 'EmbedThumbnail'})
            ydl_opts['postprocessors'].append({'key': 'FFmpegMetadata'})

        self._append_log_safe(f"   Save to: {dest}\n\n")

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])

            self._append_log_safe("\n✅ Download complete!\n")
            self.after(0, self._download_success, dest)
        except Exception as e:
            err_str = str(e)
            if "aborted" in err_str.lower() or "terminated" in err_str.lower():
                pass  # already handled by cancel
            else:
                self._append_log_safe(f"\n❌ Error: {err_str}\n")
                self.after(0, self._download_failed)

    def _progress_hook(self, d):
        status = d.get('status', '')
        if status == 'downloading':
            total = d.get('total_bytes') or d.get('total_bytes_estimate') or 0
            downloaded = d.get('downloaded_bytes', 0)
            speed = d.get('speed')
            eta = d.get('eta')

            if total > 0:
                pct = downloaded / total
                self.after(0, self.progress_bar.set, pct)
                info = f"{pct * 100:.1f}%"
            else:
                info = "Downloading..."

            if speed:
                if speed > 1_000_000:
                    info += f" • {speed / 1_000_000:.1f}MiB/s"
                elif speed > 1000:
                    info += f" • {speed / 1000:.0f}KiB/s"

            if eta and eta > 0:
                info += f" • ETA {fmt_duration(eta)}"

            self.after(0, self.progress_lbl.configure, {"text": info})

        elif status == 'finished':
            self.after(0, self.progress_lbl.configure,
                       {"text": "Merging / post-processing..."})

    def _download_success(self, dest: str):
        self.progress_bar.set(1.0)
        self.progress_lbl.configure(text=f"Complete — saved to {dest}",
                                     text_color=SUCCESS_COLOR)
        self._set_downloading(False)
        # Reset color after a few seconds
        self.after(6000, lambda: self.progress_lbl.configure(
            text_color=TXT3))

    def _download_failed(self):
        self.progress_lbl.configure(text="Failed", text_color=ERROR_COLOR)
        self._set_downloading(False)
        self.after(6000, lambda: self.progress_lbl.configure(
            text_color=TXT3))

    def _set_downloading(self, active: bool):
        self.is_downloading = active
        if active:
            self.dl_btn.configure(text="✕  Cancel Download",
                                  fg_color=ERROR_COLOR,
                                  hover_color="#D05050")
        else:
            self.dl_btn.configure(text="⬇  Download",
                                  fg_color=ACCENT_COLOR,
                                  hover_color=ACCENT_DK)
        self.fetch_btn.configure(state="disabled" if active else "normal")
        self.url_entry.configure(state="disabled" if active else "normal")
        self.format_menu.configure(state="disabled" if active else "normal")
        is_audio = "Audio" in self.format_var.get()
        if active or is_audio:
            self.quality_menu.configure(state="disabled")
        else:
            self.quality_menu.configure(state="normal")


# ═══════════════════════════════════════════════════════════════
# Entry Point
# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    app = UnidownApp()
    app.mainloop()
