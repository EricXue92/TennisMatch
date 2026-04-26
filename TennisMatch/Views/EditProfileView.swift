//
//  EditProfileView.swift
//  TennisMatch
//
//  編輯資料頁面
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore

    // MARK: - Form State
    //
    // Edits happen on a local draft, so closing without saving doesn't mutate
    // the shared store. `onAppear` seeds the draft from the store,
    // `saveButton` pushes it back.

    @State private var name: String = ""
    @State private var selectedGender: Gender = .male
    @State private var ageRange: String = "26-35"
    @State private var bio: String = ""
    @State private var ntrpLevel: Double = 3.5
    @State private var selectedCourts: [TennisCourt] = []
    @State private var showCourtPicker = false
    @State private var courtPickerSelection: Set<TennisCourt> = []
    /// 偏好球場最多可選的數量。
    private let maxPreferredCourts = 3
    @State private var partnerLevelLow: Double = 3.0
    @State private var partnerLevelHigh: Double = 4.5
    @State private var region: String = "香港"
    @State private var preferredSlots: [PreferredTimeSlot] = [
        PreferredTimeSlot(day: .tue, startTime: "19:30", endTime: "21:30"),
        PreferredTimeSlot(day: .sun, startTime: "09:00", endTime: "10:00"),
    ]
    @State private var showAddSlot = false
    @State private var showDiscardAlert = false

    // 頭像選擇 — 草稿態,儲存時才寫回 UserStore.avatarImageData。
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarData: Data?

    private let ntrpMin: Double = 1.0
    private let ntrpMax: Double = 7.0
    private let regionOptions = ["香港", "上海", "深圳", "廣州"]

    // MARK: - Unsaved Changes Detection

    /// 比較偏好時段內容（UUID 每次建立都不同，改用內容比對）
    private var slotsChanged: Bool {
        guard preferredSlots.count == userStore.preferredSlots.count else { return true }
        return zip(preferredSlots, userStore.preferredSlots).contains { a, b in
            a.day != b.day || a.startTime != b.startTime || a.endTime != b.endTime
        }
    }

    /// 如果任何欄位與 UserStore 中的值不同，則視為有未儲存的修改
    private var hasUnsavedChanges: Bool {
        name != userStore.displayName ||
        selectedGender != userStore.gender ||
        ageRange != userStore.ageRange ||
        bio != userStore.bio ||
        ntrpLevel != userStore.ntrpLevel ||
        region != userStore.region ||
        selectedCourts.map(\.id) != userStore.selectedCourts.map(\.id) ||
        partnerLevelLow != userStore.partnerLevelLow ||
        partnerLevelHigh != userStore.partnerLevelHigh ||
        slotsChanged ||
        avatarData != userStore.avatarImageData
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar

            ScrollView {
                VStack(spacing: Spacing.md) {
                    avatarSection
                    basicInfoCard
                    skillCard
                    locationTimeCard
                    saveButton
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xl)
            }
        }
        .alert("放棄修改？", isPresented: $showDiscardAlert) {
            Button("繼續編輯", role: .cancel) { }
            Button("放棄", role: .destructive) { dismiss() }
        } message: {
            Text("你有未儲存的修改，確定要放棄嗎？")
        }
        .background(Theme.background)
        .navigationBarHidden(true)
        .onAppear {
            // Seed draft from store (only first appear — avoids overwriting
            // an in-progress edit if the view re-appears).
            if name.isEmpty {
                name = userStore.displayName
                selectedGender = userStore.gender
                ageRange = userStore.ageRange
                bio = userStore.bio
                ntrpLevel = userStore.ntrpLevel
                region = userStore.region
                selectedCourts = userStore.selectedCourts
                partnerLevelLow = userStore.partnerLevelLow
                partnerLevelHigh = userStore.partnerLevelHigh
                preferredSlots = userStore.preferredSlots
                avatarData = userStore.avatarImageData
            }
        }
        .onChange(of: avatarItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    avatarData = data
                }
            }
        }
        .sheet(isPresented: $showCourtPicker) {
            CourtPickerView(
                selected: $courtPickerSelection,
                singleSelect: false,
                maxSelection: maxPreferredCourts
            )
            .onDisappear {
                // 按 allCourts 原始順序排，避免 Set 順序不穩
                selectedCourts = allCourts.filter { courtPickerSelection.contains($0) }
            }
        }
        .sheet(isPresented: $showAddSlot) {
            AddPreferredSlotSheet { slot in
                preferredSlots.append(slot)
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                // 若有未儲存修改，先彈出確認對話框
                if hasUnsavedChanges {
                    showDiscardAlert = true
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 44, height: 44)
            }
            Text("編輯資料")
                .font(Typography.sectionTitle)
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, Spacing.xs)
        .background(Theme.surface)
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $avatarItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    // Gradient ring + thumb
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.primary, Theme.primaryEmerald, Theme.accentGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: Theme.primary.opacity(0.25), radius: 12, y: 6)

                        Circle()
                            .fill(Theme.surface)
                            .frame(width: 92, height: 92)

                        avatarThumb
                    }

                    // Camera badge — white-ringed green chip
                    ZStack {
                        Circle()
                            .fill(Theme.surface)
                            .frame(width: 34, height: 34)
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 28, height: 28)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Theme.primary.opacity(0.35), radius: 6, y: 2)
                    .offset(x: 4, y: 4)
                }
                .accessibilityLabel("更換頭像")
            }
            .buttonStyle(.plain)

            // Pill-style affordance — clearer hit target than plain text.
            HStack(spacing: 5) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 11, weight: .semibold))
                Text("更換照片")
                    .font(Typography.smallMedium)
            }
            .foregroundColor(Theme.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(Theme.primaryLight)
            )
            .overlay(
                Capsule().strokeBorder(Theme.primary.opacity(0.18), lineWidth: 0.5)
            )
            .allowsHitTesting(false) // 真正點擊已由整個 PhotosPicker 處理
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
        .background(
            // 後方柔和綠色光暈,呼應網球場光線氛圍。
            RadialGradient(
                colors: [Theme.primaryLight.opacity(0.85), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 170
            )
        )
    }

    @ViewBuilder
    private var avatarThumb: some View {
        if let data = avatarData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 84, height: 84)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.primaryLight, Theme.surface],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 84, height: 84)
                Text(name.isEmpty ? userStore.avatarInitial : String(name.suffix(1)))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primary)
            }
        }
    }

    // MARK: - Section Cards

    private var basicInfoCard: some View {
        sectionCard(title: "基本資料", icon: "person.text.rectangle.fill") {
            VStack(spacing: 0) {
                formRow(label: "用戶名") {
                    TextField("請輸入用戶名", text: $name)
                        .font(Typography.bodyMedium)
                        .foregroundColor(Theme.textBody)
                }
                formDivider

                formRow(label: "性別") {
                    HStack(spacing: Spacing.lg) {
                        radioButton(label: "男", isSelected: selectedGender == .male) {
                            selectedGender = .male
                        }
                        radioButton(label: "女", isSelected: selectedGender == .female) {
                            selectedGender = .female
                        }
                        Spacer()
                    }
                }
                formDivider

                formRow(label: "年齡") {
                    Picker("", selection: $ageRange) {
                        ForEach(UserStore.ageRangeOptions, id: \.self) { range in
                            Text(range).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.textBody)
                    Spacer()
                }
                formDivider

                formRow(label: "個人簡介") {
                    TextField("一句話介紹自己", text: $bio)
                        .font(Typography.bodyMedium)
                        .foregroundColor(Theme.textBody)
                }
            }
        }
    }

    private var skillCard: some View {
        sectionCard(title: "球技偏好", icon: "figure.tennis") {
            VStack(spacing: 0) {
                ntrpSliderSection
                formDivider

                formRow(label: "偏好球場") {
                    Button {
                        courtPickerSelection = Set(selectedCourts)
                        showCourtPicker = true
                    } label: {
                        HStack {
                            Text(selectedCourts.isEmpty
                                 ? "選擇球場"
                                 : selectedCourts.map(\.name).joined(separator: "、"))
                                .font(Typography.bodyMedium)
                                .foregroundColor(selectedCourts.isEmpty ? Theme.textHint : Theme.textBody)
                                .lineLimit(2)
                                .multilineTextAlignment(.trailing)
                            Spacer(minLength: Spacing.xs)
                            Image(systemName: "chevron.right")
                                .font(Typography.smallMedium)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
                formDivider

                partnerLevelSliderSection
            }
        }
    }

    private var locationTimeCard: some View {
        sectionCard(title: "場地與時段", icon: "mappin.and.ellipse") {
            VStack(spacing: 0) {
                formRow(label: "所在地區") {
                    Picker("", selection: $region) {
                        ForEach(regionOptions, id: \.self) { r in
                            Text(r).tag(r)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.textBody)
                    Spacer()
                }
                formDivider

                preferredTimeSection
            }
        }
    }

    @ViewBuilder
    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.primary)
                    .frame(width: 22, height: 22)
                    .background(Theme.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(title)
                    .font(Typography.labelSemibold)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, Spacing.xs)

            content()
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
    }

    // MARK: - Preferred Time Section

    private var preferredTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("偏好打球時間")
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                    showAddSlot = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(Typography.micro)
                        Text("新增")
                            .font(Typography.smallMedium)
                    }
                    .foregroundColor(Theme.primary)
                }
            }
            .padding(.top, Spacing.sm)

            if preferredSlots.isEmpty {
                Text("尚未設定偏好時間")
                    .font(Typography.caption)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.bottom, Spacing.xs)
            } else {
                ForEach(preferredSlots) { slot in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "clock")
                            .font(Typography.small)
                            .foregroundColor(Theme.primary)

                        Text(slot.displayText)
                            .font(Typography.caption)
                            .foregroundColor(Theme.textBody)

                        Spacer()

                        Button {
                            preferredSlots.removeAll { $0.id == slot.id }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, Spacing.sm)
                    .background(Theme.primaryLight.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }

    // MARK: - Save Button

    @State private var showNameError = false
    @State private var nameErrorMessage = ""

    private var saveButton: some View {
        VStack(spacing: Spacing.xs) {
            if showNameError {
                Text(nameErrorMessage)
                    .font(Typography.small)
                    .foregroundColor(Theme.requiredText)
                    .transition(.opacity)
            }

            Button {
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    nameErrorMessage = "請輸入用戶名"
                    withAnimation { showNameError = true }
                    return
                }
                if userStore.isNameTaken(trimmed, excludingCurrent: true) {
                    nameErrorMessage = "該用戶名已被使用，請換一個"
                    withAnimation { showNameError = true }
                    return
                }
                showNameError = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                userStore.displayName = trimmed
                userStore.gender = selectedGender
                userStore.ageRange = ageRange
                userStore.bio = bio
                userStore.ntrpLevel = ntrpLevel
                userStore.region = region
                userStore.selectedCourts = selectedCourts
                userStore.partnerLevelLow = partnerLevelLow
                userStore.partnerLevelHigh = partnerLevelHigh
                userStore.preferredSlots = preferredSlots
                userStore.avatarImageData = avatarData
                dismiss()
            } label: {
                Text("儲存修改")
                    .font(Typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: - Helpers

    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(Typography.bodyMedium)
                .foregroundColor(Theme.textPrimary)
                .frame(width: 110, alignment: .leading)
            content()
        }
        .frame(minHeight: 44)
    }

    private var formDivider: some View {
        Theme.divider.frame(height: 1)
    }

    private func radioButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.primary : Theme.border, lineWidth: isSelected ? 2 : 1.5)
                        .frame(width: 16, height: 16)
                    if isSelected {
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(label)
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textBody)
            }
        }
    }

    // MARK: - NTRP Single Slider

    private var ntrpSliderSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("NTRP 水平")
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(String(format: "%.1f", ntrpLevel))
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.primary)
            }

            HStack(spacing: Spacing.sm) {
                Text(String(format: "%.1f", ntrpMin))
                    .font(Typography.captionMedium)
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 28)

                GeometryReader { geo in
                    let width = geo.size.width
                    let range = ntrpMax - ntrpMin
                    let thumbX = (ntrpLevel - ntrpMin) / range * width

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.inputBorder)
                            .frame(height: 4)

                        Capsule()
                            .fill(Theme.primary)
                            .frame(width: max(0, thumbX), height: 4)

                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                            .overlay {
                                Circle()
                                    .fill(Theme.primary)
                                    .frame(width: 10, height: 10)
                            }
                            .position(x: thumbX, y: geo.size.height / 2)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let raw = value.location.x / width * range + ntrpMin
                                        let snapped = (raw * 2).rounded() / 2
                                        ntrpLevel = min(max(snapped, ntrpMin), ntrpMax)
                                    }
                            )
                    }
                }
                .frame(height: 28)

                Text(String(format: "%.1f", ntrpMax))
                    .font(Typography.captionMedium)
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 28)
            }
        }
        .frame(minHeight: 44)
    }

    // MARK: - Partner Level Dual Slider

    private var partnerLevelSliderSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("偏好球友水平")
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(String(format: "%.1f - %.1f", partnerLevelLow, partnerLevelHigh))
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.primary)
            }

            NTRPRangeSlider(low: $partnerLevelLow, high: $partnerLevelHigh, range: ntrpMin...ntrpMax)
        }
        .frame(minHeight: 44)
    }
}

// MARK: - Preferred Time Slot

struct PreferredTimeSlot: Identifiable {
    let id = UUID()
    let day: PreferredDay
    let startTime: String
    let endTime: String

    var displayText: String {
        "每\(day.label)  \(startTime) - \(endTime)"
    }
}

enum PreferredDay: Int, CaseIterable, Identifiable {
    case mon = 1, tue, wed, thu, fri, sat, sun

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .mon: return "週一"
        case .tue: return "週二"
        case .wed: return "週三"
        case .thu: return "週四"
        case .fri: return "週五"
        case .sat: return "週六"
        case .sun: return "週日"
        }
    }

    var short: String {
        switch self {
        case .mon: return "一"
        case .tue: return "二"
        case .wed: return "三"
        case .thu: return "四"
        case .fri: return "五"
        case .sat: return "六"
        case .sun: return "日"
        }
    }
}

// MARK: - Add Slot Sheet

private struct AddPreferredSlotSheet: View {
    let onAdd: (PreferredTimeSlot) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDay: PreferredDay = .sat
    @State private var startTime = "09:00"
    @State private var endTime = "10:30"

    private let timeSlots: [String] = {
        var slots: [String] = []
        for hour in 6...23 {
            slots.append(String(format: "%02d:00", hour))
            slots.append(String(format: "%02d:30", hour))
        }
        return slots
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("新增偏好時段")
                .font(Typography.body)
                .foregroundColor(Theme.textPrimary)

            // Day selection
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("星期")
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 6) {
                    ForEach(PreferredDay.allCases) { day in
                        let isSelected = selectedDay == day
                        Button { selectedDay = day } label: {
                            Text(day.short)
                                .font(Typography.captionMedium)
                                .foregroundColor(isSelected ? .white : Theme.textBody)
                                .frame(width: 38, height: 38)
                                .background(isSelected ? Theme.primary : Theme.inputBg)
                                .clipShape(Circle())
                        }
                    }
                }
            }

            // Time pickers (30-min intervals)
            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("開始")
                        .font(Typography.bodyMedium)
                        .foregroundColor(Theme.textPrimary)
                    Picker("", selection: $startTime) {
                        ForEach(timeSlots, id: \.self) { slot in
                            Text(slot).tag(slot)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.primary)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("結束")
                        .font(Typography.bodyMedium)
                        .foregroundColor(Theme.textPrimary)
                    Picker("", selection: $endTime) {
                        ForEach(endTimeSlots, id: \.self) { slot in
                            Text(slot).tag(slot)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.primary)
                }
                Spacer()
            }
            .onChange(of: startTime) { _, newStart in
                if endTime <= newStart {
                    if let idx = timeSlots.firstIndex(of: newStart), idx + 1 < timeSlots.count {
                        endTime = timeSlots[idx + 1]
                    }
                }
            }

            // Preview
            let preview = buildSlot()
            HStack(spacing: Spacing.xs) {
                Image(systemName: "clock")
                    .font(Typography.caption)
                    .foregroundColor(Theme.primary)
                Text(preview.displayText)
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.primary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Theme.primaryLight)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Spacer()

            // Buttons
            HStack(spacing: Spacing.sm) {
                Button {
                    dismiss()
                } label: {
                    Text("取消")
                        .font(Typography.bodyMedium)
                        .foregroundColor(Theme.textBody)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Theme.inputBorder, lineWidth: 1)
                        )
                }

                Button {
                    onAdd(buildSlot())
                    dismiss()
                } label: {
                    Text("新增")
                        .font(Typography.labelSemibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(Spacing.lg)
    }

    /// 結束時間只顯示開始時間之後的選項
    private var endTimeSlots: [String] {
        guard let startIdx = timeSlots.firstIndex(of: startTime) else { return timeSlots }
        return Array(timeSlots.suffix(from: timeSlots.index(after: startIdx)))
    }

    private func buildSlot() -> PreferredTimeSlot {
        PreferredTimeSlot(
            day: selectedDay,
            startTime: startTime,
            endTime: endTime
        )
    }
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        EditProfileView()
    }
    .environment(UserStore())
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        EditProfileView()
    }
    .environment(UserStore())
}
