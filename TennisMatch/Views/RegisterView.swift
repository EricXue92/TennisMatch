//
//  RegisterView.swift
//  TennisMatch
//
//  註冊頁面 — 建立帳號表單
//

import SwiftUI
import UIKit

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var gender = Gender.male
    @State private var birthday = Date(timeIntervalSince1970: 640_310_400) // 1990/04/17
    @State private var avatarImage: UIImage?

    @State private var showGenderPicker = false
    @State private var showDatePicker = false
    @State private var showImagePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                avatarSection
                formCard
                if avatarImage == nil {
                    warningBanner
                }
                disclaimer
                submitButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("註冊")
                    .font(Typography.navTitle)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: Spacing.xs) {
            Button { showImagePicker = true } label: {
                if let avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Theme.primaryLight)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .strokeBorder(Theme.primary.opacity(0.3), lineWidth: 1.5)
                        )
                }
            }

            Button { showImagePicker = true } label: {
                Text("上傳頭像")
                    .font(Typography.small)
                    .foregroundColor(Theme.primary)
            }
        }
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("建立帳號")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            textField(label: "姓名", text: $name)
            textField(label: "使用者名稱", text: $username)
            textField(label: "電子郵件", text: $email, keyboard: .emailAddress)
            pickerField(label: "性別", value: gender.displayName) {
                showGenderPicker.toggle()
            }
            pickerField(label: "生日", value: formattedBirthday, showDivider: false) {
                showDatePicker.toggle()
            }

            if showGenderPicker {
                genderPickerView
            }
            if showDatePicker {
                datePickerView
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Form Fields

    private func textField(
        label: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Typography.fieldLabel)
                .foregroundColor(Theme.textSecondary)

            TextField(label, text: text)
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textPrimary)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .frame(minHeight: 22)

            Theme.divider.frame(height: 1)
        }
        .padding(.vertical, Spacing.sm)
    }

    private func pickerField(
        label: String,
        value: String,
        showDivider: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Typography.fieldLabel)
                .foregroundColor(Theme.textSecondary)

            Button(action: action) {
                HStack {
                    Text(value)
                        .font(Typography.fieldValue)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("▾")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(minHeight: 22)
            }

            if showDivider {
                Theme.divider.frame(height: 1)
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Pickers

    private var genderPickerView: some View {
        Picker("性別", selection: $gender) {
            ForEach(Gender.allCases) { g in
                Text(g.displayName).tag(g)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, Spacing.xs)
    }

    private var datePickerView: some View {
        DatePicker(
            "生日",
            selection: $birthday,
            in: ...Date.now,
            displayedComponents: .date
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
        .padding(.top, Spacing.xs)
    }

    // MARK: - Warning Banner

    private var warningBanner: some View {
        HStack {
            Text("⚠ 請上傳個人頭像照片")
                .font(Typography.small)
                .foregroundColor(Theme.warningText)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Theme.warningBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        Text("點擊「加入」即表示您提供的所有資訊均為真實、準確且完整。")
            .font(Typography.fieldLabel)
            .foregroundColor(Theme.textSecondary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            // TODO: submit registration
        } label: {
            Text("加入 Let's Tennis")
                .font(Typography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Helpers

    private var formattedBirthday: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f.string(from: birthday)
    }
}

// MARK: - Gender

enum Gender: String, CaseIterable, Identifiable {
    case male, female, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male:   return "男"
        case .female: return "女"
        case .other:  return "其他"
        }
    }
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        RegisterView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        RegisterView()
    }
    .previewDevice("iPhone 15 Pro")
}
