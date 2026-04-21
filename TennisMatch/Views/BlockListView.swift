//
//  BlockListView.swift
//  TennisMatch
//
//  封鎖名單
//

import SwiftUI

struct BlockListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var blockedUsers: [BlockedUser] = mockBlockedUsers
    @State private var userToUnblock: BlockedUser?
    @State private var showUnblockAlert = false

    var body: some View {
        VStack(spacing: 0) {
            if blockedUsers.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textSecondary)
                    Text("沒有封鎖的用戶")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(blockedUsers) { user in
                        HStack(spacing: Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(Theme.avatarPlaceholder)
                                    .frame(width: 44, height: 44)
                                Text(String(user.name.prefix(1)))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Theme.textPrimary)
                                Text("封鎖於 \(user.blockedDate)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }

                            Spacer()

                            Button {
                                userToUnblock = user
                                showUnblockAlert = true
                            } label: {
                                Text("解除封鎖")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.textBody)
                                    .padding(.horizontal, Spacing.sm)
                                    .frame(height: 30)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Theme.inputBorder, lineWidth: 1)
                                    }
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("封鎖名單")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .alert("解除封鎖", isPresented: $showUnblockAlert) {
            Button("取消", role: .cancel) { userToUnblock = nil }
            Button("確認解除", role: .destructive) {
                if let user = userToUnblock {
                    withAnimation {
                        blockedUsers.removeAll { $0.id == user.id }
                    }
                }
                userToUnblock = nil
            }
        } message: {
            if let user = userToUnblock {
                Text("確定要解除對「\(user.name)」的封鎖嗎？")
            }
        }
    }
}

// MARK: - Data

private struct BlockedUser: Identifiable {
    let id = UUID()
    let name: String
    let blockedDate: String
}

private let mockBlockedUsers: [BlockedUser] = [
    BlockedUser(name: "張三", blockedDate: "2026/04/10"),
    BlockedUser(name: "李四", blockedDate: "2026/03/25"),
    BlockedUser(name: "陳大文", blockedDate: "2026/02/14"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        BlockListView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        BlockListView()
    }
}
