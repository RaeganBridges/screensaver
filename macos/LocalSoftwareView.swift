import AppKit
import ScreenSaver
import WebKit

@objc(LocalSoftwareView)
public final class LocalSoftwareView: ScreenSaverView, WKNavigationDelegate {
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
        wv.navigationDelegate = self
        addSubview(wv)
        webView = wv

        loadScreensaver()
    }

    private func loadScreensaver() {
        let bundle = Bundle(for: type(of: self))
        guard let htmlURL = bundle.url(forResource: "index", withExtension: "html") else {
            showFallback()
            return
        }
        let resourceRoot = bundle.bundleURL
        webView?.loadFileURL(htmlURL, allowingReadAccessTo: resourceRoot)
    }

    private func showFallback() {
        let fallbackHTML = """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <style>
            html, body {
              margin: 0;
              width: 100%;
              height: 100%;
              background: linear-gradient(135deg, #050c1f 0%, #092556 30%, #1363a2 60%, #48a8d6 85%, #c4f1f7 100%);
            }
          </style>
        </head>
        <body></body>
        </html>
        """
        webView?.loadHTMLString(fallbackHTML, baseURL: nil)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("LocalSoftwareView navigation failed: %@", error.localizedDescription)
        showFallback()
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("LocalSoftwareView provisional navigation failed: %@", error.localizedDescription)
        showFallback()
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
