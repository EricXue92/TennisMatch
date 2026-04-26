//
//  HomeView.swift
//  TennisMatch
//
//  首頁 — 統計、推薦、約球列表、底部 Tab
//

import SwiftUI

// MARK: - Main Tab Container

struct HomeView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(FollowStore.self) private var followStore
    @Environment(BookingStore.self) private var bookingStore
    @Environment(NotificationStore.self) private var notificationStore
    @Environment(InviteStore.self) private var inviteStore
    @State private var showDrawer = false
    @State private var showTournaments = false
    @State private var selectedTab = 0
    @State private var selectedFilter = "全部"
    private let matchFilterOptions = ["全部", "單打", "雙打", "拉球"]
    @State private var showFilterPanel = false
    @State private var ntrpLow: Double = 1.0
    @State private var ntrpHigh: Double = 7.0
    @State private var selectedAgeRange: Set<String> = []
    @State private var selectedGender: String = ""
    @State private var selectedCourts: Set<TennisCourt> = []
    @State private var selectedDays: Set<String> = []
    @State private var timeFrom: Double = 7.0
    @State private var timeTo: Double = 23.0
    @State private var selectedMatchDetail: MatchDetailData?
    @State private var showCreateMatch = false
    @State private var signUpMatch: SignUpMatchInfo?
    @State private var successMatch: SignUpMatchInfo?
    @State private var matches: [MockMatch] = initialMockMatches
    @State private var upcomingMatches: [MyMatchItem] = mockUpcomingMatchesInitial
    @State private var signUpMatchId: UUID?
    @State private var chatUnreadCount = 0
    @State private var sharedChats: [MockChat] = mockChatsInitial
    @State private var drawerNav: DrawerDestination?
    @State private var pendingDMOrganizer: SignUpMatchInfo?
    @State private var dmChat: MockChat?
    @State private var dmMatchContext: String?
    @State private var dmInitialMessage: String?
    /// Sign-up留言 captured on confirm — carried to dmChat when user
    /// chooses "聯繫發起人" from the success screen.
    @State private var pendingSignUpMessage: String = ""
    /// Top toast for booking-conflict warnings shown when the user taps 報名
    /// on a match whose start window overlaps an existing booking.
    @State private var conflictToast: String?
    /// Selected player for navigating to PublicProfileView
    @State private var selectedPlayer: PublicPlayerData?

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case 0: homeTab
                case 1: MyMatchesView(
                    sharedChats: $sharedChats,
                    upcomingMatches: $upcomingMatches,
                    onGoHome: { selectedTab = 0 },
                    onGoTournaments: { showTournaments = true },
                    onMatchCancelled: { payload in
                        handleMyMatchCancellation(payload)
                    },
                    onInviteAccepted: { _, _, sourceMatchID in
                        guard let id = sourceMatchID,
                              let idx = matches.firstIndex(where: { $0.id == id }) else { return }
                        matches[idx].currentPlayers += 1
                    },
                    onInviteUndoAccepted: { _, sourceMatchID in
                        guard let id = sourceMatchID,
                              let idx = matches.firstIndex(where: { $0.id == id }),
                              matches[idx].currentPlayers > 0 else { return }
                        matches[idx].currentPlayers -= 1
                    }
                )
                case 2: MatchAssistantView()
                case 3: MessagesView(
                    totalUnread: $chatUnreadCount,
                    chats: $sharedChats,
                    matchActions: makeMessagesActions(),
                    matchLookup: { id in upcomingMatches.first(where: { $0.id == id }) }
                )
                case 4: ProfileView()
                default: homeTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab, chatUnreadCount: chatUnreadCount) {
                showCreateMatch = true
            }

            // 側邊抽屜
            if showDrawer {
                DrawerView(
                    isPresented: $showDrawer,
                    unreadNotificationCount: notificationStore.unreadCount
                ) { destination in
                    if destination == .tournaments {
                        showTournaments = true
                    } else {
                        drawerNav = destination
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showTournaments) {
            TournamentView()
        }
        .fullScreenCover(isPresented: $showCreateMatch) {
            NavigationStack {
                CreateMatchView(onPublish: { info in
                    addPublishedMatch(info)
                    conflictToast = L10n.string("約球已成功發布 🎾")
                })
            }
        }
        .sheet(item: $signUpMatch) { info in
            SignUpConfirmSheet(match: info) { message in
                if let matchId = signUpMatchId,
                   let idx = matches.firstIndex(where: { $0.id == matchId }) {
                    matches[idx].currentPlayers += 1
                    let accepted = makeAcceptedMatchInfo(for: matches[idx])
                    // showSignUp 已先做过 conflict 检查;这里 signUp 二次校验属防御性。
                    switch bookingStore.signUp(matchID: matchId, info: accepted) {
                    case .ok, .alreadySignedUp:
                        break
                    case .conflict(let label):
                        // 极少触发(只有先后异步注入的 externalSlots 才会到这一步)。
                        conflictToast = L10n.string("該時段已與「\(label)」衝突,請先取消已預訂的時段")
                        if matches[idx].currentPlayers > 0 {
                            matches[idx].currentPlayers -= 1
                        }
                        return
                    }
                }
                pendingSignUpMessage = message
                successMatch = info
            }
            .presentationDetents([.medium])
        }
        .fullScreenCover(item: $successMatch, onDismiss: {
            if let info = pendingDMOrganizer {
                let symbol = info.organizerGender.symbol
                let color = info.organizerGender == .female ? Theme.genderFemale : Theme.genderMale
                let chat = MockChat(
                    type: .personal(name: info.organizerName, symbol: symbol, symbolColor: color),
                    lastMessage: "點擊開始聊天",
                    time: "剛剛",
                    unreadCount: 0
                )
                dmChat = chat
                dmMatchContext = "🎾 約球已確認\n📅 \(info.dateTime)\n📍 \(info.location)\n🏸 \(info.matchType) · NTRP \(info.ntrpRange)\n💰 \(info.fee)"
                let trimmed = pendingSignUpMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                dmInitialMessage = trimmed.isEmpty ? nil : trimmed
                // 同步到共享聊天列表
                if !sharedChats.contains(where: { $0.id == chat.id }) {
                    sharedChats.insert(chat, at: 0)
                }
                pendingDMOrganizer = nil
                pendingSignUpMessage = ""
            }
        }) { info in
            SignUpSuccessView(match: info, onContactOrganizer: {
                pendingDMOrganizer = info
                successMatch = nil
            })
        }
        .navigationDestination(item: $selectedMatchDetail) { detail in
            MatchDetailView(
                match: detail,
                onSignUp: { matchId in
                    if let idx = matches.firstIndex(where: { $0.id == matchId }) {
                        matches[idx].currentPlayers += 1
                    }
                }
            )
        }
        .navigationDestination(item: $drawerNav) { dest in
            switch dest {
            case .matchAssistant: MatchAssistantView()
            case .reviews:        ReviewsView()
            case .notifications:  NotificationsView()
            case .tipDeveloper:   TipDeveloperView()
            case .blockList:      BlockListView()
            case .inviteFriends:  InviteFriendsView()
            case .settings:       SettingsView()
            case .help:           HelpView()
            case .tournaments:    EmptyView() // handled via fullScreenCover
            }
        }
        .navigationDestination(item: $selectedPlayer) { player in
            PublicProfileView(player: player)
        }
        .navigationDestination(item: $dmChat) { chat in
            ChatDetailView(
                chat: chat,
                matchContext: dmMatchContext,
                initialMessage: dmInitialMessage
            )
            .onDisappear {
                dmMatchContext = nil
                dmInitialMessage = nil
            }
        }
        .overlay(alignment: .top) {
            calendarToastBanner($conflictToast, systemImage: "exclamationmark.triangle.fill")
        }
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        VStack(spacing: 0) {
            headerSection
            ScrollView {
                VStack(spacing: 0) {
                    RecommendedPlayersSection(selectedPlayer: $selectedPlayer)
                    dividerLine
                    filterChips
                    if showFilterPanel {
                        MatchFilterPanelView(
                            ntrpLow: $ntrpLow,
                            ntrpHigh: $ntrpHigh,
                            selectedAgeRange: $selectedAgeRange,
                            selectedGender: $selectedGender,
                            selectedCourts: $selectedCourts,
                            selectedDays: $selectedDays,
                            timeFrom: $timeFrom,
                            timeTo: $timeTo,
                            onDismiss: { withAnimation(.easeInOut(duration: 0.25)) { showFilterPanel = false } }
                        )
                    }
                    matchCardList
                }
                .padding(.bottom, 80)
            }
            .refreshable {
                // Mock 階段模擬刷新
                try? await Task.sleep(for: .seconds(0.8))
            }
        }
        .background(Theme.inputBg)
    }
}

// MARK: - Header

private extension HomeView {
    /// 根據時間給出問候 — 早 / 午 / 晚。
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11:  return "早安"
        case 11..<14: return "午安"
        case 14..<18: return "下午好"
        case 18..<23: return "晚上好"
        default:      return "夜深了"
        }
    }

    var headerSection: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    showDrawer = true
                }
            } label: {
                VStack(spacing: 3.5) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.white)
                            .frame(width: 22, height: 2)
                    }
                }
                .frame(width: 44, height: 44)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Theme.badge)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: 6)
                }
            }

            // 問候 + 副標
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(greeting + "，")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                    Text(userStore.displayName)
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundColor(.white)
                    Text("👋")
                        .font(.system(size: 14))
                }
                Text("揮拍時刻，找到合適的球友")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.78))
            }

            Spacer()

            // 天氣 chip
            HStack(spacing: 4) {
                Text("☀️")
                    .font(.system(size: 12))
                Text("24°C")
                    .font(Typography.smallMedium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(.white.opacity(0.18))
            )
            .overlay(
                Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.sm)
        // bg 用 ignoresSafeArea(edges: .top) 將綠色延伸到狀態列下方,
        // 容器本身仍然吃 safe area,所以 hamburger / 天氣 chip 不會跟系統圖示重疊。
        .background(
            LinearGradient(
                colors: [Theme.primary, Theme.primaryDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 180, height: 180)
                    .blur(radius: 30)
                    .offset(x: 60, y: -90)
            }
            .ignoresSafeArea(edges: .top)
        )
    }
}

// MARK: - Filters

private extension HomeView {
    var dividerLine: some View {
        Theme.inputBorder.frame(height: 1)
    }

    var hasNTRPFilter: Bool {
        ntrpLow != 1.0 || ntrpHigh != 7.0
    }

    var hasTimeFilter: Bool {
        !selectedDays.isEmpty || timeFrom != 7.0 || timeTo != 23.0
    }

    var activeFilterCount: Int {
        (hasNTRPFilter ? 1 : 0) + selectedAgeRange.count + (selectedGender.isEmpty ? 0 : 1) + selectedCourts.count + (hasTimeFilter ? 1 : 0)
    }

    var filterChips: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(matchFilterOptions, id: \.self) { option in
                let isSelected = option == selectedFilter
                Button {
                    selectedFilter = option
                } label: {
                    Text(LocalizedStringKey(option))
                        .font(Typography.captionMedium)
                        .foregroundColor(isSelected ? .white : Theme.textBody)
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 30)
                        .background(isSelected ? Theme.primary : .white)
                        .clipShape(Capsule())
                        .overlay {
                            if !isSelected {
                                Capsule().stroke(Theme.inputBorder, lineWidth: 1)
                            }
                        }
                }
                .frame(minHeight: 44)
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showFilterPanel.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(Typography.smallMedium)
                    Text("篩選")
                        .font(Typography.smallMedium)
                    if activeFilterCount > 0 {
                        Text("\(activeFilterCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Theme.badge)
                            .clipShape(Circle())
                    }
                }
                .foregroundColor(showFilterPanel ? .white : Theme.primary)
                .padding(.horizontal, Spacing.sm)
                .frame(height: 30)
                .background(showFilterPanel ? Theme.primary : .white)
                .clipShape(Capsule())
                .overlay {
                    if !showFilterPanel {
                        Capsule().stroke(Theme.primary, lineWidth: 1)
                    }
                }
            }
            .frame(minHeight: 44)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Theme.surface)
    }
}

// MARK: - Match Cards

private extension HomeView {
    var filteredMatches: [MockMatch] {
        let filtered = matches.filter { match in
            // 首页只显示未来可约的信息,过期/自动取消的不展示
            if match.isExpired { return false }
            // 已报名的约球不再显示在首页,已移至"我的约球"
            if bookingStore.isSignedUp(matchID: match.id) { return false }
            // 滿員約球從首頁消失(包括自己發起的)— 已轉移到「我的約球 → 即將到來」管理
            if match.isFull { return false }
            // Match type filter
            if selectedFilter != "全部" && match.matchType != selectedFilter {
                return false
            }
            // NTRP range: match's range must overlap with selected range
            if hasNTRPFilter && !match.isOwnMatch {
                if match.ntrpHigh < ntrpLow || match.ntrpLow > ntrpHigh {
                    return false
                }
            }
            // Age range
            if !selectedAgeRange.isEmpty && !match.isOwnMatch && !selectedAgeRange.contains(match.ageRange) {
                return false
            }
            // Gender (single select)
            if !selectedGender.isEmpty && selectedGender != "不限" && !match.isOwnMatch && selectedGender != match.genderLabel {
                return false
            }
            // Court
            if !selectedCourts.isEmpty && !match.isOwnMatch {
                let courtNames = selectedCourts.map(\.name)
                if !courtNames.contains(where: { match.location.contains($0) }) {
                    return false
                }
            }
            // Time: check hour range and day of week
            if hasTimeFilter && !match.isOwnMatch {
                if Double(match.hour) < timeFrom || Double(match.hour) > timeTo {
                    return false
                }
                if !selectedDays.isEmpty && !selectedDays.contains(match.dayOfWeek) {
                    return false
                }
            }
            return true
        }
        // 按时间排列,最近的时间在最上面
        return filtered.sorted { $0.sortDate < $1.sortDate }
    }

    var matchCardList: some View {
        VStack(spacing: Spacing.md) {
            if filteredMatches.isEmpty {
                ContentUnavailableView {
                    Label("沒有符合條件的約球", systemImage: "magnifyingglass")
                } description: {
                    Text("試試調整篩選條件，或發起一場新的約球")
                } actions: {
                    Button("清除篩選") {
                        selectedFilter = "全部"
                        ntrpLow = 1.0; ntrpHigh = 7.0
                        selectedAgeRange.removeAll()
                        selectedGender = ""
                        selectedCourts.removeAll()
                        selectedDays.removeAll()
                        timeFrom = 7.0; timeTo = 23.0
                        showFilterPanel = false
                    }
                    .buttonStyle(.bordered)

                    Button("發起約球") {
                        showCreateMatch = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primary)
                }
            } else {
                ForEach(filteredMatches) { match in
                    matchCard(match)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.xl)
    }

    /// 自己發起的約球(`isOwnMatch == true`)的展示名 / 性別跟隨 `UserStore` 實時值,
    /// 而非創建時寫進 `MockMatch` 的快照。改名後首頁卡片立刻同步,接後端時這套邏輯
    /// 自然演進為 `host.userId == currentUser.userId` 的判斷。
    private func hostDisplayName(for match: MockMatch) -> String {
        match.isOwnMatch ? userStore.displayName : match.name
    }

    private func hostDisplayGender(for match: MockMatch) -> Gender {
        match.isOwnMatch ? userStore.gender : match.gender
    }

    func matchCard(_ match: MockMatch) -> some View {
        Button {
            navigateToDetail(match)
        } label: {
        VStack(alignment: .leading, spacing: 6) {
            // Row 1: avatar + name + gender + type + weather
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(hostDisplayName(for: match))
                            .font(Typography.bodyMedium)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                        let hostGender = hostDisplayGender(for: match)
                        Text(hostGender.symbol)
                            .font(Typography.bodyMedium)
                            .foregroundColor(hostGender == .female ? Theme.genderFemale : Theme.genderMale)

                        Text(match.matchType)
                            .font(Typography.micro)
                            .foregroundColor(Theme.textBody)
                            .padding(.horizontal, 6)
                            .frame(height: 18)
                            .background(Theme.chipUnselectedBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }

                Spacer()

                Text(match.weather)
                    .font(Typography.smallMedium)
                    .foregroundColor(Theme.textBody)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.inputBg)
                    .clipShape(Capsule())
            }

            // Detail rows — SF Symbol 圖示 + 文本
            detailRow(symbol: "calendar", text: match.dateTimeDisplay)
            detailRow(symbol: "mappin.and.ellipse", text: match.location)
            detailRow(symbol: "person.2.fill", text: match.players)

            // Bottom: tags + sign up button
            HStack(spacing: Spacing.xs) {
                Text(match.fee)
                    .font(Typography.micro)
                    .foregroundColor(Theme.textBody)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 22)
                    .background(Theme.chipUnselectedBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(match.isOwnMatch ? "我發起的" : "招募中")
                    .font(Typography.micro)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 22)
                    .background(match.isOwnMatch ? Theme.accentGreen : Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()

                if !match.isOwnMatch {
                    let autoCancelled = match.isAutoCancelled
                    let alreadySignedUp = !autoCancelled && bookingStore.isSignedUp(matchID: match.id)
                    // Precedence: auto-cancel > already-signed-up > expired > full > open for sign-up.
                    // - Auto-cancelled (expired & under capacity) wins over 已報名 because the match never ran.
                    // - Already-signed-up wins next: the slot is genuinely booked.
                    // - Expired beats full: a past match is no longer actionable regardless of capacity.
                    let expiredForOthers = !autoCancelled && !alreadySignedUp && match.isExpired
                    let isFullForOthers = !autoCancelled && !alreadySignedUp && !expiredForOthers && match.isFull
                    let disabled = autoCancelled || alreadySignedUp || expiredForOthers || isFullForOthers
                    let label: String = {
                        if autoCancelled { return "已自動取消" }
                        if alreadySignedUp { return "已報名" }
                        if expiredForOthers { return "已過期" }
                        if isFullForOthers { return "已額滿" }
                        return "報名"
                    }()

                    Button {
                        showSignUp(match)
                    } label: {
                        Text(LocalizedStringKey(label))
                            .font(Typography.smallMedium)
                            .foregroundColor(disabled ? Theme.textSecondary : .white)
                            .frame(minWidth: 52, idealWidth: 52)
                            .padding(.horizontal, autoCancelled ? Spacing.xs : 0)
                            .frame(height: 30)
                            .background(disabled ? Theme.chipUnselectedBg : Theme.primaryDark)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .disabled(disabled)
                }
            }
        }
        .padding(Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
        .overlay(alignment: .leading) {
            if match.isOwnMatch {
                Theme.primary
                    .frame(width: 4)
                    .padding(.vertical, Spacing.sm)
            }
        }
        } // end label
        .buttonStyle(.plain)
    }

    func navigateToDetail(_ match: MockMatch) {
        selectedMatchDetail = makeMatchDetail(from: match)
    }

    func showSignUp(_ match: MockMatch) {
        guard !match.isFull else { return }
        guard !match.isExpired else { return }
        guard !bookingStore.isSignedUp(matchID: match.id) else { return }

        // 时段冲突拦截:同一时间不能重复报名(CLAUDE.md 边界 case #4)。
        // 查询统一从 BookingStore.conflict 走,涵盖 accepted + externalSlots。
        let range = matchTimeWindow(for: match)
        if let conflict = bookingStore.conflict(start: range.start, end: range.end, excluding: match.id) {
            conflictToast = L10n.string("該時段已與「\(conflict.label)」衝突,請先取消已預訂的時段")
            return
        }

        // Phase 2a: 显示字段直接从 startDate 派生,确保与底层 Date 一致。
        let endDate = match.startDate.addingTimeInterval(2 * 3600)
        let date = AppDateFormatter.yearMonthDay.string(from: match.startDate)
        let startTime = AppDateFormatter.hourMinute.string(from: match.startDate)
        let endTime = AppDateFormatter.hourMinute.string(from: endDate)
        let timeRange = "\(startTime) - \(endTime)"

        signUpMatchId = match.id

        // Build info with incremented player count (preview of after sign-up)
        let newCount = match.currentPlayers + 1
        let playersStr = "\(newCount)/\(match.maxPlayers)"

        signUpMatch = SignUpMatchInfo(
            organizerName: match.name,
            organizerGender: match.gender,
            dateTime: "\(date)  \(timeRange)",
            location: match.location,
            matchType: match.matchType,
            ntrpRange: String(format: "%.1f-%.1f", match.ntrpLow, match.ntrpHigh),
            fee: match.fee,
            notes: "自帶球拍和球",
            players: playersStr,
            isFull: newCount >= match.maxPlayers,
            startDate: match.startDate,
            endDate: endDate
        )
    }

    /// 取 `MockMatch` 的起止时间窗口(默认 2 小时);Phase 2a 之后直接基于 `startDate`。
    func matchTimeWindow(for match: MockMatch) -> (start: Date, end: Date) {
        (start: match.startDate, end: match.startDate.addingTimeInterval(2 * 3600))
    }

    func makeMatchDetail(from match: MockMatch) -> MatchDetailData {
        // Phase 2a: 显示字段从 startDate 派生。
        let endDate = match.startDate.addingTimeInterval(2 * 3600)
        let date = AppDateFormatter.yearMonthDay.string(from: match.startDate)
        let startTime = AppDateFormatter.hourMinute.string(from: match.startDate)
        let endTime = AppDateFormatter.hourMinute.string(from: endDate)
        let timeRange = "\(startTime) - \(endTime)"

        // Parse weather emoji + temp
        let temp = match.weather.replacingOccurrences(of: "☀️ ", with: "")
            .replacingOccurrences(of: "⛅ ", with: "")
            .replacingOccurrences(of: "🌤 ", with: "")

        let hostName = hostDisplayName(for: match)
        let hostGender = hostDisplayGender(for: match)

        return MatchDetailData(
            matchId: match.id,
            name: hostName,
            gender: hostGender,
            ntrp: String(format: "%.1f", (match.ntrpLow + match.ntrpHigh) / 2),
            reputation: [85, 88, 90, 92, 78, 95][abs(match.name.hashValue) % 6],
            matchType: match.matchType,
            date: date,
            timeRange: timeRange,
            startDate: match.startDate,
            endDate: endDate,
            location: match.location,
            district: "香港",
            players: match.players.components(separatedBy: " •").first ?? match.players,
            ntrpRange: String(format: "%.1f-%.1f", match.ntrpLow, match.ntrpHigh),
            fee: match.fee,
            notes: "自帶球拍和球，準時到達",
            weather: MatchWeather(temp: temp, humidity: "65%", uv: "6", wind: "10"),
            participantList: [
                MatchParticipant(name: hostName, gender: hostGender, ntrp: String(format: "%.1f", match.ntrpLow), isOrganizer: true)
            ],
            isOwnMatch: match.isOwnMatch
        )
    }

    /// 由 `MockMatch` 构造写入 BookingStore 的 AcceptedMatchInfo。
    /// Phase 2a:显示字段从 `startDate` 派生,与底层 Date 一致。
    func makeAcceptedMatchInfo(for match: MockMatch) -> AcceptedMatchInfo {
        let start = match.startDate
        let end = start.addingTimeInterval(2 * 3600)
        let dateStr = AppDateFormatter.monthDay.string(from: start)
        let startTime = AppDateFormatter.hourMinute.string(from: start)

        return AcceptedMatchInfo(
            organizerName: match.name,
            matchType: match.matchType,
            dateString: dateStr,
            time: startTime,
            location: match.location,
            sourceMatchID: match.id,
            durationHours: 2,
            players: "\(match.currentPlayers)/\(match.maxPlayers)",
            ntrpRange: String(format: "%.1f-%.1f", match.ntrpLow, match.ntrpHigh),
            startDate: start,
            endDate: end
        )
    }

    private func makeMessagesActions() -> InviteMatchActions {
        InviteMatchActions(
            acceptInvite: { invite in
                applyInviteAcceptInHome(invite)
            },
            undoAcceptInvite: { invite in
                applyInviteUndoAcceptInHome(invite)
            }
        )
    }

    /// 用戶從「聊天」tab 接受邀請時的 home 端副作用 —— 同步寫 upcomingMatches
    /// 與首頁 matches.currentPlayers,行為與 MyMatchesView.applyInviteAccept 對齊。
    private func applyInviteAcceptInHome(_ invite: InviteStore.Invite) {
        guard let idx = upcomingMatches.firstIndex(where: { $0.id == invite.matchID }) else { return }
        var match = upcomingMatches[idx]
        guard !match.registrants.contains(where: { $0.name == invite.inviteeName }) else { return }
        match.registrants.append(MatchRegistrant(
            name: invite.inviteeName,
            gender: invite.inviteeGender,
            ntrp: invite.inviteeNTRP,
            isOrganizer: false
        ))
        let (cur, mx) = match.playerCounts
        let newCurrent = cur + 1
        let ntrpRange = match.players.components(separatedBy: "NTRP ").last ?? ""
        match.players = "\(newCurrent)/\(mx) · NTRP \(ntrpRange)"
        if newCurrent >= mx {
            match.status = .confirmed
            let label = "\(match.title) \(match.dateLabel) \(match.timeRange)"
            bookingStore.registerExternal(BookedSlot(
                id: match.id,
                start: match.startDate,
                end: match.endDate,
                label: label
            ))
        }
        upcomingMatches[idx] = match

        // 同步首頁 MockMatch.currentPlayers
        if let src = match.sourceMatchID,
           let mIdx = matches.firstIndex(where: { $0.id == src }) {
            matches[mIdx].currentPlayers += 1
        }
    }

    private func applyInviteUndoAcceptInHome(_ invite: InviteStore.Invite) {
        guard let idx = upcomingMatches.firstIndex(where: { $0.id == invite.matchID }) else { return }
        var match = upcomingMatches[idx]
        guard let rIdx = match.registrants.firstIndex(where: { $0.name == invite.inviteeName }) else { return }
        match.registrants.remove(at: rIdx)
        let (cur, mx) = match.playerCounts
        let newCurrent = max(0, cur - 1)
        let ntrpRange = match.players.components(separatedBy: "NTRP ").last ?? ""
        match.players = "\(newCurrent)/\(mx) · NTRP \(ntrpRange)"
        if cur >= mx {
            match.status = .pending
            bookingStore.removeExternal(id: match.id)
        }
        upcomingMatches[idx] = match

        if let src = match.sourceMatchID,
           let mIdx = matches.firstIndex(where: { $0.id == src }),
           matches[mIdx].currentPlayers > 0 {
            matches[mIdx].currentPlayers -= 1
        }
    }

    /// 處理「我的約球」取消操作對首頁的副作用。
    /// 三種情況:
    /// 1. 找到源 MockMatch → 遞減 currentPlayers(BookingStore-backed sign-up 流)。
    /// 2. 用戶為發起人 → 整場取消,不重新出現在首頁。
    /// 3. 找不到源 MockMatch 且非發起人 → 用 payload 在首頁合成一筆 MockMatch,
    ///    讓種子假資料 / 邀請接受 / 聊天接受的取消也能讓「空名額」對其他人可見。
    func handleMyMatchCancellation(_ payload: CancelledMatchPayload) {
        if let id = payload.sourceMatchID,
           let idx = matches.firstIndex(where: { $0.id == id }) {
            if matches[idx].currentPlayers > 0 {
                matches[idx].currentPlayers -= 1
            }
            return
        }
        guard !payload.isOrganizer else { return }
        let synthesized = makeRevenantMockMatch(from: payload)
        // 去重:若首頁已有同 organizer / location / startDate / matchType 的 MockMatch,
        // 視為重複取消(例如歷史殘留 + 再次取消),不再追加。
        let alreadyOnHome = matches.contains { existing in
            existing.name == synthesized.name
                && existing.location == synthesized.location
                && existing.matchType == synthesized.matchType
                && existing.startDate == synthesized.startDate
        }
        guard !alreadyOnHome else { return }
        matches.insert(synthesized, at: 0)
    }

    /// 由取消 payload 合成回首頁的 MockMatch。沒有 fee / age / gender 等 metadata,
    /// 取合理預設,避免在首頁卡片露出空字串。
    func makeRevenantMockMatch(from payload: CancelledMatchPayload) -> MockMatch {
        // 解析「莎拉 發起的單打」 → "莎拉";解析失敗 fallback 到 "球友"。
        let organizerName: String = {
            let parts = payload.title.components(separatedBy: " 發起的")
            if let first = parts.first, !first.isEmpty, first != "我" { return first }
            return "球友"
        }()

        // 解析 "2/2 · NTRP 3.0-4.0":current/max + ntrp 上下限。
        let counts: (current: Int, max: Int) = {
            let digits = payload.players.split { !$0.isNumber }.map(String.init)
            guard digits.count >= 2,
                  let cur = Int(digits[0]),
                  let mx = Int(digits[1]) else { return (1, 2) }
            return (cur, mx)
        }()
        let ntrp: (low: Double, high: Double) = {
            guard let range = payload.players.components(separatedBy: "NTRP ").last else { return (3.0, 4.0) }
            let parts = range.split(separator: "-").compactMap { Double($0) }
            guard parts.count == 2 else { return (3.0, 4.0) }
            return (parts[0], parts[1])
        }()

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: payload.startDate)
        let weekdayIndex = calendar.component(.weekday, from: payload.startDate)
        let dayMap = [1: "日", 2: "一", 3: "二", 4: "三", 5: "四", 6: "五", 7: "六"]
        let dayOfWeek = dayMap[weekdayIndex] ?? "一"
        let dateStr = AppDateFormatter.monthDay.string(from: payload.startDate)
        let startTimeStr = AppDateFormatter.hourMinute.string(from: payload.startDate)

        // 取消後實際 current = 原 current - 1(用戶剛離開)。
        let newCurrent = max(counts.current - 1, 0)

        return MockMatch(
            name: organizerName,
            gender: .male,
            matchType: payload.matchType,
            weather: payload.weather,
            dateTime: "\(dateStr) \(startTimeStr)",
            startDate: payload.startDate,
            location: payload.location,
            fee: "AA ¥100",
            ntrpLow: ntrp.low,
            ntrpHigh: ntrp.high,
            ageRange: "26-35",
            genderLabel: "不限",
            hour: hour,
            dayOfWeek: dayOfWeek,
            currentPlayers: newCurrent,
            maxPlayers: counts.max,
            isOwnMatch: false
        )
    }

    func addPublishedMatch(_ info: PublishedMatchInfo) {
        let dateStr = AppDateFormatter.monthDay.string(from: info.date)
        let dateTime = "\(dateStr) \(info.startTime)"

        let hourStr = info.startTime.prefix(2)
        let hour = Int(hourStr) ?? 10
        let minuteStr = info.startTime.dropFirst(3).prefix(2)
        let minute = Int(minuteStr) ?? 0

        // Compute day of week
        let weekdayIndex = Calendar.current.component(.weekday, from: info.date)
        let dayMap = [1: "日", 2: "一", 3: "二", 4: "三", 5: "四", 6: "五", 7: "六"]
        let dayOfWeek = dayMap[weekdayIndex] ?? "一"

        // Phase 2a: 组合 startDate 用于业务比较(过期 / 排序),与 dateTime 字符串并行存在。
        var startComps = Calendar.current.dateComponents([.year, .month, .day], from: info.date)
        startComps.hour = hour
        startComps.minute = minute
        let startDate = Calendar.current.date(from: startComps) ?? info.date

        let fee = info.costType == "免費" ? "免費" : "AA ¥\(info.costAmount)"
        let genderLabel: String
        switch info.gender {
        case "僅限男性": genderLabel = "男"
        case "僅限女性": genderLabel = "女"
        default: genderLabel = "不限"
        }

        let newMatch = MockMatch(
            name: userStore.displayName,
            gender: userStore.gender,
            matchType: info.matchType,
            weather: "☀️ --°C",
            dateTime: dateTime,
            startDate: startDate,
            location: info.courtName,
            fee: fee,
            ntrpLow: info.ntrpLow,
            ntrpHigh: info.ntrpHigh,
            ageRange: "26-35",
            genderLabel: genderLabel,
            hour: hour,
            dayOfWeek: dayOfWeek,
            currentPlayers: 1,
            maxPlayers: info.matchType == "雙打" ? 4 : 2,
            isOwnMatch: true
        )
        matches.insert(newMatch, at: 0)
    }

    func detailRow(symbol: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.primary)
                .frame(width: 14)
            Text(text)
                .font(Typography.small)
                .foregroundColor(Theme.textBody)
                .lineLimit(1)
        }
        .padding(.leading, 52)
    }
}

// MARK: - Preview

#Preview("iPhone SE") {
    HomeView()
        .environment(FollowStore())
        .environment(UserStore())
        .environment(CreditScoreStore())
        .environment(InviteStore())
}

#Preview("iPhone 15 Pro") {
    HomeView()
        .environment(FollowStore())
        .environment(UserStore())
        .environment(CreditScoreStore())
        .environment(InviteStore())
}
