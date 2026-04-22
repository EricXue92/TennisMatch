//
//  MyMatchesView.swift
//  TennisMatch
//
//  我的約球 — 即將到來、已完成、收到邀請
//

import SwiftUI

struct MyMatchesView: View {
    @Binding var acceptedMatches: [AcceptedMatchInfo]
    @Binding var sharedChats: [MockChat]
    /// 點擊「去首頁看看」時觸發，由父層 HomeView 切換到 Tab 0。
    var onGoHome: (() -> Void)? = nil
    /// Fires when a user-signed-up match is cancelled. Passes the originating HomeView match ID (or nil for mock/invitation-accept items).
    var onMatchCancelled: ((UUID?) -> Void)? = nil
    @Environment(BookedSlotStore.self) private var bookedSlotStore
    @Environment(NotificationStore.self) private var notificationStore
    @Environment(CreditScoreStore.self) private var creditScoreStore
    @State private var selectedFilter = "即將到來"
    @State private var selectedChat: MockChat?
    @State private var selectedChatMatchContext: String?
    @State private var matchToCancel: MyMatchItem?
    @State private var showCancelAlert = false
    @State private var showManageSheet = false
    @State private var matchToManage: MyMatchItem?
    /// Single-slot toast so cancel / reject / coming-soon can't visually stack.
    /// New toasts replace the current one instead of queueing on top.
    @State private var toast: ToastMessage?
    /// Stable content keys (inviter|type|details|time) of rejected invitations,
    /// JSON-encoded and persisted via @AppStorage so rejections survive app
    /// restarts. UUIDs change each launch with mock data, so we key by content.
    @AppStorage("rejectedInvitationKeys") private var rejectedInvitationKeysJSON: String = "[]"
    @State private var upcomingMatches: [MyMatchItem] = mockUpcomingMatchesInitial
    @State private var acceptedInvitation: MyMatchInvitation?
    @State private var showAcceptSuccess = false
    @State private var pendingDMContact: MyMatchInvitation?
    @State private var dmChat: MockChat?
    @State private var dmMatchContext: String?
    @State private var registrantMatch: MyMatchItem?
    @State private var selectedCompletedMatch: MyMatchItem?

    private var sortedUpcoming: [MyMatchItem] {
        (acceptedMatchItems + upcomingMatches).sorted { $0.sortDate < $1.sortDate }
    }

    private var sortedCompleted: [MyMatchItem] {
        mockCompletedMatches.sorted { $0.sortDate > $1.sortDate }
    }

    private var rejectedInvitationKeys: Set<String> {
        guard let data = rejectedInvitationKeysJSON.data(using: .utf8),
              let arr = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(arr)
    }

    private func rejectKey(for inv: MyMatchInvitation) -> String {
        let parts = [inv.inviterName, inv.matchType, inv.details, inv.time]
        return (try? JSONEncoder().encode(parts)).flatMap { String(data: $0, encoding: .utf8) }
            ?? "\(inv.inviterName)|\(inv.matchType)|\(inv.details)|\(inv.time)"
    }

    private func persistRejection(_ inv: MyMatchInvitation) {
        var keys = rejectedInvitationKeys
        keys.insert(rejectKey(for: inv))
        if let data = try? JSONEncoder().encode(Array(keys)),
           let json = String(data: data, encoding: .utf8) {
            rejectedInvitationKeysJSON = json
        }
    }

    private var visibleInvitations: [MyMatchInvitation] {
        let rejected = rejectedInvitationKeys
        return mockInvitations.filter { !rejected.contains(rejectKey(for: $0)) }
    }

    private var acceptedMatchItems: [MyMatchItem] {
        acceptedMatches.map { info in
            let timeStr = info.time
            let startHour = Int(timeStr.prefix(2)) ?? 10
            let endHour = startHour + info.durationHours
            let endTime = String(format: "%02d:00", endHour)
            return MyMatchItem(
                title: "\(info.organizerName) 發起的\(info.matchType)",
                isOrganizer: false,
                status: .confirmed,
                dateLabel: "\(info.dateString)",
                location: "\(info.location)網球場",
                timeRange: "\(timeStr) - \(endTime)",
                players: "\(info.players) · NTRP \(info.ntrpRange)",
                weather: "☀️ 24°C",
                matchType: info.matchType,
                acceptedMatchID: info.id,
                sourceMatchID: info.sourceMatchID
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            filterTabs
            let rejectedKeys = rejectedInvitationKeys
            let upcomingEmpty = acceptedMatchItems.isEmpty
                && upcomingMatches.isEmpty
                && mockInvitations.allSatisfy { rejectedKeys.contains(rejectKey(for: $0)) }
            let completedEmpty = mockCompletedMatches.isEmpty

            if selectedFilter == "即將到來" && upcomingEmpty {
                VStack(spacing: Spacing.md) {
                    ContentUnavailableView(
                        "還沒有即將到來的約球",
                        systemImage: "figure.tennis",
                        description: Text("去首頁找一場約球，或發起新的約球")
                    )
                    if let onGoHome {
                        Button {
                            onGoHome()
                        } label: {
                            Text("去首頁看看")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.lg)
                                .frame(height: 36)
                                .background(Theme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if selectedFilter == "已完成" && completedEmpty {
                ContentUnavailableView(
                    "暫無已完成的約球",
                    systemImage: "checkmark.circle",
                    description: Text("完成的約球會顯示在這裡")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        if selectedFilter == "即將到來" {
                            ForEach(sortedUpcoming) { match in
                                myMatchCard(match)
                            }
                            ForEach(visibleInvitations) { invitation in
                                invitationCard(invitation)
                            }
                        } else {
                            ForEach(sortedCompleted) { match in
                                myMatchCard(match)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Theme.inputBg)
        .navigationDestination(item: $selectedChat) { chat in
            ChatDetailView(chat: chat, acceptedMatches: $acceptedMatches, matchContext: selectedChatMatchContext)
                .onDisappear { selectedChatMatchContext = nil }
        }
        .alert("取消約球", isPresented: $showCancelAlert) {
            Button("再想想", role: .cancel) {
                matchToCancel = nil
            }
            Button("確認取消", role: .destructive) {
                if let match = matchToCancel {
                    let scheduleText = "\(match.dateLabel) \(match.timeRange)"
                    let hoursToStart: Double = {
                        guard let start = MatchSchedule.startDate(text: scheduleText) else {
                            return .infinity
                        }
                        return start.timeIntervalSince(.now) / 3600
                    }()
                    withAnimation {
                        if let aid = match.acceptedMatchID {
                            acceptedMatches.removeAll { $0.id == aid }
                            bookedSlotStore.remove(id: aid)
                        }
                        upcomingMatches.removeAll { $0.id == match.id }
                    }
                    onMatchCancelled?(match.sourceMatchID)
                    // 阶梯扣分: ≥24h → 0, 2-24h → -1, <2h → -2
                    let deduction = creditScoreStore.recordCancellation(
                        hoursBeforeStart: hoursToStart,
                        detail: "\(match.title) · \(match.location)"
                    )
                    let creditDeducted = deduction > 0
                    if creditDeducted {
                        notificationStore.push(MatchNotification(
                            type: .cancelled,
                            title: "信譽積分 -\(deduction)",
                            body: "距開場不足 \(hoursToStart < 2 ? "2" : "24") 小時取消，已扣除 \(deduction) 分信譽積分（當前 \(creditScoreStore.score) 分）",
                            time: "剛剛",
                            isRead: false
                        ))
                    }
                    if match.isOrganizer {
                        notificationStore.push(MatchNotification(
                            type: .cancelled,
                            title: "你的約球已取消",
                            body: "已通知所有報名者：「\(match.title)」（\(match.dateLabel) \(match.timeRange) · \(match.location)）",
                            time: "剛剛",
                            isRead: false
                        ))
                    } else {
                        notificationStore.push(MatchNotification(
                            type: .cancelled,
                            title: "約球取消",
                            body: "「\(match.title)」（\(match.dateLabel) \(match.timeRange) · \(match.location)）已取消",
                            time: "剛剛",
                            isRead: false
                        ))
                    }
                    // 检查账号冻结/封禁
                    if creditScoreStore.score < CreditScoreStore.banThreshold {
                        toast = .init(kind: .warning, text: "信譽分低於 60，帳號已被永久封禁")
                    } else if creditScoreStore.score < CreditScoreStore.freezeThreshold {
                        toast = .init(kind: .warning, text: "信譽分低於 70，帳號將凍結 1 個月")
                    } else if creditDeducted {
                        toast = .init(kind: .warning, text: "已取消約球，扣 \(deduction) 分信譽")
                    } else {
                        toast = .init(kind: .success, text: "已取消約球，已通知所有參與者")
                    }
                }
                matchToCancel = nil
            }
        } message: {
            if let match = matchToCancel {
                Text(cancelAlertMessage(for: match))
            }
        }
        .confirmationDialog("管理約球", isPresented: $showManageSheet, presenting: matchToManage) { match in
            Button("編輯約球") {
                toast = .init(kind: .info, text: "編輯約球功能即將推出")
            }
            Button("查看報名者") {
                registrantMatch = match
            }
            Button("關閉報名") {
                toast = .init(kind: .info, text: "關閉報名功能即將推出")
            }
            Button("取消約球", role: .destructive) {
                matchToCancel = match
                showCancelAlert = true
            }
            Button("取消", role: .cancel) {}
        } message: { match in
            Text(match.title)
        }
        .sheet(item: $registrantMatch) { match in
            NavigationStack {
                List {
                    let count = match.playerCounts.current
                    ForEach(0..<max(count, 1), id: \.self) { i in
                        let names = ["小王", "艾美", "大衛", "莎拉", "小張"]
                        let name = names[i % names.count]
                        HStack(spacing: Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(Theme.avatarPlaceholder)
                                    .frame(width: 36, height: 36)
                                Text(String(name.suffix(1)))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.textPrimary)
                                Text("NTRP 3.5")
                                    .font(Typography.small)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            if i == 0 {
                                Text("發起人")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Theme.primary)
                                    .padding(.horizontal, Spacing.xs)
                                    .frame(height: 20)
                                    .background(Theme.primaryLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle("報名者 (\(match.playerCounts.current)/\(match.playerCounts.max))")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") {
                            registrantMatch = nil
                        }
                    }
                }
            }
        }
        .task {
            // 把 mock 中"已确认"的 upcomingMatches 登记到 BookedSlotStore,
            // 供 HomeView/MatchDetail/ChatDetail 的报名流程做冲突拦截。
            // BookedSlotStore.add 按 id 去重,重复 task 触发是安全的。
            // 自动取消的约球不再登记 — 它实际未进行,不应阻塞后续报名。
            for item in upcomingMatches where item.status == .confirmed && !item.isAutoCancelled {
                let scheduleText = "\(item.dateLabel) \(item.timeRange)"
                guard let range = MatchSchedule.dateRange(text: scheduleText) else { continue }
                let label = "\(item.title) \(item.dateLabel) \(item.timeRange)"
                bookedSlotStore.add(BookedSlot(
                    id: item.id,
                    start: range.start,
                    end: range.end,
                    label: label
                ))
            }
        }
        .overlay(alignment: .top) {
            if let current = toast {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: current.kind.icon)
                        .foregroundColor(.white)
                    Text(current.text)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Capsule().fill(Theme.textDeep))
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, Spacing.lg)
                .task(id: current.id) {
                    try? await Task.sleep(nanoseconds: 2_200_000_000)
                    // Only clear if this is still the active toast — a newer
                    // toast with a different id will have its own task.
                    if toast?.id == current.id {
                        withAnimation { toast = nil }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toast?.id)
        .sheet(item: $selectedCompletedMatch) { match in
            CompletedMatchReviewSheet(match: match)
        }
        .fullScreenCover(isPresented: $showAcceptSuccess, onDismiss: {
            if let inv = pendingDMContact {
                let chat = MockChat(
                    type: .personal(name: inv.inviterName, symbol: "♂", symbolColor: Theme.genderMale),
                    lastMessage: "點擊開始聊天",
                    time: "剛剛",
                    unreadCount: 0
                )
                dmChat = chat
                dmMatchContext = "🎾 已接受約球邀請\n🏸 \(inv.matchType)\n📋 \(inv.displayDetails)"
                // 同步到共享聊天列表
                if !sharedChats.contains(where: { $0.id == chat.id }) {
                    sharedChats.insert(chat, at: 0)
                }
                pendingDMContact = nil
            }
        }) {
            if let inv = acceptedInvitation {
                InvitationAcceptSuccessView(invitation: inv, onContactOrganizer: {
                    pendingDMContact = inv
                    showAcceptSuccess = false
                })
            }
        }
        .navigationDestination(item: $dmChat) { chat in
            ChatDetailView(chat: chat, acceptedMatches: $acceptedMatches, matchContext: dmMatchContext)
                .onDisappear { dmMatchContext = nil }
        }
    }

    private func cancelAlertMessage(for match: MyMatchItem) -> String {
        let scheduleText = "\(match.dateLabel) \(match.timeRange)"
        let hoursToStart = MatchSchedule.startDate(text: scheduleText)
            .map { $0.timeIntervalSince(.now) / 3600 } ?? Double.infinity

        let penaltyLine: String
        if hoursToStart >= 24 {
            penaltyLine = "距開場超過 24 小時，不扣信譽分"
        } else if hoursToStart >= 2 {
            penaltyLine = "距開場不足 24 小時，將扣除 1 分信譽分"
        } else {
            penaltyLine = "距開場不足 2 小時，將扣除 2 分信譽分"
        }

        return """
        確定要取消「\(match.title)」嗎？取消後將通知所有參與者。

        \(penaltyLine)

        取消規則：
        · 24 小時前取消：不扣分
        · 24 小時內取消：扣 1 分
        · 2 小時內取消：扣 2 分
        · 信譽分低於 70：凍結帳號 1 個月
        · 信譽分低於 60：永久封號

        當前信譽分：\(creditScoreStore.score) 分
        """
    }

    private func openChat(for match: MyMatchItem) {
        // Extract location name from "XXX網球場" → "XXX"
        let locationBase = match.location
            .replacingOccurrences(of: "網球場", with: "")
            .replacingOccurrences(of: "遊樂場", with: "")
        let chatTitle = "\(locationBase) \(match.matchType)"
        let dateStr = match.dateLabel.replacingOccurrences(of: "明天 · ", with: "")
        let dateTime = "\(dateStr) \(match.timeRange)"

        // 构建约球信息摘要,进入聊天时作为置顶卡片显示
        selectedChatMatchContext = "🎾 約球已確認\n📅 \(dateStr) \(match.timeRange)\n📍 \(match.location)\n🏸 \(match.matchType)\n👥 \(match.players)"

        let chat = MockChat(
            type: .match(title: chatTitle, dateTime: dateTime),
            lastMessage: "點擊開始聊天",
            time: "剛剛",
            unreadCount: 0
        )
        selectedChat = chat

        // 同步到共享聊天列表,使其在「聊天」Tab 可见
        if !sharedChats.contains(where: {
            if case .match(let t, _) = $0.type { return t == chatTitle }
            return false
        }) {
            sharedChats.insert(chat, at: 0)
        }
    }
}

// MARK: - Header & Filters

private extension MyMatchesView {
    var headerBar: some View {
        HStack {
            Text("我的約球")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            if !visibleInvitations.isEmpty {
                Text("邀請 \(visibleInvitations.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 26)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(.white)
    }

    var filterTabs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(["即將到來", "已完成"], id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = tab
                        }
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Text(tab)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedFilter == tab ? Theme.primary : Theme.textBody)
                                .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(selectedFilter == tab ? Theme.primary : .clear)
                                .frame(width: 60, height: 3)
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

// MARK: - Match Card

private extension MyMatchesView {
    func myMatchCard(_ match: MyMatchItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            dateBanner(match)

            VStack(alignment: .leading, spacing: 6) {
                // Avatar + title + weather
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(Theme.avatarPlaceholder)
                        .frame(width: 36, height: 36)

                    HStack(spacing: 4) {
                        Text(match.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)

                        if match.isOrganizer {
                            Text("發起人")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.primary)
                                .padding(.horizontal, 6)
                                .frame(height: 18)
                                .background(Theme.confirmedBg)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }

                    Spacer()

                    Text(match.weather)
                        .font(Typography.fieldLabel)
                        .foregroundColor(Theme.textBody)
                }

                // Detail rows
                matchDetailRow(icon: "📍", text: match.location)
                matchDetailRow(icon: "🕐", text: match.timeRange)
                matchDetailRow(icon: "👥", text: match.players)

                // Action buttons — 自动取消的约球不再展示操作按钮
                if match.status == .completed {
                    // 已完成的约球 — 点击查看评论
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Text("查看評論")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.primary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.primary)
                        }
                        .frame(minHeight: 44)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCompletedMatch = match
                    }
                } else if !match.isAutoCancelled {
                    HStack {
                        Spacer()
                        if match.isOrganizer {
                            matchActionButton("管理", style: .filled) {
                                matchToManage = match
                                showManageSheet = true
                            }
                            matchActionButton("取消", style: .outlined) {
                                matchToCancel = match
                                showCancelAlert = true
                            }
                        } else {
                            matchActionButton("💬 聊天", style: .filled) {
                                openChat(for: match)
                            }
                            matchActionButton("取消", style: .outlined) {
                                matchToCancel = match
                                showCancelAlert = true
                            }
                        }
                    }
                }
            }
            .padding(Spacing.sm)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
    }

    func dateBanner(_ match: MyMatchItem) -> some View {
        // 人员不足 + 已过开始时间 → 自动取消(覆盖 confirmed/pending 状态)。
        let autoCancelled = match.isAutoCancelled
        let badgeText = autoCancelled ? "已自動取消" : match.status.rawValue
        let badgeColor = autoCancelled ? Theme.requiredText : match.status.badgeColor
        let bannerColor = autoCancelled ? Theme.requiredBg : match.status.bannerColor
        return HStack {
            Text("🗓️ \(match.dateLabel)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Text(badgeText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xs)
                .frame(height: 20)
                .background(badgeColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, Spacing.sm)
        .frame(height: 30)
        .background(bannerColor)
    }

    func matchDetailRow(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(Typography.small)
            Text(text)
                .font(Typography.small)
                .foregroundColor(Theme.textBody)
        }
        .padding(.leading, 48)
    }

    func matchActionButton(_ title: String, style: MatchActionStyle, action: (() -> Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(style == .filled ? .white : Theme.textBody)
                .padding(.horizontal, Spacing.sm)
                .frame(height: 30)
                .background(style == .filled ? Theme.primary : .white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    if style == .outlined {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    }
                }
                .frame(minWidth: 44, minHeight: 44)
        }
    }
}

// MARK: - Invitation Card

private extension MyMatchesView {
    func invitationCard(_ invitation: MyMatchInvitation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Banner
            Text("📩 收到邀請")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Spacing.sm)
                .frame(height: 26, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.requiredBg)

            // Content
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(invitation.inviterName) 邀請你打\(invitation.matchType)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text(invitation.displayDetails)
                        .font(Typography.fieldLabel)
                        .foregroundColor(Theme.textBody)
                }

                Spacer()

                Button {
                    withAnimation {
                        persistRejection(invitation)
                    }
                    toast = .init(kind: .warning, text: "已拒絕邀請")
                } label: {
                    Text("拒絕")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textBody)
                        .frame(width: 48, height: 26)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.inputBorder, lineWidth: 1)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                }

                Button {
                    let dateString = invitation.details.components(separatedBy: " · ").first ?? ""
                    let location = invitation.details.components(separatedBy: " · ").dropFirst().first ?? ""
                    // 时段冲突拦截:同一时间不能重复报名(CLAUDE.md 边界 case #4)。
                    let scheduleText = "\(dateString) \(invitation.time)"
                    if let range = MatchSchedule.dateRange(
                        text: scheduleText,
                        defaultDurationHours: invitation.durationHours
                    ),
                       let conflict = bookedSlotStore.conflict(start: range.start, end: range.end) {
                        toast = .init(
                            kind: .warning,
                            text: "該時段已與「\(conflict.label)」衝突,請先取消已預訂的時段"
                        )
                        return
                    }
                    let accepted = AcceptedMatchInfo(
                        organizerName: invitation.inviterName,
                        matchType: invitation.matchType,
                        dateString: dateString,
                        time: invitation.time,
                        location: location,
                        sourceMatchID: nil,
                        durationHours: invitation.durationHours
                    )
                    acceptedMatches.append(accepted)
                    if let range = MatchSchedule.dateRange(
                        text: scheduleText,
                        defaultDurationHours: invitation.durationHours
                    ) {
                        let label = "\(invitation.inviterName) \(scheduleText)"
                        bookedSlotStore.add(BookedSlot(
                            id: accepted.id,
                            start: range.start,
                            end: range.end,
                            label: label
                        ))
                    }
                    acceptedInvitation = invitation
                    showAcceptSuccess = true
                } label: {
                    Text("接受")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 26)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
    }
}

// MARK: - Data

private enum MyMatchStatus: String {
    case confirmed = "已確認"
    case pending = "等待中"
    case completed = "已完成"

    var bannerColor: Color {
        switch self {
        case .confirmed: return Theme.confirmedBg
        case .pending: return Theme.pendingBg
        case .completed: return Theme.chipUnselectedBg
        }
    }

    var badgeColor: Color {
        switch self {
        case .confirmed: return Theme.primary
        case .pending: return Theme.pendingBadge
        case .completed: return Theme.textSecondary
        }
    }
}

private enum MatchActionStyle {
    case filled, outlined
}

private struct MyMatchItem: Identifiable {
    let id = UUID()
    let title: String
    let isOrganizer: Bool
    let status: MyMatchStatus
    let dateLabel: String
    let location: String
    let timeRange: String
    let players: String
    let weather: String
    var matchType: String = "單打"
    var acceptedMatchID: UUID?  // links back to AcceptedMatchInfo for cancellation
    var sourceMatchID: UUID?    // links back to the originating HomeView match (if any)

    /// Parses `"2/4 · NTRP 3.0-4.0"` → (current: 2, max: 4). Falls back to (0, 0)
    /// when the players string lacks two leading numeric tokens.
    var playerCounts: (current: Int, max: Int) {
        let digits = players.split { !$0.isNumber }.map(String.init)
        guard digits.count >= 2,
              let current = Int(digits[0]),
              let mx = Int(digits[1]) else { return (0, 0) }
        return (current, mx)
    }

    /// 起始时间已过且未满员 — 视为"人员不足,自动取消"(CLAUDE.md 边界 case #2)。
    /// `sortDate == .distantFuture` 表示无法解析日期,此时保守返回 false。
    var isAutoCancelled: Bool {
        let counts = playerCounts
        guard counts.max > 0, counts.current < counts.max else { return false }
        guard sortDate != .distantFuture else { return false }
        return sortDate < .now
    }

    /// Parsed date used for chronological sorting. Pulls MM/dd from `dateLabel`
    /// and combines it with the start hour of `timeRange` so same-day items
    /// order by time. Items without a parseable date sort to the end.
    var sortDate: Date {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        var month = 0
        var day = 0
        if let match = dateLabel.range(of: #"(\d{1,2})/(\d{1,2})"#, options: .regularExpression) {
            let parts = dateLabel[match].split(separator: "/")
            month = Int(parts[0]) ?? 0
            day = Int(parts.count > 1 ? parts[1] : "0") ?? 0
        }
        guard month > 0, day > 0 else { return .distantFuture }
        let hour = Int(timeRange.prefix(2)) ?? 0
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return cal.date(from: components) ?? .distantFuture
    }
}

private struct MyMatchInvitation: Identifiable {
    let id = UUID()
    let inviterName: String
    let matchType: String
    let details: String
    let time: String            // "14:00"
    let durationHours: Int      // e.g. 2

    /// 显示用文本,在日期后插入时段。
    /// "04/25 · 將軍澳 · NTRP 3.5" → "04/25 18:00 - 20:00 · 將軍澳 · NTRP 3.5"
    var displayDetails: String {
        let startHour = Int(time.prefix(2)) ?? 0
        let startMin = time.count >= 5 ? String(time.suffix(2)) : "00"
        let endHour = startHour + durationHours
        let endTime = String(format: "%02d:%@", endHour, startMin)
        let parts = details.components(separatedBy: " · ")
        guard let datePart = parts.first else { return details }
        let rest = parts.dropFirst().joined(separator: " · ")
        return "\(datePart) \(time) - \(endTime) · \(rest)"
    }
}

private let mockUpcomingMatchesInitial: [MyMatchItem] = [
    MyMatchItem(
        title: "莎拉 發起的單打",
        isOrganizer: false,
        status: .confirmed,
        dateLabel: "明天 · 04/23（三）",
        location: "維多利亞公園網球場",
        timeRange: "10:00 - 12:00",
        players: "2/2 · NTRP 3.0-4.0",
        weather: "☀️ 24°C"
    ),
    MyMatchItem(
        title: "我發起的雙打",
        isOrganizer: true,
        status: .pending,
        dateLabel: "04/25（五）",
        location: "跑馬地遊樂場",
        timeRange: "14:00 - 16:00",
        players: "2/4 · NTRP 3.5-4.5",
        weather: "⛅ 26°C"
    ),
    MyMatchItem(
        title: "大衛 發起的雙打",
        isOrganizer: false,
        status: .confirmed,
        dateLabel: "04/26（六）",
        location: "歌和老街公園網球場",
        timeRange: "18:30 - 20:00",
        players: "3/4 · NTRP 4.0-5.0",
        weather: "☀️ 24°C",
        matchType: "雙打"
    ),
    MyMatchItem(
        title: "我發起的雙打",
        isOrganizer: true,
        status: .pending,
        dateLabel: "04/28（一）",
        location: "將軍澳運動場",
        timeRange: "18:00 - 20:00",
        players: "2/2 · NTRP 3.0-4.0",
        weather: "☀️ 24°C",
        matchType: "雙打"
    ),
    MyMatchItem(
        title: "Michael 發起的單打",
        isOrganizer: false,
        status: .confirmed,
        dateLabel: "04/30（三）",
        location: "跑馬地遊樂場",
        timeRange: "08:00 - 10:00",
        players: "2/2 · NTRP 4.5-5.0",
        weather: "☀️ 25°C"
    ),
]

private let mockCompletedMatches: [MyMatchItem] = [
    MyMatchItem(
        title: "王強 發起的雙打",
        isOrganizer: false,
        status: .completed,
        dateLabel: "04/12（六）",
        location: "九龍仔公園",
        timeRange: "14:00 - 16:00",
        players: "4/4 · NTRP 3.5-4.5",
        weather: "☀️ 28°C"
    ),
    MyMatchItem(
        title: "我發起的單打",
        isOrganizer: true,
        status: .completed,
        dateLabel: "04/10（四）",
        location: "香港網球中心",
        timeRange: "09:00 - 11:00",
        players: "2/2 · NTRP 3.0-4.0",
        weather: "🌤 25°C"
    ),
    MyMatchItem(
        title: "大衛 發起的雙打",
        isOrganizer: false,
        status: .completed,
        dateLabel: "04/06（日）",
        location: "歌和老街公園",
        timeRange: "16:00 - 18:00",
        players: "4/4 · NTRP 4.0-5.0",
        weather: "☀️ 27°C",
        matchType: "雙打"
    ),
    MyMatchItem(
        title: "嘉欣 發起的雙打",
        isOrganizer: false,
        status: .completed,
        dateLabel: "03/29（六）",
        location: "沙田公園",
        timeRange: "10:00 - 12:00",
        players: "4/4 · NTRP 3.0-3.5",
        weather: "⛅ 23°C",
        matchType: "雙打"
    ),
    MyMatchItem(
        title: "我發起的單打",
        isOrganizer: true,
        status: .completed,
        dateLabel: "03/22（六）",
        location: "維多利亞公園網球場",
        timeRange: "08:00 - 10:00",
        players: "2/2 · NTRP 3.5-4.0",
        weather: "☀️ 22°C"
    ),
]

private let mockInvitations: [MyMatchInvitation] = [
    MyMatchInvitation(
        inviterName: "艾美",
        matchType: "單打",
        details: "04/24 · 京士柏 · NTRP 3.0",
        time: "14:00",
        durationHours: 2
    ),
    MyMatchInvitation(
        inviterName: "俊傑",
        matchType: "雙打",
        details: "04/26 · 將軍澳 · NTRP 3.5-4.5",
        time: "18:00",
        durationHours: 2
    ),
    MyMatchInvitation(
        inviterName: "思慧",
        matchType: "單打",
        details: "04/28 · 香港公園 · NTRP 3.0-3.5",
        time: "09:00",
        durationHours: 2
    ),
]

// MARK: - Invitation Accept Success

private struct InvitationAcceptSuccessView: View {
    let invitation: MyMatchInvitation
    var onContactOrganizer: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var calendarToast: String?

    private var detailParts: [String] {
        invitation.details.components(separatedBy: " · ")
    }

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

            Text("已接受邀請！")
                .font(Typography.title)
                .foregroundColor(Theme.textDark)

            Text("你已加入\(invitation.inviterName)的\(invitation.matchType)約球")
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textHint)
                .padding(.top, Spacing.xs)

            Spacer().frame(height: Spacing.lg)

            // Summary card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let date = detailParts.first {
                    summaryRow(icon: "calendar", text: date)
                }
                if detailParts.count > 1 {
                    summaryRow(icon: "mappin.and.ellipse", text: detailParts[1])
                }
                if detailParts.count > 2 {
                    summaryRow(icon: "figure.tennis", text: "\(invitation.matchType) · \(detailParts[2])")
                }
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
                outlineButton(icon: "bubble.left.fill", label: "私信\(invitation.inviterName)") {
                    onContactOrganizer?()
                }
                outlineButton(icon: "calendar.badge.plus", label: "加入日曆") {
                    saveInvitationToCalendar()
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            Button { dismiss() } label: {
                Text("返回我的約球")
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

    private func saveInvitationToCalendar() {
        guard let monthDay = detailParts.first,
              let range = CalendarService.parseShortMatch(
                monthDay: monthDay,
                startTime: invitation.time,
                durationHours: invitation.durationHours
              ) else {
            calendarToast = "無法解析約球時間"
            return
        }
        let location = detailParts.count > 1 ? detailParts[1] : ""
        let title = "\(invitation.inviterName) 的\(invitation.matchType)"
        let notes = "\(invitation.matchType) · \(invitation.details)"
        Task {
            do {
                try await CalendarService.addEvent(
                    title: title,
                    startDate: range.start,
                    endDate: range.end,
                    location: location,
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

// MARK: - Toast Model

/// One-slot toast payload. `id` lets SwiftUI's `.task(id:)` cancel the
/// auto-dismiss of a previous toast when a new one replaces it.
private struct ToastMessage: Equatable, Identifiable {
    enum Kind {
        case success, warning, info
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "xmark.circle.fill"
            case .info:    return "hourglass"
            }
        }
    }
    let id = UUID()
    let kind: Kind
    let text: String
}

// MARK: - Completed Match Review

private struct MatchReviewItem: Identifiable {
    let id = UUID()
    let reviewerName: String
    let isMyReview: Bool
    let rating: Int
    let comment: String
    let date: String
}

private struct CompletedMatchReviewSheet: View {
    let match: MyMatchItem
    @Environment(\.dismiss) private var dismiss

    private var reviews: [MatchReviewItem] {
        reviewsForMatch(match)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // 约球摘要
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(match.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        HStack(spacing: Spacing.sm) {
                            Label(match.dateLabel, systemImage: "calendar")
                            Label(match.timeRange, systemImage: "clock")
                        }
                        .font(Typography.small)
                        .foregroundColor(Theme.textSecondary)
                        Label(match.location, systemImage: "mappin.circle")
                            .font(Typography.small)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // 评论区
                    Text("互相評論")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    if reviews.isEmpty {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.textSecondary)
                            Text("暫無評論")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                            Text("雙方尚未留下評論")
                                .font(Typography.small)
                                .foregroundColor(Theme.textCaption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xl)
                    } else {
                        ForEach(reviews) { review in
                            reviewCard(review)
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Theme.background)
            .navigationTitle("約球評論")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
        }
    }

    private func reviewCard(_ review: MatchReviewItem) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(review.isMyReview ? Theme.primary : Theme.avatarPlaceholder)
                    .frame(width: 36, height: 36)
                Text(String(review.reviewerName.prefix(1)))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(review.reviewerName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    if review.isMyReview {
                        Text("我的評論")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.primary)
                            .padding(.horizontal, 6)
                            .frame(height: 16)
                            .background(Theme.confirmedBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    Spacer()
                    Text(review.date)
                        .font(Typography.fieldLabel)
                        .foregroundColor(Theme.textSecondary)
                }

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < review.rating ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundColor(i < review.rating ? Theme.starYellow : Theme.textSecondary)
                    }
                }

                Text(review.comment)
                    .font(Typography.caption)
                    .foregroundColor(Theme.textBody)
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// 根据已完成约球生成 mock 评论数据。评论是自愿的,部分约球可能没有评论。
private func reviewsForMatch(_ match: MyMatchItem) -> [MatchReviewItem] {
    let dateStr = match.dateLabel.replacingOccurrences(of: "（.*?）", with: "", options: .regularExpression)
        .trimmingCharacters(in: .whitespaces)
    if dateStr.contains("04/12") {
        return [
            MatchReviewItem(reviewerName: "王強", isMyReview: false, rating: 5,
                            comment: "配合默契，球技穩健，歡迎下次再來！", date: "04/12"),
            MatchReviewItem(reviewerName: "我", isMyReview: true, rating: 4,
                            comment: "打得很開心，場地不錯", date: "04/12"),
        ]
    } else if dateStr.contains("04/10") {
        return [
            MatchReviewItem(reviewerName: "莎拉", isMyReview: false, rating: 5,
                            comment: "很準時到達，球技好，節奏掌控佳", date: "04/10"),
        ]
    } else if dateStr.contains("04/06") {
        return [
            MatchReviewItem(reviewerName: "大衛", isMyReview: false, rating: 4,
                            comment: "接發球很到位，下次再約！", date: "04/06"),
            MatchReviewItem(reviewerName: "我", isMyReview: true, rating: 5,
                            comment: "球風穩健，值得推薦的球友", date: "04/06"),
        ]
    } else if dateStr.contains("03/29") {
        // 暂无评论 — 双方都没有留下评论(自愿)
        return []
    } else if dateStr.contains("03/22") {
        return [
            MatchReviewItem(reviewerName: "對手", isMyReview: false, rating: 4,
                            comment: "準時開場，球場狀況好", date: "03/22"),
            MatchReviewItem(reviewerName: "我", isMyReview: true, rating: 4,
                            comment: "對手水平匹配，打得盡興", date: "03/22"),
        ]
    }
    return []
}

// MARK: - Preview

#Preview("iPhone SE") {
    MyMatchesView(acceptedMatches: .constant([]), sharedChats: .constant([]))
}

#Preview("iPhone 15 Pro") {
    MyMatchesView(acceptedMatches: .constant([]), sharedChats: .constant([]))
}
