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
    @Binding var acceptedMatches: [AcceptedMatchInfo]
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var sentMessages: [ChatBubble] = []
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var showChatMenu = false

    private var chatTitle: String {
        switch chat.type {
        case .match(let title, _): return title
        case .personal(let name, _, _): return name
        }
    }

    private var organizerName: String {
        switch chat.type {
        case .match(let title, _):
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
        return acceptedMatches.contains { m in
            m.organizerName == organizerName && m.dateString == dateStr && m.location == location
        }
    }

    private var allMessages: [ChatBubble] {
        var messages: [ChatBubble] = []
        for msg in mockMessages {
            messages.append(msg)
            // After an accepted invitation, insert a system confirmation
            if case .invitation(let date, let location) = msg.content,
               isInvitationAccepted(date: date, location: location) {
                messages.append(ChatBubble(
                    .systemMessage("🎾 約球已確認！\(date) 在\(location)，記得準時到達！")
                ))
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
                        Text("今天")
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
                    // TODO: navigate to MatchDetailView
                }
                Button("查看群成員") {
                    // TODO: show members
                }
                Button("靜音通知") {
                    // TODO: toggle mute
                }
                Button("退出群聊", role: .destructive) {
                    dismiss()
                }
            case .personal(let name, _, _):
                Button("查看 \(name) 的資料") {
                    // TODO: navigate to PublicProfileView
                }
                Button("靜音通知") {
                    // TODO: toggle mute
                }
                Button("封鎖對方", role: .destructive) {
                    // TODO: block
                }
                Button("刪除聊天", role: .destructive) {
                    dismiss()
                }
            }
            Button("取消", role: .cancel) {}
        }
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
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textHint)
                }
            }
        case .outgoingImage(let data):
            VStack(alignment: .trailing, spacing: 4) {
                outgoingImageBubble(data)
                if let ts = message.timestamp {
                    Text(ts)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textHint)
                }
            }
        case .invitation(let date, let location):
            invitationCard(messageID: message.id, date: date, location: location)
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
                        .font(.system(size: 14))
                )

            Text(text)
                .font(Typography.caption)
                .foregroundColor(Theme.textDark)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
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
        HStack {
            Spacer()
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textCaption)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.confirmedBg)
                )
            Spacer()
        }
    }

    // MARK: - Invitation Card

    private func invitationCard(messageID: UUID, date: String, location: String) -> some View {
        let isAccepted = isInvitationAccepted(date: date, location: location)

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
                                location: location
                            )
                            acceptedMatches.append(match)
                        } label: {
                            Text("接受")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Theme.accentGreen)
                                )
                        }

                        Button {} label: {
                            Text("拒絕")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.accentGreen)
                                .frame(width: 60, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Theme.accentGreen, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
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
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let ts = formatter.string(from: now)
        sentMessages.append(ChatBubble(.outgoing(trimmed), timestamp: ts))
        messageText = ""
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
                        .frame(width: 44, height: 36)
                        .background(
                            Capsule().fill(Theme.inputBg)
                        )
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            selectedPhotoData = data
                            let now = Date()
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            let ts = formatter.string(from: now)
                            sentMessages.append(ChatBubble(.outgoingImage(data), timestamp: ts))
                        }
                        selectedPhotoItem = nil
                    }
                }

                TextField("輸入訊息...", text: $messageText)
                    .font(Typography.caption)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 36)
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
                        .frame(width: 50, height: 36)
                        .background(
                            Capsule().fill(Theme.accentGreen)
                        )
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(.white)
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
        case invitation(date: String, location: String)
        case systemMessage(String)
    }
}

private let mockMessages: [ChatBubble] = [
    ChatBubble(.incoming("嗨！明天下午的單打還缺人嗎？")),
    ChatBubble(.outgoing("還缺一位，歡迎加入！")),
    ChatBubble(.incoming("太好了！幾點開始？")),
    ChatBubble(.outgoing("下午3點，維多利亞公園3號場")),
    ChatBubble(.incoming("好的，我會準時到 👍")),
    ChatBubble(.outgoing("記得帶水，天氣會比較熱 ☀️")),
    ChatBubble(.incoming("沒問題！我帶球，你帶球拍？")),
    ChatBubble(.outgoing("👌 我有兩副拍子可以用")),
    ChatBubble(.invitation(date: "04/19 15:00", location: "維多利亞公園")),
    ChatBubble(.incoming("太好了，那就這樣定了！")),
    ChatBubble(.outgoing("明天見！🎾"), timestamp: "14:30"),
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
            ),
            acceptedMatches: .constant([])
        )
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        ChatDetailView(
            chat: MockChat(
                type: .personal(name: "莎拉", symbol: "♀", symbolColor: Theme.genderFemale),
                lastMessage: "謝謝你上次的比賽，打得很開心！",
                time: "昨天",
                unreadCount: 3
            ),
            acceptedMatches: .constant([])
        )
    }
}
