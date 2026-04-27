//
//  CreditScoreHistoryView.swift
//  TennisMatch
//
//  信譽積分歷史 — 以 sheet 形式從 ProfileView 進入
//

import SwiftUI

/// 信譽積分變動記錄。正值為加分,負值為扣分。
struct CreditScoreEntry: Identifiable, Hashable {
    let id = UUID()
    let date: String      // e.g. "04/18"
    let delta: Int        // +3 / -5
    let reason: String    // e.g. "完成約球"
    let detail: String    // e.g. "維多利亞公園 · 單打"
}

struct CreditScoreHistoryView: View {
    let currentScore: Int
    let entries: [CreditScoreEntry]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    summaryCard
                    rulesCard
                    historyCard
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xl)
            }
            .background(Theme.background)
            .navigationTitle("信譽積分")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .font(Typography.bodyMedium)
                        .foregroundColor(Theme.primary)
                }
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(spacing: Spacing.xs) {
            Text("\(currentScore)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(Theme.primary)
            Text("當前積分")
                .font(Typography.caption)
                .foregroundColor(Theme.textCaption)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Rules

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("積分規則")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)
            ruleRow(sign: "+", amount: "1", text: "完成一場約球")
            ruleRow(sign: "+", amount: "1", text: "獲得球友好評")
            ruleRow(sign: "-", amount: "1", text: "撤回報名(距開場 2-24 小時)")
            ruleRow(sign: "-", amount: "2", text: "撤回報名(距開場不足 2 小時)")
            ruleRow(sign: "-", amount: "4", text: "確認後取消(距開場不足 4 小時)")
            ruleRow(sign: "-", amount: "5", text: "爽約未到場")

            Divider().padding(.vertical, 4)
            Text("帳號處罰")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)
            HStack(spacing: Spacing.xs) {
                Text("< 70")
                    .font(Typography.captionMedium)
                    .foregroundColor(Theme.requiredText)
                    .frame(width: 40, alignment: .leading)
                Text("禁止發起約球(仍可報名)")
                    .font(Typography.caption)
                    .foregroundColor(Theme.textBody)
            }
            HStack(spacing: Spacing.xs) {
                Text("< 60")
                    .font(Typography.captionMedium)
                    .foregroundColor(Theme.requiredText)
                    .frame(width: 40, alignment: .leading)
                Text("封號 3 個月")
                    .font(Typography.caption)
                    .foregroundColor(Theme.textBody)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func ruleRow(sign: String, amount: String, text: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Text("\(sign)\(amount)")
                .font(Typography.captionMedium)
                .foregroundColor(sign == "+" ? Theme.primary : Theme.requiredText)
                .frame(width: 40, alignment: .leading)
            Text(text)
                .font(Typography.caption)
                .foregroundColor(Theme.textBody)
        }
    }

    // MARK: - History

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("變動記錄")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)
                .padding(.bottom, Spacing.sm)

            if entries.isEmpty {
                Text("暫無變動記錄")
                    .font(Typography.caption)
                    .foregroundColor(Theme.textCaption)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.md)
            } else {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    historyRow(entry)
                    if index < entries.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func historyRow(_ entry: CreditScoreEntry) -> some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.reason)
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textBody)
                Text("\(entry.date) · \(entry.detail)")
                    .font(Typography.fieldLabel)
                    .foregroundColor(Theme.textCaption)
            }
            Spacer()
            Text("\(entry.delta > 0 ? "+" : "")\(entry.delta)")
                .font(Typography.labelSemibold)
                .foregroundColor(entry.delta >= 0 ? Theme.primary : Theme.requiredText)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Mock Data

extension CreditScoreHistoryView {
    /// 示例數據 — demo 階段使用。
    /// `nonisolated` 讓它能用作其他 store 的 default argument(這些 store 在
    /// `@MainActor` 下,但 default-arg 表達式於 caller context 計算)。
    nonisolated static let mockEntries: [CreditScoreEntry] = [
        CreditScoreEntry(date: "04/18", delta: 1, reason: "完成約球", detail: "維多利亞公園 · 單打"),
        CreditScoreEntry(date: "04/15", delta: 1, reason: "獲得好評", detail: "來自莎拉"),
        CreditScoreEntry(date: "04/12", delta: 1, reason: "完成約球", detail: "九龍公園 · 雙打"),
        CreditScoreEntry(date: "04/05", delta: -1, reason: "臨時取消", detail: "距開場 8 小時"),
        CreditScoreEntry(date: "03/28", delta: 1, reason: "完成約球", detail: "維多利亞公園 · 單打"),
        CreditScoreEntry(date: "03/20", delta: 1, reason: "獲得好評", detail: "來自 Tommy"),
    ]
}

// MARK: - Preview

#Preview("iPhone SE") {
    CreditScoreHistoryView(currentScore: 80, entries: CreditScoreHistoryView.mockEntries)
}

#Preview("iPhone 15 Pro") {
    CreditScoreHistoryView(currentScore: 80, entries: CreditScoreHistoryView.mockEntries)
}
