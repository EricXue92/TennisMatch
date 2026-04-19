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
