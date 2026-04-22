//
//  FollowerListView.swift
//  TennisMatch
//
//  粉絲 — 關注我的球友列表(佔位頁面)
//

import SwiftUI

struct FollowerListView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ContentUnavailableView(
            "粉絲列表",
            systemImage: "person.2",
            description: Text("關注你的球友將顯示在這裡")
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
                Text("粉絲")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FollowerListView()
    }
    .environment(FollowStore())
}
