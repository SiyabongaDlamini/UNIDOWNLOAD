import Cocoa

// ═══════════════════════════════════════════════════════════════
// MARK: - Theme
// ═══════════════════════════════════════════════════════════════

struct Theme {
    static let bg       = NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1)
    static let cardBg   = NSColor(red: 0.11, green: 0.11, blue: 0.14, alpha: 1)
    static let border   = NSColor(white: 0.20, alpha: 1)
    static let accent   = NSColor(red: 0.40, green: 0.36, blue: 0.95, alpha: 1)
    static let accentDk = NSColor(red: 0.30, green: 0.26, blue: 0.80, alpha: 1)
    static let success  = NSColor(red: 0.20, green: 0.83, blue: 0.60, alpha: 1)
    static let error    = NSColor(red: 0.97, green: 0.44, blue: 0.44, alpha: 1)
    static let txt1     = NSColor.white
    static let txt2     = NSColor(white: 0.55, alpha: 1)
    static let txt3     = NSColor(white: 0.38, alpha: 1)
    static let logGreen = NSColor(red: 0.55, green: 0.82, blue: 0.55, alpha: 1)
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Helpers
// ═══════════════════════════════════════════════════════════════

func findYtDlp() -> String? {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    for p in ["/usr/local/bin/yt-dlp","/opt/homebrew/bin/yt-dlp",
              "\(home)/.local/bin/yt-dlp","/usr/bin/yt-dlp"] {
        if FileManager.default.fileExists(atPath: p) { return p }
    }
    return nil
}

func platformInfo(_ url: String) -> (String, NSColor) {
    let u = url.lowercased()
    if u.contains("youtube.com") || u.contains("youtu.be") { return ("YouTube", NSColor(red:1,green:0.18,blue:0.18,alpha:1)) }
    if u.contains("instagram.com") { return ("Instagram", NSColor(red:0.88,green:0.24,blue:0.60,alpha:1)) }
    if u.contains("tiktok.com")    { return ("TikTok", NSColor(red:0.0,green:0.96,blue:0.84,alpha:1)) }
    if u.contains("twitter.com") || u.contains("x.com") { return ("X / Twitter", NSColor(red:0.45,green:0.68,blue:1.0,alpha:1)) }
    if u.contains("facebook.com") || u.contains("fb.watch") { return ("Facebook", NSColor(red:0.26,green:0.40,blue:0.96,alpha:1)) }
    if u.contains("vimeo.com")     { return ("Vimeo", NSColor(red:0.10,green:0.72,blue:0.88,alpha:1)) }
    if u.contains("reddit.com")    { return ("Reddit", NSColor(red:1.0,green:0.45,blue:0.0,alpha:1)) }
    if u.contains("twitch.tv")     { return ("Twitch", NSColor(red:0.57,green:0.32,blue:1.0,alpha:1)) }
    if u.contains("soundcloud.com"){ return ("SoundCloud", NSColor(red:1.0,green:0.33,blue:0.0,alpha:1)) }
    if u.contains("dailymotion")   { return ("Dailymotion", NSColor(red:0.0,green:0.62,blue:0.88,alpha:1)) }
    if u.contains("bilibili.com")  { return ("Bilibili", NSColor(red:0.0,green:0.73,blue:0.87,alpha:1)) }
    return ("Web", Theme.txt2)
}

func fmtDuration(_ s: Int) -> String {
    if s <= 0 { return "Unknown" }
    let h = s / 3600; let m = (s % 3600) / 60; let sec = s % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
}

func heightLabel(_ h: Int) -> String {
    if h >= 2160 { return "4K (2160p)" }
    return "\(h)p"
}



// ═══════════════════════════════════════════════════════════════
// MARK: - App Delegate
// ═══════════════════════════════════════════════════════════════

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ n: Notification) {
        // Menu bar
        let mainMenu = NSMenu()
        let appItem = NSMenuItem(); mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Unidown", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Unidown", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        let editItem = NSMenuItem(); mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        NSApp.mainMenu = mainMenu

        // Window
        let scr = NSScreen.main?.frame ?? NSRect(x:0,y:0,width:1440,height:900)
        let w: CGFloat = 760, h: CGFloat = 740
        window = NSWindow(
            contentRect: NSRect(x: (scr.width-w)/2, y: (scr.height-h)/2, width: w, height: h),
            styleMask: [.titled,.closable,.miniaturizable,.resizable], backing: .buffered, defer: false)
        window.title = "Unidown"
        window.minSize = NSSize(width: 620, height: 600)
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = Theme.bg
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentViewController = MainVC()
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Main View Controller
// ═══════════════════════════════════════════════════════════════

class MainVC: NSViewController {

    // ── UI elements ──
    private var urlField: NSTextField!
    private var fetchBtn: NSButton!

    private var previewCard: NSView!
    private var placeholderLbl: NSTextField!
    private var thumbView: NSImageView!
    private var vidTitleLbl: NSTextField!
    private var vidInfoLbl: NSTextField!
    private var platformLbl: NSTextField!

    private var qualityPopup: NSPopUpButton!
    private var formatPopup: NSPopUpButton!

    private var savePathLbl: NSTextField!
    private var savePath: String = ""

    private var dlBtn: NSButton!
    private var progressBar: NSProgressIndicator!
    private var progressLbl: NSTextField!

    private var logView: NSTextView!
    private var logScroll: NSScrollView!



    // ── State ──
    private var isFetching = false
    private var isDownloading = false
    private var currentProcess: Process?
    private var fetchedURL: String = ""
    private var availableHeights: [Int] = []

    override func loadView() { view = NSView(frame: NSRect(x:0,y:0,width:760,height:740)) }
    override func viewDidLoad() { super.viewDidLoad(); setupUI() }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: UI Setup
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func setupUI() {
        let vw = view.bounds.width, vh = view.bounds.height
        let pad: CGFloat = 24
        let cw = vw - pad * 2    // content width
        view.wantsLayer = true
        view.layer?.backgroundColor = Theme.bg.cgColor
        savePath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").path
        var y = vh

        // ── Header ──
        y -= 50
        let title = mkLabel("Unidown", size: 26, bold: true, color: Theme.txt1)
        title.frame = NSRect(x: pad, y: y, width: 300, height: 32)
        title.autoresizingMask = [.minYMargin]
        view.addSubview(title)

        y -= 20
        let sub = mkLabel("Download videos from anywhere", size: 13, bold: false, color: Theme.txt2)
        sub.frame = NSRect(x: pad, y: y, width: 400, height: 18)
        sub.autoresizingMask = [.minYMargin]
        view.addSubview(sub)

        // ── About Button (top-right) ──
        let aboutBtn = mkButton("About",
                                rect: NSRect(x: vw - pad - 70, y: y + 22, width: 60, height: 24),
                                bg: Theme.cardBg, fg: Theme.txt1)
        aboutBtn.font = NSFont.systemFont(ofSize: 11)
        aboutBtn.layer?.borderWidth = 1; aboutBtn.layer?.borderColor = Theme.border.cgColor
        aboutBtn.autoresizingMask = [.minXMargin, .minYMargin]
        aboutBtn.target = self; aboutBtn.action = #selector(aboutPressed)
        view.addSubview(aboutBtn)

        // ── URL Card ──
        y -= 62
        let urlCard = mkCard(NSRect(x: pad, y: y, width: cw, height: 50))
        urlCard.autoresizingMask = [.width, .minYMargin]
        view.addSubview(urlCard)

        urlField = NSTextField(frame: NSRect(x: 14, y: 8, width: urlCard.bounds.width - 120, height: 34))
        urlField.placeholderString = "Paste any video URL here..."
        urlField.font = NSFont.systemFont(ofSize: 14)
        urlField.isBordered = false; urlField.focusRingType = .none
        urlField.drawsBackground = false; urlField.textColor = Theme.txt1
        urlField.autoresizingMask = [.width]
        urlField.target = self; urlField.action = #selector(fetchPressed)
        urlCard.addSubview(urlField)

        fetchBtn = mkButton("Fetch", rect: NSRect(x: urlCard.bounds.width - 100, y: 7, width: 88, height: 36),
                            bg: Theme.accent, fg: .white)
        fetchBtn.autoresizingMask = [.minXMargin]
        fetchBtn.target = self; fetchBtn.action = #selector(fetchPressed)
        urlCard.addSubview(fetchBtn)

        // ── Preview Card ──
        y -= 150
        previewCard = mkCard(NSRect(x: pad, y: y, width: cw, height: 138))
        previewCard.autoresizingMask = [.width, .minYMargin]
        view.addSubview(previewCard)

        placeholderLbl = mkLabel("Paste a URL above and click Fetch to preview", size: 14, bold: false, color: Theme.txt3)
        placeholderLbl.frame = NSRect(x: 0, y: 0, width: previewCard.bounds.width, height: previewCard.bounds.height)
        placeholderLbl.alignment = .center
        placeholderLbl.autoresizingMask = [.width, .height]
        previewCard.addSubview(placeholderLbl)

        thumbView = NSImageView(frame: NSRect(x: 14, y: 14, width: 192, height: 110))
        thumbView.imageScaling = .scaleProportionallyUpOrDown
        thumbView.wantsLayer = true
        thumbView.layer?.cornerRadius = 8
        thumbView.layer?.masksToBounds = true
        thumbView.layer?.backgroundColor = NSColor(white: 0.15, alpha: 1).cgColor
        thumbView.isHidden = true
        previewCard.addSubview(thumbView)

        vidTitleLbl = mkLabel("", size: 15, bold: true, color: Theme.txt1)
        vidTitleLbl.frame = NSRect(x: 220, y: 82, width: previewCard.bounds.width - 240, height: 42)
        vidTitleLbl.maximumNumberOfLines = 2
        vidTitleLbl.lineBreakMode = .byTruncatingTail
        vidTitleLbl.autoresizingMask = [.width]
        vidTitleLbl.isHidden = true
        previewCard.addSubview(vidTitleLbl)

        vidInfoLbl = mkLabel("", size: 12, bold: false, color: Theme.txt2)
        vidInfoLbl.frame = NSRect(x: 220, y: 54, width: previewCard.bounds.width - 240, height: 18)
        vidInfoLbl.autoresizingMask = [.width]
        vidInfoLbl.isHidden = true
        previewCard.addSubview(vidInfoLbl)

        platformLbl = mkLabel("", size: 11, bold: true, color: Theme.accent)
        platformLbl.frame = NSRect(x: 220, y: 24, width: 200, height: 22)
        platformLbl.wantsLayer = true
        platformLbl.layer?.cornerRadius = 4
        platformLbl.isHidden = true
        previewCard.addSubview(platformLbl)

        // ── Options Row ──
        y -= 48
        let qLbl = mkLabel("Quality", size: 12, bold: true, color: Theme.txt2)
        qLbl.frame = NSRect(x: pad, y: y + 14, width: 55, height: 16)
        qLbl.autoresizingMask = [.minYMargin]
        view.addSubview(qLbl)

        qualityPopup = NSPopUpButton(frame: NSRect(x: pad + 56, y: y + 6, width: 170, height: 30), pullsDown: false)
        qualityPopup.addItems(withTitles: ["Best (Auto)"])
        qualityPopup.autoresizingMask = [.minYMargin]
        view.addSubview(qualityPopup)

        let fLbl = mkLabel("Format", size: 12, bold: true, color: Theme.txt2)
        fLbl.frame = NSRect(x: pad + 250, y: y + 14, width: 55, height: 16)
        fLbl.autoresizingMask = [.minYMargin]
        view.addSubview(fLbl)

        formatPopup = NSPopUpButton(frame: NSRect(x: pad + 306, y: y + 6, width: 170, height: 30), pullsDown: false)
        formatPopup.addItems(withTitles: ["MP4 (Video)", "WebM (Video)", "MP3 (Audio)", "M4A (Audio)"])
        formatPopup.target = self; formatPopup.action = #selector(formatChanged)
        formatPopup.autoresizingMask = [.minYMargin]
        view.addSubview(formatPopup)

        // ── Save Location ──
        y -= 44
        let saveLbl = mkLabel("Save to", size: 12, bold: true, color: Theme.txt2)
        saveLbl.frame = NSRect(x: pad, y: y + 8, width: 52, height: 16)
        saveLbl.autoresizingMask = [.minYMargin]
        view.addSubview(saveLbl)

        savePathLbl = mkLabel(savePath, size: 12, bold: false, color: Theme.txt2)
        savePathLbl.frame = NSRect(x: pad + 54, y: y + 2, width: cw - 150, height: 28)
        savePathLbl.lineBreakMode = .byTruncatingMiddle
        savePathLbl.wantsLayer = true
        savePathLbl.layer?.backgroundColor = Theme.cardBg.cgColor
        savePathLbl.layer?.cornerRadius = 6
        savePathLbl.autoresizingMask = [.width, .minYMargin]
        view.addSubview(savePathLbl)

        let browseBtn = mkButton("Browse", rect: NSRect(x: vw - pad - 80, y: y + 2, width: 80, height: 28),
                                 bg: Theme.cardBg, fg: Theme.txt1)
        browseBtn.layer?.borderWidth = 1; browseBtn.layer?.borderColor = Theme.border.cgColor
        browseBtn.autoresizingMask = [.minXMargin, .minYMargin]
        browseBtn.target = self; browseBtn.action = #selector(browsePressed)
        view.addSubview(browseBtn)

        // ── Download Button ──
        y -= 56
        dlBtn = mkButton("⬇  Download", rect: NSRect(x: pad, y: y, width: cw, height: 46),
                         bg: Theme.accent, fg: .white)
        dlBtn.font = NSFont.boldSystemFont(ofSize: 16)
        dlBtn.autoresizingMask = [.width, .minYMargin]
        dlBtn.target = self; dlBtn.action = #selector(downloadPressed)
        view.addSubview(dlBtn)

        // ── Progress ──
        y -= 36
        progressBar = NSProgressIndicator(frame: NSRect(x: pad, y: y + 20, width: cw, height: 6))
        progressBar.style = .bar; progressBar.isIndeterminate = false
        progressBar.minValue = 0; progressBar.maxValue = 100; progressBar.doubleValue = 0
        progressBar.autoresizingMask = [.width, .minYMargin]
        progressBar.isHidden = true
        view.addSubview(progressBar)

        progressLbl = mkLabel("Ready", size: 12, bold: false, color: Theme.txt3)
        progressLbl.frame = NSRect(x: pad, y: y - 2, width: cw, height: 18)
        progressLbl.autoresizingMask = [.width, .minYMargin]
        view.addSubview(progressLbl)

        // ── Log Area ──
        y -= 28
        let logLbl = mkLabel("Output Log", size: 11, bold: true, color: Theme.txt3)
        logLbl.frame = NSRect(x: pad, y: y, width: 100, height: 14)
        logLbl.autoresizingMask = [.minYMargin]
        view.addSubview(logLbl)

        y -= 6
        logScroll = NSScrollView(frame: NSRect(x: pad, y: 16, width: cw, height: y - 16))
        logScroll.hasVerticalScroller = true; logScroll.autohidesScrollers = true
        logScroll.borderType = .noBorder; logScroll.drawsBackground = false
        logScroll.wantsLayer = true
        logScroll.layer?.cornerRadius = 8
        logScroll.layer?.backgroundColor = NSColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1).cgColor
        logScroll.layer?.borderWidth = 1; logScroll.layer?.borderColor = Theme.border.cgColor
        logScroll.autoresizingMask = [.width, .height]

        logView = NSTextView(frame: logScroll.bounds)
        logView.isEditable = false; logView.isSelectable = true
        logView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        logView.textColor = Theme.logGreen
        logView.backgroundColor = NSColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1)
        logView.isVerticallyResizable = true; logView.isHorizontallyResizable = false
        logView.autoresizingMask = [.width]
        logView.textContainerInset = NSSize(width: 10, height: 10)
        logView.textContainer?.widthTracksTextView = true
        logScroll.documentView = logView
        view.addSubview(logScroll)

        // ── Version Label ──
        let verLbl = mkLabel("v1.0.0", size: 10, bold: false, color: Theme.txt3)
        verLbl.frame = NSRect(x: vw - pad - 50, y: 12, width: 50, height: 14)
        verLbl.alignment = .right
        verLbl.autoresizingMask = [.minXMargin, .maxYMargin]
        view.addSubview(verLbl)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: UI Helpers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func mkLabel(_ text: String, size: CGFloat, bold: Bool, color: NSColor) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
        l.textColor = color; l.isBezeled = false; l.drawsBackground = false
        l.isEditable = false; l.isSelectable = false
        return l
    }

    private func mkCard(_ frame: NSRect) -> NSView {
        let v = NSView(frame: frame); v.wantsLayer = true
        v.layer?.backgroundColor = Theme.cardBg.cgColor
        v.layer?.cornerRadius = 12
        v.layer?.borderWidth = 1; v.layer?.borderColor = Theme.border.cgColor
        return v
    }

    private func mkButton(_ title: String, rect: NSRect, bg: NSColor, fg: NSColor) -> NSButton {
        let b = NSButton(frame: rect); b.title = title
        b.bezelStyle = .rounded; b.isBordered = false
        b.wantsLayer = true; b.layer?.backgroundColor = bg.cgColor
        b.layer?.cornerRadius = 8; b.contentTintColor = fg
        b.font = NSFont.boldSystemFont(ofSize: 13)
        return b
    }

    private func appendLog(_ text: String) {
        logView.textStorage?.append(NSAttributedString(string: text, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: Theme.logGreen
        ]))
        logView.scrollToEndOfDocument(nil)
    }

    private func appendLogErr(_ text: String) {
        logView.textStorage?.append(NSAttributedString(string: text, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: Theme.error
        ]))
        logView.scrollToEndOfDocument(nil)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: Fetch
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    @objc private func fetchPressed() {
        let url = urlField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else {
            showAlert("No URL", "Please paste a video URL first."); return
        }
        guard !isFetching else { return }

        guard let ytdlp = findYtDlp() else {
            showAlert("yt-dlp Not Found",
                "Unidown requires yt-dlp.\n\nInstall with:\n  brew install yt-dlp ffmpeg")
            return
        }

        // Reset preview
        setFetching(true)
        logView.string = ""
        fetchedURL = url
        placeholderLbl.stringValue = "⏳ Fetching video info..."
        placeholderLbl.isHidden = false
        thumbView.isHidden = true; vidTitleLbl.isHidden = true
        vidInfoLbl.isHidden = true; platformLbl.isHidden = true
        thumbView.image = nil
        progressLbl.stringValue = "Fetching..."

        let (pName, pColor) = platformInfo(url)
        appendLog("🔗 Fetching from \(pName): \(url)\n")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runFetch(url: url, ytdlp: ytdlp, platform: pName, pColor: pColor)
        }
    }

    private func runFetch(url: String, ytdlp: String, platform: String, pColor: NSColor) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlp)
        process.arguments = ["--dump-json", "--no-download", "--no-warnings", "--no-playlist", url]
        var env = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:\(home)/.local/bin:" + (env["PATH"] ?? "")
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe; process.standardError = Pipe()

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            guard process.terminationStatus == 0,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { [weak self] in
                    self?.appendLogErr("❌ Failed to fetch video info. Check the URL.\n")
                    self?.placeholderLbl.stringValue = "❌ Could not fetch video info. Check the URL and try again."
                    self?.setFetching(false)
                    self?.progressLbl.stringValue = "Fetch failed"
                }
                return
            }

            // Extract data
            let title = json["title"] as? String ?? "Unknown Title"
            let duration = json["duration"] as? Int ?? (json["duration"] as? Double).map { Int($0) } ?? 0
            let thumbURL = json["thumbnail"] as? String ?? ""
            let formats = json["formats"] as? [[String: Any]] ?? []

            // Gather available heights
            var heights = Set<Int>()
            for f in formats {
                let vc = f["vcodec"] as? String ?? "none"
                if vc != "none", let h = f["height"] as? Int, h > 0 { heights.insert(h) }
            }
            let sortedHeights = heights.sorted(by: >)

            // Download thumbnail
            var thumbImage: NSImage?
            if let tURL = URL(string: thumbURL) {
                if let tData = try? Data(contentsOf: tURL) {
                    thumbImage = NSImage(data: tData)
                }
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.appendLog("✅ Found: \(title)\n")
                self.appendLog("   Duration: \(fmtDuration(duration)) • Formats: \(formats.count)\n\n")

                // Show preview
                self.placeholderLbl.isHidden = true
                self.thumbView.image = thumbImage
                self.thumbView.isHidden = false
                self.vidTitleLbl.stringValue = title
                self.vidTitleLbl.isHidden = false
                self.vidInfoLbl.stringValue = "Duration: \(fmtDuration(duration)) • \(formats.count) formats available"
                self.vidInfoLbl.isHidden = false
                self.platformLbl.stringValue = "  \(platform)  "
                self.platformLbl.textColor = pColor
                self.platformLbl.layer?.backgroundColor = pColor.withAlphaComponent(0.15).cgColor
                self.platformLbl.isHidden = false

                // Populate quality dropdown
                self.availableHeights = sortedHeights
                self.qualityPopup.removeAllItems()
                self.qualityPopup.addItem(withTitle: "Best (Auto)")
                for h in sortedHeights {
                    self.qualityPopup.addItem(withTitle: heightLabel(h))
                }

                self.setFetching(false)
                self.progressLbl.stringValue = "Ready to download"
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.appendLogErr("❌ Error: \(error.localizedDescription)\n")
                self?.placeholderLbl.stringValue = "❌ Error fetching video info."
                self?.setFetching(false)
                self?.progressLbl.stringValue = "Error"
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: Format Changed
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    @objc private func formatChanged() {
        let sel = formatPopup.titleOfSelectedItem ?? ""
        let isAudio = sel.contains("Audio")
        qualityPopup.isEnabled = !isAudio
        if isAudio { qualityPopup.selectItem(at: 0) }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: Browse
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    @objc private func browsePressed() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true; panel.canChooseFiles = false
        panel.canCreateDirectories = true; panel.prompt = "Select Folder"
        panel.directoryURL = URL(fileURLWithPath: savePath)
        if panel.runModal() == .OK, let url = panel.url {
            savePath = url.path
            savePathLbl.stringValue = savePath
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: Download
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    @objc private func downloadPressed() {
        if isDownloading {
            currentProcess?.terminate(); currentProcess = nil
            setDownloading(false)
            appendLogErr("\n⛔ Download cancelled.\n")
            progressLbl.stringValue = "Cancelled"
            return
        }

        guard !fetchedURL.isEmpty else {
            showAlert("No Video", "Please fetch a video first before downloading."); return
        }
        guard let ytdlp = findYtDlp() else {
            showAlert("yt-dlp Not Found", "Install with: brew install yt-dlp ffmpeg"); return
        }

        setDownloading(true)
        progressBar.doubleValue = 0
        progressBar.isHidden = false
        progressLbl.stringValue = "Starting download..."
        appendLog("⬇ Starting download...\n")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runDownload(ytdlp: ytdlp)
        }
    }

    private func runDownload(ytdlp: String) {
        let url = fetchedURL
        let selFormat = formatPopup.titleOfSelectedItem ?? "MP4 (Video)"
        let selQuality = qualityPopup.titleOfSelectedItem ?? "Best (Auto)"
        let dest = savePath

        var args: [String] = []

        if selFormat.contains("MP3") {
            args += ["-x", "--audio-format", "mp3"]
            main { self.appendLog("   Format: MP3 (Audio Only)\n") }
        } else if selFormat.contains("M4A") {
            args += ["-x", "--audio-format", "m4a"]
            main { self.appendLog("   Format: M4A (Audio Only)\n") }
        } else {
            let ext = selFormat.contains("WebM") ? "webm" : "mp4"
            if selQuality == "Best (Auto)" {
                args += ["-f", "bv*+ba/b"]
            } else {
                let h = extractHeight(selQuality)
                args += ["-f", "bv*[height<=\(h)]+ba/b[height<=\(h)]"]
            }
            args += ["--merge-output-format", ext]
            main { self.appendLog("   Format: \(ext.uppercased()) • Quality: \(selQuality)\n") }
        }

        args += ["--embed-metadata", "--embed-thumbnail", "--newline",
                 "-o", "\(dest)/%(title)s.%(ext)s", url]

        main { self.appendLog("   Save to: \(dest)\n\n") }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlp)
        process.arguments = args
        var env = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:\(home)/.local/bin:" + (env["PATH"] ?? "")
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe; process.standardError = pipe
        self.currentProcess = process

        let handle = pipe.fileHandleForReading
        handle.readabilityHandler = { [weak self] fh in
            let data = fh.availableData
            guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self?.handleOutputLine(line)
            }
        }

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            main { [weak self] in
                self?.appendLogErr("❌ Failed to start: \(error.localizedDescription)\n")
                self?.setDownloading(false)
                self?.progressLbl.stringValue = "Error"
            }
            return
        }

        handle.readabilityHandler = nil
        let remaining = handle.readDataToEndOfFile()
        if let r = String(data: remaining, encoding: .utf8), !r.isEmpty {
            main { self.handleOutputLine(r) }
        }

        let code = process.terminationStatus
        main { [weak self] in
            guard let self = self else { return }
            if code == 0 {
                self.progressBar.doubleValue = 100
                self.appendLog("\n✅ Download complete!\n")
                self.progressLbl.stringValue = "Complete — saved to \(dest)"
                self.progressLbl.textColor = Theme.success
                // Show success notification
                let notif = NSUserNotification()
                notif.title = "Unidown"
                notif.informativeText = "Download complete!"
                NSUserNotificationCenter.default.deliver(notif)
            } else if code == 15 {
                self.progressLbl.stringValue = "Cancelled"
            } else {
                self.appendLogErr("\n❌ Download failed (exit code \(code))\n")
                self.progressLbl.stringValue = "Failed"
                self.progressLbl.textColor = Theme.error
            }
            self.setDownloading(false)
            self.currentProcess = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                self.progressLbl.textColor = Theme.txt3
            }
        }
    }

    private func handleOutputLine(_ text: String) {
        appendLog(text)
        // Parse progress: [download]  45.2% of ...
        for line in text.components(separatedBy: .newlines) {
            if line.contains("[download]") && line.contains("%") {
                if let range = line.range(of: #"(\d+\.?\d*)%"#, options: .regularExpression) {
                    let pctStr = String(line[range]).replacingOccurrences(of: "%", with: "")
                    if let pct = Double(pctStr) {
                        progressBar.doubleValue = pct
                        // Extract speed and ETA
                        var info = String(format: "%.1f%%", pct)
                        if let sRange = line.range(of: #"at\s+\S+"#, options: .regularExpression) {
                            let speed = String(line[sRange]).replacingOccurrences(of: "at ", with: "").trimmingCharacters(in: .whitespaces)
                            info += " • \(speed)"
                        }
                        if let eRange = line.range(of: #"ETA\s+\S+"#, options: .regularExpression) {
                            let eta = String(line[eRange]).replacingOccurrences(of: "ETA ", with: "").trimmingCharacters(in: .whitespaces)
                            info += " • ETA \(eta)"
                        }
                        progressLbl.stringValue = info
                    }
                }
            } else if line.contains("[Merger]") || line.contains("Merging") {
                progressLbl.stringValue = "Merging audio + video..."
                progressBar.isIndeterminate = true; progressBar.startAnimation(nil)
            } else if line.contains("[EmbedThumbnail]") || line.contains("Embedding") {
                progressLbl.stringValue = "Embedding metadata..."
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: State Helpers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func setFetching(_ active: Bool) {
        isFetching = active
        fetchBtn.title = active ? "Fetching..." : "Fetch"
        fetchBtn.isEnabled = !active
        urlField.isEnabled = !active
        if active {
            progressBar.isIndeterminate = true; progressBar.isHidden = false
            progressBar.startAnimation(nil)
        } else {
            progressBar.stopAnimation(nil)
            progressBar.isIndeterminate = false; progressBar.isHidden = true
        }
    }

    private func setDownloading(_ active: Bool) {
        isDownloading = active
        dlBtn.title = active ? "✕  Cancel Download" : "⬇  Download"
        dlBtn.layer?.backgroundColor = active ? Theme.error.withAlphaComponent(0.85).cgColor : Theme.accent.cgColor
        fetchBtn.isEnabled = !active
        urlField.isEnabled = !active
        formatPopup.isEnabled = !active
        qualityPopup.isEnabled = !active && !(formatPopup.titleOfSelectedItem ?? "").contains("Audio")
        if !active {
            progressBar.stopAnimation(nil)
            progressBar.isIndeterminate = false
        }
    }

    private func extractHeight(_ q: String) -> Int {
        if q.contains("4K") || q.contains("2160") { return 2160 }
        if q.contains("1440") { return 1440 }
        if q.contains("1080") { return 1080 }
        if q.contains("720") { return 720 }
        if q.contains("480") { return 480 }
        if q.contains("360") { return 360 }
        if q.contains("240") { return 240 }
        if q.contains("144") { return 144 }
        return 9999
    }

    private func showAlert(_ title: String, _ msg: String) {
        let a = NSAlert(); a.messageText = title; a.informativeText = msg
        a.alertStyle = .warning; a.addButton(withTitle: "OK"); a.runModal()
    }

    private func main(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }

    @objc private func aboutPressed() {
        let text = "Unidown v1.0.0\n\nA universal video downloader powered by yt-dlp.\nDeveloped by Siyabonga Majaha Dlamini\nSocial: lugal_siyabonga\n\nThank you for your support!"
        let alert = NSAlert()
        alert.messageText = "About Unidown"
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Close")
        alert.runModal()
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Entry Point
// ═══════════════════════════════════════════════════════════════

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
