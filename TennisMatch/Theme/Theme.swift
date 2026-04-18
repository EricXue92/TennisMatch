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
