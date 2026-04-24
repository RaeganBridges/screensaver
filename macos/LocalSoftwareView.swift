import AppKit
import ScreenSaver
import WebKit

@objc(LocalSoftwareView)
public final class LocalSoftwareView: ScreenSaverView {
    private var webView: WKWebView?

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        animationTimeInterval = 1.0 / 30.0
        autoresizingMask = [.width, .height]
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        if #available(macOS 11.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        let wv = WKWebView(frame: bounds, configuration: config)
        wv.autoresizingMask = [.width, .height]
        wv.setValue(false, forKey: "drawsBackground")
        addSubview(wv)
        webView = wv

        loadScreensaver()
    }

    private func loadScreensaver() {
        let bundle = Bundle(for: type(of: self))
        guard let htmlURL = bundle.url(forResource: "screensaver", withExtension: "html") else {
            return
        }
        let resourceRoot = htmlURL.deletingLastPathComponent()
        webView?.loadFileURL(htmlURL, allowingReadAccessTo: resourceRoot)
    }

    public override func startAnimation() {
        super.startAnimation()
    }

    public override func stopAnimation() {
        super.stopAnimation()
    }

    public override func animateOneFrame() {
        // CSS keyframes drive the animation; nothing to do per-frame.
    }

    public override var hasConfigureSheet: Bool { false }
    public override var configureSheet: NSWindow? { nil }
}
