//
//  CalendarToastBanner.swift
//  TennisMatch
//
//  Small transient toast shown at the top of a view after a calendar add attempt.
//  Auto-dismisses ~2.4s after appearing. Binds to an optional String so callers
//  can flip it back to nil themselves or let it fade.
//

import SwiftUI

/// Top-aligned toast banner that renders when `message` is non-nil.
/// Attach via `.overlay(alignment: .top) { calendarToastBanner($state) }`.
/// `systemImage` defaults to the calendar success icon; pass an alternative
/// (e.g. `"exclamationmark.triangle.fill"`) for warnings.
func calendarToastBanner(
    _ message: Binding<String?>,
    systemImage: String = "calendar.badge.checkmark"
) -> some View {
    CalendarToastBanner(message: message, systemImage: systemImage)
}

private struct CalendarToastBanner: View {
    @Binding var message: String?
    let systemImage: String

    var body: some View {
        Group {
            if let text = message {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .semibold))
                    Text(text)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Theme.textDeeper.opacity(0.92))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                .padding(.top, Spacing.md)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: text) {
                    try? await Task.sleep(nanoseconds: 2_400_000_000)
                    withAnimation(.easeOut(duration: 0.25)) {
                        message = nil
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.25), value: message)
    }
}
