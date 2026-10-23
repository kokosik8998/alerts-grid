// AlertsGrid — 4 карти повітряних тривог у сітці 2×2 в одному вікні.
// Кожна карта це WKWebView (справжній top-level контекст), тож X-Frame-Options
// та CSP frame-ancestors на неї НЕ діють — працюють усі 4 сайти.
//
// Запуск:   swift AlertsGrid.swift
// Збірка:   див. build.sh (робить AlertsGrid.app для подвійного кліку)

import Cocoa
import WebKit

// Перетворює CSS-текст на безпечний JS-рядковий літерал (з лапками та екрануванням).
func cssStringLiteral(_ s: String) -> String {
    let data = try! JSONSerialization.data(withJSONObject: [s])   // ["..."]
    let json = String(data: data, encoding: .utf8)!               // ["\"...\""]
    return String(json.dropFirst().dropLast())                    // лишаємо сам літерал у лапках
}

// Список карт: назва + URL + CSS для приховування зайвих елементів (порожній рядок — нічого не ховати).
// Щоб знайти селектор: відкрий сайт у Safari → ПКМ на елементі → «Інспектувати».
let MAPS: [(name: String, url: String, css: String)] = [
    ("КОНТУР",        "https://kontur.systems/",       ""),
    ("UkraineAlarm",  "https://map.ukrainealarm.com/", ".header, .bottom-banner { display: none !important; }"),
    ("War-Monitor",   "http://map.war-monitor.org",    ""),
    ("UA Radar",      "https://www.ua-radar.online/",  ""),
]

// Межі масштабу карт.
let ZMIN: CGFloat = 0.3, ZMAX: CGFloat = 2.0, ZSTEP: CGFloat = 0.1

// Одна панель: тонкий заголовок (назва + масштаб + оновлення) та веб-в'ю під ним.
final class Pane: NSView {
    let web: WKWebView
    let url: URL
    let mapName: String
    var zoom: CGFloat
    let pct: NSTextField

    init(title: String, urlString: String, css: String = "") {
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .default()          // зберігає куки/логіни між запусками

        // Впорскуємо CSS, що ховає зайві банери. <style> лишається в DOM і діє
        // навіть на елементи, які сайт додасть пізніше.
        if !css.isEmpty {
            let js = """
            (function(){
              var s = document.createElement('style');
              s.textContent = \(cssStringLiteral(css));
              (document.head || document.documentElement).appendChild(s);
            })();
            """
            let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            cfg.userContentController.addUserScript(script)
        }

        self.web = WKWebView(frame: .zero, configuration: cfg)
        self.url = URL(string: urlString)!
        self.mapName = title

        // Відновлюємо збережений масштаб (UserDefaults), інакше 100%.
        let saved = UserDefaults.standard.object(forKey: "zoom:\(title)") as? Double
        self.zoom = {
            if let v = saved.map({ CGFloat($0) }), v >= ZMIN, v <= ZMAX { return v }
            return 1
        }()
        self.pct = NSTextField(labelWithString: "100%")

        super.init(frame: .zero)

        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        // Заголовок
        let header = NSView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.wantsLayer = true
        header.layer?.backgroundColor = NSColor(white: 0.10, alpha: 1).cgColor

        let label = NSTextField(labelWithString: title)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        // Подвійний клік по назві — скинути масштаб на 100%.
        let dbl = NSClickGestureRecognizer(target: self, action: #selector(resetZoom))
        dbl.numberOfClicksRequired = 2
        label.addGestureRecognizer(dbl)

        func makeButton(_ t: String, _ sel: Selector, _ size: CGFloat) -> NSButton {
            let b = NSButton(title: t, target: self, action: sel)
            b.bezelStyle = .inline
            b.isBordered = false
            b.contentTintColor = .white
            b.font = .systemFont(ofSize: size)
            b.setContentHuggingPriority(.required, for: .horizontal)
            return b
        }
        let minus  = makeButton("−", #selector(zoomOutTapped), 15)
        let plus   = makeButton("+", #selector(zoomInTapped), 15)
        let reload = makeButton("⟳", #selector(reloadTapped), 14)

        pct.font = .systemFont(ofSize: 10)
        pct.textColor = NSColor(white: 0.65, alpha: 1)
        pct.alignment = .center

        // Праворуч — група керування.
        let controls = NSStackView(views: [minus, pct, plus, reload])
        controls.orientation = .horizontal
        controls.spacing = 2
        controls.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(label)
        header.addSubview(controls)

        web.translatesAutoresizingMaskIntoConstraints = false
        web.allowsBackForwardNavigationGestures = true

        addSubview(header)
        addSubview(web)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor),
            header.leadingAnchor.constraint(equalTo: leadingAnchor),
            header.trailingAnchor.constraint(equalTo: trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 26),

            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 10),
            label.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: controls.leadingAnchor, constant: -6),

            controls.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -6),
            controls.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            pct.widthAnchor.constraint(equalToConstant: 34),

            web.topAnchor.constraint(equalTo: header.bottomAnchor),
            web.leadingAnchor.constraint(equalTo: leadingAnchor),
            web.trailingAnchor.constraint(equalTo: trailingAnchor),
            web.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        applyZoom()                      // застосувати відновлений масштаб + оновити %
        web.load(URLRequest(url: url))
    }

    required init?(coder: NSCoder) { fatalError() }

    func applyZoom() {
        web.pageZoom = zoom
        pct.stringValue = "\(Int((zoom * 100).rounded()))%"
    }

    func setZoom(_ z: CGFloat) {
        zoom = min(ZMAX, max(ZMIN, (z * 100).rounded() / 100))
        applyZoom()
        UserDefaults.standard.set(Double(zoom), forKey: "zoom:\(mapName)")
    }

    @objc func reloadTapped() { web.reload() }
    @objc func zoomInTapped()  { setZoom(zoom + ZSTEP) }
    @objc func zoomOutTapped() { setZoom(zoom - ZSTEP) }
    @objc func resetZoom()     { setZoom(1) }
    func reload() { web.reload() }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var panes: [Pane] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        let rect = NSRect(x: 0, y: 0, width: 1600, height: 1000)
        window = NSWindow(contentRect: rect,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Карти повітряних тривог"
        window.center()

        panes = MAPS.map { Pane(title: $0.name, urlString: $0.url, css: $0.css) }

        // Сітка 2×2: два горизонтальних ряди в одному вертикальному стеку.
        func row(_ a: Pane, _ b: Pane) -> NSStackView {
            let s = NSStackView(views: [a, b])
            s.orientation = .horizontal
            s.distribution = .fillEqually
            s.spacing = 1
            return s
        }
        let grid = NSStackView(views: [row(panes[0], panes[1]), row(panes[2], panes[3])])
        grid.orientation = .vertical
        grid.distribution = .fillEqually
        grid.spacing = 1
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.wantsLayer = true
        grid.layer?.backgroundColor = NSColor.black.cgColor

        let content = window.contentView!
        content.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            grid.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])

        buildMenu()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // Меню з ⌘R (оновити всі) та ⌘Q.
    func buildMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Оновити всі", action: #selector(reloadAll), keyEquivalent: "r")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Збільшити всі", action: #selector(zoomInAll), keyEquivalent: "=")
        appMenu.addItem(withTitle: "Зменшити всі", action: #selector(zoomOutAll), keyEquivalent: "-")
        appMenu.addItem(withTitle: "Скинути масштаб", action: #selector(zoomResetAll), keyEquivalent: "0")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Вийти", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = mainMenu
    }

    @objc func reloadAll() { panes.forEach { $0.reload() } }
    @objc func zoomInAll()  { panes.forEach { $0.setZoom($0.zoom + ZSTEP) } }
    @objc func zoomOutAll() { panes.forEach { $0.setZoom($0.zoom - ZSTEP) } }
    @objc func zoomResetAll() { panes.forEach { $0.setZoom(1) } }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
