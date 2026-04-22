//
//  MatchDetailView.swift
//  TennisMatch
//
//  約球詳情頁
//

import SwiftUI

struct MatchDetailView: View {
    let match: MatchDetailData
    @Binding var acceptedMatches: [AcceptedMatchInfo]
    /// IDs of matches the user has signed up for. Bound to HomeView so
    /// signing up here keeps the card and the detail in sync.
    @Binding var signedUpMatchIDs: Set<UUID>
    /// Called when the user confirms sign-up, so the caller can bump the
    /// underlying match's `currentPlayers`. Receives the match id.
    var onSignUp: (UUID) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(FollowStore.self) private var followStore
    @Environment(UserStore.self) private var userStore
    @Environment(BookedSlotStore.self) private var bookedSlotStore
    @State private var showInviteSheet = false
    @State private var showSignUpConfirm = false
    @State private var showSignUpSuccess = false
    @State private var navigateToChat = false
    @State private var pendingContactOrganizer = false
    /// Top toast for time-conflict warnings shown when 報名 overlaps an existing booking.
    @State private var conflictToast: String?

    /// Live participant list (seeded from `match.participantList` on appear,
    /// the current user is appended on sign-up confirm).
    @State private var participants: [MatchParticipant] = []
    /// Live count override — nil means "use the original `match.players`".
    /// Incremented locally on sign-up so the 👥 row reflects the new state.
    @State private var localPlayerCurrent: Int? = nil
    /// Sign-up留言 — carried into the organizer chat as the first outgoing bubble.
    @State private var signUpMessage: String = ""

    private var hasSignedUp: Bool {
        guard let mid = match.matchId else { return false }
        return signedUpMatchIDs.contains(mid)
    }

    private var playersDisplay: String {
        let counts = match.playerCounts
        guard counts.max > 0 else { return match.players }
        let current = localPlayerCurrent ?? counts.current
        return "\(current)/\(counts.max) 人"
    }

    private var displayIsFull: Bool {
        let counts = match.playerCounts
        let current = localPlayerCurrent ?? counts.current
        return counts.max > 0 && current >= counts.max
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    creatorCard
                    weatherCard
                    participantsCard
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, 100)
            }
            .background(Theme.inputBg)

            bottomBar
        }
        .onAppear {
            if participants.isEmpty {
                participants = match.participantList
            }
        }
        .overlay(alignment: .top) {
            calendarToastBanner($conflictToast, systemImage: "exclamationmark.triangle.fill")
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("約球詳情")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }
}

// MARK: - Creator & Info Card

private extension MatchDetailView {
    var creatorCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Creator info
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Theme.avatarPlaceholder)
                        .frame(width: 56, height: 56)
                    Text(String(match.name.prefix(1)))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(match.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text(match.gender == .female ? "♀" : "♂")
                            .font(.system(size: 17))
                            .foregroundColor(match.gender == .female ? Theme.genderFemale : Theme.genderMale)
                    }
                    Text("NTRP \(match.ntrp) · 信譽分 \(match.reputation)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textMuted)
                }

                Spacer()

                Button {
                    withAnimation { followStore.toggle(match.name) }
                } label: {
                    let following = followStore.isFollowing(match.name)
                    Text(following ? "已關注" : "關注")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(following ? .white : Theme.textDark)
                        .frame(width: 60, height: 44)
                        .background(following ? Theme.primary : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay {
                            if !following {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Theme.borderMuted, lineWidth: 1)
                            }
                        }
                }
            }
            .padding(Spacing.md)

            // Divider
            Rectangle()
                .fill(Theme.pillBg)
                .frame(height: 1)
                .padding(.horizontal, Spacing.md)

            // Tags
            HStack(spacing: Spacing.xs) {
                Text(match.matchType)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 24)
                    .background(Theme.primaryDark)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(match.isOwnMatch ? "我發起的" : "招募中")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(match.isOwnMatch ? .white : Theme.textDeep)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 24)
                    .background(match.isOwnMatch ? Theme.accentGreen : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        if !match.isOwnMatch {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.borderMuted, lineWidth: 1)
                        }
                    }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            // Detail rows
            VStack(alignment: .leading, spacing: Spacing.md) {
                detailRow(icon: "📅", title: match.date, subtitle: match.timeRange)
                detailRow(icon: "📍", title: match.location, subtitle: match.district)
                detailRow(icon: "👥", title: playersDisplay, subtitle: "水平範圍: \(match.ntrpRange)")
                detailRow(icon: "💰", title: match.fee, subtitle: nil)
            }
            .padding(Spacing.md)

            // Divider
            Rectangle()
                .fill(Theme.pillBg)
                .frame(height: 1)
                .padding(.horizontal, Spacing.md)

            // Notes
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("備註")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Text(match.notes)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(Spacing.md)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func detailRow(icon: String, title: String, subtitle: String?) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(icon)
                .font(.system(size: 16))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                }
            }
        }
    }
}

// MARK: - Weather Card

private extension MatchDetailView {
    var weatherCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("⛅ 天氣")
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 0) {
                weatherItem(value: match.weather.temp, label: nil)
                weatherItem(value: "💧 \(match.weather.humidity)", label: nil)
                weatherItem(value: "☀️ \(match.weather.uv)", label: "UV")
                weatherItem(value: "💨 \(match.weather.wind)", label: "km/h")
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func weatherItem(value: String, label: String?) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            if let label {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Participants Card

private extension MatchDetailView {
    var participantsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("參加者")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            ForEach(participants, id: \.name) { p in
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Theme.avatarPlaceholder)
                            .frame(width: 36, height: 36)
                        Text(String(p.name.prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(p.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                            Text(p.gender == .female ? "♀" : "♂")
                                .font(.system(size: 14))
                                .foregroundColor(p.gender == .female ? Theme.genderFemale : Theme.genderMale)
                        }
                        Text("NTRP \(p.ntrp)")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textFaint)
                    }

                    Spacer()

                    if p.isOrganizer {
                        Text("發起人")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textMuted)
                            .padding(.horizontal, Spacing.sm)
                            .frame(height: 22)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Theme.borderMuted, lineWidth: 1)
                            }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Bottom Bar

private extension MatchDetailView {
    var bottomBar: some View {
        HStack(spacing: Spacing.sm) {
            if match.isOwnMatch {
                Button {
                    showInviteSheet = true
                } label: {
                    Text("📨 邀請")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.primaryDark)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            } else {
                Button {
                    navigateToChat = true
                } label: {
                    Text("💬 私信")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.primaryDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Theme.primaryDark, lineWidth: 1.5)
                        }
                }

                // Precedence: 已自動取消 > 已報名 > 已過期 > 已額滿 > 報名.
                // - Auto-cancel (expired & under capacity) overrides 已報名 because the match never ran.
                // - Already-signed-up takes priority next: the slot is already booked
                //   from this user's perspective even if the start time has passed.
                // - Expired beats full: a past match is no longer actionable.
                let autoCancelled = match.isAutoCancelled
                let expired = !autoCancelled && !hasSignedUp && match.isExpired
                let full = !autoCancelled && displayIsFull && !hasSignedUp && !expired
                let disabled = autoCancelled || hasSignedUp || expired || full
                let label: String = {
                    if autoCancelled { return "已自動取消" }
                    if hasSignedUp { return "已報名" }
                    if expired { return "已過期" }
                    if full { return "已額滿" }
                    return "報名"
                }()

                Button {
                    // 时段冲突拦截:同一时间不能重复报名(CLAUDE.md 边界 case #4)。
                    let scheduleText = "\(match.date) \(match.timeRange)"
                    if let range = MatchSchedule.dateRange(text: scheduleText),
                       let conflict = bookedSlotStore.conflict(
                           start: range.start,
                           end: range.end,
                           excluding: match.matchId
                       ) {
                        conflictToast = "該時段已與「\(conflict.label)」衝突,請先取消已預訂的時段"
                        return
                    }
                    showSignUpConfirm = true
                } label: {
                    Text(label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(disabled ? Theme.textSecondary : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(disabled ? Theme.chipUnselectedBg : Theme.primaryDark)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(disabled)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xl)
        .background(
            Rectangle()
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 4, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
        .sheet(isPresented: $showInviteSheet) {
            InviteContactsSheet(matchType: match.matchType, location: match.location)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSignUpConfirm) {
            SignUpConfirmSheetForDetail(match: match) { message in
                signUpMessage = message
                // Local: append current user + bump count.
                let counts = match.playerCounts
                localPlayerCurrent = (localPlayerCurrent ?? counts.current) + 1
                participants.append(
                    MatchParticipant(
                        name: userStore.displayName,
                        gender: userStore.gender,
                        ntrp: userStore.ntrpText,
                        isOrganizer: false
                    )
                )
                // Parent: mark signed up + bump underlying match.
                if let mid = match.matchId {
                    signedUpMatchIDs.insert(mid)
                    onSignUp(mid)
                }
                showSignUpSuccess = true
            }
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showSignUpSuccess, onDismiss: {
            if pendingContactOrganizer {
                pendingContactOrganizer = false
                navigateToChat = true
            }
        }) {
            SignUpSuccessViewForDetail(match: match, onContactOrganizer: {
                pendingContactOrganizer = true
                showSignUpSuccess = false
            })
        }
        .navigationDestination(isPresented: $navigateToChat) {
            ChatDetailView(
                chat: MockChat(
                    type: .personal(name: match.name, symbol: match.gender == .female ? "♀" : "♂", symbolColor: match.gender == .female ? Theme.genderFemale : Theme.genderMale),
                    lastMessage: "點擊開始聊天",
                    time: "now",
                    unreadCount: 0
                ),
                acceptedMatches: $acceptedMatches,
                matchContext: "🎾 約球已確認\n📅 \(match.date) \(match.timeRange)\n📍 \(match.location)\n🏸 \(match.matchType) · NTRP \(match.ntrpRange)\n💰 \(match.fee)",
                initialMessage: signUpMessage.isEmpty ? nil : signUpMessage
            )
        }
    }
}

// MARK: - Data Model

struct MatchDetailData: Identifiable, Hashable {
    let id = UUID()
    /// The originating match's id (HomeView's `MockMatch.id`).
    /// Used to coordinate sign-up state with the caller.
    /// Nil for standalone previews / flows without a source match.
    var matchId: UUID? = nil
    let name: String
    let gender: Gender
    let ntrp: String
    let reputation: Int
    let matchType: String
    let date: String
    let timeRange: String
    let location: String
    let district: String
    let players: String
    let ntrpRange: String
    let fee: String
    let notes: String
    let weather: MatchWeather
    let participantList: [MatchParticipant]
    var isOwnMatch: Bool = false

    /// Parses `"1/2 人"` → (current: 1, max: 2). Falls back to (0, 0).
    var playerCounts: (current: Int, max: Int) {
        let digits = players.split { !$0.isNumber }.map(String.init)
        guard digits.count >= 2,
              let current = Int(digits[0]),
              let max = Int(digits[1]) else {
            return (0, 0)
        }
        return (current, max)
    }

    var isFull: Bool {
        let c = playerCounts
        return c.max > 0 && c.current >= c.max
    }

    /// 起始时间已过(由 `date` 中的 MM/dd 与 `timeRange` 起始 HH:mm 组合)。
    /// 解析失败时返回 `false`,避免误把数据当成过期。
    var isExpired: Bool {
        MatchSchedule.isExpired(text: "\(date) \(timeRange)")
    }

    /// 起始时间已过且未满员 — 视为"人员不足,自动取消"(CLAUDE.md 边界 case #2)。
    var isAutoCancelled: Bool { isExpired && !isFull }
}

struct MatchWeather: Hashable {
    let temp: String
    let humidity: String
    let uv: String
    let wind: String
}

struct MatchParticipant: Hashable {
    let name: String
    let gender: Gender
    let ntrp: String
    let isOrganizer: Bool
}

// MARK: - Invite Contacts Sheet

private struct InviteContactsSheet: View {
    let matchType: String
    let location: String
    @Environment(\.dismiss) private var dismiss
    @State private var invitedIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("選擇要邀請的朋友加入\(matchType)")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textCaption)
                    .padding(.top, Spacing.sm)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(inviteContacts) { contact in
                            let isInvited = invitedIDs.contains(contact.id)
                            HStack(spacing: Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.avatarPlaceholder)
                                        .frame(width: 40, height: 40)
                                    Text(String(contact.name.prefix(1)))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(contact.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Theme.textPrimary)
                                        Text(contact.genderSymbol)
                                            .font(.system(size: 14))
                                            .foregroundColor(contact.genderColor)
                                    }
                                    Text("NTRP \(contact.ntrp)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textCaption)
                                }

                                Spacer()

                                Button {
                                    if !isInvited {
                                        invitedIDs.insert(contact.id)
                                    }
                                } label: {
                                    Text(isInvited ? "已邀請" : "邀請")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(isInvited ? Theme.textCaption : .white)
                                        .frame(width: 56, height: 30)
                                        .background(isInvited ? Theme.chipUnselectedBg : Theme.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .disabled(isInvited)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)

                            Rectangle()
                                .fill(Theme.inputBorder)
                                .frame(height: 1)
                                .padding(.leading, 68)
                        }
                    }
                }
            }
            .navigationTitle("邀請朋友")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
        }
    }
}

private struct InviteContact: Identifiable {
    let id = UUID()
    let name: String
    let genderSymbol: String
    let genderColor: Color
    let ntrp: String
}

private let inviteContacts: [InviteContact] = [
    InviteContact(name: "莎拉", genderSymbol: "♀", genderColor: Theme.genderFemale, ntrp: "3.5"),
    InviteContact(name: "王強", genderSymbol: "♂", genderColor: Theme.genderMale, ntrp: "4.0"),
    InviteContact(name: "小美", genderSymbol: "♀", genderColor: Theme.genderFemale, ntrp: "3.0"),
    InviteContact(name: "張偉", genderSymbol: "♂", genderColor: Theme.genderMale, ntrp: "4.5"),
    InviteContact(name: "嘉欣", genderSymbol: "♀", genderColor: Theme.genderFemale, ntrp: "3.5"),
    InviteContact(name: "艾美", genderSymbol: "♀", genderColor: Theme.genderFemale, ntrp: "3.0"),
    InviteContact(name: "大衛", genderSymbol: "♂", genderColor: Theme.genderMale, ntrp: "4.0"),
    InviteContact(name: "阿豪", genderSymbol: "♂", genderColor: Theme.genderMale, ntrp: "3.5"),
    InviteContact(name: "思慧", genderSymbol: "♀", genderColor: Theme.genderFemale, ntrp: "4.0"),
    InviteContact(name: "俊傑", genderSymbol: "♂", genderColor: Theme.genderMale, ntrp: "4.0"),
]

// MARK: - Sign Up from Detail

private struct SignUpConfirmSheetForDetail: View {
    let match: MatchDetailData
    var onConfirm: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("確認報名")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                infoRow(icon: "calendar", text: "\(match.date) \(match.timeRange)")
                infoRow(icon: "mappin.circle.fill", text: match.location)
                infoRow(icon: "figure.tennis", text: "\(match.matchType) · NTRP \(match.ntrpRange)")
                infoRow(icon: "dollarsign.circle.fill", text: match.fee)
            }

            Theme.divider.frame(height: 1)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("給發起人留言（選填）")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                TextField("例如：我會準時到！", text: $message, axis: .vertical)
                    .font(.system(size: 14))
                    .lineLimit(3...5)
                    .padding(Spacing.sm)
                    .background(Theme.inputBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
            }

            Spacer()

            Button {
                dismiss()
                onConfirm(message)
            } label: {
                Text("確認報名")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

private struct SignUpSuccessViewForDetail: View {
    let match: MatchDetailData
    var onContactOrganizer: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var calendarToast: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.textDark)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.xs)

            Spacer().frame(height: Spacing.xxl)

            ZStack {
                Circle().fill(Theme.primary).frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer().frame(height: Spacing.md)

            Text("報名成功！")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.textDark)

            Text("你已成功加入\(match.name)的約球")
                .font(.system(size: 15))
                .foregroundColor(Theme.textHint)
                .padding(.top, Spacing.xs)

            Spacer().frame(height: Spacing.lg)

            // Summary card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                summaryRow(icon: "calendar", text: "\(match.date) \(match.timeRange)")
                summaryRow(icon: "mappin.and.ellipse", text: match.location)
                summaryRow(icon: "dollarsign.circle", text: match.fee)
                summaryRow(icon: "person.2.fill", text: "\(match.players) · 水平 \(match.ntrpRange)")
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

            Button { dismiss() } label: {
                Text("返回詳情")
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
        guard let range = CalendarService.parseDateTimeRange(date: match.date, timeRange: match.timeRange) else {
            calendarToast = "無法解析約球時間"
            return
        }
        let title = "\(match.name) · \(match.matchType)"
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
                .font(.system(size: 15))
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

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        MatchDetailView(
            match: previewMatchDetail,
            acceptedMatches: .constant([]),
            signedUpMatchIDs: .constant([])
        )
    }
    .environment(FollowStore())
    .environment(UserStore())
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        MatchDetailView(
            match: previewMatchDetail,
            acceptedMatches: .constant([]),
            signedUpMatchIDs: .constant([])
        )
    }
    .environment(FollowStore())
    .environment(UserStore())
}

private let previewMatchDetail = MatchDetailData(
    name: "莎拉", gender: .female, ntrp: "3.5", reputation: 90,
    matchType: "單打", date: "2026/04/19", timeRange: "10:00 - 12:00",
    location: "維多利亞公園網球場", district: "香港銅鑼灣",
    players: "1/2 人", ntrpRange: "3.0-4.0", fee: "AA ¥120",
    notes: "自帶球拍和球",
    weather: MatchWeather(temp: "24°C", humidity: "10%", uv: "7", wind: "12"),
    participantList: [
        MatchParticipant(name: "莎拉", gender: .female, ntrp: "3.5", isOrganizer: true)
    ]
)
