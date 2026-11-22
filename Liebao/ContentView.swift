import SwiftUI
import WebKit

struct ContentView: View {
    @ObservedObject var server: LocalHTTPServer

    // 自检入口
    @State private var showSelfCheck = false
    @State private var showTip = false
    @State private var tipFaded = false

    private let tipKey = "yg_selfcheck_tip_shown"

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let port = server.port, let url = URL(string: "http://127.0.0.1:\(port)/index.html") {
                    WebView(url: url)
                        .ignoresSafeArea(.container, edges: .bottom)
                } else {
                    VStack(spacing: 14) {
                        ProgressView()
                        Text("猎豹钩子软件")
                            .font(.headline)
                        Text("正在准备离线工作区…")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                }
            }

            // ── 自检入口：左上角淡色标记，长按 1.5 秒 ──
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    ZStack {
                        // 可点区域（透明但可命中）
                        Color.white.opacity(0.001)
                            .frame(width: 76, height: 76)

                        VStack(spacing: 2) {
                            Text("⋯")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.white.opacity(0.30))
                            Text("自检")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.white.opacity(0.22))
                        }
                    }
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 1.5) {
                        laramgr.shared.logmsg("[ui] 自检入口触发")
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showSelfCheck = true
                    }

                    Spacer()
                }

                if showTip && !tipFaded {
                    Text("长按左上角「⋯」打开自检")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(7)
                        .padding(.leading, 10)
                        .padding(.top, 2)
                        .transition(.opacity)
                }

                Spacer()
            }
            .padding(.top, 4)
        }
        .sheet(isPresented: $showSelfCheck) {
            SelfCheckView()
        }
        .onAppear {
            // 前几次启动给个提示，方便找到入口
            let shown = UserDefaults.standard.integer(forKey: tipKey)
            if shown < 3 {
                showTip = true
                UserDefaults.standard.set(shown + 1, forKey: tipKey)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation(.easeOut(duration: 0.6)) { tipFaded = true }
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
