//
//  MessagesView.swift
//  TennisMatch
//
//  聊天 — 約球群組 & 私人對話列表
//

import SwiftUI

struct MessagesView: View {
    @Binding var totalUnread: Int
    @Binding var acceptedMatches: [AcceptedMatchInfo]
    @State private var selectedChat: MockChat?
    @State private var readChatIDs: Set<UUID> = []
    @State private var chats: [MockChat] = mockChatsInitial
    @State private var chatToDelete: MockChat?
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            Rectangle()
                .fill(Theme.inputBorder)
                .frame(height: 1)

            if chats.isEmpty {
                ContentUnavailableView(
                    "暫無聊天",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("開始約球後，與對手的對話會顯示在這裡")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
            List {
                // First item as highlighted card
                if let first = chats.first {
                    chatCard(first)
                        .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.xs, bottom: 0, trailing: Spacing.xs))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.white)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                chatToDelete = first
                                showDeleteAlert = true
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                }

                // Remaining items as regular rows
                ForEach(Array(chats.dropFirst())) { chat in
                    chatRowContent(chat)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.white)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                chatToDelete = chat
                                showDeleteAlert = true
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .padding(.bottom, 100)
            }
        }
        .background(.white)
        .onAppear { recalculateUnread() }
        .navigationDestination(item: $selectedChat) { chat in
            ChatDetailView(chat: chat, acceptedMatches: $acceptedMatches)
        }
        .onChange(of: selectedChat) { _, newChat in
            guard let chat = newChat, !readChatIDs.contains(chat.id) else { return }
            readChatIDs.insert(chat.id)
            recalculateUnread()
        }
        .alert("刪除聊天", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {
                chatToDelete = nil
            }
            Button("刪除", role: .destructive) {
                if let chat = chatToDelete {
                    withAnimation {
                        chats.removeAll { $0.id == chat.id }
                    }
                    recalculateUnread()
                    chatToDelete = nil
                }
            }
        } message: {
            Text("確定要刪除此聊天記錄嗎？刪除後無法恢復。")
        }
    }

    private func effectiveUnread(_ chat: MockChat) -> Int {
        readChatIDs.contains(chat.id) ? 0 : chat.unreadCount
    }

    private func recalculateUnread() {
        totalUnread = chats.reduce(0) { sum, c in
            sum + (readChatIDs.contains(c.id) ? 0 : c.unreadCount)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("聊天")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Highlighted Card

    private func chatCard(_ chat: MockChat) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            tennisAvatar

            chatContent(chat)

            Spacer(minLength: 0)

            trailingInfo(chat)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { selectedChat = chat }
    }

    // MARK: - Regular Row

    private func chatRowContent(_ chat: MockChat) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                tennisAvatar

                chatContent(chat)

                Spacer(minLength: 0)

                trailingInfo(chat)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)

            Rectangle()
                .fill(Theme.inputBorder)
                .frame(height: 1)
                .padding(.leading, 76)
        }
        .contentShape(Rectangle())
        .onTapGesture { selectedChat = chat }
    }

    // MARK: - Shared Components

    private var tennisAvatar: some View {
        ZStack {
            Circle()
                .fill(Theme.primaryLight)
                .frame(width: 48, height: 48)
            Text("🎾")
                .font(.system(size: 18))
        }
    }

    @ViewBuilder
    private func chatContent(_ chat: MockChat) -> some View {
        let unread = effectiveUnread(chat)
        VStack(alignment: .leading, spacing: 2) {
            switch chat.type {
            case .match(let title, let dateTime):
                Text(title)
                    .font(.system(size: 15, weight: unread > 0 ? .semibold : .medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text("📍 \(dateTime)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.primary)
                    .lineLimit(1)
            case .personal(let name, let symbol, let symbolColor):
                HStack(spacing: 4) {
                    Text(name)
                        .font(.system(size: 15, weight: unread > 0 ? .semibold : .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text(symbol)
                        .font(Typography.fieldValue)
                        .foregroundColor(symbolColor)
                }
            }

            Text(chat.lastMessage)
                .font(Typography.caption)
                .foregroundColor(Theme.textCaption)
                .lineLimit(1)
        }
    }

    private func trailingInfo(_ chat: MockChat) -> some View {
        let unread = effectiveUnread(chat)
        return VStack(alignment: .trailing, spacing: Spacing.xs) {
            Text(chat.time)
                .font(Typography.fieldLabel)
                .foregroundColor(Theme.textSecondary)
            if unread > 0 {
                Text("\(unread)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Theme.primary))
            }
        }
    }
}

// MARK: - Mock Data

enum ChatType {
    case match(title: String, dateTime: String)
    case personal(name: String, symbol: String, symbolColor: Color)
}

struct MockChat: Identifiable, Hashable {
    let id = UUID()
    let type: ChatType
    let lastMessage: String
    let time: String
    let unreadCount: Int

    static func == (lhs: MockChat, rhs: MockChat) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct AcceptedMatchInfo: Identifiable {
    let id = UUID()
    let organizerName: String
    let matchType: String
    let dateString: String
    let time: String
    let location: String
    /// Origin HomeView match ID so a future cancel can decrement the correct source match.
    /// Nil when the accepted entry does not originate from a HomeView sign-up (e.g., invitation accept, chat accept).
    var sourceMatchID: UUID? = nil
    var durationHours: Int = 2
    var players: String = "2/2"
    var ntrpRange: String = "3.0-4.0"
}

let mockChatsInitial: [MockChat] = []

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        MessagesView(totalUnread: .constant(4), acceptedMatches: .constant([]))
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        MessagesView(totalUnread: .constant(4), acceptedMatches: .constant([]))
    }
}
