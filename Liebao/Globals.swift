//
//  Globals.swift
//  原 lara.swift 里的全局符号（该文件含 @main，已从本工程移除）
//  这里补齐仍被其它文件引用的部分。
//

import Foundation

/// 调试构建标记；dirtyZeroView 用它放宽版本限制
var weonadebugbuild_pjbweouttahereexclamationmark: Bool = false

/// lara 全工程大量使用 `throw "字符串"`，必须让 String 符合 Error
extension String: @retroactive Error {}
