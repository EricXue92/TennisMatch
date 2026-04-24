//
//  Typography.swift
//  TennisMatch
//

import SwiftUI

/// 使用系統文字樣式以支援 Dynamic Type（無障礙字體縮放）。
/// 預設大小與舊版硬編碼一致，但會隨系統設定自動調整。
enum Typography {
    // MARK: - 基礎樣式
    static let title      = Font.system(.title2, weight: .bold)       // ~22pt bold
    static let subtitle   = Font.system(.subheadline)                 // ~15pt
    static let body       = Font.system(.body, weight: .bold)         // ~17pt bold
    static let navTitle   = Font.system(.headline)                    // ~17pt bold
    static let button     = Font.system(.callout, weight: .bold)      // ~16pt bold
    static let caption    = Font.system(.footnote)                    // ~13pt
    static let codeDigit  = Font.system(.title2, weight: .medium)     // ~22pt
    static let fieldLabel = Font.system(.caption2)                    // ~11pt
    static let fieldValue = Font.system(.subheadline)                 // ~15pt
    static let small      = Font.system(.caption)                     // ~12pt

    // MARK: - 擴展樣式（覆蓋常見 size/weight 組合）
    /// 卡片內文、列表說明（替代 14pt medium，最常見的硬編碼樣式）
    static let bodyMedium     = Font.system(.subheadline, weight: .medium)  // ~15pt medium
    /// 區塊標題（替代 14pt/13pt semibold）
    static let labelSemibold  = Font.system(.subheadline, weight: .semibold) // ~15pt semibold
    /// 頁面副標題（替代 18pt semibold）
    static let sectionTitle   = Font.system(.body, weight: .semibold)       // ~17pt semibold
    /// 按鈕/選項文字（替代 16pt medium）
    static let buttonMedium   = Font.system(.callout, weight: .medium)      // ~16pt medium
    /// 輔助標籤（替代 13pt medium）
    static let captionMedium  = Font.system(.footnote, weight: .medium)     // ~13pt medium
    /// 小標籤/tag（替代 12pt medium）
    static let smallMedium    = Font.system(.caption, weight: .medium)      // ~12pt medium
    /// 極小標籤/badge（替代 11pt medium, 10pt medium）
    static let micro          = Font.system(.caption2, weight: .medium)     // ~11pt medium
    /// 大統計數字（替代 20pt bold）
    static let largeStat      = Font.system(.title3, weight: .bold)         // ~20pt bold
    /// 超大數字（替代 36pt+ bold）
    static let heroStat       = Font.system(.largeTitle, weight: .bold)     // ~34pt bold
}
