//
//  LocaleManager.swift
//  TennisMatch
//
//  全域語言偏好管理 — @Observable，持久化於 UserDefaults
//

import Foundation
import SwiftUI

@Observable
final class LocaleManager {
    static let shared = LocaleManager()

    enum AppLanguage: String, CaseIterable, Identifiable {
        case system
        case zhHans
        case zhHant
        case en

        var id: String { rawValue }
    }

    /// 用戶選擇的語言偏好（持久化）
    var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: Self.storageKey)
        }
    }

    /// 當前生效的 Locale —— 注入到 SwiftUI \.locale 環境
    var currentLocale: Locale {
        switch selectedLanguage {
        case .system: return .autoupdatingCurrent
        case .zhHans: return Locale(identifier: "zh-Hans")
        case .zhHant: return Locale(identifier: "zh-Hant")
        case .en:     return Locale(identifier: "en")
        }
    }

    private static let storageKey = "appLanguage"

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppLanguage.system.rawValue
        self.selectedLanguage = AppLanguage(rawValue: raw) ?? .system
    }
}
