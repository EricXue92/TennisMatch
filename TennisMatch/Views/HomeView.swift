//
//  HomeView.swift
//  TennisMatch
//
//  首頁 — 統計、推薦、約球列表、底部 Tab
//

import SwiftUI

// MARK: - Main Tab Container

struct HomeView: View {
    @State private var showDrawer = false
    @State private var showTournaments = false
    @State private var selectedTab = 0
    @State private var selectedFilter = "全部"
    @State private var showFilterPanel = false
    @State private var ntrpLow: Double = 1.0
    @State private var ntrpHigh: Double = 7.0
    @State private var selectedAgeRange: Set<String> = []
    @State private var selectedGender: String = ""
    @State private var selectedCourts: Set<TennisCourt> = []
    @State private var showCourtPicker = false
    @State private var selectedDays: Set<String> = []
    @State private var timeFrom: Double = 7.0
    @State private var timeTo: Double = 23.0
    @State private var selectedMatchDetail: MatchDetailData?
    @State private var showCreateMatch = false
    @State private var signUpMatch: SignUpMatchInfo?
    @State private var successMatch: SignUpMatchInfo?
    @State private var matches: [MockMatch] = initialMockMatches
    @State private var signUpMatchId: UUID?
    @State private var chatUnreadCount = 4
    @State private var acceptedMatches: [AcceptedMatchInfo] = []
    @State private var showMatchAssistant = false
    @State private var showReviews = false
    @State private var showNotifications = false
    @State private var showFollowing = false
    @State private var showBlockList = false
    @State private var showInviteFriends = false
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var pendingDMOrganizer: SignUpMatchInfo?
    @State private var dmChat: MockChat?
    @State private var dmMatchContext: String?
    @State private var signedUpMatchIDs: Set<UUID> = []

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case 0: homeTab
                case 1: MyMatchesView(acceptedMatches: $acceptedMatches, onMatchCancelled: { sourceMatchID in
                    // Decrement player count and clear the "已報名" flag for the originating HomeView match.
                    // sourceMatchID is nil for mock upcoming items / invitation-accept flows, which correctly no-op.
                    guard let id = sourceMatchID,
                          let idx = matches.firstIndex(where: { $0.id == id })
                    else { return }
                    if matches[idx].currentPlayers > 0 {
                        matches[idx].currentPlayers -= 1
                    }
                    signedUpMatchIDs.remove(id)
                })
                case 2: MatchAssistantView()
                case 3: MessagesView(totalUnread: $chatUnreadCount, acceptedMatches: $acceptedMatches)
                case 4: ProfileView()
                default: homeTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            customTabBar

            // Drawer overlay
            if showDrawer {
                drawerOverlay
            }
        }
        .fullScreenCover(isPresented: $showTournaments) {
            TournamentView()
        }
        .fullScreenCover(isPresented: $showCreateMatch) {
            NavigationStack {
                CreateMatchView(onPublish: { info in
                    addPublishedMatch(info)
                })
            }
        }
        .sheet(item: $signUpMatch) { info in
            SignUpConfirmSheet(match: info) {
                // Increment player count in the match
                if let matchId = signUpMatchId,
                   let idx = matches.firstIndex(where: { $0.id == matchId }) {
                    matches[idx].currentPlayers += 1
                    signedUpMatchIDs.insert(matchId)
                }
                successMatch = info
            }
            .presentationDetents([.medium])
        }
        .fullScreenCover(item: $successMatch, onDismiss: {
            if let info = pendingDMOrganizer {
                let symbol = info.organizerGender == .female ? "♀" : "♂"
                let color = info.organizerGender == .female ? Theme.genderFemale : Theme.genderMale
                dmChat = MockChat(
                    type: .personal(name: info.organizerName, symbol: symbol, symbolColor: color),
                    lastMessage: "點擊開始聊天",
                    time: "now",
                    unreadCount: 0
                )
                dmMatchContext = "🎾 約球已確認\n📅 \(info.dateTime)\n📍 \(info.location)\n🏸 \(info.matchType) · NTRP \(info.ntrpRange)\n💰 \(info.fee)"
                pendingDMOrganizer = nil
            }
        }) { info in
            SignUpSuccessView(match: info, onContactOrganizer: {
                pendingDMOrganizer = info
                successMatch = nil
            })
        }
        .navigationDestination(item: $selectedMatchDetail) { detail in
            MatchDetailView(match: detail, acceptedMatches: $acceptedMatches)
        }
        .navigationDestination(isPresented: $showMatchAssistant) {
            MatchAssistantView()
        }
        .navigationDestination(isPresented: $showReviews) {
            ReviewsView()
        }
        .navigationDestination(isPresented: $showNotifications) {
            NotificationsView()
        }
        .navigationDestination(isPresented: $showFollowing) {
            FollowingView()
        }
        .navigationDestination(isPresented: $showBlockList) {
            BlockListView()
        }
        .navigationDestination(isPresented: $showInviteFriends) {
            InviteFriendsView()
        }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .navigationDestination(isPresented: $showHelp) {
            HelpView()
        }
        .navigationDestination(item: $dmChat) { chat in
            ChatDetailView(chat: chat, acceptedMatches: $acceptedMatches, matchContext: dmMatchContext)
                .onDisappear { dmMatchContext = nil }
        }
    }

    private func placeholderTab(_ title: String) -> some View {
        VStack {
            Spacer()
            Text(title)
                .font(Typography.title)
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(icon: "🎯", label: "首頁", tag: 0)
            tabBarItem(icon: "🗓", label: "我的約球", tag: 1)
            centerTabButton
            tabBarItem(icon: "💬", label: "聊天", tag: 3, badgeCount: chatUnreadCount)
            tabBarItem(icon: "👤", label: "我的", tag: 4)
        }
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xl)
        .background(
            Rectangle()
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabBarItem(icon: String, label: String, tag: Int, badgeCount: Int = 0) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Text(icon)
                        .font(.system(size: 20))
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 8, y: -4)
                    }
                }
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(selectedTab == tag ? Theme.primary : Theme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }

    private var centerTabButton: some View {
        Button {
            showCreateMatch = true
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Theme.primary)
                        .frame(width: 52, height: 52)
                        .shadow(color: Theme.primary.opacity(0.4), radius: 6, y: 2)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(y: -16)
                Text("一鍵約球")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(selectedTab == 2 ? Theme.primary : Theme.textSecondary)
                    .offset(y: -16)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        VStack(spacing: 0) {
            headerSection
            ScrollView {
                VStack(spacing: 0) {
                    recommendationSection
                    dividerLine
                    filterChips
                    if showFilterPanel {
                        filterPanel
                    }
                    matchCardList
                }
                .padding(.bottom, 80)
            }
        }
        .background(Theme.inputBg)
    }
}

// MARK: - Drawer

private extension HomeView {
    var drawerOverlay: some View {
        ZStack(alignment: .leading) {
            // Dim background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeIn(duration: 0.2)) {
                        showDrawer = false
                    }
                }

            // Drawer panel
            drawerPanel
                .frame(width: 300)
                .transition(.move(edge: .leading))
        }
    }

    var drawerPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 60)

            // Menu items
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    drawerMenuItem(icon: "🏆", label: "賽事") {
                        showTournaments = true
                    }
                    drawerMenuItem(icon: "🤖", label: "約球助理") {
                        showMatchAssistant = true
                    }
                    drawerMenuItem(icon: "⭐", label: "評價", badge: 2) {
                        showReviews = true
                    }
                    drawerMenuItem(icon: "🔔", label: "通知", badge: 5) {
                        showNotifications = true
                    }
                    drawerMenuItem(icon: "👥", label: "關注") {
                        showFollowing = true
                    }
                    drawerMenuItem(icon: "🚫", label: "封鎖名單") {
                        showBlockList = true
                    }
                    drawerMenuItem(icon: "📨", label: "邀請好友") {
                        showInviteFriends = true
                    }

                    // Divider
                    Rectangle()
                        .fill(Color(hex: 0xE5E7EB))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                        .padding(.vertical, Spacing.sm)

                    drawerMenuItem(icon: "⚙️", label: "設定", isSecondary: true) {
                        showSettings = true
                    }
                    drawerMenuItem(icon: "❓", label: "幫助", isSecondary: true) {
                        showHelp = true
                    }
                }
            }

            Spacer()

            // Version
            Text("v0.1.0")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: 0x9CA3AF))
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
        }
        .frame(maxHeight: .infinity)
        .background(.white)
    }

    func drawerMenuItem(icon: String, label: String, badge: Int = 0, isSecondary: Bool = false, action: (() -> Void)? = nil) -> some View {
        Button {
            withAnimation(.easeIn(duration: 0.2)) {
                showDrawer = false
            }
            action?()
        } label: {
            HStack {
                Text(icon)
                    .font(.system(size: 20))
                    .frame(width: 28)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSecondary ? Color(hex: 0x6B7280) : Color(hex: 0x1F2937))
                Spacer()
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .frame(height: 48)
        }
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
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: 6)
                        }
                    }

                    Spacer()

                    Text("☀️ 24°C")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Spacing.md)

                // Stats cards
                HStack(spacing: Spacing.xs) {
                    statCard(label: "信譽積分", value: "85")
                    statCard(label: "場次", value: "28")
                    statCard(label: "NTRP", value: "3.5")
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.md)
            }
        }
        .frame(height: 160)
        .background(Theme.primary)
    }

    func statCard(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.9))
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Recommendations

private extension HomeView {
    var recommendationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("📈 推薦")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    recommendCard(
                        name: "莎拉",
                        gender: .female,
                        ntrp: "3.5"
                    )
                    recommendCard(
                        name: "王強",
                        gender: .male,
                        ntrp: "4.0"
                    )
                    recommendCard(
                        name: "小美",
                        gender: .female,
                        ntrp: "3.0"
                    )
                    recommendCard(
                        name: "志明",
                        gender: .male,
                        ntrp: "4.5"
                    )
                    recommendCard(
                        name: "嘉欣",
                        gender: .female,
                        ntrp: "3.5"
                    )
                    recommendCard(
                        name: "大衛",
                        gender: .male,
                        ntrp: "4.0"
                    )
                    recommendCard(
                        name: "艾美",
                        gender: .female,
                        ntrp: "3.0"
                    )
                    recommendCard(
                        name: "阿豪",
                        gender: .male,
                        ntrp: "3.5"
                    )
                    recommendCard(
                        name: "思慧",
                        gender: .female,
                        ntrp: "4.0"
                    )
                    recommendCard(
                        name: "Michael",
                        gender: .male,
                        ntrp: "5.0"
                    )
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .padding(.vertical, Spacing.sm)
        .background(.white)
    }

    func recommendCard(name: String, gender: Gender, ntrp: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color(hex: 0xE0E0E0))
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text(gender == .female ? "♀" : "♂")
                        .font(.system(size: 13))
                        .foregroundColor(gender == .female ? Theme.genderFemale : Theme.genderMale)
                }

                Text("NTRP \(ntrp)")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textCaption)

                Button {
                    // TODO: follow
                } label: {
                    Text("關注")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 24)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .frame(width: 170, alignment: .leading)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.inputBorder, lineWidth: 1)
        }
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
                    Text(option)
                        .font(.system(size: 13, weight: .medium))
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
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showFilterPanel.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 12, weight: .medium))
                    Text("篩選")
                        .font(.system(size: 12, weight: .medium))
                    if activeFilterCount > 0 {
                        Text("\(activeFilterCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.red)
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
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(.white)
    }

    var filterPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ntpRangeRow
            filterRow(title: "年齡", options: filterAgeOptions, selection: $selectedAgeRange)
            genderFilterRow
            courtFilterRow
            timeFilterRow

            HStack(spacing: Spacing.sm) {
                Button {
                    ntrpLow = 1.0
                    ntrpHigh = 7.0
                    selectedAgeRange.removeAll()
                    selectedGender = ""
                    selectedCourts.removeAll()
                    selectedDays.removeAll()
                    timeFrom = 7.0
                    timeTo = 23.0
                } label: {
                    Text("重置")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textBody)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.inputBorder, lineWidth: 1)
                        }
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showFilterPanel = false
                    }
                } label: {
                    Text("確認")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(Spacing.md)
        .background(.white)
    }

    var genderFilterRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("性別")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Spacing.xs) {
                ForEach(filterGenderOptions, id: \.self) { option in
                    let isSelected = selectedGender == option
                    Button {
                        selectedGender = isSelected ? "" : option
                    } label: {
                        Text(option)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSelected ? .white : Theme.textBody)
                            .padding(.horizontal, Spacing.sm)
                            .frame(height: 28)
                            .background(isSelected ? Theme.primary : Theme.inputBg)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
        }
    }

    var timeFilterRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("時間")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            // Day of week selection
            HStack(spacing: 4) {
                ForEach(filterDayOptions, id: \.self) { day in
                    let isSelected = selectedDays.contains(day)
                    Button {
                        if isSelected {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    } label: {
                        Text(day)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSelected ? .white : Theme.textBody)
                            .frame(width: 36, height: 36)
                            .background(isSelected ? Theme.primary : Theme.inputBg)
                            .clipShape(Circle())
                    }
                }
            }

            // Time range pickers
            HStack(spacing: Spacing.sm) {
                Text("從")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textCaption)
                Picker("", selection: $timeFrom) {
                    ForEach(timeSlots, id: \.self) { slot in
                        Text(formatTimeSlot(slot)).tag(slot)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.primary)
                .fixedSize()

                Text("到")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textCaption)
                Picker("", selection: $timeTo) {
                    ForEach(timeSlots.filter { $0 >= timeFrom }, id: \.self) { slot in
                        Text(formatTimeSlot(slot)).tag(slot)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.primary)
                .fixedSize()

                Spacer()
            }
        }
    }

    var timeSlots: [Double] {
        stride(from: 7.0, through: 23.0, by: 0.5).map { $0 }
    }

    func formatTimeSlot(_ slot: Double) -> String {
        let hour = Int(slot)
        let minute = slot.truncatingRemainder(dividingBy: 1) == 0.5 ? 30 : 0
        return String(format: "%02d:%02d", hour, minute)
    }

    var courtFilterRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("球場")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                    showCourtPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCourts.isEmpty ? "選擇球場" : "已選 \(selectedCourts.count) 個")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(Theme.primary)
                }
            }

            if !selectedCourts.isEmpty {
                let columns = [GridItem(.adaptive(minimum: 90), spacing: Spacing.xs)]
                LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.xs) {
                    ForEach(Array(selectedCourts).sorted { $0.name < $1.name }) { court in
                        HStack(spacing: 4) {
                            Text(court.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.primary)
                                .lineLimit(1)
                            Button {
                                selectedCourts.remove(court)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Theme.textCaption)
                            }
                        }
                        .padding(.horizontal, Spacing.sm)
                        .frame(height: 28)
                        .background(Theme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
        }
        .sheet(isPresented: $showCourtPicker) {
            CourtPickerView(selected: $selectedCourts)
        }
    }

    var ntpRangeRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("NTRP")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(ntrpRangeLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.primary)
            }

            HStack(spacing: Spacing.sm) {
                Text(String(format: "%.1f", ntrpLow))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textBody)
                    .frame(width: 28)

                GeometryReader { geo in
                    let width = geo.size.width
                    let range = 6.0 // 7.0 - 1.0
                    let lowX = (ntrpLow - 1.0) / range * width
                    let highX = (ntrpHigh - 1.0) / range * width

                    ZStack(alignment: .leading) {
                        // Track background
                        Capsule()
                            .fill(Theme.inputBg)
                            .frame(height: 4)

                        // Active range
                        Capsule()
                            .fill(Theme.primary)
                            .frame(width: max(0, highX - lowX), height: 4)
                            .offset(x: lowX)

                        // Low thumb
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                            .overlay {
                                Circle()
                                    .fill(Theme.primary)
                                    .frame(width: 10, height: 10)
                            }
                            .position(x: lowX, y: geo.size.height / 2)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let raw = value.location.x / width * range + 1.0
                                        let snapped = (raw * 2).rounded() / 2 // snap to 0.5
                                        ntrpLow = min(max(snapped, 1.0), ntrpHigh)
                                    }
                            )

                        // High thumb
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                            .overlay {
                                Circle()
                                    .fill(Theme.primary)
                                    .frame(width: 10, height: 10)
                            }
                            .position(x: highX, y: geo.size.height / 2)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let raw = value.location.x / width * range + 1.0
                                        let snapped = (raw * 2).rounded() / 2
                                        ntrpHigh = max(min(snapped, 7.0), ntrpLow)
                                    }
                            )
                    }
                }
                .frame(height: 28)

                Text(String(format: "%.1f", ntrpHigh))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textBody)
                    .frame(width: 28)
            }
        }
    }

    var ntrpRangeLabel: String {
        if ntrpLow == 1.0 && ntrpHigh == 7.0 {
            return "不限"
        }
        return String(format: "%.1f - %.1f", ntrpLow, ntrpHigh)
    }

    func filterRow(title: String, options: [String], selection: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            // Use LazyVGrid for wrapping layout
            let columns = [GridItem(.adaptive(minimum: 70), spacing: Spacing.xs)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.xs) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selection.wrappedValue.contains(option)
                    Button {
                        if isSelected {
                            selection.wrappedValue.remove(option)
                        } else {
                            selection.wrappedValue.insert(option)
                        }
                    } label: {
                        Text(option)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSelected ? .white : Theme.textBody)
                            .padding(.horizontal, Spacing.sm)
                            .frame(height: 28)
                            .background(isSelected ? Theme.primary : Theme.inputBg)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
        }
    }
}

// MARK: - Match Cards

private extension HomeView {
    var filteredMatches: [MockMatch] {
        let filtered = matches.filter { match in
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
        // Own matches always first
        return filtered.sorted { $0.isOwnMatch && !$1.isOwnMatch }
    }

    var matchCardList: some View {
        VStack(spacing: Spacing.md) {
            if filteredMatches.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Text("🎾")
                        .font(.system(size: 40))
                    Text("沒有符合條件的約球")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
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
        VStack(alignment: .leading, spacing: 6) {
            // Row 1: avatar + name + gender + type + weather
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Color(hex: 0xE0E0E0))
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(match.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text(match.gender == .female ? "♀" : "♂")
                            .font(.system(size: 14))
                            .foregroundColor(match.gender == .female ? Theme.genderFemale : Theme.genderMale)

                        Text(match.matchType)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textBody)
                            .padding(.horizontal, 6)
                            .frame(height: 18)
                            .background(Theme.chipUnselectedBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }

                Spacer()

                Text(match.weather)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textCaption)
            }

            // Detail rows
            detailRow(icon: "📅", text: match.dateTime)
            detailRow(icon: "📍", text: match.location)
            detailRow(icon: "👥", text: match.players)

            // Bottom: tags + sign up button
            HStack(spacing: Spacing.xs) {
                Text(match.fee)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textBody)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 22)
                    .background(Theme.chipUnselectedBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(match.isOwnMatch ? "我發起的" : "招募中")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 22)
                    .background(match.isOwnMatch ? Theme.accentGreen : Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()

                if !match.isOwnMatch {
                    let alreadySignedUp = signedUpMatchIDs.contains(match.id)
                    Button {
                        showSignUp(match)
                    } label: {
                        Text(alreadySignedUp ? "已報名" : "報名")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(alreadySignedUp ? Theme.textSecondary : .white)
                            .frame(width: 52, height: 30)
                            .background(alreadySignedUp ? Theme.chipUnselectedBg : Theme.primaryDark)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .disabled(alreadySignedUp)
                }
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
        .overlay(alignment: .leading) {
            if match.isOwnMatch {
                Theme.primary
                    .frame(width: 4)
                    .padding(.vertical, Spacing.sm)
            }
        }
        .onTapGesture {
            navigateToDetail(match)
        }
    }

    func navigateToDetail(_ match: MockMatch) {
        selectedMatchDetail = makeMatchDetail(from: match)
    }

    func showSignUp(_ match: MockMatch) {
        guard !match.isFull else { return }
        guard !signedUpMatchIDs.contains(match.id) else { return }

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
            isFull: newCount >= match.maxPlayers
        )
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
            name: match.name,
            gender: match.gender,
            ntrp: String(format: "%.1f", (match.ntrpLow + match.ntrpHigh) / 2),
            reputation: [85, 88, 90, 92, 78, 95][abs(match.name.hashValue) % 6],
            matchType: match.matchType,
            date: date,
            timeRange: timeRange,
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

    func addPublishedMatch(_ info: PublishedMatchInfo) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let dateStr = formatter.string(from: info.date)
        let dateTime = "\(dateStr) \(info.startTime)"

        let hourStr = info.startTime.prefix(2)
        let hour = Int(hourStr) ?? 10

        // Compute day of week
        let weekdayIndex = Calendar.current.component(.weekday, from: info.date)
        let dayMap = [1: "日", 2: "一", 3: "二", 4: "三", 5: "四", 6: "五", 7: "六"]
        let dayOfWeek = dayMap[weekdayIndex] ?? "一"

        let fee = info.costType == "免費" ? "免費" : "AA ¥\(info.costAmount)"
        let genderLabel: String
        switch info.gender {
        case "僅限男性": genderLabel = "男"
        case "僅限女性": genderLabel = "女"
        default: genderLabel = "不限"
        }

        let newMatch = MockMatch(
            name: "小李",
            gender: .male,
            matchType: info.matchType,
            weather: "☀️ --°C",
            dateTime: dateTime,
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
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Theme.textBody)
        }
        .padding(.leading, 52)
    }
}

private let matchFilterOptions = ["全部", "單打", "雙打"]

// MARK: - Filter Options

private let filterAgeOptions = ["14-17", "18-25", "26-35", "36-45", "46-55", "55+"]
private let filterGenderOptions = ["男", "女", "不限"]
private let filterDayOptions = ["一", "二", "三", "四", "五", "六", "日"]

// MARK: - Mock Data

private struct MockMatch: Identifiable {
    let id = UUID()
    let name: String
    let gender: Gender
    let matchType: String
    let weather: String
    let dateTime: String
    let location: String
    let fee: String
    // Structured filter fields
    let ntrpLow: Double
    let ntrpHigh: Double
    let ageRange: String    // e.g. "18-25"
    let genderLabel: String // "男" or "女"
    let hour: Int           // 7-23
    let dayOfWeek: String   // "一"-"日"
    // Player count
    var currentPlayers: Int
    var maxPlayers: Int
    var isOwnMatch: Bool = false

    var players: String {
        "\(currentPlayers)/\(maxPlayers) • \(String(format: "%.1f-%.1f", ntrpLow, ntrpHigh))"
    }

    var isFull: Bool { currentPlayers >= maxPlayers }
}

private let initialMockMatches: [MockMatch] = [
    MockMatch(
        name: "莎拉", gender: .female, matchType: "單打",
        weather: "☀️ 24°C", dateTime: "04/19 10:00",
        location: "維多利亞公園網球場", fee: "AA ¥120",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "女", hour: 10, dayOfWeek: "六",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "王強", gender: .male, matchType: "雙打",
        weather: "⛅ 26°C", dateTime: "04/20 14:00",
        location: "跑馬地遊樂場", fee: "AA ¥200",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 14, dayOfWeek: "日",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "美琪", gender: .female, matchType: "單打",
        weather: "☀️ 28°C", dateTime: "04/21 08:30",
        location: "九龍仔公園", fee: "AA ¥100",
        ntrpLow: 3.5, ntrpHigh: 4.0, ageRange: "18-25",
        genderLabel: "女", hour: 8, dayOfWeek: "一",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "志明", gender: .male, matchType: "單打",
        weather: "🌤 25°C", dateTime: "04/21 16:00",
        location: "香港網球中心", fee: "AA ¥150",
        ntrpLow: 4.0, ntrpHigh: 4.5, ageRange: "36-45",
        genderLabel: "男", hour: 16, dayOfWeek: "一",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "小美", gender: .female, matchType: "雙打",
        weather: "☀️ 27°C", dateTime: "04/22 10:00",
        location: "沙田公園", fee: "AA ¥80",
        ntrpLow: 3.0, ntrpHigh: 3.5, ageRange: "18-25",
        genderLabel: "女", hour: 10, dayOfWeek: "二",
        currentPlayers: 3, maxPlayers: 4
    ),
    MockMatch(
        name: "大衛", gender: .male, matchType: "雙打",
        weather: "⛅ 23°C", dateTime: "04/22 18:30",
        location: "歌和老街公園", fee: "AA ¥180",
        ntrpLow: 4.0, ntrpHigh: 5.0, ageRange: "26-35",
        genderLabel: "男", hour: 18, dayOfWeek: "二",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "嘉欣", gender: .female, matchType: "單打",
        weather: "🌤 26°C", dateTime: "04/23 09:00",
        location: "香港公園", fee: "AA ¥100",
        ntrpLow: 2.5, ntrpHigh: 3.5, ageRange: "18-25",
        genderLabel: "女", hour: 9, dayOfWeek: "三",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "俊傑", gender: .male, matchType: "雙打",
        weather: "☀️ 29°C", dateTime: "04/23 15:00",
        location: "將軍澳運動場", fee: "AA ¥160",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 15, dayOfWeek: "三",
        currentPlayers: 1, maxPlayers: 4
    ),
    MockMatch(
        name: "阿杰", gender: .male, matchType: "單打",
        weather: "☀️ 25°C", dateTime: "04/19 07:00",
        location: "沙田公園", fee: "AA ¥60",
        ntrpLow: 2.0, ntrpHigh: 3.0, ageRange: "18-25",
        genderLabel: "男", hour: 7, dayOfWeek: "六",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "麗莎", gender: .female, matchType: "雙打",
        weather: "⛅ 26°C", dateTime: "04/20 19:00",
        location: "香港網球中心", fee: "AA ¥250",
        ntrpLow: 4.5, ntrpHigh: 5.5, ageRange: "26-35",
        genderLabel: "女", hour: 19, dayOfWeek: "日",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "老張", gender: .male, matchType: "單打",
        weather: "🌤 22°C", dateTime: "04/24 07:00",
        location: "九龍仔公園", fee: "AA ¥200",
        ntrpLow: 5.0, ntrpHigh: 6.0, ageRange: "46-55",
        genderLabel: "男", hour: 7, dayOfWeek: "四",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "小玲", gender: .female, matchType: "單打",
        weather: "☀️ 28°C", dateTime: "04/25 17:30",
        location: "將軍澳運動場", fee: "AA ¥70",
        ntrpLow: 2.0, ntrpHigh: 2.5, ageRange: "18-25",
        genderLabel: "女", hour: 17, dayOfWeek: "五",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "林叔", gender: .male, matchType: "雙打",
        weather: "⛅ 24°C", dateTime: "04/26 15:00",
        location: "維多利亞公園網球場", fee: "AA ¥120",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "55+",
        genderLabel: "男", hour: 15, dayOfWeek: "六",
        currentPlayers: 3, maxPlayers: 4
    ),
    MockMatch(
        name: "Kelly", gender: .female, matchType: "雙打",
        weather: "☀️ 27°C", dateTime: "04/27 10:30",
        location: "沙田公園", fee: "AA ¥100",
        ntrpLow: 3.5, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "女", hour: 10, dayOfWeek: "日",
        currentPlayers: 1, maxPlayers: 4
    ),
    MockMatch(
        name: "Peter", gender: .male, matchType: "單打",
        weather: "☀️ 30°C", dateTime: "04/28 20:00",
        location: "跑馬地遊樂場", fee: "AA ¥180",
        ntrpLow: 4.5, ntrpHigh: 5.0, ageRange: "36-45",
        genderLabel: "男", hour: 20, dayOfWeek: "一",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "陳教練", gender: .male, matchType: "單打",
        weather: "🌤 23°C", dateTime: "04/29 07:30",
        location: "香港網球中心", fee: "AA ¥300",
        ntrpLow: 5.0, ntrpHigh: 6.0, ageRange: "36-45",
        genderLabel: "男", hour: 7, dayOfWeek: "二",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "雅婷", gender: .female, matchType: "雙打",
        weather: "☀️ 26°C", dateTime: "04/29 17:00",
        location: "九龍公園", fee: "AA ¥90",
        ntrpLow: 2.5, ntrpHigh: 3.0, ageRange: "18-25",
        genderLabel: "女", hour: 17, dayOfWeek: "二",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "阿豪", gender: .male, matchType: "雙打",
        weather: "⛅ 25°C", dateTime: "04/30 19:30",
        location: "歌和老街公園", fee: "AA ¥150",
        ntrpLow: 3.5, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "男", hour: 19, dayOfWeek: "三",
        currentPlayers: 1, maxPlayers: 4
    ),
    MockMatch(
        name: "思慧", gender: .female, matchType: "單打",
        weather: "☀️ 29°C", dateTime: "04/30 09:00",
        location: "將軍澳運動場", fee: "AA ¥80",
        ntrpLow: 3.0, ntrpHigh: 3.5, ageRange: "26-35",
        genderLabel: "女", hour: 9, dayOfWeek: "三",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "張偉", gender: .male, matchType: "單打",
        weather: "🌤 24°C", dateTime: "05/01 08:00",
        location: "維多利亞公園網球場", fee: "AA ¥120",
        ntrpLow: 4.0, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 8, dayOfWeek: "四",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "詠琪", gender: .female, matchType: "雙打",
        weather: "☀️ 27°C", dateTime: "05/01 15:30",
        location: "沙田公園", fee: "AA ¥100",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "18-25",
        genderLabel: "女", hour: 15, dayOfWeek: "四",
        currentPlayers: 3, maxPlayers: 4
    ),
    MockMatch(
        name: "Michael", gender: .male, matchType: "單打",
        weather: "⛅ 22°C", dateTime: "05/02 18:00",
        location: "跑馬地遊樂場", fee: "AA ¥200",
        ntrpLow: 4.5, ntrpHigh: 5.5, ageRange: "36-45",
        genderLabel: "男", hour: 18, dayOfWeek: "五",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "艾美", gender: .female, matchType: "雙打",
        weather: "☀️ 28°C", dateTime: "05/03 10:00",
        location: "京士柏運動場", fee: "AA ¥130",
        ntrpLow: 3.0, ntrpHigh: 3.5, ageRange: "26-35",
        genderLabel: "女", hour: 10, dayOfWeek: "六",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "家明", gender: .male, matchType: "雙打",
        weather: "🌤 25°C", dateTime: "05/03 16:00",
        location: "九龍仔公園", fee: "AA ¥160",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 16, dayOfWeek: "六",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "曉彤", gender: .female, matchType: "單打",
        weather: "☀️ 30°C", dateTime: "05/04 11:00",
        location: "香港公園", fee: "AA ¥70",
        ntrpLow: 2.0, ntrpHigh: 3.0, ageRange: "14-17",
        genderLabel: "女", hour: 11, dayOfWeek: "日",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "國輝", gender: .male, matchType: "單打",
        weather: "⛅ 24°C", dateTime: "05/04 07:00",
        location: "沙田公園", fee: "AA ¥100",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "55+",
        genderLabel: "男", hour: 7, dayOfWeek: "日",
        currentPlayers: 1, maxPlayers: 2
    ),
]

// MARK: - Sign Up Confirmation

struct SignUpMatchInfo: Identifiable {
    let id = UUID()
    let organizerName: String
    let organizerGender: Gender
    let dateTime: String
    let location: String
    let matchType: String
    let ntrpRange: String
    let fee: String
    let notes: String
    let players: String
    let isFull: Bool
}

private struct SignUpConfirmSheet: View {
    let match: SignUpMatchInfo
    var onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("確認報名")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                infoRow(icon: "calendar", text: match.dateTime)
                infoRow(icon: "mappin.circle.fill", text: match.location)
                infoRow(icon: "figure.tennis", text: "\(match.matchType)  ·  NTRP \(match.ntrpRange)")
                infoRow(icon: "dollarsign.circle.fill", text: match.fee)
                infoRow(icon: "exclamationmark.triangle.fill", text: match.notes)
            }

            Theme.divider.frame(height: 1)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("給發起人留言（選填）")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                TextField("例如：我會準時到！", text: $message, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textPrimary)
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
                .font(.system(size: 15))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

// MARK: - Sign Up Success

private struct SignUpSuccessView: View {
    let match: SignUpMatchInfo
    var onContactOrganizer: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

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
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.textDark)

            Spacer().frame(height: Spacing.xs)

            // Subtitle
            Text("你已成功加入\(match.organizerName)的約球")
                .font(.system(size: 15))
                .foregroundColor(Theme.textHint)

            Spacer().frame(height: Spacing.lg)

            // Summary card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                summaryRow(icon: "calendar", text: match.dateTime)
                summaryRow(icon: "mappin.and.ellipse", text: match.location)
                summaryRow(icon: "dollarsign.circle", text: match.fee)
                summaryRow(icon: "person.2.fill", text: "\(match.players) 人 · 水平 \(match.ntrpRange)")
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
                    // TODO: add to calendar
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            // Return button
            Button {
                dismiss()
            } label: {
                Text("返回首頁")
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
        .background(Color(hex: 0xFFF0F0).opacity(0.3))
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
    HomeView()
}

#Preview("iPhone 15 Pro") {
    HomeView()
}
