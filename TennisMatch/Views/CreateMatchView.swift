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
    @State private var showStartTimePicker = false
    @State private var showEndTimePicker = false
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
    @State private var showCostError = false

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
        .navigationBarHidden(true)
        .sheet(isPresented: $showCourtPicker) {
            CourtPickerView(selected: $courtPickerSelection)
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
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 44, height: 44)
            }

            Text("創建約球")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Spacer()
        }
        .padding(.horizontal, Spacing.xs)
        .background(.white)
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
        .background(.white)
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
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Spacing.lg) {
                radioButton(label: "單打", isSelected: matchType == "單打") {
                    matchType = "單打"
                }
                radioButton(label: "雙打", isSelected: matchType == "雙打") {
                    matchType = "雙打"
                }
            }
        }
    }

    // MARK: - Date & Time

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("日期與時間")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            // Date
            Button {
                showDatePicker.toggle()
                showStartTimePicker = false
                showEndTimePicker = false
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textPrimary)
                    Text(dateFormatted)
                        .font(.system(size: 13))
                        .foregroundColor(dateWasEdited ? Theme.textPrimary : Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 44)
                .padding(.horizontal, Spacing.sm)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }

            if showDatePicker {
                DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Theme.primary)
                    .onChange(of: selectedDate) { _, _ in
                        dateWasEdited = true
                        showDatePicker = false
                    }
            }

            // Time range
            HStack(spacing: Spacing.sm) {
                Button {
                    showStartTimePicker.toggle()
                    showEndTimePicker = false
                    showDatePicker = false
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textPrimary)
                        Text(startTimeEdited ? selectedStartTime : "開始時間")
                            .font(.system(size: 13))
                            .foregroundColor(startTimeEdited ? Theme.textPrimary : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 44)
                    .padding(.horizontal, Spacing.sm)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                }

                Text("~")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)

                Button {
                    showEndTimePicker.toggle()
                    showStartTimePicker = false
                    showDatePicker = false
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textPrimary)
                        Text(endTimeEdited ? selectedEndTime : "結束時間")
                            .font(.system(size: 13))
                            .foregroundColor(endTimeEdited ? Theme.textPrimary : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 44)
                    .padding(.horizontal, Spacing.sm)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                }
            }

            if showStartTimePicker {
                Picker("", selection: $selectedStartTime) {
                    ForEach(timeSlots, id: \.self) { slot in
                        Text(slot).tag(slot)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .onChange(of: selectedStartTime) { _, newValue in
                    startTimeEdited = true
                    if selectedEndTime <= newValue {
                        if let idx = timeSlots.firstIndex(of: newValue), idx + 1 < timeSlots.count {
                            selectedEndTime = timeSlots[idx + 1]
                            endTimeEdited = true
                        }
                    }
                    let dismissId = UUID()
                    startTimeDismissId = dismissId
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if startTimeDismissId == dismissId {
                            showStartTimePicker = false
                        }
                    }
                }
            }

            if showEndTimePicker {
                Picker("", selection: $selectedEndTime) {
                    ForEach(endTimeSlots, id: \.self) { slot in
                        Text(slot).tag(slot)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .onChange(of: selectedEndTime) { _, _ in
                    endTimeEdited = true
                    let dismissId = UUID()
                    endTimeDismissId = dismissId
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if endTimeDismissId == dismissId {
                            showEndTimePicker = false
                        }
                    }
                }
            }
        }
    }

    @State private var dateWasEdited = false
    @State private var startTimeEdited = false
    @State private var endTimeEdited = false
    @State private var startTimeDismissId = UUID()
    @State private var endTimeDismissId = UUID()

    private var dateFormatted: String {
        if !dateWasEdited { return "選擇日期" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: selectedDate)
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
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Button {
                courtPickerSelection = selectedCourt.map { Set([$0]) } ?? []
                showCourtPicker = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text("📍")
                        .font(.system(size: 14))
                    Text(selectedCourt?.name ?? "選擇球場...")
                        .font(.system(size: 13))
                        .foregroundColor(selectedCourt != nil ? Theme.textPrimary : Theme.textSecondary)
                    Spacer()
                }
                .frame(height: 44)
                .padding(.horizontal, Spacing.sm)
                .background(.white)
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(String(format: "%.1f - %.1f", ntrpLow, ntrpHigh))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.primary)
            }

            HStack(spacing: Spacing.sm) {
                Text(String(format: "%.1f", ntrpMin))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 28)

                GeometryReader { geo in
                    let width = geo.size.width
                    let range = ntrpMax - ntrpMin
                    let lowX = (ntrpLow - ntrpMin) / range * width
                    let highX = (ntrpHigh - ntrpMin) / range * width

                    ZStack(alignment: .leading) {
                        // Track background
                        Capsule()
                            .fill(Theme.inputBorder)
                            .frame(height: 4)

                        // Active range
                        Capsule()
                            .fill(Theme.primary)
                            .frame(width: max(0, highX - lowX), height: 4)
                            .offset(x: lowX)

                        // Low thumb
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                            .overlay {
                                Circle()
                                    .fill(Theme.primary)
                                    .frame(width: 10, height: 10)
                            }
                            .position(x: lowX, y: geo.size.height / 2)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let raw = value.location.x / width * range + ntrpMin
                                        let snapped = (raw * 2).rounded() / 2
                                        ntrpLow = min(max(snapped, ntrpMin), ntrpHigh)
                                    }
                            )

                        // High thumb
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                            .overlay {
                                Circle()
                                    .fill(Theme.primary)
                                    .frame(width: 10, height: 10)
                            }
                            .position(x: highX, y: geo.size.height / 2)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let raw = value.location.x / width * range + ntrpMin
                                        let snapped = (raw * 2).rounded() / 2
                                        ntrpHigh = max(min(snapped, ntrpMax), ntrpLow)
                                    }
                            )
                    }
                }
                .frame(height: 28)

                Text(String(format: "%.1f", ntrpMax))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 28)
            }
        }
    }

    // MARK: - Gender

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("性別要求")
                .font(.system(size: 14, weight: .semibold))
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
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Spacing.lg) {
                radioButton(label: "AA制", isSelected: costType == "AA制") {
                    costType = "AA制"
                }
                radioButton(label: "免費", isSelected: costType == "免費") {
                    costType = "免費"
                    showCostError = false
                }
            }

            if costType == "AA制" {
                TextField("費用金額 (港幣)", text: $costAmount)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textPrimary)
                    .keyboardType(.numberPad)
                    .frame(height: 44)
                    .padding(.horizontal, Spacing.sm)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
            }
            if showCostError && costType == "AA制" {
                Text("請填寫費用金額")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.requiredText)
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("備註")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            TextField("例如：自帶球、需要教練等", text: $notes)
                .font(.system(size: 13))
                .foregroundColor(Theme.textPrimary)
                .frame(height: 44)
                .padding(.horizontal, Spacing.sm)
                .background(.white)
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
            if costType == "AA制" && (costAmount.isEmpty || Int(costAmount) ?? 0 <= 0) {
                showCostError = true
                return
            }
            showCostError = false
            showConfirmation = true
        } label: {
            Text("發布約球")
                .font(.system(size: 16, weight: .semibold))
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
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textDark)
            }
            .frame(minHeight: 44)
        }
    }
    // MARK: - Confirmation Sheet

    private var confirmationSheet: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("確認約球資訊")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                confirmRow(icon: "figure.tennis", text: matchType)
                confirmRow(icon: "calendar", text: confirmDateText)
                confirmRow(icon: "mappin.circle.fill", text: selectedCourt?.name ?? "未選擇")
                confirmRow(icon: "star.fill", text: "NTRP \(String(format: "%.1f - %.1f", ntrpLow, ntrpHigh))")
                confirmRow(icon: "person.2.fill", text: genderRequirement)
                confirmRow(icon: "dollarsign.circle.fill", text: costType == "免費" ? "免費" : "AA ¥\(costAmount)")
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
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textBody)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(.white)
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
                        .font(.system(size: 15, weight: .semibold))
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
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Theme.textPrimary)
        }
    }

    private var confirmDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let dateStr = dateWasEdited ? formatter.string(from: selectedDate) : "未選擇"
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
            notes: notes
        )
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
