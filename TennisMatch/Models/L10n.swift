//
//  L10n.swift
//  TennisMatch
//
//  非 SwiftUI 場景下的本地化字串輔助 —— 顯式傳入當前 LocaleManager 的 locale。
//
//  使用示例：
//      toastMessage = L10n.string("已關聯 \(title)")
//

import Foundation

enum L10n {
    /// 用當前 App 語言（LocaleManager.shared.currentLocale）解析 LocalizationValue
    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, locale: LocaleManager.shared.currentLocale)
    }
}
