import customtkinter as ctk
import threading
import os
import yt_dlp
import sys

# Theme setup (matching Swift app)
BG_COLOR = "#121217"
CARD_COLOR = "#1C1C24"
ACCENT_COLOR = "#665CF2"
TEXT_COLOR = "#FFFFFF"

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")  # We'll override with ACCENT_COLOR

class MyLogger:
    def __init__(self, app):
        self.app = app
    def debug(self, msg):
        self.app.after(0, self.app.append_log, msg + "\n")
    def warning(self, msg):
        self.app.after(0, self.app.append_log, "Warning: " + msg + "\n")
    def error(self, msg):
        self.app.after(0, self.app.append_log, "Error: " + msg + "\n")

class UnidownApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        
        self.title("Unidown")
        self.geometry("760x740")
        self.configure(fg_color=BG_COLOR)
        
        # Header
        self.title_lbl = ctk.CTkLabel(self, text="Unidown", font=ctk.CTkFont(size=26, weight="bold"), text_color=TEXT_COLOR)
        self.title_lbl.pack(pady=(30, 0), anchor="w", padx=24)
        
        self.sub_lbl = ctk.CTkLabel(self, text="Download videos from anywhere", font=ctk.CTkFont(size=13), text_color="#8c8c8c")
        self.sub_lbl.pack(anchor="w", padx=24, pady=(0, 20))
        
        # URL Card
        self.url_frame = ctk.CTkFrame(self, fg_color=CARD_COLOR, corner_radius=12, border_width=1, border_color="#333333")
        self.url_frame.pack(fill="x", padx=24, pady=10)
        
        self.url_entry = ctk.CTkEntry(self.url_frame, placeholder_text="Paste any video URL here...", 
                                      fg_color="transparent", border_width=0, font=ctk.CTkFont(size=14))
        self.url_entry.pack(side="left", fill="x", expand=True, padx=14, pady=10)
        
        self.fetch_btn = ctk.CTkButton(self.url_frame, text="Fetch & Download", fg_color=ACCENT_COLOR, hover_color="#554ce0", 
                                       width=140, height=36, corner_radius=8, command=self.start_download)
        self.fetch_btn.pack(side="right", padx=10, pady=7)
        
        # Log Area
        self.log_lbl = ctk.CTkLabel(self, text="Output Log", font=ctk.CTkFont(size=12, weight="bold"), text_color="#8c8c8c")
        self.log_lbl.pack(anchor="w", padx=24, pady=(20, 5))
        
        self.log_area = ctk.CTkTextbox(self, fg_color="#17171c", border_color="#333333", border_width=1, 
                                       corner_radius=8, font=ctk.CTkFont(family="Courier", size=12), text_color="#8cde8c")
        self.log_area.pack(fill="both", expand=True, padx=24, pady=(0, 24))
        
    def start_download(self):
        url = self.url_entry.get().strip()
        if not url:
            self.append_log("❌ Error: Please enter a valid URL.\n")
            return
            
        self.fetch_btn.configure(state="disabled", text="Downloading...")
        self.log_area.delete("1.0", "end")
        self.append_log(f"⬇ Starting download for: {url}\n\n")
        
        threading.Thread(target=self.run_yt_dlp, args=(url,), daemon=True).start()

    def my_hook(self, d):
        if d['status'] == 'finished':
            self.after(0, self.append_log, "Done downloading, now converting ...\n")
        elif d['status'] == 'downloading':
            # Optionally print progress
            pass

    def run_yt_dlp(self, url):
        home_dir = os.path.expanduser("~")
        output_template = os.path.join(home_dir, "Downloads", "%(title)s.%(ext)s")
        
        ydl_opts = {
            'format': 'bv*+ba/b',
            'merge_output_format': 'mp4',
            'outtmpl': output_template,
            'logger': MyLogger(self),
            'progress_hooks': [self.my_hook],
            'writethumbnail': True,
        }
        
        # If ffmpeg is bundled next to the exe, point to it (for PyInstaller)
        if getattr(sys, 'frozen', False):
            # We are running in a PyInstaller bundle
            bundle_dir = sys._MEIPASS
            # Note: We won't bundle ffmpeg automatically via python code, 
            # PyInstaller needs to do it. But yt_dlp looks in PATH.
        
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
            self.after(0, self.append_log, f"\n✅ Download complete! Saved to {os.path.join(home_dir, 'Downloads')}\n")
        except Exception as e:
            self.after(0, self.append_log, f"\n❌ Error: {str(e)}\n")
        finally:
            self.after(0, self.reset_button)

    def append_log(self, text):
        self.log_area.insert("end", text)
        self.log_area.see("end")

    def reset_button(self):
        self.fetch_btn.configure(state="normal", text="Fetch & Download")

if __name__ == "__main__":
    app = UnidownApp()
    app.mainloop()
