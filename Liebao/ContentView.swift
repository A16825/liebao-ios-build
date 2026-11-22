import SwiftUI
import WebKit

struct ContentView: View {
    @ObservedObject var server: LocalHTTPServer

    // 自检页入口：左上角 60×60 热区，长按 3 秒
    @State private var showSelfCheck = false

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

            // 隐藏热区：完全透明，不挡外壳任何操作
            Color.clear
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 3.0) {
                    laramgr.shared.logmsg("[ui] 自检入口触发")
                    showSelfCheck = true
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
