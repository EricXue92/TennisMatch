//
//  FollowPlayerRow.swift
//  TennisMatch
//
//  共用的球友列表行 — 替代 FollowingView / FollowerListView / MutualFollowListView 中的重複行組件
//

import SwiftUI

struct FollowPlayerRow: View {
    let player: FollowPlayer

    /// 按鈕文字（如「已關注」「互相關注」「關注」）
    let buttonLabel: String

    /// 按鈕是否使用 outline 樣式（true = 邊框，false = 填充背景）
    let isOutlineStyle: Bool

    /// 點擊按鈕的回調
    var onButtonTap: () -> Void

    /// 點擊整行的回調（導航到公開資料頁）
    var onRowTap: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // 頭像
            ZStack {
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 48, height: 48)
                Text(String(player.name.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            // 名稱 + 資訊
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text(player.gender.symbol)
                        .font(Typography.fieldValue)
                        .foregroundColor(player.gender == .female ? Theme.genderFemale : Theme.genderMale)
                }
                Text("NTRP \(player.ntrp) · \(player.latestActivity)")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            // 關注按鈕
            Button(action: onButtonTap) {
                Text(buttonLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isOutlineStyle ? Theme.textBody : .white)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 30)
                    .background(isOutlineStyle ? .clear : Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        if isOutlineStyle {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.inputBorder, lineWidth: 1)
                        }
                    }
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: onRowTap)
    }
}
