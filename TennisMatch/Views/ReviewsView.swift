//
//  ReviewsView.swift
//  TennisMatch
//
//  評價 — 收到的評價 / 待評價
//

import SwiftUI

struct ReviewsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RatingFeedbackStore.self) private var ratingFeedbackStore
    @Environment(UserStore.self) private var userStore
    @State private var selectedTab = "收到的評價"
    @State private var pendingReviews: [PendingReview] = mockPendingReviews
    @State private var reviewTarget: PendingReview?
    @State private var reviewRating: Int = 0
    @State private var reviewText = ""
    @State private var showReviewSheet = false
    @State private var showSubmitToast = false

    var body: some View {
        VStack(spacing: 0) {
            filterTabs

            if selectedTab == "收到的評價" && mockReceivedReviews.isEmpty {
                ContentUnavailableView(
                    "暫無評價",
                    systemImage: "star.bubble",
                    description: Text("完成約球後收到的評價會顯示在這裡")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if selectedTab == "待評價" && pendingReviews.isEmpty {
                ContentUnavailableView(
                    "沒有待評價的約球",
                    systemImage: "checkmark.seal",
                    description: Text("完成約球後，可在這裡給對手留下評價")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.sm) {
                        if selectedTab == "收到的評價" {
                            ForEach(mockReceivedReviews) { review in
                                receivedReviewCard(review)
                            }
                        } else {
                            ForEach(pendingReviews) { review in
                                pendingReviewCard(review)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Typography.buttonMedium)
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("評價")
                    .font(Typography.sectionTitle)
            }
        }
        .sheet(isPresented: $showReviewSheet) {
            if let target = reviewTarget {
                ReviewFormSheet(
                    targetName: target.name,
                    rating: $reviewRating,
                    text: $reviewText,
                    onSubmit: {
                        // 模擬對手回評：根據用戶給的星級推算對手對自己 NTRP 的估計
                        let ntrpEstimate: Double = {
                            let base = userStore.ntrpLevel
                            switch reviewRating {
                            case 5: return base + 0.5
                            case 4: return base
                            case 3: return base - 0.5
                            case 2: return base - 1.0
                            default: return base - 1.5
                            }
                        }()
                        ratingFeedbackStore.recordPeerRating(
                            reviewer: target.name,
                            ntrpEstimate: min(max(ntrpEstimate, 1.0), 7.0)
                        )

                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation {
                            pendingReviews.removeAll { $0.id == target.id }
                        }
                        showReviewSheet = false
                        showSubmitToast = true
                        reviewTarget = nil
                        reviewRating = 0
                        reviewText = ""
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .overlay(alignment: .top) {
            if showSubmitToast {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text("評價提交成功")
                        .font(Typography.captionMedium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Capsule().fill(Theme.textBody))
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, Spacing.lg)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showSubmitToast = false }
                    }
                }
            }
        }
    }

    private var filterTabs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(["收到的評價", "待評價"], id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Text(tab)
                                .font(Typography.bodyMedium)
                                .foregroundColor(selectedTab == tab ? Theme.primary : Theme.textBody)
                                .frame(maxWidth: .infinity)
                            Rectangle()
                                .fill(selectedTab == tab ? Theme.primary : .clear)
                                .frame(width: 60, height: 3)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.top, Spacing.sm)
            Theme.inputBorder.frame(height: 1)
        }
        .background(Theme.surface)
    }

    private func receivedReviewCard(_ review: ReceivedReview) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 40, height: 40)
                Text(String(review.name.prefix(1)))
                    .font(Typography.button)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(review.name)
                        .font(Typography.bodyMedium)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(review.date)
                        .font(Typography.fieldLabel)
                        .foregroundColor(Theme.textSecondary)
                }

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < review.rating ? "star.fill" : "star")
                            .font(Typography.small)
                            .foregroundColor(i < review.rating ? Theme.starYellow : Theme.textSecondary)
                    }
                }

                Text(review.comment)
                    .font(Typography.caption)
                    .foregroundColor(Theme.textBody)
            }
        }
        .padding(Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func pendingReviewCard(_ review: PendingReview) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 40, height: 40)
                Text(String(review.name.prefix(1)))
                    .font(Typography.button)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(review.name)
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textPrimary)
                Text(review.matchInfo)
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Button {
                reviewTarget = review
                showReviewSheet = true
            } label: {
                Text("評價")
                    .font(Typography.smallMedium)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 30)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Review Form Sheet

private struct ReviewFormSheet: View {
    let targetName: String
    @Binding var rating: Int
    @Binding var text: String
    var onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("評價 \(targetName)")
                .font(Typography.largeStat)
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    ForEach(1...5, id: \.self) { i in
                        Button {
                            rating = i
                        } label: {
                            Image(systemName: i <= rating ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundColor(i <= rating ? Theme.starYellow : Theme.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                // 未選星級時顯示提示
                if rating == 0 {
                    Text("請先選擇評分")
                        .font(Typography.small)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            TextField("說說你的打球體驗...", text: $text, axis: .vertical)
                .font(Typography.bodyMedium)
                .lineLimit(3...5)
                .padding(Spacing.sm)
                .background(Theme.inputBg)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.inputBorder, lineWidth: 1)
                )

            Spacer()

            Button(action: onSubmit) {
                Text("提交評價")
                    .font(Typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    // 未選星級時顯示灰色，已選則顯示主色
                    .background(rating == 0 ? Theme.chipUnselectedBg : Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(rating == 0)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }
}

// MARK: - Data

private struct ReceivedReview: Identifiable {
    let id = UUID()
    let name: String
    let rating: Int
    let comment: String
    let date: String
}

private struct PendingReview: Identifiable {
    let id = UUID()
    let name: String
    let matchInfo: String
}

private let mockReceivedReviews: [ReceivedReview] = [
    ReceivedReview(name: "莎拉", rating: 5, comment: "很準時，球技很好，打得很開心！", date: "04/19"),
    ReceivedReview(name: "王強", rating: 4, comment: "配合默契的雙打搭檔", date: "04/15"),
    ReceivedReview(name: "小美", rating: 5, comment: "球品好，推薦！", date: "04/10"),
    ReceivedReview(name: "大衛", rating: 5, comment: "球風穩健，接發球很到位", date: "04/06"),
    ReceivedReview(name: "嘉欣", rating: 4, comment: "很有耐心的球友，適合練習對打", date: "03/29"),
    ReceivedReview(name: "俊傑", rating: 3, comment: "遲到了十分鐘，但球技不錯", date: "03/22"),
    ReceivedReview(name: "艾美", rating: 5, comment: "非常友善，下次還想約！節奏掌控很好", date: "03/15"),
]

private let mockPendingReviews: [PendingReview] = [
    PendingReview(name: "志明", matchInfo: "04/21 單打 · 香港網球中心"),
    PendingReview(name: "嘉欣", matchInfo: "04/18 雙打 · 沙田公園"),
    PendingReview(name: "Michael", matchInfo: "04/20 單打 · 跑馬地遊樂場"),
    PendingReview(name: "阿豪", matchInfo: "04/17 雙打 · 歌和老街公園"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        ReviewsView()
    }
    .environment(RatingFeedbackStore())
    .environment(UserStore())
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        ReviewsView()
    }
    .environment(RatingFeedbackStore())
    .environment(UserStore())
}
