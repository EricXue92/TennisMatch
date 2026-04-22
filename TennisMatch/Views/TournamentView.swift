//
//  TournamentView.swift
//  TennisMatch
//
//  賽事列表 + 賽事詳情
//

import SwiftUI

// MARK: - Tournament List

struct TournamentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore
    @State private var selectedFilter = "全部"
    @State private var selectedTournament: MockTournament?
    @State private var showCreateTournament = false
    @State private var tournaments: [MockTournament] = mockTournaments

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBar
                filterTabs
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        ForEach(filteredTournaments) { tournament in
                            tournamentCard(tournament)
                                .onTapGesture {
                                    selectedTournament = tournament
                                }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .background(Theme.inputBg)
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedTournament) { tournament in
                TournamentDetailView(tournament: tournament)
            }
            .navigationDestination(isPresented: $showCreateTournament) {
                CreateTournamentView(onPublish: { info in
                    addPublishedTournament(info)
                })
            }
        }
    }

    private var filteredTournaments: [MockTournament] {
        let base = selectedFilter == "全部" ? tournaments : tournaments.filter { $0.status == selectedFilter }
        return base.sorted { $0.isOwnTournament && !$1.isOwnTournament }
    }

    private func addPublishedTournament(_ info: PublishedTournamentInfo) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateRange = "\(formatter.string(from: info.startDate)) - \(formatter.string(from: info.endDate))"

        let tournament = MockTournament(
            name: info.name.isEmpty ? "我的賽事" : info.name,
            format: info.format,
            matchType: info.matchType,
            ntrpRange: info.level,
            status: "報名中",
            dateRange: dateRange,
            location: info.courtName.isEmpty ? "待定" : info.courtName,
            participants: "0/\(info.participantCount.isEmpty ? "16" : info.participantCount)",
            fee: info.fee.isEmpty ? "免費" : "\(info.fee) 港幣",
            organizer: userStore.displayName,
            organizerGender: userStore.gender,
            gradientColors: [Theme.gradGreenLight, Theme.primary],
            rules: info.rules.isEmpty ? [] : [info.rules],
            playerList: [],
            isOwnTournament: true
        )
        tournaments.insert(tournament, at: 0)
    }
}

// MARK: - Header & Filters

private extension TournamentView {
    var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 44, height: 44)
            }
            Text("賽事")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Button {
                showCreateTournament = true
            } label: {
                Text("+ 建立賽事")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 28)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.xs)
        .background(.white)
    }

    var filterTabs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(tournamentFilterOptions, id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = option
                        }
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Text(option)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedFilter == option ? Theme.primary : Theme.textSecondary)
                                .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(selectedFilter == option ? Theme.primary : .clear)
                                .frame(width: 40, height: 3)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.top, Spacing.sm)

            Theme.inputBorder.frame(height: 1)
        }
        .background(.white)
    }
}

// MARK: - Tournament Card

private extension TournamentView {
    func tournamentCard(_ t: MockTournament) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top: icon + title + tags
            HStack(alignment: .top, spacing: Spacing.sm) {
                // Trophy icon with gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: t.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Text("🏆")
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(t.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    // Tags
                    HStack(spacing: 4) {
                        tagPill(t.format, style: .gray)
                        tagPill(t.matchType, style: .gray)
                        tagPill(t.ntrpRange, style: .gray)
                        if t.isOwnTournament {
                            Text("我發起的")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .frame(height: 20)
                                .background(Theme.accentGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        } else {
                            statusPill(t.status)
                        }
                    }
                }
            }

            // Info rows
            VStack(alignment: .leading, spacing: 4) {
                infoRow(icon: "📅", text: t.dateRange)
                infoRow(icon: "📍", text: t.location)
                infoRow(icon: "👥", text: t.participants)
                infoRow(icon: "💰", text: t.fee)
            }
            .padding(.leading, 60)

            // Bottom: organizer + action button
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.avatarPlaceholder)
                        .frame(width: 20, height: 20)
                    Text("發起人: \(t.organizer)")
                        .font(Typography.fieldLabel)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.leading, 60)

                Spacer()

                if !t.isOwnTournament {
                    if t.status == "報名中" {
                        Button {
                            selectedTournament = t
                        } label: {
                            Text("報名")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 26)
                                .background(Theme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    } else if t.status == "進行中" {
                        Button {
                            selectedTournament = t
                        } label: {
                            Text("查看")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.primary)
                                .frame(width: 70, height: 26)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Theme.primary, lineWidth: 1)
                                }
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
        .overlay(alignment: .leading) {
            if t.isOwnTournament {
                Theme.primary
                    .frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(.vertical, 8)
            }
        }
    }

    func tagPill(_ text: String, style: TagStyle) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(style == .gray ? Theme.textSecondary : .white)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(style == .gray ? Theme.chipUnselectedBg : Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func statusPill(_ status: String) -> some View {
        Text(status)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(statusColor(status))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(Typography.small)
            Text(text)
                .font(Typography.small)
                .foregroundColor(Theme.textSecondary)
        }
    }
}

private func statusColor(_ status: String) -> Color {
    switch status {
    case "報名中": return Theme.primary
    case "進行中": return Theme.accentBlue
    case "已完成": return Theme.gradGrayLight
    default: return Theme.primary
    }
}

private enum TagStyle { case gray, colored }

// MARK: - Tournament Detail

struct TournamentDetailView: View {
    let tournament: MockTournament
    @Environment(\.dismiss) private var dismiss
    @Environment(FollowStore.self) private var followStore
    @State private var isSignedUp = false
    @State private var showSignUpConfirm = false
    @State private var showSignUpSuccess = false
    @State private var pendingContactOrganizer = false
    @State private var dmChat: MockChat?
    @State private var dmMatchContext: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    headerCard
                    infoCard
                    organizerCard
                    participantsCard
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, 100)
            }
            .background(Theme.inputBg)

            bottomBar
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
                Text("賽事詳情")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .sheet(isPresented: $showSignUpConfirm) {
            TournamentSignUpSheet(tournament: tournament) {
                isSignedUp = true
                showSignUpSuccess = true
            }
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showSignUpSuccess, onDismiss: {
            if pendingContactOrganizer {
                pendingContactOrganizer = false
                dmChat = MockChat(
                    type: .personal(
                        name: tournament.organizer,
                        symbol: tournament.organizerGender.symbol,
                        symbolColor: tournament.organizerGender == .female ? Theme.genderFemale : Theme.genderMale
                    ),
                    lastMessage: "點擊開始聊天",
                    time: "now",
                    unreadCount: 0
                )
                dmMatchContext = "🏆 賽事報名確認\n📅 \(tournament.dateRange)\n📍 \(tournament.location)\n🏸 \(tournament.format) · \(tournament.matchType) · NTRP \(tournament.ntrpRange)\n💰 \(tournament.fee)"
            }
        }) {
            TournamentSignUpSuccessView(tournament: tournament, onContactOrganizer: {
                pendingContactOrganizer = true
                showSignUpSuccess = false
            })
        }
        .navigationDestination(item: $dmChat) { chat in
            ChatDetailView(chat: chat, acceptedMatches: .constant([]), matchContext: dmMatchContext)
                .onDisappear { dmMatchContext = nil }
        }
    }
}

// MARK: - Detail Sections

private extension TournamentDetailView {
    // Gradient header card
    var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.gradGoldLight, Theme.gradGoldDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 44)
                Text("🏆")
                    .font(.system(size: 28))
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(tournament.name)
                    .font(Typography.navTitle)
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    detailBadge(tournament.format)
                    detailBadge(tournament.matchType)
                    detailBadge(tournament.ntrpRange)
                    Text(tournament.status)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 3)
                        .background(Theme.primaryEmerald)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: tournament.gradientColors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func detailBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 3)
            .background(.white.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // Info card
    var infoCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("賽事資訊")
                .font(Typography.button)
                .foregroundColor(Theme.textInk)

            detailInfoRow(icon: "📅", label: "比賽日期", value: tournament.dateRange)
            detailInfoRow(icon: "📍", label: "比賽場地", value: tournament.location)
            detailInfoRow(icon: "👥", label: "參賽人數", value: tournament.participants)
            detailInfoRow(icon: "💰", label: "報名費用", value: tournament.fee)

            Rectangle()
                .fill(Theme.pillBg)
                .frame(height: 1)

            Text("賽事規則")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textInk)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(tournament.rules, id: \.self) { rule in
                    Text("• \(rule)")
                        .font(Typography.small)
                        .foregroundColor(Theme.textMuted)
                        .lineSpacing(4)
                }
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    func detailInfoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(icon)
                .font(.system(size: 16))
            Text(label)
                .font(Typography.caption)
                .foregroundColor(Theme.textMid)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textDeeper)
        }
    }

    // Organizer card
    var organizerCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("主辦方")
                .font(Typography.button)
                .foregroundColor(Theme.textInk)

            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tournament.organizer)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textInk)
                    Text("NTRP 4.0 · 賽事組織者")
                        .font(Typography.fieldLabel)
                        .foregroundColor(Theme.textSubtle)
                }

                Spacer()

                Button {
                    withAnimation { followStore.toggle(tournament.organizer) }
                } label: {
                    Text(followStore.isFollowing(tournament.organizer) ? "已關注" : "關注")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(followStore.isFollowing(tournament.organizer) ? .white : Theme.textDark)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(followStore.isFollowing(tournament.organizer) ? Theme.primary : Theme.chipBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // Participants card
    var isCompleted: Bool { tournament.status == "已完成" }

    var participantsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(isCompleted ? "比賽成績" : "已報名選手")
                    .font(Typography.button)
                    .foregroundColor(Theme.textInk)
                Spacer()
                Text(tournament.participants)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textSubtle)
            }

            ForEach(Array(tournament.playerList.enumerated()), id: \.offset) { index, player in
                HStack(spacing: Spacing.sm) {
                    if isCompleted && index < 3 {
                        Text(["🥇", "🥈", "🥉"][index])
                            .font(.system(size: 16))
                            .frame(width: 22, height: 22)
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textMid)
                            .frame(width: 22, height: 22)
                            .background(Theme.chipBg)
                            .clipShape(Circle())
                    }

                    Circle()
                        .fill(Theme.avatarPlaceholder)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(player.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textDeeper)
                        Text("NTRP \(player.ntrp)")
                            .font(Typography.fieldLabel)
                            .foregroundColor(Theme.textSubtle)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // Bottom action bar
    @ViewBuilder
    var bottomBar: some View {
        if !isCompleted {
            VStack {
                Button {
                    if !isSignedUp {
                        showSignUpConfirm = true
                    }
                } label: {
                    Text(isSignedUp ? "已報名" : "立即報名 · \(tournament.fee)")
                        .font(Typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isSignedUp ? Theme.chipUnselectedBg : Theme.primaryEmerald)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(isSignedUp)
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
        }
    }
}

// MARK: - Tournament Sign Up

private struct TournamentSignUpSheet: View {
    let tournament: MockTournament
    var onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("確認報名")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                infoRow(icon: "trophy.fill", text: tournament.name)
                infoRow(icon: "calendar", text: tournament.dateRange)
                infoRow(icon: "mappin.circle.fill", text: tournament.location)
                infoRow(icon: "dollarsign.circle.fill", text: tournament.fee)
            }

            Spacer()

            Button {
                dismiss()
                onConfirm()
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
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textPrimary)
        }
    }
}

private struct TournamentSignUpSuccessView: View {
    let tournament: MockTournament
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
                .font(Typography.title)
                .foregroundColor(Theme.textDark)

            Text("你已成功報名「\(tournament.name)」")
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textHint)
                .padding(.top, Spacing.xs)

            Spacer().frame(height: Spacing.lg)

            // Summary card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                summaryRow(icon: "calendar", text: tournament.dateRange)
                summaryRow(icon: "mappin.and.ellipse", text: tournament.location)
                summaryRow(icon: "dollarsign.circle", text: tournament.fee)
                summaryRow(icon: "person.2.fill", text: "\(tournament.participants) · NTRP \(tournament.ntrpRange)")
                summaryRow(icon: "trophy.fill", text: "\(tournament.format) · \(tournament.matchType)")
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
                    saveTournamentToCalendar()
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            Button { dismiss() } label: {
                Text("返回賽事")
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

    private func saveTournamentToCalendar() {
        guard let range = CalendarService.parseTournamentRange(tournament.dateRange) else {
            calendarToast = "無法解析賽事日期"
            return
        }
        let title = tournament.name
        let notes = "\(tournament.format) · \(tournament.matchType) · NTRP \(tournament.ntrpRange)\n費用：\(tournament.fee)\n發起人：\(tournament.organizer)"
        Task {
            do {
                try await CalendarService.addEvent(
                    title: title,
                    startDate: range.start,
                    endDate: range.end,
                    location: tournament.location,
                    notes: notes,
                    isAllDay: true
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

// MARK: - Data

private let tournamentFilterOptions = ["全部", "報名中", "進行中", "已完成"]

struct MockTournament: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let format: String       // 淘汰賽, 階梯賽, 循環賽
    let matchType: String    // 單打, 雙打
    let ntrpRange: String
    let status: String       // 報名中, 進行中, 已完成
    let dateRange: String
    let location: String
    let participants: String
    let fee: String
    let organizer: String
    let organizerGender: Gender
    let gradientColors: [Color]
    let rules: [String]
    let playerList: [TournamentPlayer]
    var isOwnTournament: Bool = false
}

struct TournamentPlayer: Hashable {
    let name: String
    let ntrp: String
}

let mockTournaments: [MockTournament] = [
    MockTournament(
        name: "香港春季網球公開賽",
        format: "淘汰賽", matchType: "單打", ntrpRange: "3.0-4.0",
        status: "報名中",
        dateRange: "2026/05/01 - 05/03",
        location: "維多利亞公園網球場",
        participants: "4/16",
        fee: "300 港幣",
        organizer: "莎拉",
        organizerGender: .female,
        gradientColors: [Theme.gradAmberLight, Theme.gradAmberDeep],
        rules: [
            "單淘汰制，一局定勝負",
            "每場比賽採用三盤兩勝制",
            "選手需提前15分鐘到場",
            "遲到超過10分鐘視為棄權"
        ],
        playerList: [
            TournamentPlayer(name: "莎拉", ntrp: "4.0"),
            TournamentPlayer(name: "小明", ntrp: "3.5"),
            TournamentPlayer(name: "嘉欣", ntrp: "3.5"),
            TournamentPlayer(name: "志明", ntrp: "4.0"),
        ]
    ),
    MockTournament(
        name: "香港網球階梯挑戰賽",
        format: "階梯賽", matchType: "單打", ntrpRange: "3.5-5.0",
        status: "進行中",
        dateRange: "2026/04/20 - 06/30",
        location: "多個球場",
        participants: "3/30",
        fee: "200 港幣",
        organizer: "王強",
        organizerGender: .male,
        gradientColors: [Theme.gradSkyLight, Theme.accentBlueAlt],
        rules: [
            "階梯積分制，可隨時挑戰排名更高的選手",
            "每場比賽採用兩盤一勝制",
            "雙方需在7天內完成比賽",
            "無故棄權將扣除積分"
        ],
        playerList: [
            TournamentPlayer(name: "王強", ntrp: "4.5"),
            TournamentPlayer(name: "大衛", ntrp: "4.0"),
            TournamentPlayer(name: "Peter", ntrp: "5.0"),
        ]
    ),
    MockTournament(
        name: "九龍區業餘雙打賽",
        format: "循環賽", matchType: "雙打", ntrpRange: "2.5-3.5",
        status: "報名中",
        dateRange: "2026/05/15 - 05/17",
        location: "九龍仔公園",
        participants: "6/16",
        fee: "250 港幣",
        organizer: "美琪",
        organizerGender: .female,
        gradientColors: [Theme.gradPurpleLight, Theme.gradPurpleDeep],
        rules: [
            "小組循環賽 + 淘汰賽",
            "每場比賽採用一盤定勝負（搶七）",
            "雙打搭檔需在報名時確定",
            "選手需自備球拍"
        ],
        playerList: [
            TournamentPlayer(name: "美琪", ntrp: "3.0"),
            TournamentPlayer(name: "小美", ntrp: "3.0"),
            TournamentPlayer(name: "Kelly", ntrp: "3.5"),
            TournamentPlayer(name: "嘉欣", ntrp: "3.0"),
            TournamentPlayer(name: "林叔", ntrp: "3.5"),
            TournamentPlayer(name: "阿杰", ntrp: "2.5"),
        ]
    ),
    MockTournament(
        name: "新界友誼邀請賽",
        format: "淘汰賽", matchType: "單打", ntrpRange: "4.0-5.5",
        status: "已完成",
        dateRange: "2026/03/10 - 03/12",
        location: "沙田公園",
        participants: "16/16",
        fee: "350 港幣",
        organizer: "陳教練",
        organizerGender: .male,
        gradientColors: [Theme.gradGrayLight, Theme.gradGrayDeep],
        rules: [
            "單淘汰制",
            "每場比賽採用三盤兩勝制",
            "獎金分配：冠軍60%、亞軍30%、季軍10%",
            "選手需穿著正式網球服裝"
        ],
        playerList: [
            TournamentPlayer(name: "老張", ntrp: "5.0"),
            TournamentPlayer(name: "Peter", ntrp: "5.0"),
            TournamentPlayer(name: "志明", ntrp: "4.5"),
            TournamentPlayer(name: "王強", ntrp: "4.5"),
            TournamentPlayer(name: "大衛", ntrp: "4.5"),
            TournamentPlayer(name: "陳教練", ntrp: "4.0"),
            TournamentPlayer(name: "俊傑", ntrp: "4.0"),
            TournamentPlayer(name: "林叔", ntrp: "4.0"),
            TournamentPlayer(name: "阿杰", ntrp: "4.0"),
            TournamentPlayer(name: "莎拉", ntrp: "4.5"),
            TournamentPlayer(name: "麗莎", ntrp: "5.0"),
            TournamentPlayer(name: "美琪", ntrp: "4.0"),
            TournamentPlayer(name: "嘉欣", ntrp: "4.5"),
            TournamentPlayer(name: "Kelly", ntrp: "4.0"),
            TournamentPlayer(name: "小美", ntrp: "4.0"),
            TournamentPlayer(name: "小玲", ntrp: "4.0"),
        ]
    ),
    MockTournament(
        name: "港島區週末快速賽",
        format: "淘汰賽", matchType: "單打", ntrpRange: "2.5-3.5",
        status: "報名中",
        dateRange: "2026/05/10 - 05/10",
        location: "香港公園",
        participants: "7/16",
        fee: "180 港幣",
        organizer: "艾美",
        organizerGender: .female,
        gradientColors: [Theme.gradGreenLight, Theme.gradGreenDeep],
        rules: [
            "單淘汰制，一盤定勝負（搶七）",
            "每場比賽限時 45 分鐘",
            "適合初中階球友參加",
            "主辦方提供比賽用球"
        ],
        playerList: [
            TournamentPlayer(name: "艾美", ntrp: "3.0"),
            TournamentPlayer(name: "小美", ntrp: "3.0"),
            TournamentPlayer(name: "曉彤", ntrp: "2.5"),
            TournamentPlayer(name: "雅婷", ntrp: "3.0"),
            TournamentPlayer(name: "阿杰", ntrp: "2.5"),
            TournamentPlayer(name: "嘉欣", ntrp: "3.5"),
            TournamentPlayer(name: "國輝", ntrp: "3.5"),
        ]
    ),
    MockTournament(
        name: "全港混雙邀請賽",
        format: "循環賽", matchType: "雙打", ntrpRange: "3.5-5.0",
        status: "進行中",
        dateRange: "2026/04/15 - 05/31",
        location: "香港網球中心",
        participants: "12/16",
        fee: "400 港幣",
        organizer: "老張",
        organizerGender: .male,
        gradientColors: [Theme.gradPinkLight, Theme.gradPinkDeep],
        rules: [
            "混雙循環賽，每組需一男一女",
            "每場比賽採用超級搶十",
            "小組前兩名晉級淘汰賽",
            "決賽採用三盤兩勝制"
        ],
        playerList: [
            TournamentPlayer(name: "老張", ntrp: "5.0"),
            TournamentPlayer(name: "莎拉", ntrp: "4.5"),
            TournamentPlayer(name: "王強", ntrp: "4.5"),
            TournamentPlayer(name: "麗莎", ntrp: "5.0"),
            TournamentPlayer(name: "Michael", ntrp: "5.0"),
            TournamentPlayer(name: "嘉欣", ntrp: "4.5"),
            TournamentPlayer(name: "大衛", ntrp: "4.0"),
            TournamentPlayer(name: "思慧", ntrp: "4.0"),
            TournamentPlayer(name: "志明", ntrp: "4.5"),
            TournamentPlayer(name: "Kelly", ntrp: "4.0"),
            TournamentPlayer(name: "Peter", ntrp: "5.0"),
            TournamentPlayer(name: "美琪", ntrp: "3.5"),
        ]
    ),
]

// MARK: - Preview

#Preview("iPhone SE") {
    TournamentView()
        .environment(UserStore())
        .environment(FollowStore())
}

#Preview("iPhone 15 Pro") {
    TournamentView()
        .environment(UserStore())
        .environment(FollowStore())
}
