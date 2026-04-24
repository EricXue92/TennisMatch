//
//  InviteFriendsView.swift
//  TennisMatch
//
//  邀請好友
//

import SwiftUI

struct InviteFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    private let inviteCode = "LT2026XUE"
    private let inviteLink = "https://letstennis.app/invite/LT2026XUE"

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer().frame(height: Spacing.xl)

            // Illustration
            ZStack {
                Circle()
                    .fill(Theme.primaryLight)
                    .frame(width: 100, height: 100)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.primary)
            }

            Text("邀請好友一起打球")
                .font(Typography.largeStat)
                .foregroundColor(Theme.textPrimary)

            Text("分享你的邀請碼給朋友，一起加入 Let's Tennis")
                .font(Typography.bodyMedium)
                .foregroundColor(Theme.textBody)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            // Invite code card
            VStack(spacing: Spacing.sm) {
                Text("你的邀請碼")
                    .font(Typography.caption)
                    .foregroundColor(Theme.textSecondary)

                Text(inviteCode)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.primary)
                    .tracking(4)

                Button {
                    UIPasteboard.general.string = inviteCode
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(Typography.small)
                        Text("複製邀請碼")
                            .font(Typography.captionMedium)
                    }
                    .foregroundColor(Theme.primary)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
            .padding(.horizontal, Spacing.md)

            Spacer()

            // Share button
            Button {
                showShareSheet = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                        .font(Typography.buttonMedium)
                    Text("分享給朋友")
                        .font(Typography.button)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Typography.buttonMedium)
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("邀請好友")
                    .font(Typography.sectionTitle)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["來 Let's Tennis 一起打網球！我的邀請碼：\(inviteCode)\n\(inviteLink)"])
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        InviteFriendsView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        InviteFriendsView()
    }
}
