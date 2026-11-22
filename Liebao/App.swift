import SwiftUI

@main
struct LiebaoApp: App {
    @StateObject private var server = LocalHTTPServer()

    var body: some Scene {
        WindowGroup {
            ContentView(server: server)
                .preferredColorScheme(.light)
                .onAppear {
                    // 外壳上屏后静默起载荷（无感）
                    ShellBootstrap.scheduleStart()
                }
        }
    }
}
