//
//  Theme.swift
//  TennisMatch
//

import SwiftUI
import UIKit

enum Theme {
    // MARK: - Primary (品牌色，不隨模式切換)
    static let primary       = Color(hex: 0x16A34A)
    static let primaryLight  = Color(light: Color(hex: 0xE5F5E5), dark: Color(hex: 0x1A3A24))

    // MARK: - Surface & Background (深色模式核心)
    /// 頁面底層背景
    static let background    = Color(light: Color(hex: 0xF5F7F7), dark: Color(hex: 0x000000))
    /// 卡片/區塊/輸入框背景 — 取代所有 `.background(.white)`
    static let surface       = Color(light: .white, dark: Color(hex: 0x1C1C1E))
    /// 浮層/彈窗背景
    static let surfaceElevated = Color(light: .white, dark: Color(hex: 0x2C2C2E))

    // MARK: - Text
    static let textPrimary   = Color(light: Color(hex: 0x1F2938), dark: Color(hex: 0xF2F2F7))
    static let textSecondary = Color(light: Color(hex: 0x9CA3B0), dark: Color(hex: 0x8E8E93))

    // MARK: - Border
    static let border        = Color(light: Color(hex: 0xDADFE4), dark: Color(hex: 0x3A3A3C))
    static let divider       = Color(light: Color(hex: 0xE9ECEF), dark: Color(hex: 0x38383A))

    // MARK: - Warning
    static let warningBg     = Color(light: Color(hex: 0xFFF3E0), dark: Color(hex: 0x3D2E12))
    static let warningText   = Color(light: Color(hex: 0xB48232), dark: Color(hex: 0xF0C060))

    // MARK: - Chip
    static let chipSelectedBg   = Color(light: Color(hex: 0xDCF0E1), dark: Color(hex: 0x1A3A24))
    static let chipUnselectedBg = Color(light: Color(hex: 0xF0F3F5), dark: Color(hex: 0x2C2C2E))
    static let chipUnselectedFg = Color(light: Color(hex: 0x505A64), dark: Color(hex: 0xAEAEB2))

    // MARK: - Badge
    static let requiredBg    = Color(hex: 0xFFEDED)
    static let requiredText  = Color(hex: 0xE34545)
    static let badge         = requiredText          // 通知小红点
    static let optionalBg    = Color(hex: 0xF0F5F7)

    // MARK: - Tag
    static let tagBg         = Color(light: Color(hex: 0xF0F8F3), dark: Color(hex: 0x1A3A24))
    static let tagBorder     = Color(light: Color(hex: 0xDCE6DE), dark: Color(hex: 0x2D4A34))
    static let slotBg        = Color(light: Color(hex: 0xF0FDF4), dark: Color(hex: 0x1A3A24))
    static let slotBorder    = Color(red: 0.298, green: 0.686, blue: 0.314, opacity: 0.3)

    // MARK: - Input
    static let inputBg       = Color(light: Color(hex: 0xF9FAFB), dark: Color(hex: 0x2C2C2E))
    static let inputBorder   = Color(light: Color(hex: 0xE5E7EB), dark: Color(hex: 0x3A3A3C))

    // MARK: - Card Text
    static let textDark      = Color(light: Color(hex: 0x333333), dark: Color(hex: 0xE5E5EA))
    static let textHint      = Color(light: Color(hex: 0x888888), dark: Color(hex: 0x8E8E93))
    static let textMedium    = Color(light: Color(hex: 0x505050), dark: Color(hex: 0xAEAEB2))

    // MARK: - Accent
    static let accentGreen   = Color(hex: 0x4CAF50)
    static let primaryDark   = Color(hex: 0x218C21)

    // MARK: - Gender
    static let genderFemale  = Color(hex: 0xE54D80)
    static let genderMale    = Color(hex: 0x3366E5)

    // MARK: - Body Text
    static let textBody      = Color(light: Color(hex: 0x4B5563), dark: Color(hex: 0xD1D5DB))
    static let textCaption   = Color(light: Color(hex: 0x6B7280), dark: Color(hex: 0x9CA3AF))

    // MARK: - Match Status
    static let confirmedBg   = Color(light: Color(hex: 0xE7F4EC), dark: Color(hex: 0x1A3A24))
    static let pendingBg     = Color(light: Color(hex: 0xFEF3E3), dark: Color(hex: 0x3D2E12))
    static let pendingBadge  = Color(hex: 0xEA9319)

    // MARK: - Tournament Create
    static let tournamentBg    = Color(light: Color(hex: 0xFFF0F0, alpha: 0.3), dark: Color(hex: 0x3A2020, alpha: 0.3))
    static let selectedCardBg  = Color(light: Color(hex: 0xECFDF5), dark: Color(hex: 0x1A3A24))

    // MARK: - Neutrals
    static let avatarPlaceholder = Color(light: Color(hex: 0xE0E0E0), dark: Color(hex: 0x3A3A3C))
    static let borderMuted       = Color(light: Color(hex: 0xCCCCCC), dark: Color(hex: 0x48484A))
    static let pillBg            = Color(light: Color(hex: 0xEBEBEB), dark: Color(hex: 0x3A3A3C))
    static let chipBg            = Color(light: Color(hex: 0xF2F2F2), dark: Color(hex: 0x2C2C2E))
    static let surfaceMuted      = Color(light: Color(hex: 0xF3F4F6), dark: Color(hex: 0x2C2C2E))
    static let textMuted         = Color(light: Color(hex: 0x666666), dark: Color(hex: 0xAEAEB2))
    static let textFaint         = Color(light: Color(hex: 0x808080), dark: Color(hex: 0x8E8E93))
    static let textMid           = Color(light: Color(hex: 0x737373), dark: Color(hex: 0x9CA3AF))
    static let textDeep          = Color(light: Color(hex: 0x4D4D4D), dark: Color(hex: 0xD1D5DB))
    static let textDeeper        = Color(light: Color(hex: 0x262626), dark: Color(hex: 0xE5E5EA))
    static let textInk           = Color(light: Color(hex: 0x1A1A1A), dark: Color(hex: 0xF2F2F7))
    static let textSubtle        = Color(light: Color(hex: 0x8C8C8C), dark: Color(hex: 0x8E8E93))

    // MARK: - Accents
    static let accentBlue        = Color(hex: 0x2674DD)
    static let accentBlueAlt     = Color(hex: 0x2673DE)
    static let starYellow        = Color(hex: 0xFACC15)
    static let goldText          = Color(hex: 0xCA8A04)
    static let goldBg            = Color(hex: 0xFEF9C3)
    static let primaryEmerald    = Color(hex: 0x26AD61)

    // MARK: - Login Screen
    static let loginBgTop     = Color(red: 0.02, green: 0.04, blue: 0.02)
    static let loginBgMid     = Color(red: 0.04, green: 0.12, blue: 0.06)
    static let loginBgBot     = Color(red: 0.03, green: 0.08, blue: 0.04)
    static let loginChartreuse = Color(red: 0.784, green: 0.902, blue: 0.271)
    static let loginAccentDeep = Color(red: 0.58,  green: 0.70,  blue: 0.16)
    static let loginWechat    = Color(red: 0.07,  green: 0.76,  blue: 0.38)
    static let loginSage      = Color(red: 0.55,  green: 0.67,  blue: 0.56)

    // MARK: - Tournament Card Gradients
    static let gradGreenLight    = Color(hex: 0x34D399)
    static let gradGreenDeep     = Color(hex: 0x059669)
    static let gradGoldLight     = Color(hex: 0xFFF299)
    static let gradGoldDeep      = Color(hex: 0xFFBF4D)
    static let gradAmberLight    = Color(hex: 0xFACC2E)
    static let gradAmberDeep     = Color(hex: 0xF28C1A)
    static let gradSkyLight      = Color(hex: 0x66B2FF)
    static let gradPurpleLight   = Color(hex: 0xA78BFA)
    static let gradPurpleDeep    = Color(hex: 0x7C3AED)
    static let gradGrayLight     = Color(hex: 0x9CA3AF)
    static let gradGrayDeep      = Color(hex: 0x6B7280)
    static let gradPinkLight     = Color(hex: 0xF472B6)
    static let gradPinkDeep      = Color(hex: 0xDB2777)
}

// MARK: - Hex Initializer

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: alpha
        )
    }

    /// 根據淺色/深色模式自動切換顏色
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
