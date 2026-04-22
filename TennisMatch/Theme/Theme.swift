//
//  Theme.swift
//  TennisMatch
//

import SwiftUI

enum Theme {
    // MARK: - Primary
    static let primary       = Color(hex: 0x16A34A)
    static let primaryLight  = Color(hex: 0xE5F5E5)

    // MARK: - Background
    static let background    = Color(hex: 0xF5F7F7)

    // MARK: - Text
    static let textPrimary   = Color(hex: 0x1F2938)
    static let textSecondary = Color(hex: 0x9CA3B0)

    // MARK: - Border
    static let border        = Color(hex: 0xDADFE4)
    static let divider       = Color(hex: 0xE9ECEF)

    // MARK: - Warning
    static let warningBg     = Color(hex: 0xFFF3E0)
    static let warningText   = Color(hex: 0xB48232)

    // MARK: - Chip
    static let chipSelectedBg   = Color(hex: 0xDCF0E1)
    static let chipUnselectedBg = Color(hex: 0xF0F3F5)
    static let chipUnselectedFg = Color(hex: 0x505A64)

    // MARK: - Badge
    static let requiredBg    = Color(hex: 0xFFEDED)
    static let requiredText  = Color(hex: 0xE34545)
    static let optionalBg    = Color(hex: 0xF0F5F7)

    // MARK: - Tag
    static let tagBg         = Color(hex: 0xF0F8F3)
    static let tagBorder     = Color(hex: 0xDCE6DE)
    static let slotBg        = Color(hex: 0xF0FDF4)
    static let slotBorder    = Color(red: 0.298, green: 0.686, blue: 0.314, opacity: 0.3)

    // MARK: - Input
    static let inputBg       = Color(hex: 0xF9FAFB)
    static let inputBorder   = Color(hex: 0xE5E7EB)

    // MARK: - Card Text
    static let textDark      = Color(hex: 0x333333)
    static let textHint      = Color(hex: 0x888888)
    static let textMedium    = Color(hex: 0x505050)

    // MARK: - Accent
    static let accentGreen   = Color(hex: 0x4CAF50)
    static let primaryDark   = Color(hex: 0x218C21)

    // MARK: - Gender
    static let genderFemale  = Color(hex: 0xE54D80)
    static let genderMale    = Color(hex: 0x3366E5)

    // MARK: - Body Text
    static let textBody      = Color(hex: 0x4B5563)
    static let textCaption   = Color(hex: 0x6B7280)

    // MARK: - Match Status
    static let confirmedBg   = Color(hex: 0xE7F4EC)
    static let pendingBg     = Color(hex: 0xFEF3E3)
    static let pendingBadge  = Color(hex: 0xEA9319)

    // MARK: - Tournament Create
    static let tournamentBg    = Color(hex: 0xFFF0F0, alpha: 0.3)
    static let selectedCardBg  = Color(hex: 0xECFDF5)

    // MARK: - Neutrals (added for B2-11 theme refactor)
    static let avatarPlaceholder = Color(hex: 0xE0E0E0)
    static let borderMuted       = Color(hex: 0xCCCCCC)
    static let pillBg            = Color(hex: 0xEBEBEB)
    static let chipBg            = Color(hex: 0xF2F2F2)
    static let surfaceMuted      = Color(hex: 0xF3F4F6)
    static let textMuted         = Color(hex: 0x666666)
    static let textFaint         = Color(hex: 0x808080)
    static let textMid           = Color(hex: 0x737373)
    static let textDeep          = Color(hex: 0x4D4D4D)
    static let textDeeper        = Color(hex: 0x262626)
    static let textInk           = Color(hex: 0x1A1A1A)
    static let textSubtle        = Color(hex: 0x8C8C8C)

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
}
