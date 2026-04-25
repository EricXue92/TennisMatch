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
    @Environment(BookedSlotStore.self) private var bookedSlotStore
    @Environment(NotificationStore.self) private var notificationStore
    @Environment(CreditScoreStore.self) private var creditScoreStore
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
    @State private var signUpMatchId: UUID?
    @State private var chatUnreadCount = 0
    @State private var sharedChats: [MockChat] = mockChatsInitial
    @State private var acceptedMatches: [AcceptedMatchInfo] = []
    @State private var drawerNav: DrawerDestination?
    @State private var pendingDMOrganizer: SignUpMatchInfo?
    @State private var dmChat: MockChat?
    @State private var dmMatchContext: String?
    @State private var dmInitialMessage: String?
    @State private var signedUpMatchIDs: Set<UUID> = []
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
                case 1: MyMatchesView(acceptedMatches: $acceptedMatches, sharedChats: $sharedChats, onGoHome: { selectedTab = 0 }, onGoTournaments: { showTournaments = true }, onMatchCancelled: { sourceMatchID in
                    // Decrement player count and clear the "已報名" flag for the originating HomeView match.
                    // sourceMatchID is nil for mock upcoming items / invitation-accept flows, which correctly no-op.
                    guard let id = sourceMatchID,
                          let idx = matches.firstIndex(where: { $0.id == id })
                    else { return }
                    if matches[idx].currentPlayers > 0 {
                        matches[idx].currentPlayers -= 1
                    }
                    signedUpMatchIDs.remove(id)
                    bookedSlotStore.remove(id: id)
                })
                case 2: MatchAssistantView()
                case 3: MessagesView(totalUnread: $chatUnreadCount, acceptedMatches: $acceptedMatches, chats: $sharedChats)
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
                // Increment player count in the match
                if let matchId = signUpMatchId,
                   let idx = matches.firstIndex(where: { $0.id == matchId }) {
                    matches[idx].currentPlayers += 1
                    signedUpMatchIDs.insert(matchId)
                    registerBookedSlot(for: matches[idx])
                    // 报名成功后加入"我的约球"列表
                    addToAcceptedMatches(match: matches[idx])
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
                acceptedMatches: $acceptedMatches,
                signedUpMatchIDs: $signedUpMatchIDs,
                onSignUp: { matchId in
                    if let idx = matches.firstIndex(where: { $0.id == matchId }) {
                        matches[idx].currentPlayers += 1
                        registerBookedSlot(for: matches[idx])
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
                acceptedMatches: $acceptedMatches,
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
        .onAppear {
            if let data = UserDefaults.standard.data(forKey: "signedUpMatchIDs"),
               let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
                signedUpMatchIDs = ids
            }
        }
        .onChange(of: signedUpMatchIDs) { _, newValue in
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "signedUpMatchIDs")
            }
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
    var headerSection: some View {
        ZStack(alignment: .topLeading) {
            Theme.primary.ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                // Top row: hamburger + weather
                HStack {
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

                    Spacer()

                    Text("☀️ 24°C")
                        .font(Typography.bodyMedium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Spacing.md)

                // Stats cards
                HStack(spacing: Spacing.xs) {
                    statCard(label: "信譽積分", value: "\(creditScoreStore.score)")
                    statCard(label: "場次", value: "\(signedUpMatchIDs.count)")
                    statCard(label: "NTRP", value: userStore.ntrpText)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.md)
            }
        }
        .frame(height: 160)
        .background(Theme.primary)
    }

    func statCard(label: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Typography.fieldLabel)
                .foregroundColor(.white.opacity(0.9))
            Text(value)
                .font(Typography.title)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            if signedUpMatchIDs.contains(match.id) { return false }
            // Hide full matches (but always show own)
            if match.isFull && !match.isOwnMatch { return false }
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
                        Text(match.name)
                            .font(Typography.bodyMedium)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                        Text(match.gender.symbol)
                            .font(Typography.bodyMedium)
                            .foregroundColor(match.gender == .female ? Theme.genderFemale : Theme.genderMale)

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
                    .font(Typography.small)
                    .foregroundColor(Theme.textCaption)
            }

            // Detail rows
            detailRow(icon: "📅", text: match.dateTimeDisplay)
            detailRow(icon: "📍", text: match.location)
            detailRow(icon: "👥", text: match.players)

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
                    let alreadySignedUp = !autoCancelled && signedUpMatchIDs.contains(match.id)
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
        guard !signedUpMatchIDs.contains(match.id) else { return }

        // 时段冲突拦截:同一时间不能重复报名(CLAUDE.md 边界 case #4)。
        // 这里查询的是全局 BookedSlotStore,涵盖其它已报名 + 已接受邀请。
        let range = matchTimeWindow(for: match)
        if let conflict = bookedSlotStore.conflict(start: range.start, end: range.end, excluding: match.id) {
            conflictToast = L10n.string("該時段已與「\(conflict.label)」衝突,請先取消已預訂的時段")
            return
        }

        let parts = match.dateTime.split(separator: " ")
        let date = "2026/\(parts[0])"
        let startTime = String(parts[1])
        let startHour = Int(startTime.prefix(2)) ?? 10
        let endHour = startHour + 2
        let timeRange = "\(startTime) - \(String(format: "%02d:00", endHour))"

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
            endDate: match.startDate.addingTimeInterval(2 * 3600)
        )
    }

    /// 取 `MockMatch` 的起止时间窗口(默认 2 小时);Phase 2a 之后直接基于 `startDate`。
    func matchTimeWindow(for match: MockMatch) -> (start: Date, end: Date) {
        (start: match.startDate, end: match.startDate.addingTimeInterval(2 * 3600))
    }

    /// 报名成功后向 BookedSlotStore 登记该时段,
    /// 后续在其它入口(MyMatches 接受邀请 / ChatDetail)拦截冲突。
    func registerBookedSlot(for match: MockMatch) {
        let range = matchTimeWindow(for: match)
        let label = "\(match.name) \(match.dateTime)"
        bookedSlotStore.add(BookedSlot(id: match.id, start: range.start, end: range.end, label: label))
    }

    func makeMatchDetail(from match: MockMatch) -> MatchDetailData {
        // Parse dateTime "04/19 10:00" → date + timeRange
        let parts = match.dateTime.split(separator: " ")
        let date = "2026/\(parts[0])"
        let startTime = String(parts[1])
        // Estimate 2-hour session
        let startHour = Int(startTime.prefix(2)) ?? 10
        let endHour = startHour + 2
        let timeRange = "\(startTime) - \(String(format: "%02d:00", endHour))"

        // Parse weather emoji + temp
        let temp = match.weather.replacingOccurrences(of: "☀️ ", with: "")
            .replacingOccurrences(of: "⛅ ", with: "")
            .replacingOccurrences(of: "🌤 ", with: "")

        return MatchDetailData(
            matchId: match.id,
            name: match.name,
            gender: match.gender,
            ntrp: String(format: "%.1f", (match.ntrpLow + match.ntrpHigh) / 2),
            reputation: [85, 88, 90, 92, 78, 95][abs(match.name.hashValue) % 6],
            matchType: match.matchType,
            date: date,
            timeRange: timeRange,
            startDate: match.startDate,
            endDate: match.startDate.addingTimeInterval(2 * 3600),
            location: match.location,
            district: "香港",
            players: match.players.components(separatedBy: " •").first ?? match.players,
            ntrpRange: String(format: "%.1f-%.1f", match.ntrpLow, match.ntrpHigh),
            fee: match.fee,
            notes: "自帶球拍和球，準時到達",
            weather: MatchWeather(temp: temp, humidity: "65%", uv: "6", wind: "10"),
            participantList: [
                MatchParticipant(name: match.name, gender: match.gender, ntrp: String(format: "%.1f", match.ntrpLow), isOrganizer: true)
            ],
            isOwnMatch: match.isOwnMatch
        )
    }

    /// 报名成功后,将约球信息加入 acceptedMatches,使其显示在"我的约球"页面。
    func addToAcceptedMatches(match: MockMatch) {
        let parts = match.dateTime.split(separator: " ")
        let dateStr = String(parts[0]) // "04/19" — 仅用于显示
        let startTime = parts.count > 1 ? String(parts[1]) : "\(match.hour):00"
        let start = match.startDate
        let end = start.addingTimeInterval(2 * 3600)

        let accepted = AcceptedMatchInfo(
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
        acceptedMatches.append(accepted)
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

    func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(Typography.small)
                .foregroundColor(Theme.textSecondary)
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
}

#Preview("iPhone 15 Pro") {
    HomeView()
        .environment(FollowStore())
        .environment(UserStore())
        .environment(CreditScoreStore())
}
