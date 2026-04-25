import SwiftUI

// MARK: - Sign Up Confirmation

struct SignUpConfirmSheet: View {
    let match: SignUpMatchInfo
    var showNotes: Bool = true
    var onConfirm: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var isSubmitting = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("確認報名")
                .font(Typography.largeStat)
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                infoRow(icon: "calendar", text: match.dateTime)
                infoRow(icon: "mappin.circle.fill", text: match.location)
                infoRow(icon: "figure.tennis", text: "\(match.matchType)  ·  NTRP \(match.ntrpRange)")
                infoRow(icon: "dollarsign.circle.fill", text: match.fee)
                if showNotes {
                    infoRow(icon: "exclamationmark.triangle.fill", text: match.notes)
                }
            }

            Theme.divider.frame(height: 1)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("給發起人留言（選填）")
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textPrimary)

                TextField("例如：我會準時到！", text: $message, axis: .vertical)
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(3...5)
                    .padding(Spacing.sm)
                    .background(Theme.inputBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
                    .disabled(isSubmitting)
            }

            Spacer()

            Button {
                guard !isSubmitting else { return }
                isSubmitting = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                let messageSnapshot = message
                // dismiss + onConfirm 必须在同一帧,但 isSubmitting 已经把按钮 disable
                dismiss()
                onConfirm(messageSnapshot)
            } label: {
                ZStack {
                    Text("確認報名")
                        .font(Typography.button)
                        .foregroundColor(.white)
                        .opacity(isSubmitting ? 0 : 1)

                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSubmitting ? Theme.primary.opacity(0.6) : Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isSubmitting)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(Typography.bodyMedium)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 20)
            Text(text)
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textPrimary)
        }
    }
}
