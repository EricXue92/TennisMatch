//
//  CreateTournamentView.swift
//  TennisMatch
//
//  創建賽事頁面 — 填寫賽事資訊後發布
//

import SwiftUI

struct PublishedTournamentInfo {
    let name: String
    let matchType: String
    let participantCount: String
    let format: String
    let startDate: Date
    let endDate: Date
    let courtName: String
    let level: String
    let fee: String
    let rules: String
}

struct CreateTournamentView: View {
    @Environment(\.dismiss) private var dismiss
    var onPublish: ((PublishedTournamentInfo) -> Void)?

    // MARK: - Form State

    @State private var showConfirmation = false
    @State private var tournamentName = ""
    @State private var matchType = "單打"
    @State private var participantCount = ""
    @State private var selectedFormat = "分組+淘汰"
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var startDateEdited = false
    @State private var endDateEdited = false
    @State private var selectedCourt: TennisCourt?
    @State private var showCourtPicker = false
    @State private var courtPickerSelection: Set<TennisCourt> = []
    @State private var selectedLevel = "3.0 - 4.5"
    @State private var fee = ""
    @State private var rules = ""

    var body: some View {
        VStack(spacing: 0) {
            navBar

            ScrollView {
                VStack(spacing: 0) {
                    formCard
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)

                    submitButton
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                }
            }
        }
        .background(Theme.tournamentBg)
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
}

// MARK: - Navigation Bar

private extension CreateTournamentView {
    var navBar: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 44, height: 44)
            }

            Text("創建賽事")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Spacer()
        }
        .padding(.horizontal, Spacing.xs)
        .background(.white)
    }
}

// MARK: - Form Card

private extension CreateTournamentView {
    var formCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            nameSection
            sectionDivider
            matchTypeSection
            sectionDivider
            participantSection
            sectionDivider
            formatSection
            sectionDivider
            dateSection
            sectionDivider
            venueSection
            sectionDivider
            levelAndFeeSection
            sectionDivider
            rulesSection
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    var sectionDivider: some View {
        Theme.inputBorder
            .frame(height: 1)
            .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Form Sections

private extension CreateTournamentView {

    // 賽事名稱
    var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionTitle("賽事名稱")

            TextField("例如：香港春季網球公開賽", text: $tournamentName)
                .font(.system(size: 13))
                .foregroundColor(Theme.textDark)
                .frame(height: 34)
                .padding(.horizontal, Spacing.sm)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.inputBorder, lineWidth: 1)
                )
        }
    }

    // 比賽類型
    var matchTypeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionTitle("比賽類型")

            HStack(spacing: Spacing.xl) {
                radioButton(label: "單打", isSelected: matchType == "單打") {
                    matchType = "單打"
                }
                radioButton(label: "雙打", isSelected: matchType == "雙打") {
                    matchType = "雙打"
                }
            }
        }
    }

    // 預計參賽人數
    var participantSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionTitle("預計參賽人數")

            ZStack(alignment: .trailing) {
                TextField("", text: $participantCount)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textDark)
                    .keyboardType(.numberPad)
                    .frame(height: 34)
                    .padding(.horizontal, Spacing.sm)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
                    .onChange(of: participantCount) { _, _ in
                        let formats = recommendedFormats
                        if !formats.isEmpty && !formats.contains(selectedFormat) {
                            let ordered = ["單循環賽", "分組+淘汰", "單敗淘汰", "瑞士輪"]
                            if let first = ordered.first(where: { formats.contains($0) }) {
                                selectedFormat = first
                            }
                        }
                    }

                Text("人")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textHint)
                    .padding(.trailing, Spacing.sm)
            }

            if !participantCount.isEmpty && !recommendedFormats.isEmpty {
                Text("💡 根據人數，推薦「\(recommendedFormatText)」")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.accentGreen)
            }
        }
    }

    // 賽制選擇
    var formatSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionTitle("賽制選擇")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm)
            ], spacing: Spacing.xs) {
                ForEach(formatOptions) { format in
                    formatCard(format)
                }
            }
        }
    }

    // 比賽日期
    var dateSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionTitle("比賽日期")

            HStack(spacing: Spacing.sm) {
                Button {
                    showStartDatePicker.toggle()
                    showEndDatePicker = false
                } label: {
                    HStack(spacing: 6) {
                        Text("📅")
                            .font(.system(size: 13))
                        Text(startDateEdited ? formattedDate(startDate) : "開始日期")
                            .font(.system(size: 13))
                            .foregroundColor(startDateEdited ? Theme.textDark : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 34)
                    .padding(.horizontal, Spacing.sm)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
                }

                Button {
                    showEndDatePicker.toggle()
                    showStartDatePicker = false
                } label: {
                    HStack(spacing: 6) {
                        Text("📅")
                            .font(.system(size: 13))
                        Text(endDateEdited ? formattedDate(endDate) : "結束日期")
                            .font(.system(size: 13))
                            .foregroundColor(endDateEdited ? Theme.textDark : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 34)
                    .padding(.horizontal, Spacing.sm)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
                }
            }

            if showStartDatePicker {
                DatePicker("", selection: $startDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Theme.accentGreen)
                    .onChange(of: startDate) { _, newValue in
                        startDateEdited = true
                        showStartDatePicker = false
                        // Auto-adjust end date if it's before start date
                        if endDate < newValue {
                            endDate = newValue
                        }
                    }
            }

            if showEndDatePicker {
                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Theme.accentGreen)
                    .onChange(of: endDate) { _, _ in
                        endDateEdited = true
                        showEndDatePicker = false
                    }
            }
        }
    }

    // 比賽場地
    var venueSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionTitle("比賽場地")

            Button {
                courtPickerSelection = selectedCourt.map { Set([$0]) } ?? []
                showCourtPicker = true
            } label: {
                HStack(spacing: 6) {
                    Text("📍")
                        .font(.system(size: 13))
                    Text(selectedCourt?.name ?? "選擇場地...")
                        .font(.system(size: 13))
                        .foregroundColor(selectedCourt != nil ? Theme.textDark : Theme.textSecondary)
                    Spacer()
                }
                .frame(height: 34)
                .padding(.horizontal, Spacing.sm)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.inputBorder, lineWidth: 1)
                )
            }
        }
    }

    // 水平要求 + 報名費用
    var levelAndFeeSection: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                sectionTitle("水平要求")

                Menu {
                    ForEach(ntrpRanges, id: \.self) { range in
                        Button(range) { selectedLevel = range }
                    }
                } label: {
                    HStack {
                        Text(selectedLevel)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textDark)
                        Spacer()
                        Text("▾")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textHint)
                    }
                    .frame(height: 34)
                    .padding(.horizontal, Spacing.sm)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                sectionTitle("報名費用")

                ZStack(alignment: .trailing) {
                    TextField("", text: $fee)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textDark)
                        .keyboardType(.numberPad)
                        .frame(height: 34)
                        .padding(.horizontal, Spacing.sm)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.inputBorder, lineWidth: 1)
                        )

                    Text("港幣")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textHint)
                        .padding(.trailing, Spacing.sm)
                }
            }
        }
    }

    // 賽事規則
    var rulesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionTitle("賽事規則")

            TextField("例如：單淘汰制，三盤兩勝", text: $rules)
                .font(.system(size: 13))
                .foregroundColor(Theme.textDark)
                .frame(height: 36)
                .padding(.horizontal, Spacing.sm)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.inputBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - Components

private extension CreateTournamentView {
    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Theme.textDark)
    }

    func radioButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.accentGreen : Theme.inputBorder, lineWidth: isSelected ? 2 : 1.5)
                        .frame(width: 16, height: 16)

                    if isSelected {
                        Circle()
                            .fill(Theme.accentGreen)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textDark)
            }
            .frame(minHeight: 44)
        }
    }

    func formatCard(_ format: FormatOption) -> some View {
        let isSelected = selectedFormat == format.name

        return Button {
            selectedFormat = format.name
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(format.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? Theme.accentGreen : Theme.textDark)

                    Spacer()

                    if recommendedFormats.contains(format.name) {
                        Text("推薦")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accentGreen)
                            .clipShape(Capsule())
                    }
                }

                Text(format.range)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textHint)

                Text(format.description)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Theme.selectedCardBg : .white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Theme.accentGreen : Theme.inputBorder, lineWidth: 1.5)
            )
        }
    }

    var submitButton: some View {
        Button {
            showConfirmation = true
        } label: {
            Text("發布賽事")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.accentGreen)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    var confirmationSheet: some View {
        VStack(spacing: 0) {
            // Header
            Text("確認賽事資訊")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

            // Info rows
            VStack(spacing: Spacing.sm) {
                confirmRow("賽事名稱", value: tournamentName.isEmpty ? "未填寫" : tournamentName)
                confirmRow("比賽類型", value: matchType)
                confirmRow("參賽人數", value: participantCount.isEmpty ? "未填寫" : "\(participantCount) 人")
                confirmRow("賽制", value: selectedFormat)
                confirmRow("比賽日期", value: startDateEdited && endDateEdited
                           ? "\(formattedDate(startDate)) ~ \(formattedDate(endDate))"
                           : "未選擇")
                confirmRow("比賽場地", value: selectedCourt?.name ?? "未選擇")
                confirmRow("水平要求", value: selectedLevel)
                confirmRow("報名費用", value: fee.isEmpty ? "未填寫" : "\(fee) 港幣")
                if !rules.isEmpty {
                    confirmRow("賽事規則", value: rules)
                }
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            // Buttons
            HStack(spacing: Spacing.sm) {
                Button {
                    showConfirmation = false
                } label: {
                    Text("返回修改")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.chipUnselectedBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    publishTournament()
                } label: {
                    Text("確認發布")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.accentGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }

    func confirmRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textDark)
            Spacer()
        }
    }

    func publishTournament() {
        let info = PublishedTournamentInfo(
            name: tournamentName,
            matchType: matchType,
            participantCount: participantCount,
            format: selectedFormat,
            startDate: startDate,
            endDate: endDate,
            courtName: selectedCourt?.name ?? "",
            level: selectedLevel,
            fee: fee,
            rules: rules
        )
        showConfirmation = false
        onPublish?(info)
        dismiss()
    }
}

// MARK: - Helpers

private extension CreateTournamentView {
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    var recommendedFormats: Set<String> {
        guard let count = Int(participantCount), count > 0 else { return [] }
        var result: Set<String> = []
        if count >= 4 && count <= 8 { result.insert("單循環賽") }
        if count >= 8 && count <= 16 { result.insert("分組+淘汰") }
        if count >= 16 && count <= 32 { result.insert("單敗淘汰") }
        if count >= 24 && count <= 64 { result.insert("瑞士輪") }
        return result
    }

    var recommendedFormatText: String {
        let formats = recommendedFormats
        if formats.isEmpty { return "" }
        let ordered = ["單循環賽", "分組+淘汰", "單敗淘汰", "瑞士輪"]
        let matching = ordered.filter { formats.contains($0) }
        return matching.joined(separator: "」或「")
    }

    var ntrpRanges: [String] {
        ["1.0 - 2.0", "2.0 - 3.0", "2.5 - 3.5", "3.0 - 4.0", "3.0 - 4.5",
         "3.5 - 5.0", "4.0 - 5.5", "4.5 - 6.0", "5.0 - 7.0"]
    }
}

// MARK: - Format Data

private struct FormatOption: Identifiable {
    let id = UUID()
    let name: String
    let range: String
    let description: String
}

private let formatOptions: [FormatOption] = [
    FormatOption(name: "單循環賽", range: "4-8人", description: "每人打所有對手"),
    FormatOption(name: "分組+淘汰", range: "8-16人", description: "小組賽+決賽"),
    FormatOption(name: "單敗淘汰", range: "16-32人", description: "輸一場即出局"),
    FormatOption(name: "瑞士輪", range: "24-64人", description: "戰績配對排位"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        CreateTournamentView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        CreateTournamentView()
    }
}
