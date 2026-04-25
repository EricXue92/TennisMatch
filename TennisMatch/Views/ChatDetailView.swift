//
//  ChatDetailView.swift
//  TennisMatch
//
//  聊天對話 — 消息氣泡 & 輸入框
//

import SwiftUI
import PhotosUI

struct ChatDetailView: View {
    let chat: MockChat
    var matchContext: String? = nil
    /// Seed message from the sign-up "給發起人留言" field. Sent as an
    /// outgoing bubble on first appear so the organizer sees it at the top.
    var initialMessage: String? = nil
    var onRemoveChat: (() -> Void)? = nil
    /// 封鎖用戶時回調，參數為被封鎖者名稱
    var onBlockUser: ((String) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(BookingStore.self) private var bookingStore
    @State private var messageText = ""
    @State private var sentMessages: [ChatBubble] = []
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    /// 待發送的圖片暫存，讓用戶在發送前先預覽
    @State private var pendingPhotoData: Data?
    @State private var showChatMenu = false
    @State private var didSeedInitialMessage = false
    /// Lets the user clear the sign-up-success context card. Once dismissed
    /// for this session, the card does not re-appear on re-entry to the chat.
    @State private var matchContextDismissed = false
    @State private var isMuted = false
    @State private var chatMenuToast: String?
    @State private var showBlockAlert = false
    @State private var selectedPlayer: PublicPlayerData?
    // Mock 階段：婉拒狀態僅保存在 @State 中，離開頁面即重置。
    // 正式版應持久化至 UserDefaults 或資料庫，注意 @AppStorage JSON 有大小限制。
    @State private var declinedInvitationIDs: Set<UUID> = []

    private var chatTitle: String {
        switch chat.type {
        case .match(let title, _): return title
        case .personal(let name, _, _): return name
        }
    }

    private var organizerName: String {
        switch chat.type {
        case .match(let title, _):
            // Match titles come in two shapes:
            //   A) "{organizerName} 發起的{matchType}"  (created via MyMatchesView)
            //   B) "{location} {matchType}"            (mock chats in MessagesView,
            //      no organizer encoded — fall through)
            // Using " 發起的" as the splitter tolerates organizer names that
            // themselves contain spaces (e.g. "小 明"), which breaks a naive
            // first-whitespace split.
            if let range = title.range(of: " 發起的") {
                return String(title[..<range.lowerBound])
            }
            return title.components(separatedBy: " ").first ?? title
        case .personal(let name, _, _):
            return name
        }
    }

    private var matchTypeFromChat: String {
        switch chat.type {
        case .match(let title, _):
            if title.contains("雙打") { return "雙打" }
            return "單打"
        case .personal:
            return "單打"
        }
    }

    private func isInvitationAccepted(date: String, location: String) -> Bool {
        let parts = date.components(separatedBy: " ")
        let dateStr = parts.first ?? date
        return bookingStore.accepted.contains { m in
            m.organizerName == organizerName && m.dateString == dateStr && m.location == location
        }
    }

    /// 日期分隔標籤:顯示「今天 — yyyy/MM/dd」，避免 hardcode 字串
    private func dateSeparatorLabel() -> String {
        return "今天 — \(AppDateFormatter.yearMonthDay.string(from: Date()))"
    }

    private var allMessages: [ChatBubble] {
        var messages: [ChatBubble] = []
        if let context = matchContext {
            // From sign-up success → show match info as context, no generic mock messages.
            // Dismissing hides the banner but keeps the empty-chat-above-input feel
            // (we intentionally do NOT fall through to mock messages on dismiss, otherwise
            // pre-existing mock chat would suddenly appear).
            if !matchContextDismissed {
                messages.append(ChatBubble(.systemMessage(context)))
            }
        } else {
            for msg in mockMessages {
                messages.append(msg)
                // After an accepted invitation, insert a system confirmation
                if case .invitation(let date, let location, _, _) = msg.content,
                   isInvitationAccepted(date: date, location: location) {
                    messages.append(ChatBubble(
                        .systemMessage("🎾 約球已確認！\(date) 在\(location)，記得準時到達！")
                    ))
                }
            }
        }
        messages.append(contentsOf: sentMessages)
        return messages
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        Text(dateSeparatorLabel())
                            .font(Typography.small)
                            .foregroundColor(Theme.textHint)
                            .frame(maxWidth: .infinity)
                            .padding(.top, Spacing.xs)

                        ForEach(allMessages) { message in
                            messageView(message)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .onChange(of: sentMessages.count) { _, _ in
                    if let lastMsg = allMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMsg.id, anchor: .bottom)
                        }
                    }
                }
            }

            inputBar
        }
        .background(Theme.inputBg)
        .onAppear {
            // Seed the sign-up message once; guarded so re-appears don't
            // duplicate the bubble.
            guard !didSeedInitialMessage else { return }
            didSeedInitialMessage = true
            if let seed = initialMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
               !seed.isEmpty {
                let ts = AppDateFormatter.hourMinute.string(from: Date())
                sentMessages.append(ChatBubble(.outgoing(seed), timestamp: ts))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                }
            }
            ToolbarItem(placement: .principal) {
                Text(chatTitle)
                    .font(Typography.navTitle)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showChatMenu = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17))
                        .frame(width: 44, height: 44)
                }
            }
        }
        .toolbarBackground(Theme.accentGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog("", isPresented: $showChatMenu) {
            switch chat.type {
            case .match:
                Button("查看約球詳情") {
                    chatMenuToast = L10n.string("即將推出")
                }
                Button("查看群成員") {
                    chatMenuToast = L10n.string("即將推出")
                }
                Button(LocalizedStringKey(isMuted ? "取消靜音" : "靜音通知")) {
                    isMuted.toggle()
                    chatMenuToast = L10n.string(isMuted ? "已靜音通知" : "已取消靜音")
                }
                Button("退出群聊", role: .destructive) {
                    onRemoveChat?()
                    dismiss()
                }
            case .personal(let name, let symbol, _):
                Button("查看 \(name) 的資料") {
                    let gender: Gender = symbol == "♀" ? .female : .male
                    selectedPlayer = mockPublicPlayerData(name: name, gender: gender, ntrp: "3.5")
                }
                Button(LocalizedStringKey(isMuted ? "取消靜音" : "靜音通知")) {
                    isMuted.toggle()
                    chatMenuToast = L10n.string(isMuted ? "已靜音通知" : "已取消靜音")
                }
                Button("封鎖對方", role: .destructive) {
                    showBlockAlert = true
                }
                Button("刪除聊天", role: .destructive) {
                    onRemoveChat?()
                    dismiss()
                }
            }
            Button("取消", role: .cancel) {}
        }
        .alert("封鎖用戶", isPresented: $showBlockAlert) {
            Button("取消", role: .cancel) {}
            Button("確認封鎖", role: .destructive) {
                if case .personal(let name, _, _) = chat.type {
                    onBlockUser?(name)
                }
                onRemoveChat?()
                dismiss()
            }
        } message: {
            if case .personal(let name, _, _) = chat.type {
                Text("封鎖「\(name)」後，對方將無法查看你的資料和約球，也無法向你發送私信。")
            } else {
                Text("封鎖後對方將無法再聯絡你。")
            }
        }
        .navigationDestination(item: $selectedPlayer) { player in
            PublicProfileView(player: player)
        }
        .toast($chatMenuToast, icon: "info.circle.fill")
    }

    // MARK: - Message Routing

    @ViewBuilder
    private func messageView(_ message: ChatBubble) -> some View {
        switch message.content {
        case .incoming(let text):
            incomingBubble(text)
        case .outgoing(let text):
            VStack(alignment: .trailing, spacing: 4) {
                outgoingBubble(text)
                if let ts = message.timestamp {
                    Text(ts)
                        .font(Typography.micro)
                        .foregroundColor(Theme.textHint)
                }
            }
        case .outgoingImage(let data):
            VStack(alignment: .trailing, spacing: 4) {
                outgoingImageBubble(data)
                if let ts = message.timestamp {
                    Text(ts)
                        .font(Typography.micro)
                        .foregroundColor(Theme.textHint)
                }
            }
        case .invitation(let date, let location, let start, let end):
            invitationCard(messageID: message.id, date: date, location: location, startDate: start, endDate: end)
        case .systemMessage(let text):
            systemMessageBubble(text)
        }
    }

    // MARK: - Incoming Bubble

    private func incomingBubble(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Circle()
                .fill(Theme.primaryLight)
                .frame(width: 32, height: 32)
                .overlay(
                    Text("🎾")
                        .font(Typography.bodyMedium)
                )
                .onTapGesture {
                    // 點擊頭像查看對方資料
                    if case .personal(let name, let symbol, _) = chat.type {
                        let gender: Gender = symbol == "♀" ? .female : .male
                        selectedPlayer = mockPublicPlayerData(name: name, gender: gender, ntrp: "3.5")
                    }
                }

            Text(text)
                .font(Typography.caption)
                .foregroundColor(Theme.textDark)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.surface)
                )

            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Outgoing Bubble

    private func outgoingBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 60)

            Text(text)
                .font(Typography.caption)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.accentGreen)
                )
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Outgoing Image Bubble

    private func outgoingImageBubble(_ data: Data) -> some View {
        HStack {
            Spacer(minLength: 60)

            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 200, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - System Message

    private func systemMessageBubble(_ text: String) -> some View {
        let isMatchContext = text.contains("約球已確認") || text.contains("賽事報名確認") || text.contains("已接受約球邀請") || text.contains("邀請你加入我的約球") || text.contains("邀請你參加我的賽事")
        // Only the sign-up-success context card (passed via `matchContext`) is
        // dismissible — the auto-generated "約球已確認" inline banners are not.
        let isDismissible = isMatchContext && matchContext != nil && text == matchContext
        return HStack {
            Spacer()
            if isMatchContext {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(text.components(separatedBy: "\n"), id: \.self) { line in
                            Text(LocalizedStringKey(line))
                                .font(.system(size: 13, weight: line == text.components(separatedBy: "\n").first ? .bold : .regular))
                                .foregroundColor(Theme.textDark)
                        }
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.confirmedBg)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.primary.opacity(0.3), lineWidth: 1)
                    )

                    if isDismissible {
                        Button {
                            withAnimation { matchContextDismissed = true }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.textHint)
                                .frame(width: 28, height: 28)
                        }
                        .accessibilityLabel("關閉")
                    }
                }
            } else {
                Text(LocalizedStringKey(text))
                    .font(Typography.smallMedium)
                    .foregroundColor(Theme.textCaption)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.confirmedBg)
                    )
            }
            Spacer()
        }
    }

    // MARK: - Invitation Card

    private func invitationCard(messageID: UUID, date: String, location: String, startDate: Date, endDate: Date) -> some View {
        let isAccepted = isInvitationAccepted(date: date, location: location)
        let isDeclined = declinedInvitationIDs.contains(messageID)

        return HStack(alignment: .top, spacing: Spacing.xs) {
            Color.clear.frame(width: 32, height: 1)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("🎾 約球邀請")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.accentGreen)

                Text("📅 \(date)  📍 \(location)")
                    .font(Typography.fieldLabel)
                    .foregroundColor(Theme.textDark)

                if isAccepted {
                    Text("✅ 已接受")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.primary)
                } else if isDeclined {
                    Text("已婉拒")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                } else {
                    HStack(spacing: Spacing.xs) {
                        Button {
                            let parts = date.components(separatedBy: " ")
                            let dateStr = parts.first ?? date
                            let timeStr = parts.count > 1 ? parts[1] : "10:00"
                            let match = AcceptedMatchInfo(
                                organizerName: organizerName,
                                matchType: matchTypeFromChat,
                                dateString: dateStr,
                                time: timeStr,
                                location: location,
                                startDate: startDate,
                                endDate: endDate
                            )
                            // 时段冲突拦截 + 写入已确认列表 一次完成(CLAUDE.md 边界 case #4)。
                            switch bookingStore.acceptInvitation(match) {
                            case .ok:
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            case .conflict(let label):
                                chatMenuToast = L10n.string("該時段已與「\(label)」衝突,請先取消已預訂的時段")
                            }
                        } label: {
                            Text("接受")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                // 視覺保持小尺寸,但觸控區域至少 44pt(HIG 標準)
                                .frame(width: 60, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Theme.accentGreen)
                                )
                                .frame(minHeight: 44)
                        }

                        Button {
                            withAnimation {
                                _ = declinedInvitationIDs.insert(messageID)
                            }
                            // 发送系统消息告知已拒绝
                            let ts = AppDateFormatter.hourMinute.string(from: Date())
                            sentMessages.append(ChatBubble(
                                .systemMessage("已婉拒 \(date) 在 \(location) 的約球邀請"),
                                timestamp: ts
                            ))
                        } label: {
                            Text("拒絕")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.accentGreen)
                                // 視覺保持小尺寸,但觸控區域至少 44pt(HIG 標準)
                                .frame(width: 60, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Theme.accentGreen, lineWidth: 1)
                                )
                                .frame(minHeight: 44)
                        }
                    }
                }
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
            )

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input Bar

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let ts = AppDateFormatter.hourMinute.string(from: Date())
        sentMessages.append(ChatBubble(.outgoing(trimmed), timestamp: ts))
        messageText = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.inputBorder)
                .frame(height: 1)

            HStack(spacing: Spacing.xs) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.textDark)
                        .frame(width: 44, height: 44)
                        .background(
                            Capsule().fill(Theme.inputBg)
                        )
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            // 先暫存圖片，顯示預覽讓用戶確認後再發送
                            pendingPhotoData = data
                        }
                        selectedPhotoItem = nil
                    }
                }
                // 圖片發送前預覽浮層
                .sheet(isPresented: Binding(
                    get: { pendingPhotoData != nil },
                    set: { if !$0 { pendingPhotoData = nil } }
                )) {
                    if let data = pendingPhotoData, let uiImage = UIImage(data: data) {
                        NavigationStack {
                            VStack(spacing: Spacing.lg) {
                                Spacer()
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .padding(.horizontal, Spacing.md)
                                Spacer()
                            }
                            .navigationTitle("發送圖片")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("取消") {
                                        // 取消：清除暫存圖片
                                        pendingPhotoData = nil
                                    }
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("發送") {
                                        // 確認發送：加入訊息列表
                                        let ts = AppDateFormatter.hourMinute.string(from: Date())
                                        sentMessages.append(ChatBubble(.outgoingImage(data), timestamp: ts))
                                        selectedPhotoData = data
                                        pendingPhotoData = nil
                                    }
                                    .fontWeight(.bold)
                                }
                            }
                        }
                    }
                }

                TextField("輸入訊息...", text: $messageText)
                    .font(Typography.caption)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 44)
                    .background(
                        Capsule()
                            .fill(Theme.inputBg)
                            .overlay(
                                Capsule()
                                    .stroke(Theme.inputBorder, lineWidth: 1)
                            )
                    )
                    .onSubmit { sendMessage() }

                Button { sendMessage() } label: {
                    Text("發送")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 54, height: 44)
                        .background(
                            Capsule().fill(messageText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Theme.chipUnselectedBg
                                : Theme.accentGreen)
                        )
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Theme.surface)
        }
    }
}

// MARK: - Mock Messages

private struct ChatBubble: Identifiable {
    let id = UUID()
    let content: BubbleContent
    let timestamp: String?

    init(_ content: BubbleContent, timestamp: String? = nil) {
        self.content = content
        self.timestamp = timestamp
    }

    enum BubbleContent {
        case incoming(String)
        case outgoing(String)
        case outgoingImage(Data)
        case invitation(date: String, location: String, startDate: Date, endDate: Date)
        case systemMessage(String)
    }
}

// 模擬聊天訊息，含系統通知、對方發言、自己發言
private let mockMessages: [ChatBubble] = [
    ChatBubble(.systemMessage("你已加入約球群組"), timestamp: nil),
    ChatBubble(.incoming("大家好！明天見 🎾"), timestamp: "09:30"),
    ChatBubble(.outgoing("收到，我會準時到！"), timestamp: "09:31"),
    ChatBubble(.incoming("場地已確認，記得帶水"), timestamp: "09:32"),
    ChatBubble(.outgoing("好的，謝謝提醒"), timestamp: "09:33"),
    ChatBubble(.incoming("球場旁邊有停車場，很方便"), timestamp: "09:35"),
    ChatBubble(.outgoing("太好了，我開車去"), timestamp: "09:36"),
    ChatBubble(.systemMessage("約球將於明天 10:00 開始"), timestamp: nil),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        ChatDetailView(
            chat: MockChat(
                type: .personal(name: "莎拉", symbol: "♀", symbolColor: Theme.genderFemale),
                lastMessage: "謝謝你上次的比賽，打得很開心！",
                time: "昨天",
                unreadCount: 3
            )
        )
    }
    .environment(BookingStore())
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        ChatDetailView(
            chat: MockChat(
                type: .personal(name: "莎拉", symbol: "♀", symbolColor: Theme.genderFemale),
                lastMessage: "謝謝你上次的比賽，打得很開心！",
                time: "昨天",
                unreadCount: 3
            )
        )
    }
    .environment(BookingStore())
}
