import SwiftUI
import WebKit

struct ContentView: View {
    @ObservedObject var server: LocalHTTPServer

    @State private var showSelfCheck = false

    var body: some View {
        ZStack {
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

            // ── 自检入口：右下角实心按钮，单击打开 ──
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        laramgr.shared.logmsg("[ui] 自检按钮点击")
                        showSelfCheck = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "stethoscope")
                                .font(.system(size: 14, weight: .bold))
                            Text("自检")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.95, green: 0.35, blue: 0.10))
                                .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
                        )
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.45), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 16)
                    .padding(.bottom, 96)   // 避开底部手势条
                }
            }
        }
        .sheet(isPresented: $showSelfCheck) {
            SelfCheckView()
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
