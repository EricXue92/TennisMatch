//
//  ReviewsView.swift
//  TennisMatch
//
//  評價 — 收到的評價 / 待評價
//

import SwiftUI

struct ReviewsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = "收到的評價"
    @State private var pendingReviews: [PendingReview] = mockPendingReviews
    @State private var reviewTarget: PendingReview?
    @State private var reviewRating: Int = 5
    @State private var reviewText = ""
    @State private var showReviewSheet = false
    @State private var showSubmitToast = false

    var body: some View {
        VStack(spacing: 0) {
            filterTabs

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
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("評價")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .sheet(isPresented: $showReviewSheet) {
            if let target = reviewTarget {
                ReviewFormSheet(
                    targetName: target.name,
                    rating: $reviewRating,
                    text: $reviewText,
                    onSubmit: {
                        withAnimation {
                            pendingReviews.removeAll { $0.id == target.id }
                        }
                        showReviewSheet = false
                        showSubmitToast = true
                        reviewTarget = nil
                        reviewRating = 5
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
                        .font(.system(size: 13, weight: .medium))
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
                                .font(.system(size: 14, weight: .medium))
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
        .background(.white)
    }

    private func receivedReviewCard(_ review: ReceivedReview) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xE0E0E0))
                    .frame(width: 40, height: 40)
                Text(String(review.name.prefix(1)))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(review.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(review.date)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < review.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(i < review.rating ? Color(hex: 0xFACC15) : Theme.textSecondary)
                    }
                }

                Text(review.comment)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textBody)
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func pendingReviewCard(_ review: PendingReview) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xE0E0E0))
                    .frame(width: 40, height: 40)
                Text(String(review.name.prefix(1)))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(review.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Text(review.matchInfo)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Button {
                reviewTarget = review
                showReviewSheet = true
            } label: {
                Text("評價")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 30)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(Spacing.md)
        .background(.white)
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
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Spacing.xs) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        rating = i
                    } label: {
                        Image(systemName: i <= rating ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundColor(i <= rating ? Color(hex: 0xFACC15) : Theme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            TextField("說說你的打球體驗...", text: $text, axis: .vertical)
                .font(.system(size: 14))
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
]

private let mockPendingReviews: [PendingReview] = [
    PendingReview(name: "志明", matchInfo: "04/21 單打 · 香港網球中心"),
    PendingReview(name: "嘉欣", matchInfo: "04/18 雙打 · 沙田公園"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        ReviewsView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        ReviewsView()
    }
}
