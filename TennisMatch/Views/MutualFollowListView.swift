//
//  MutualFollowListView.swift
//  TennisMatch
//
//  互相關注 — 互相關注的球友列表(佔位頁面)
//

import SwiftUI

struct MutualFollowListView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ContentUnavailableView(
            "互相關注",
            systemImage: "person.2.fill",
            description: Text("與你互相關注的球友將顯示在這裡")
        )
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
                Text("互相關注")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MutualFollowListView()
    }
    .environment(FollowStore())
}
