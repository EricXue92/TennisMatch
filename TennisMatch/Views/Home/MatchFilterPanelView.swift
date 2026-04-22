//
//  MatchFilterPanelView.swift
//  TennisMatch
//
//  篩選面板 — 從 HomeView 提取的獨立組件
//

import SwiftUI

struct MatchFilterPanelView: View {
    @Binding var ntrpLow: Double
    @Binding var ntrpHigh: Double
    @Binding var selectedAgeRange: Set<String>
    @Binding var selectedGender: String
    @Binding var selectedCourts: Set<TennisCourt>
    @Binding var selectedDays: Set<String>
    @Binding var timeFrom: Double
    @Binding var timeTo: Double
    var onDismiss: () -> Void

    @State private var showCourtPicker = false

    // MARK: - Constants

    static let ageOptions = ["14-17", "18-25", "26-35", "36-45", "46-55", "55+"]
    static let genderOptions = ["男", "女", "不限"]
    static let dayOptions = ["一", "二", "三", "四", "五", "六", "日"]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ntpRangeRow
            filterRow(title: "年齡", options: Self.ageOptions, selection: $selectedAgeRange)
            genderFilterRow
            courtFilterRow
            timeFilterRow

            HStack(spacing: Spacing.sm) {
                Button {
                    ntrpLow = 1.0
                    ntrpHigh = 7.0
                    selectedAgeRange.removeAll()
                    selectedGender = ""
                    selectedCourts.removeAll()
                    selectedDays.removeAll()
                    timeFrom = 7.0
                    timeTo = 23.0
                } label: {
                    Text("重置")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textBody)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.inputBorder, lineWidth: 1)
                        }
                }

                Button {
                    onDismiss()
                } label: {
                    Text("確認")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(Spacing.md)
        .background(.white)
    }
}

// MARK: - Filter Rows

private extension MatchFilterPanelView {
    var genderFilterRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("性別")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Spacing.xs) {
                ForEach(Self.genderOptions, id: \.self) { option in
                    let isSelected = selectedGender == option
                    Button {
                        selectedGender = isSelected ? "" : option
                    } label: {
                        Text(option)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSelected ? .white : Theme.textBody)
                            .padding(.horizontal, Spacing.sm)
                            .frame(height: 28)
                            .background(isSelected ? Theme.primary : Theme.inputBg)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
        }
    }

    var timeFilterRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("時間")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            // Day of week selection
            HStack(spacing: 4) {
                ForEach(Self.dayOptions, id: \.self) { day in
                    let isSelected = selectedDays.contains(day)
                    Button {
                        if isSelected {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    } label: {
                        Text(day)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSelected ? .white : Theme.textBody)
                            .frame(width: 36, height: 36)
                            .background(isSelected ? Theme.primary : Theme.inputBg)
                            .clipShape(Circle())
                    }
                }
            }

            // Time range pickers
            HStack(spacing: Spacing.sm) {
                Text("從")
                    .font(Typography.small)
                    .foregroundColor(Theme.textCaption)
                Picker("", selection: $timeFrom) {
                    ForEach(timeSlots, id: \.self) { slot in
                        Text(formatTimeSlot(slot)).tag(slot)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.primary)
                .fixedSize()
                .accessibilityLabel("開始時間")

                Text("到")
                    .font(Typography.small)
                    .foregroundColor(Theme.textCaption)
                Picker("", selection: $timeTo) {
                    ForEach(timeSlots.filter { $0 >= timeFrom }, id: \.self) { slot in
                        Text(formatTimeSlot(slot)).tag(slot)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.primary)
                .fixedSize()
                .accessibilityLabel("結束時間")

                Spacer()
            }
        }
    }

    var timeSlots: [Double] {
        stride(from: 7.0, through: 23.0, by: 0.5).map { $0 }
    }

    func formatTimeSlot(_ slot: Double) -> String {
        let hour = Int(slot)
        let minute = slot.truncatingRemainder(dividingBy: 1) == 0.5 ? 30 : 0
        return String(format: "%02d:%02d", hour, minute)
    }

    var courtFilterRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("球場")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                    showCourtPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCourts.isEmpty ? "選擇球場" : "已選 \(selectedCourts.count) 個")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(Theme.primary)
                }
            }

            if !selectedCourts.isEmpty {
                let columns = [GridItem(.adaptive(minimum: 90), spacing: Spacing.xs)]
                LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.xs) {
                    ForEach(Array(selectedCourts).sorted { $0.name < $1.name }) { court in
                        HStack(spacing: 4) {
                            Text(court.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.primary)
                                .lineLimit(1)
                            Button {
                                selectedCourts.remove(court)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Theme.textCaption)
                            }
                        }
                        .padding(.horizontal, Spacing.sm)
                        .frame(height: 28)
                        .background(Theme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
        }
        .sheet(isPresented: $showCourtPicker) {
            CourtPickerView(selected: $selectedCourts)
        }
    }

    var ntpRangeRow: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("NTRP")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(ntrpRangeLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.primary)
            }

            NTRPRangeSlider(low: $ntrpLow, high: $ntrpHigh)
        }
    }

    var ntrpRangeLabel: String {
        if ntrpLow == 1.0 && ntrpHigh == 7.0 {
            return "不限"
        }
        return String(format: "%.1f - %.1f", ntrpLow, ntrpHigh)
    }

    func filterRow(title: String, options: [String], selection: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            // Use LazyVGrid for wrapping layout
            let columns = [GridItem(.adaptive(minimum: 70), spacing: Spacing.xs)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.xs) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selection.wrappedValue.contains(option)
                    Button {
                        if isSelected {
                            selection.wrappedValue.remove(option)
                        } else {
                            selection.wrappedValue.insert(option)
                        }
                    } label: {
                        Text(option)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSelected ? .white : Theme.textBody)
                            .padding(.horizontal, Spacing.sm)
                            .frame(height: 28)
                            .background(isSelected ? Theme.primary : Theme.inputBg)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
        }
    }
}
