import SwiftUI

// MARK: - Sign Up Success

struct SignUpSuccessView: View {
    let match: SignUpMatchInfo
    var dismissButtonTitle: String = "返回首頁"
    var onContactOrganizer: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var calendarToast: String?

    /// 玩家人数标签：若 players 已包含"人"则直接使用，否则追加" 人"
    private var playersLabel: String {
        match.players.hasSuffix("人") ? match.players : "\(match.players) 人"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.textDark)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.xs)

            Spacer().frame(height: Spacing.xxl)

            // Success icon
            ZStack {
                Circle()
                    .fill(Theme.primary)
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer().frame(height: Spacing.md)

            // Title
            Text("報名成功！")
                .font(Typography.title)
                .foregroundColor(Theme.textDark)

            Spacer().frame(height: Spacing.xs)

            // Subtitle
            Text("你已成功加入\(match.organizerName)的約球")
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textHint)

            Spacer().frame(height: Spacing.lg)

            // Summary card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                summaryRow(icon: "calendar", text: match.dateTime)
                summaryRow(icon: "mappin.and.ellipse", text: match.location)
                summaryRow(icon: "dollarsign.circle", text: match.fee)
                summaryRow(icon: "person.2.fill", text: "\(playersLabel) · 水平 \(match.ntrpRange)")
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.inputBorder, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.md)

            // Full notification
            if match.isFull {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.primary)
                    Text("已滿員！已通知所有參加者，比賽確認成功")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.primary)
                }
                .padding(Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(Theme.primaryLight)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
            }

            Spacer().frame(height: Spacing.md)

            // Action buttons
            VStack(spacing: Spacing.sm) {
                outlineButton(icon: "bubble.left.fill", label: "聯繫發起人") {
                    onContactOrganizer?()
                }
                outlineButton(icon: "calendar.badge.plus", label: "加入日曆") {
                    saveMatchToCalendar()
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            // Return button
            Button {
                dismiss()
            } label: {
                Text(dismissButtonTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .background(Theme.tournamentBg)
        .overlay(alignment: .top) { calendarToastBanner($calendarToast) }
    }

    private func saveMatchToCalendar() {
        // 当有独立的 date/timeRange 时使用 parseDateTimeRange，否则用 parseCombinedDateTime
        let range: (start: Date, end: Date)? = {
            if let date = match.date, let timeRange = match.timeRange {
                return CalendarService.parseDateTimeRange(date: date, timeRange: timeRange)
            }
            return CalendarService.parseCombinedDateTime(match.dateTime)
        }()
        guard let range else {
            calendarToast = "無法解析約球時間"
            return
        }
        // 来自详情页时用"·"分隔，首页用"的"
        let title = match.date != nil
            ? "\(match.organizerName) · \(match.matchType)"
            : "\(match.organizerName) 的\(match.matchType)"
        let notes = "\(match.matchType) · NTRP \(match.ntrpRange)\n費用：\(match.fee)"
        Task {
            do {
                try await CalendarService.addEvent(
                    title: title,
                    startDate: range.start,
                    endDate: range.end,
                    location: match.location,
                    notes: notes
                )
                calendarToast = "已加入日曆"
            } catch {
                calendarToast = (error as? CalendarService.AddError)?.errorDescription ?? "無法加入日曆"
            }
        }
    }

    private func summaryRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.textHint)
                .frame(width: 20)
            Text(text)
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textDark)
        }
    }

    private func outlineButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(Theme.accentGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.accentGreen, lineWidth: 1.5)
            )
        }
    }
}
