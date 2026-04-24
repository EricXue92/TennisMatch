//
//  ToastModifier.swift
//  TennisMatch
//
//  統一 Toast 浮層 — 取代各頁面重複的 toast overlay 實現
//

import SwiftUI

/// 統一的 Toast 浮層修飾器。
/// 用法：`.toast($toastMessage)` 即可替代手動 overlay。
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var duration: TimeInterval
    var icon: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let msg = message {
                    HStack(spacing: Spacing.xs) {
                        if let icon {
                            Image(systemName: icon)
                                .foregroundColor(.white)
                        }
                        Text(msg)
                            .font(Typography.bodyMedium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Capsule().fill(Theme.textDeep.opacity(0.92)))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, Spacing.lg)
                    .task(id: msg) {
                        try? await Task.sleep(for: .seconds(duration))
                        withAnimation { message = nil }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: message)
    }
}

extension View {
    /// 顯示統一風格的頂部 Toast 浮層。
    func toast(_ message: Binding<String?>, duration: TimeInterval = 2.0, icon: String? = nil) -> some View {
        modifier(ToastModifier(message: message, duration: duration, icon: icon))
    }
}
