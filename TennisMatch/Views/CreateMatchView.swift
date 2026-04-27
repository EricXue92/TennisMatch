//
//  CreateMatchView.swift
//  TennisMatch
//
//  創建約球頁面 — 填寫比賽資訊後發布約球
//

import SwiftUI

// MARK: - Published Match Data

struct PublishedMatchInfo {
    let matchType: String
    let date: Date
    let startTime: String
    let endTime: String
    let courtName: String
    let ntrpLow: Double
    let ntrpHigh: Double
    let gender: String
    let costType: String
    let costAmount: String
    let notes: String
    /// 发起人是否要求审核报名者。
    let requiresApproval: Bool
    /// 自动接受截止时间。`requiresApproval == false` 或 lead time 太短 → nil。
    let approvalDeadline: Date?
}

struct CreateMatchView: View {
    @Environment(\.dismiss) private var dismiss
    var onPublish: ((PublishedMatchInfo) -> Void)?

    // MARK: - Form State

    @State private var showConfirmation = false

    @State private var matchType: String = "單打"
    @State private var selectedDate = Date()
    @State private var selectedStartTime = "09:00"
    @State private var selectedEndTime = "10:00"
    @State private var showDatePicker = false
    @State private var selectedCourt: TennisCourt?
    @State private var showCourtPicker = false
    @State private var ntrpLow: Double = 2.5
    @State private var ntrpHigh: Double = 4.5
    private let ntrpMin: Double = 1.0
    private let ntrpMax: Double = 7.0
    @State private var genderRequirement: String = "不限"
    @State private var costType: String = "AA制"
    @State private var costAmount: String = ""
    @State private var notes: String = ""
    @State private var validationToast: String?

    // MARK: - Court picker bridge
    @State private var courtPickerSelection: Set<TennisCourt> = []

    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            navBar

            ScrollView {
                VStack(spacing: 0) {
                    // Form card
                    formCard
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)

                    // Submit button
                    submitButton
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                }
            }
        }
        .background(Theme.background)
        .toast($validationToast, icon: "exclamationmark.circle.fill")
        .navigationBarHidden(true)
        .sheet(isPresented: $showCourtPicker) {
            CourtPickerView(selected: $courtPickerSelection, singleSelect: true)
                .onDisappear {
                    if let court = courtPickerSelection.first {
                        selectedCourt = court
                    }
                }
        }
        .sheet(isPresented: $showConfirmation) {
            confirmationSheet
                .presentationDetents([.medium])
        }
    }

    // MARK: - Navigation Bar

    private var navBar: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(Typography.sectionTitle)
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 44, height: 44)
            }

            Text("創建約球")
                .font(Typography.sectionTitle)
                .foregroundColor(Theme.textPrimary)

            Spacer()
        }
        .padding(.horizontal, Spacing.xs)
        .background(Theme.surface)
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            matchTypeSection
            sectionDivider
            dateTimeSection
            sectionDivider
            courtSection
            sectionDivider
            levelSection
            sectionDivider
            genderSection
            sectionDivider
            costSection
            sectionDivider
            notesSection
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }

    // MARK: - Divider

    private var sectionDivider: some View {
        Theme.divider
            .frame(height: 1)
            .padding(.vertical, Spacing.sm)
    }

    // MARK: - Match Type

    private var matchTypeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("比賽類型")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Spacing.lg) {
                radioButton(label: "單打", isSelected: matchType == "單打") {
                    matchType = "單打"
                }
                radioButton(label: "雙打", isSelected: matchType == "雙打") {
                    matchType = "雙打"
                }
                radioButton(label: "拉球", isSelected: matchType == "拉球") {
                    matchType = "拉球"
                }
            }
        }
    }

    // MARK: - Date & Time

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("日期與時間")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)

            datePillRow

            if showDatePicker {
                wheelDatePicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            timeRangeRow

            if let picker = activeTimePicker {
                wheelTimePicker(for: picker)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showDatePicker)
        .animation(.easeInOut(duration: 0.2), value: activeTimePicker)
    }

    // MARK: - Date · 滚轮选择

    private var datePillRow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showDatePicker.toggle()
                if showDatePicker { activeTimePicker = nil }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(showDatePicker ? Theme.primary : Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("日期")
                        .font(Typography.micro)
                        .foregroundColor(showDatePicker ? Theme.primary : Theme.textSecondary)
                    Text(dateWasEdited ? dateFormatted : "選擇日期")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundColor(dateWasEdited ? Theme.textPrimary : Theme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(showDatePicker ? Theme.chipSelectedBg : Theme.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(showDatePicker ? Theme.primary : Theme.border,
                            lineWidth: showDatePicker ? 1.5 : 1)
            )
        }
    }

    private var wheelDatePicker: some View {
        VStack(spacing: Spacing.sm) {
            DatePicker(
                "",
                selection: Binding(
                    get: { selectedDate },
                    set: { newValue in
                        selectedDate = newValue
                        dateWasEdited = true
                    }
                ),
                in: Calendar.current.startOfDay(for: .now)...,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .frame(height: 160)

            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showDatePicker = false }
                } label: {
                    Text("完成")
                        .font(Typography.buttonMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 36)
                        .background(Theme.primary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Spacing.sm)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.divider, lineWidth: 1)
        )
    }

    // MARK: - Time · 双 pill + 时长徽章

    private var timeRangeRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                timePill(label: "開始", value: startTimeEdited ? selectedStartTime : "—:—",
                         active: activeTimePicker == .start, edited: startTimeEdited) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeTimePicker = activeTimePicker == .start ? nil : .start
                        showDatePicker = false
                    }
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)

                timePill(label: "結束", value: endTimeEdited ? selectedEndTime : "—:—",
                         active: activeTimePicker == .end, edited: endTimeEdited) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeTimePicker = activeTimePicker == .end ? nil : .end
                        showDatePicker = false
                    }
                }
            }

            if let label = durationLabel {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 11, weight: .medium))
                    Text(label)
                        .font(Typography.smallMedium)
                }
                .foregroundColor(Theme.primary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
                .background(Theme.chipSelectedBg)
                .clipShape(Capsule())
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: durationLabel)
    }

    private func timePill(label: String, value: String, active: Bool, edited: Bool,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Typography.micro)
                    .foregroundColor(active ? Theme.primary : Theme.textSecondary)
                Text(value)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundColor(edited ? Theme.textPrimary : Theme.textSecondary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(active ? Theme.chipSelectedBg : Theme.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(active ? Theme.primary : Theme.border, lineWidth: active ? 1.5 : 1)
            )
        }
    }

    // MARK: - 滚轮时间选择器

    private func wheelTimePicker(for which: TimePickerKind) -> some View {
        let isStart = which == .start
        let slots: [String] = isStart
            ? timeSlots.filter { !isSlotPast($0) }
            : timeSlots.filter { $0 > selectedStartTime }
        let currentValue = isStart ? selectedStartTime : selectedEndTime
        let binding = Binding<String>(
            get: { slots.contains(currentValue) ? currentValue : (slots.first ?? currentValue) },
            set: { newValue in
                if isStart {
                    selectedStartTime = newValue
                    startTimeEdited = true
                    if let bumped = bumpedEndIfNeeded(after: newValue) {
                        selectedEndTime = bumped
                        endTimeEdited = true
                    }
                } else {
                    selectedEndTime = newValue
                    endTimeEdited = true
                }
            }
        )

        return VStack(spacing: Spacing.sm) {
            Picker("", selection: binding) {
                ForEach(slots, id: \.self) { slot in
                    Text(slot)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .monospacedDigit()
                        .tag(slot)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .frame(height: 160)

            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { activeTimePicker = nil }
                } label: {
                    Text("完成")
                        .font(Typography.buttonMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 36)
                        .background(Theme.primary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Spacing.sm)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.divider, lineWidth: 1)
        )
    }

    private func isSlotPast(_ slot: String) -> Bool {
        let p = parseTime(slot)
        return isMinutePast(hour: p.hour, minute: p.minute)
    }

    // MARK: - Time helpers

    private enum TimePickerKind { case start, end }
    @State private var activeTimePicker: TimePickerKind?

    private func parseTime(_ s: String) -> (hour: Int, minute: Int) {
        let parts = s.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return (10, 0) }
        return (h, m)
    }

    private func formatTime(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    private func bumpedEndIfNeeded(after start: String) -> String? {
        guard let startIdx = timeSlots.firstIndex(of: start),
              startIdx + 1 < timeSlots.count else { return nil }
        if !endTimeEdited || selectedEndTime <= start {
            return timeSlots[min(startIdx + 2, timeSlots.count - 1)] // 默认 +1h
        }
        return nil
    }

    private var selectedIsToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    /// 選的是「今天」時,該 hour:minute 是否已經過去。
    private func isMinutePast(hour: Int, minute: Int) -> Bool {
        guard selectedIsToday else { return false }
        let cal = Calendar.current
        let now = Date()
        let nowHour = cal.component(.hour, from: now)
        let nowMinute = cal.component(.minute, from: now)
        if hour < nowHour { return true }
        if hour > nowHour { return false }
        return minute <= nowMinute
    }

    private var durationLabel: String? {
        guard startTimeEdited, endTimeEdited,
              let s = timeSlots.firstIndex(of: selectedStartTime),
              let e = timeSlots.firstIndex(of: selectedEndTime),
              e > s else { return nil }
        let halves = e - s
        let hours = Double(halves) / 2
        if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return "時長 \(Int(hours)) 小時"
        }
        return "時長 \(hours.formatted(.number.precision(.fractionLength(1)))) 小時"
    }

    @State private var dateWasEdited = false
    @State private var startTimeEdited = false
    @State private var endTimeEdited = false

    private var dateFormatted: String {
        if !dateWasEdited { return "選擇日期" }
        return AppDateFormatter.monthDay.string(from: selectedDate)
    }

    private let timeSlots: [String] = {
        var slots: [String] = []
        for hour in 6...23 {
            slots.append(String(format: "%02d:00", hour))
            slots.append(String(format: "%02d:30", hour))
        }
        return slots
    }()

    private var endTimeSlots: [String] {
        guard let startIdx = timeSlots.firstIndex(of: selectedStartTime) else { return timeSlots }
        return Array(timeSlots.suffix(from: timeSlots.index(after: startIdx)))
    }

    // MARK: - Court

    private var courtSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("球場")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)

            Button {
                courtPickerSelection = selectedCourt.map { Set([$0]) } ?? []
                showCourtPicker = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text("📍")
                        .font(Typography.bodyMedium)
                    Text(selectedCourt?.name ?? "選擇球場...")
                        .font(Typography.caption)
                        .foregroundColor(selectedCourt != nil ? Theme.textPrimary : Theme.textSecondary)
                    Spacer()
                }
                .frame(height: 44)
                .padding(.horizontal, Spacing.sm)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Level (NTRP Range Slider)

    private var levelSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("NTRP要求")
                    .font(Typography.labelSemibold)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(String(format: "%.1f - %.1f", ntrpLow, ntrpHigh))
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.primary)
            }

            NTRPRangeSlider(low: $ntrpLow, high: $ntrpHigh, range: ntrpMin...ntrpMax)
        }
    }

    // MARK: - Gender

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("性別要求")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Spacing.lg) {
                radioButton(label: "不限", isSelected: genderRequirement == "不限") {
                    genderRequirement = "不限"
                }
                radioButton(label: "僅限男性", isSelected: genderRequirement == "僅限男性") {
                    genderRequirement = "僅限男性"
                }
                radioButton(label: "僅限女性", isSelected: genderRequirement == "僅限女性") {
                    genderRequirement = "僅限女性"
                }
            }
        }
    }

    // MARK: - Cost

    private var costSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("費用分攤")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Spacing.lg) {
                radioButton(label: "AA制", isSelected: costType == "AA制") {
                    costType = "AA制"
                }
                radioButton(label: "免費", isSelected: costType == "免費") {
                    costType = "免費"
                }
            }

            if costType == "AA制" {
                TextField("費用金額 (港幣)", text: $costAmount)
                    .font(Typography.caption)
                    .foregroundColor(Theme.textPrimary)
                    .keyboardType(.numberPad)
                    .frame(height: 44)
                    .padding(.horizontal, Spacing.sm)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
            }

        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("備註")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)

            TextField("例如：自帶球、需要教練等", text: $notes)
                .font(Typography.caption)
                .foregroundColor(Theme.textPrimary)
                .frame(height: 44)
                .padding(.horizontal, Spacing.sm)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            // 必填項校驗 — 失败统一通过顶部 toast 反饋
            if !dateWasEdited {
                validationToast = "請選擇日期"
                return
            } else if !startTimeEdited || !endTimeEdited {
                validationToast = "請選擇開始和結束時間"
                return
            } else if selectedCourt == nil {
                validationToast = "請選擇球場"
                return
            } else if costType == "AA制" && (costAmount.isEmpty || Int(costAmount) ?? 0 <= 0) {
                validationToast = "請輸入有效的費用金額"
                return
            }
            showConfirmation = true
        } label: {
            Text("發布約球")
                .font(Typography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    // MARK: - Radio Button Component

    private func radioButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
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
                    .foregroundColor(Theme.textDark)
            }
            .frame(minHeight: 44)
        }
    }
    // MARK: - Confirmation Sheet

    private var confirmationSheet: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("確認約球資訊")
                .font(Typography.largeStat)
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                confirmRow(icon: "figure.tennis", text: matchType)
                confirmRow(icon: "calendar", text: confirmDateText)
                confirmRow(icon: "mappin.circle.fill", text: selectedCourt?.name ?? "未選擇")
                confirmRow(icon: "star.fill", text: "NTRP \(String(format: "%.1f - %.1f", ntrpLow, ntrpHigh))")
                confirmRow(icon: "person.2.fill", text: genderRequirement)
                confirmRow(icon: "dollarsign.circle.fill", text: costType == "免費" ? "免費" : "AA HK$\(costAmount)")
                if !notes.isEmpty {
                    confirmRow(icon: "note.text", text: notes)
                }
            }

            Spacer()

            HStack(spacing: Spacing.sm) {
                Button {
                    showConfirmation = false
                } label: {
                    Text("返回修改")
                        .font(Typography.bodyMedium)
                        .foregroundColor(Theme.textBody)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                }

                Button {
                    publishMatch()
                } label: {
                    Text("確認發布")
                        .font(Typography.labelSemibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }

    private func confirmRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(Typography.bodyMedium)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 20)
            Text(text)
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textPrimary)
        }
    }

    private var confirmDateText: String {
        let dateStr = dateWasEdited ? AppDateFormatter.monthDay.string(from: selectedDate) : "未選擇"
        let startStr = startTimeEdited ? selectedStartTime : "--:--"
        let endStr = endTimeEdited ? selectedEndTime : "--:--"
        return "\(dateStr)  \(startStr) ~ \(endStr)"
    }

    private func publishMatch() {
        let info = PublishedMatchInfo(
            matchType: matchType,
            date: selectedDate,
            startTime: selectedStartTime,
            endTime: selectedEndTime,
            courtName: selectedCourt?.name ?? "未指定",
            ntrpLow: ntrpLow,
            ntrpHigh: ntrpHigh,
            gender: genderRequirement,
            costType: costType,
            costAmount: costAmount,
            notes: notes,
            requiresApproval: false,
            approvalDeadline: nil
        )
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showConfirmation = false
        onPublish?(info)
        dismiss()
    }
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        CreateMatchView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        CreateMatchView()
    }
}
