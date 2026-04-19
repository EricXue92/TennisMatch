//
//  RegisterView.swift
//  TennisMatch
//
//  建立帳號頁面 — 基本資料(必填) + 更多資料(選填)
//

import SwiftUI
import PhotosUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Required fields
    @State private var name = ""
    @State private var selectedGender: Gender? = nil
    @State private var selectedAgeRange: AgeRange? = nil
    @State private var ntrpScore = ""

    // MARK: - Optional fields
    @State private var selectedMatchTypes: Set<MatchType> = []
    @State private var selectedCourts: Set<TennisCourt> = []
    @State private var selectedTimeSlots: Set<TimeSlot> = []
    @State private var detailedSlots: [WeeklySlot] = []
    @State private var showCourtPicker = false
    @State private var showSlotPicker = false

    // MARK: - Avatar
    @State private var avatarItem: PhotosPickerItem? = nil
    @State private var avatarImage: Image? = nil

    // MARK: - Navigation
    @State private var navigateToHome = false

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: Spacing.sm) {
                avatarSection
                requiredCard
                optionalCard
                disclaimer
                submitButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
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
                Text("建立帳號")
                    .font(Typography.navTitle)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: Spacing.xs) {
            PhotosPicker(selection: $avatarItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let avatarImage {
                        avatarImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Theme.chipUnselectedBg)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Theme.textSecondary)
                            )
                    }

                    Circle()
                        .fill(Theme.accentGreen)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                        )
                        .offset(x: 2, y: 2)
                }
            }

            Text("設定頭像")
                .font(Typography.small)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
        .onChange(of: avatarItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    avatarImage = Image(uiImage: uiImage)
                }
            }
        }
    }

    // MARK: - Required Card

    private var requiredCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "基本資料", badge: "必填", badgeBg: Theme.requiredBg, badgeFg: Theme.requiredText)
                .padding(.bottom, Spacing.xs)

            // 姓名
            fieldRow(label: "姓名", required: true) {
                TextField("請輸入姓名", text: $name)
                    .font(Typography.fieldValue)
                    .foregroundColor(Theme.textPrimary)
            }
            Theme.divider.frame(height: 1)

            // 性別
            fieldRow(label: "性別", required: true) {
                chipGroup(
                    items: Gender.allCases,
                    selected: selectedGender,
                    label: \.displayName
                ) { selectedGender = $0 }
            }
            Theme.divider.frame(height: 1)

            // 年齡段
            fieldRow(label: "年齡段", required: true) {
                chipGroup(
                    items: AgeRange.allCases,
                    selected: selectedAgeRange,
                    label: \.displayName
                ) { selectedAgeRange = $0 }
            }
            Theme.divider.frame(height: 1)

            // 技術水平
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    requiredLabel("技術水平")
                    TextField("0.0", text: $ntrpScore)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .keyboardType(.decimalPad)
                        .frame(width: 70, height: 34)
                        .padding(.horizontal, Spacing.sm)
                        .background(Theme.inputBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Theme.inputBorder, lineWidth: 1)
                        )
                }
                .padding(.vertical, Spacing.sm)

                NavigationLink {
                    NTRPGuideView()
                } label: {
                    Text("🎾 查看 NTRP 技術分級標準 →")
                        .font(Typography.small)
                        .foregroundColor(Theme.accentGreen)
                        .underline()
                }
                .padding(.bottom, Spacing.xs)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Optional Card

    private var optionalCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.xs) {
                sectionHeader(title: "更多資料", badge: "選填", badgeBg: Theme.optionalBg, badgeFg: Theme.textSecondary)
                Text("可稍後完善")
                    .font(Typography.fieldLabel)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.bottom, Spacing.xs)

            // 比賽類型
            fieldRow(label: "比賽類型", required: false) {
                multiChipGroup(
                    items: MatchType.allCases,
                    selected: $selectedMatchTypes,
                    label: \.displayName
                )
            }
            Theme.divider.frame(height: 1)

            // 常去球場
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("常去球場")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)

                FlowLayout(spacing: 8) {
                    ForEach(Array(selectedCourts).sorted(by: { $0.name < $1.name })) { court in
                        tagView(text: "📍 \(court.name)") {
                            selectedCourts.remove(court)
                        }
                    }
                    addButton("+ 新增") {
                        showCourtPicker = true
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
            .sheet(isPresented: $showCourtPicker) {
                CourtPickerView(selected: $selectedCourts)
            }
            Theme.divider.frame(height: 1)

            // 可用時間
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("可用時間")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)

                FlowLayout(spacing: 8) {
                    ForEach(TimeSlot.allCases) { slot in
                        let isSelected = selectedTimeSlots.contains(slot)
                        Button {
                            if isSelected {
                                selectedTimeSlots.remove(slot)
                            } else {
                                selectedTimeSlots.insert(slot)
                            }
                        } label: {
                            Text(slot.displayName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isSelected ? Theme.primary : Theme.chipUnselectedFg)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 6)
                                .background(isSelected ? Theme.chipSelectedBg : Theme.chipUnselectedBg)
                                .clipShape(Capsule())
                                .overlay(
                                    isSelected
                                        ? Capsule().strokeBorder(Theme.primary, lineWidth: 1.5)
                                        : nil
                                )
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
            Theme.divider.frame(height: 1)

            // 詳細時段
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("詳細時段")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x888888))

                FlowLayout(spacing: 6) {
                    ForEach(detailedSlots) { slot in
                        slotTagView(text: "📅 \(slot.displayText)") {
                            detailedSlots.removeAll { $0.id == slot.id }
                        }
                    }
                    addButton("+ 新增時段") {
                        showSlotPicker = true
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
            .sheet(isPresented: $showSlotPicker) {
                WeeklySlotPickerView { slot in
                    detailedSlots.append(slot)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Shared Components

    private func sectionHeader(title: String, badge: String, badgeBg: Color, badgeFg: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Text(badge)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(badgeFg)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(badgeBg)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }

    private func fieldRow<Content: View>(
        label: String,
        required: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: Spacing.xs) {
            if required {
                requiredLabel(label)
            } else {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
            content()
        }
        .padding(.vertical, Spacing.sm)
    }

    private func requiredLabel(_ text: String) -> some View {
        HStack(spacing: 2) {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
            Text("*")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.requiredText)
        }
    }

    // MARK: - Chip Components

    private func chipGroup<T: Identifiable & Equatable>(
        items: [T],
        selected: T?,
        label: KeyPath<T, String>,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        HStack(spacing: Spacing.xs) {
            ForEach(items) { item in
                let isSelected = selected == item
                Button { onSelect(item) } label: {
                    Text(item[keyPath: label])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? Theme.primary : Theme.chipUnselectedFg)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(isSelected ? Theme.chipSelectedBg : Theme.chipUnselectedBg)
                        .clipShape(Capsule())
                        .overlay(
                            isSelected
                                ? Capsule().strokeBorder(Theme.primary, lineWidth: 1.5)
                                : nil
                        )
                }
            }
        }
    }

    private func multiChipGroup<T: Identifiable & Hashable>(
        items: [T],
        selected: Binding<Set<T>>,
        label: KeyPath<T, String>
    ) -> some View {
        HStack(spacing: Spacing.xs) {
            ForEach(items) { item in
                let isSelected = selected.wrappedValue.contains(item)
                Button {
                    if isSelected {
                        selected.wrappedValue.remove(item)
                    } else {
                        selected.wrappedValue.insert(item)
                    }
                } label: {
                    Text(item[keyPath: label])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? Theme.primary : Theme.chipUnselectedFg)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(isSelected ? Theme.chipSelectedBg : Theme.chipUnselectedBg)
                        .clipShape(Capsule())
                        .overlay(
                            isSelected
                                ? Capsule().strokeBorder(Theme.primary, lineWidth: 1.5)
                                : nil
                        )
                }
            }
        }
    }

    // MARK: - Tag Components

    private func tagView(text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Theme.textPrimary)
            Button(action: onRemove) {
                Text("×")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.tagBg)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Theme.tagBorder, lineWidth: 1)
        )
    }

    private func slotTagView(text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Theme.textPrimary)
            Button(action: onRemove) {
                Text("×")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x888888))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.slotBg)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Theme.slotBorder, lineWidth: 1)
        )
    }

    private func addButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Theme.primary, style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
        }
    }

    // MARK: - Disclaimer & Submit

    private var disclaimer: some View {
        Text("點擊「完成設定」即表示您提供的所有資訊均為真實且準確。")
            .font(Typography.fieldLabel)
            .foregroundColor(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.top, Spacing.xs)
    }

    private var submitButton: some View {
        Button {
            navigateToHome = true
        } label: {
            Text("完成設定")
                .font(Typography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .navigationDestination(isPresented: $navigateToHome) {
            HomeView()
                .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

// MARK: - Weekly Slot Picker

struct WeeklySlot: Identifiable, Equatable {
    let id = UUID()
    let day: Weekday
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int

    var displayText: String {
        "\(day.shortName) \(formatTime(startHour, startMinute))-\(formatTime(endHour, endMinute))"
    }

    private func formatTime(_ hour: Int, _ minute: Int) -> String {
        let period = hour >= 12 ? "pm" : "am"
        let h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d%@", h, minute, period)
    }
}

enum Weekday: Int, CaseIterable, Identifiable {
    case mon = 1, tue, wed, thu, fri, sat, sun

    var id: Int { rawValue }

    var shortName: String {
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
}

private struct WeeklySlotPickerView: View {
    let onAdd: (WeeklySlot) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: Weekday = .mon
    @State private var startHour = 18
    @State private var startMinute = 30
    @State private var endHour = 19
    @State private var endMinute = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // 星期選擇
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("選擇星期")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)

                    FlowLayout(spacing: 8) {
                        ForEach(Weekday.allCases) { day in
                            let isSelected = selectedDay == day
                            Button { selectedDay = day } label: {
                                Text(day.shortName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(isSelected ? .white : Theme.chipUnselectedFg)
                                    .frame(width: 52, height: 36)
                                    .background(isSelected ? Theme.primary : Theme.chipUnselectedBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                }

                // 時間選擇（30 分鐘為單位）
                HStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("開始時間")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        halfHourPicker(hour: $startHour, minute: $startMinute)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("結束時間")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        halfHourPicker(hour: $endHour, minute: $endMinute)
                    }
                }

                // 預覽
                let preview = buildSlot()
                Text("📅 \(preview.displayText)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Theme.chipSelectedBg)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.xs, style: .continuous))

                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle("新增時段")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("新增") {
                        onAdd(buildSlot())
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Theme.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func halfHourPicker(hour: Binding<Int>, minute: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            Picker("", selection: hour) {
                ForEach(6..<23, id: \.self) { h in
                    Text("\(h)").tag(h)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 50, height: 100)
            .clipped()

            Text(":")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            Picker("", selection: minute) {
                Text("00").tag(0)
                Text("30").tag(30)
            }
            .pickerStyle(.wheel)
            .frame(width: 50, height: 100)
            .clipped()
        }
    }

    private func buildSlot() -> WeeklySlot {
        WeeklySlot(
            day: selectedDay,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute
        )
    }
}

// MARK: - Data Models

enum Gender: String, CaseIterable, Identifiable, Equatable {
    case male, female

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male:   return "男"
        case .female: return "女"
        }
    }
}

enum AgeRange: String, CaseIterable, Identifiable, Equatable {
    case teen, young, middle, senior

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .teen:   return "14-18"
        case .young:  return "19-35"
        case .middle: return "36-55"
        case .senior: return "55+"
        }
    }
}

enum MatchType: String, CaseIterable, Identifiable, Hashable {
    case singles, doubles, rally

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .singles: return "單打"
        case .doubles: return "雙打"
        case .rally:   return "拉球"
        }
    }
}

enum TimeSlot: String, CaseIterable, Identifiable, Hashable {
    case weekendMorning, weekendAfternoon, weekdayEvening, weekendAllDay, weekdayLunch

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekendMorning:   return "🌅 週末上午"
        case .weekendAfternoon: return "☀️ 週末下午"
        case .weekdayEvening:   return "🌙 工作日晚間"
        case .weekendAllDay:    return "📅 週末全天"
        case .weekdayLunch:     return "🍱 工作日午間"
        }
    }
}

// MARK: - Courts Data

enum City: String, CaseIterable, Identifiable {
    case hongKong  = "香港"
    case shanghai  = "上海"
    case shenzhen  = "深圳"
    case guangzhou = "廣州"

    var id: String { rawValue }
}

struct TennisCourt: Identifiable, Hashable {
    let id: String
    let name: String
    let city: City
    let district: String
}

let allCourts: [TennisCourt] = [

    // ╔═══════════════════════════════╗
    // ║           香  港              ║
    // ╚═══════════════════════════════╝

    // ── 港島 ── 公共球場（康文署）
    TennisCourt(id: "vp",     name: "維多利亞公園",         city: .hongKong, district: "港島"),
    TennisCourt(id: "hktc",   name: "香港網球中心",         city: .hongKong, district: "港島"),
    TennisCourt(id: "hkp",    name: "香港公園",             city: .hongKong, district: "港島"),
    TennisCourt(id: "bwg",    name: "鰂魚涌公園",           city: .hongKong, district: "港島"),
    TennisCourt(id: "cwp",    name: "柴灣公園",             city: .hongKong, district: "港島"),
    TennisCourt(id: "abd",    name: "香港仔網球場",         city: .hongKong, district: "港島"),
    TennisCourt(id: "wch",    name: "黃竹坑遊樂場",         city: .hongKong, district: "港島"),
    TennisCourt(id: "bpg",    name: "寶雲道花園",           city: .hongKong, district: "港島"),
    TennisCourt(id: "hv",     name: "跑馬地遊樂場",         city: .hongKong, district: "港島"),
    TennisCourt(id: "mrs",    name: "摩理臣山遊樂場",       city: .hongKong, district: "港島"),
    // ── 港島 ── 私人會所
    TennisCourt(id: "hkfc",   name: "香港足球會",           city: .hongKong, district: "港島"),
    TennisCourt(id: "scaa",   name: "南華體育會",           city: .hongKong, district: "港島"),
    TennisCourt(id: "hkcc",   name: "香港木球會",           city: .hongKong, district: "港島"),
    TennisCourt(id: "lrc",    name: "婦女遊樂會",           city: .hongKong, district: "港島"),
    TennisCourt(id: "usrc",   name: "三軍會",               city: .hongKong, district: "港島"),
    TennisCourt(id: "irc",    name: "印度遊樂會",           city: .hongKong, district: "港島"),
    TennisCourt(id: "cgcc",   name: "紀利華木球會",         city: .hongKong, district: "港島"),
    TennisCourt(id: "hkcoc",  name: "香港鄉村俱樂部",       city: .hongKong, district: "港島"),
    TennisCourt(id: "abc",    name: "香港仔遊艇會",         city: .hongKong, district: "港島"),
    TennisCourt(id: "rhkyc",  name: "皇家香港遊艇會",       city: .hongKong, district: "港島"),
    TennisCourt(id: "amclub", name: "美國會（大潭）",        city: .hongKong, district: "港島"),
    // ── 港島 ── 屋苑 / 大學
    TennisCourt(id: "tks",    name: "太古城",               city: .hongKong, district: "港島"),
    TennisCourt(id: "sh",     name: "海怡半島",             city: .hongKong, district: "港島"),
    TennisCourt(id: "ba",     name: "貝沙灣",               city: .hongKong, district: "港島"),
    TennisCourt(id: "hfc",    name: "杏花邨",               city: .hongKong, district: "港島"),
    TennisCourt(id: "cfyh",   name: "置富花園",             city: .hongKong, district: "港島"),
    TennisCourt(id: "rdg",    name: "陽明山莊",             city: .hongKong, district: "港島"),
    TennisCourt(id: "pfl",    name: "碧瑤灣",               city: .hongKong, district: "港島"),
    TennisCourt(id: "hku",    name: "香港大學",             city: .hongKong, district: "港島"),

    // ── 九龍 ── 公共球場（康文署）
    TennisCourt(id: "ktp",    name: "九龍仔公園",           city: .hongKong, district: "九龍"),
    TennisCourt(id: "mp",     name: "摩士公園",             city: .hongKong, district: "九龍"),
    TennisCourt(id: "cs",     name: "歌和老街公園",         city: .hongKong, district: "九龍"),
    TennisCourt(id: "bs",     name: "界限街運動場",         city: .hongKong, district: "九龍"),
    TennisCourt(id: "thtr",   name: "大坑東遊樂場",         city: .hongKong, district: "九龍"),
    TennisCourt(id: "skmp",   name: "石硤尾公園",           city: .hongKong, district: "九龍"),
    TennisCourt(id: "sspp",   name: "深水埗公園",           city: .hongKong, district: "九龍"),
    TennisCourt(id: "lckp",   name: "荔枝角公園",           city: .hongKong, district: "九龍"),
    TennisCourt(id: "ktr",    name: "觀塘遊樂場",           city: .hongKong, district: "九龍"),
    TennisCourt(id: "ncw",    name: "牛池灣公園",           city: .hongKong, district: "九龍"),
    TennisCourt(id: "wts",    name: "黃大仙摩士公園",       city: .hongKong, district: "九龍"),
    TennisCourt(id: "ksp",    name: "京士柏遊樂場",         city: .hongKong, district: "九龍"),
    TennisCourt(id: "hmtr",   name: "何文田配水庫遊樂場",    city: .hongKong, district: "九龍"),
    TennisCourt(id: "jdv",    name: "佐敦谷公園",           city: .hongKong, district: "九龍"),
    TennisCourt(id: "chr",    name: "彩虹道遊樂場",         city: .hongKong, district: "九龍"),
    // ── 九龍 ── 私人會所
    TennisCourt(id: "ktc",    name: "九龍塘會",             city: .hongKong, district: "九龍"),
    TennisCourt(id: "klncc",  name: "九龍木球會",           city: .hongKong, district: "九龍"),
    // ── 九龍 ── 屋苑 / 大學
    TennisCourt(id: "mf",     name: "美孚新邨",             city: .hongKong, district: "九龍"),
    TennisCourt(id: "wp",     name: "黃埔花園",             city: .hongKong, district: "九龍"),
    TennisCourt(id: "lkc",    name: "麗港城",               city: .hongKong, district: "九龍"),
    TennisCourt(id: "yyc",    name: "又一村花園",           city: .hongKong, district: "九龍"),
    TennisCourt(id: "polyu",  name: "香港理工大學",         city: .hongKong, district: "九龍"),

    // ── 新界 ── 公共球場（康文署）
    TennisCourt(id: "stp",    name: "沙田公園",             city: .hongKong, district: "新界"),
    TennisCourt(id: "mosr",   name: "馬鞍山遊樂場",         city: .hongKong, district: "新界"),
    TennisCourt(id: "tps",    name: "大埔運動場",           city: .hongKong, district: "新界"),
    TennisCourt(id: "ss",     name: "上水網球場",           city: .hongKong, district: "新界"),
    TennisCourt(id: "fl",     name: "粉嶺遊樂場",           city: .hongKong, district: "新界"),
    TennisCourt(id: "ylp",    name: "元朗大球場",           city: .hongKong, district: "新界"),
    TennisCourt(id: "tmws",   name: "屯門湖山遊樂場",       city: .hongKong, district: "新界"),
    TennisCourt(id: "tswp",   name: "天水圍公園",           city: .hongKong, district: "新界"),
    TennisCourt(id: "tko",    name: "將軍澳運動場",         city: .hongKong, district: "新界"),
    TennisCourt(id: "sk",     name: "西貢鄧肇堅運動場",     city: .hongKong, district: "新界"),
    TennisCourt(id: "kc",     name: "葵涌運動場",           city: .hongKong, district: "新界"),
    TennisCourt(id: "ty",     name: "青衣公園",             city: .hongKong, district: "新界"),
    TennisCourt(id: "twcmv",  name: "城門谷運動場",         city: .hongKong, district: "新界"),
    TennisCourt(id: "tmzl",   name: "屯門兆麟運動場",       city: .hongKong, district: "新界"),
    // ── 新界 ── 私人會所
    TennisCourt(id: "jsc",    name: "JSC球場",              city: .hongKong, district: "新界"),
    TennisCourt(id: "cwbgcc", name: "清水灣鄉村俱樂部",     city: .hongKong, district: "新界"),
    TennisCourt(id: "dbrc",   name: "愉景灣康樂會",         city: .hongKong, district: "新界"),
    TennisCourt(id: "hkgc",   name: "香港高爾夫球會",       city: .hongKong, district: "新界"),
    // ── 新界 ── 屋苑 / 大學
    TennisCourt(id: "c1",     name: "沙田第一城",           city: .hongKong, district: "新界"),
    TennisCourt(id: "gc",     name: "黃金海岸",             city: .hongKong, district: "新界"),
    TennisCourt(id: "pi",     name: "珀麗灣",               city: .hongKong, district: "新界"),
    TennisCourt(id: "cbg",    name: "映灣園",               city: .hongKong, district: "新界"),
    TennisCourt(id: "khlsv",  name: "嘉湖山莊",             city: .hongKong, district: "新界"),
    TennisCourt(id: "cuhk",   name: "香港中文大學",         city: .hongKong, district: "新界"),
    TennisCourt(id: "hkust",  name: "香港科技大學",         city: .hongKong, district: "新界"),
    TennisCourt(id: "eduhk",  name: "香港教育大學",         city: .hongKong, district: "新界"),
    TennisCourt(id: "lnu",    name: "嶺南大學",             city: .hongKong, district: "新界"),

    // ╔═══════════════════════════════╗
    // ║           上  海              ║
    // ╚═══════════════════════════════╝

    // ── 浦東新區 ── 公共 / 商業
    TennisCourt(id: "sh_ys",   name: "源深體育中心",             city: .shanghai, district: "浦東新區"),
    TennisCourt(id: "sh_sjgy", name: "世紀公園網球場",           city: .shanghai, district: "浦東新區"),
    TennisCourt(id: "sh_qt",   name: "前灘體育中心",             city: .shanghai, district: "浦東新區"),
    TennisCourt(id: "sh_sl",   name: "三林體育中心",             city: .shanghai, district: "浦東新區"),
    TennisCourt(id: "sh_jq",   name: "金橋碧雲體育中心",         city: .shanghai, district: "浦東新區"),
    TennisCourt(id: "sh_lchs", name: "綠城會所網球場",           city: .shanghai, district: "浦東新區"),
    TennisCourt(id: "sh_kwpd", name: "快網網球俱樂部（南江苑店）", city: .shanghai, district: "浦東新區"),
    // ── 浦東新區 ── 高校
    TennisCourt(id: "sh_skjd", name: "上海科技大學",             city: .shanghai, district: "浦東新區"),
    // ── 浦東新區 ── 社區 / 屋苑
    TennisCourt(id: "sh_rhhb", name: "仁恒河濱城",               city: .shanghai, district: "浦東新區"),
    TennisCourt(id: "sh_byhy", name: "碧雲花園",                 city: .shanghai, district: "浦東新區"),
    TennisCourt(id: "sh_lysq", name: "聯洋社區會所",             city: .shanghai, district: "浦東新區"),
    TennisCourt(id: "sh_tcgf", name: "湯臣高爾夫花園",           city: .shanghai, district: "浦東新區"),

    // ── 徐匯區 ── 公共 / 商業
    TennisCourt(id: "sh_xjh",  name: "徐家匯體育公園",           city: .shanghai, district: "徐匯區"),
    TennisCourt(id: "sh_wtyc", name: "萬體網球中心",             city: .shanghai, district: "徐匯區"),
    TennisCourt(id: "sh_gjwq", name: "上海國際網球中心",         city: .shanghai, district: "徐匯區"),
    TennisCourt(id: "sh_yjqj", name: "越界全景網球場",           city: .shanghai, district: "徐匯區"),
    TennisCourt(id: "sh_jywq", name: "蔣越網球俱樂部",           city: .shanghai, district: "徐匯區"),
    TennisCourt(id: "sh_xxsl", name: "新興網球沙龍",             city: .shanghai, district: "徐匯區"),
    // ── 徐匯區 ── 高校
    TennisCourt(id: "sh_sjtu", name: "上海交通大學（徐匯）",     city: .shanghai, district: "徐匯區"),
    TennisCourt(id: "sh_hlgx", name: "華東理工大學（徐匯）",     city: .shanghai, district: "徐匯區"),
    // ── 徐匯區 ── 社區 / 屋苑
    TennisCourt(id: "sh_smbjhy", name: "世茂濱江花園",           city: .shanghai, district: "徐匯區"),

    // ── 長寧區 ── 公共 / 商業
    TennisCourt(id: "sh_xx",   name: "仙霞網球中心",             city: .shanghai, district: "長寧區"),
    TennisCourt(id: "sh_hq",   name: "虹橋網球場",               city: .shanghai, district: "長寧區"),
    TennisCourt(id: "sh_cnwq", name: "長寧網球場",               city: .shanghai, district: "長寧區"),
    TennisCourt(id: "sh_dawq", name: "DoubleACE室內網球學練館",   city: .shanghai, district: "長寧區"),
    TennisCourt(id: "sh_zawq", name: "早安網球學練館",           city: .shanghai, district: "長寧區"),
    // ── 長寧區 ── 高校
    TennisCourt(id: "sh_dhdx", name: "東華大學（長寧）",         city: .shanghai, district: "長寧區"),
    // ── 長寧區 ── 社區 / 屋苑
    TennisCourt(id: "sh_gbrshy", name: "古北瑞仕花園",           city: .shanghai, district: "長寧區"),
    TennisCourt(id: "sh_gbhyhy", name: "古北嘉年華庭",           city: .shanghai, district: "長寧區"),

    // ── 靜安區 ──
    TennisCourt(id: "sh_ja",   name: "靜安體育中心",             city: .shanghai, district: "靜安區"),
    TennisCourt(id: "sh_dng",  name: "大寧網球場",               city: .shanghai, district: "靜安區"),
    TennisCourt(id: "sh_mywq", name: "明越網球（共和新路店）",    city: .shanghai, district: "靜安區"),

    // ── 黃浦區 ──
    TennisCourt(id: "sh_lw",   name: "盧灣體育中心",             city: .shanghai, district: "黃浦區"),
    TennisCourt(id: "sh_sbhp", name: "世博黃浦體育園",           city: .shanghai, district: "黃浦區"),
    TennisCourt(id: "sh_buwq", name: "Best U網球中心",           city: .shanghai, district: "黃浦區"),
    // ── 黃浦區 ── 社區 / 屋苑
    TennisCourt(id: "sh_chtd", name: "翠湖天地",                 city: .shanghai, district: "黃浦區"),

    // ── 楊浦區 ── 公共 / 商業
    TennisCourt(id: "sh_yp",   name: "楊浦體育中心",             city: .shanghai, district: "楊浦區"),
    // ── 楊浦區 ── 高校
    TennisCourt(id: "sh_fd",   name: "復旦大學",                 city: .shanghai, district: "楊浦區"),
    TennisCourt(id: "sh_tj",   name: "同濟大學",                 city: .shanghai, district: "楊浦區"),
    TennisCourt(id: "sh_stxy", name: "上海體育大學（楊浦）",     city: .shanghai, district: "楊浦區"),
    TennisCourt(id: "sh_scjd", name: "上海財經大學",             city: .shanghai, district: "楊浦區"),

    // ── 閔行區 ── 公共 / 商業
    TennisCourt(id: "sh_qz",   name: "旗忠網球中心",             city: .shanghai, district: "閔行區"),
    TennisCourt(id: "sh_mhty", name: "閔行體育公園",             city: .shanghai, district: "閔行區"),
    TennisCourt(id: "sh_dkh",  name: "得客會體育中心",           city: .shanghai, district: "閔行區"),
    TennisCourt(id: "sh_sqhw", name: "申昊網球俱樂部",           city: .shanghai, district: "閔行區"),
    // ── 閔行區 ── 高校
    TennisCourt(id: "sh_jdmh", name: "上海交通大學（閔行）",     city: .shanghai, district: "閔行區"),
    TennisCourt(id: "sh_hsmh", name: "華東師範大學（閔行）",     city: .shanghai, district: "閔行區"),
    // ── 閔行區 ── 社區 / 屋苑
    TennisCourt(id: "sh_wkcsh", name: "萬科城市花園",            city: .shanghai, district: "閔行區"),
    TennisCourt(id: "sh_shcc",  name: "上海春城",                city: .shanghai, district: "閔行區"),
    TennisCourt(id: "sh_lcmghy", name: "綠城玫瑰園",             city: .shanghai, district: "閔行區"),

    // ── 虹口區 ──
    TennisCourt(id: "sh_hkwq", name: "虹口網球中心",             city: .shanghai, district: "虹口區"),
    TennisCourt(id: "sh_dswq", name: "點石網球俱樂部（曲陽）",   city: .shanghai, district: "虹口區"),
    TennisCourt(id: "sh_hxwq", name: "火星網球培訓中心",         city: .shanghai, district: "虹口區"),
    TennisCourt(id: "sh_swgh", name: "上海外國語大學（虹口）",   city: .shanghai, district: "虹口區"),

    // ── 普陀區 ── 公共 / 商業
    TennisCourt(id: "sh_ptty", name: "普陀體育中心",             city: .shanghai, district: "普陀區"),
    TennisCourt(id: "sh_sfty", name: "四方體育中心網球館",       city: .shanghai, district: "普陀區"),
    TennisCourt(id: "sh_zhwq", name: "中環網球俱樂部",           city: .shanghai, district: "普陀區"),
    TennisCourt(id: "sh_t365", name: "Tennis365室內網球學練館",   city: .shanghai, district: "普陀區"),
    // ── 普陀區 ── 高校
    TennisCourt(id: "sh_hspt", name: "華東師範大學（普陀）",     city: .shanghai, district: "普陀區"),
    // ── 普陀區 ── 社區 / 屋苑
    TennisCourt(id: "sh_zylwc", name: "中遠兩灣城",              city: .shanghai, district: "普陀區"),

    // ── 松江區 ── 公共 / 商業
    TennisCourt(id: "sh_sjdx", name: "松江大學城體育中心",       city: .shanghai, district: "松江區"),
    // ── 松江區 ── 高校
    TennisCourt(id: "sh_shwg", name: "上海外國語大學（松江）",   city: .shanghai, district: "松江區"),
    TennisCourt(id: "sh_dhsj", name: "東華大學（松江）",         city: .shanghai, district: "松江區"),
    TennisCourt(id: "sh_styd", name: "上海體育大學（松江）",     city: .shanghai, district: "松江區"),
    TennisCourt(id: "sh_sgsj", name: "上海工程技術大學（松江）", city: .shanghai, district: "松江區"),

    // ── 寶山區 ──
    TennisCourt(id: "sh_bsty", name: "寶山體育中心",             city: .shanghai, district: "寶山區"),
    TennisCourt(id: "sh_shds", name: "上海大學（寶山）",         city: .shanghai, district: "寶山區"),

    // ── 嘉定區 ──
    TennisCourt(id: "sh_jdty", name: "嘉定體育中心",             city: .shanghai, district: "嘉定區"),
    TennisCourt(id: "sh_jywq", name: "菁英網球俱樂部",           city: .shanghai, district: "嘉定區"),
    TennisCourt(id: "sh_smty", name: "上海市民體育公園",         city: .shanghai, district: "嘉定區"),

    // ── 青浦區 ──
    TennisCourt(id: "sh_qpty", name: "青浦體育中心",             city: .shanghai, district: "青浦區"),

    // ── 奉賢區 ──
    TennisCourt(id: "sh_cycd", name: "超越陽光草地網球中心",     city: .shanghai, district: "奉賢區"),
    TennisCourt(id: "sh_hlgf", name: "華東理工大學（奉賢）",     city: .shanghai, district: "奉賢區"),
    TennisCourt(id: "sh_ssdf", name: "上海師範大學（奉賢）",     city: .shanghai, district: "奉賢區"),

    // ── 金山區 ──
    TennisCourt(id: "sh_jsty", name: "金山體育中心",             city: .shanghai, district: "金山區"),

    // ── 崇明區 ──
    TennisCourt(id: "sh_cmty", name: "崇明體育中心",             city: .shanghai, district: "崇明區"),

    // ╔═══════════════════════════════╗
    // ║           深  圳              ║
    // ╚═══════════════════════════════╝

    // ── 福田區 ──
    TennisCourt(id: "sz_szty", name: "深圳市體育中心網球場",       city: .shenzhen, district: "福田區"),
    TennisCourt(id: "sz_xmgy", name: "香蜜公園體育中心網球場",     city: .shenzhen, district: "福田區"),
    TennisCourt(id: "sz_hggy", name: "皇崗公園網球場",             city: .shenzhen, district: "福田區"),
    TennisCourt(id: "sz_mlwt", name: "梅林文體中心網球場",         city: .shenzhen, district: "福田區"),
    TennisCourt(id: "sz_ftqw", name: "福田區委網球場",             city: .shenzhen, district: "福田區"),
    TennisCourt(id: "sz_jbwq", name: "嘉賓路網球場",               city: .shenzhen, district: "福田區"),
    TennisCourt(id: "sz_ytkl", name: "益田康樂會網球場",           city: .shenzhen, district: "福田區"),
    // ── 福田區 ── 社區 / 屋苑
    TennisCourt(id: "sz_xywq",   name: "熙園網球場",               city: .shenzhen, district: "福田區"),
    TennisCourt(id: "sz_jdwqhy", name: "金地網球花園",             city: .shenzhen, district: "福田區"),
    TennisCourt(id: "sz_mlyc",   name: "梅林一村",                 city: .shenzhen, district: "福田區"),
    TennisCourt(id: "sz_lhec",   name: "蓮花二村",                 city: .shenzhen, district: "福田區"),

    // ── 羅湖區 ──
    TennisCourt(id: "sz_lhwq", name: "羅湖網球中心",               city: .shenzhen, district: "羅湖區"),
    TennisCourt(id: "sz_dhgy", name: "東湖公園網球場",             city: .shenzhen, district: "羅湖區"),
    TennisCourt(id: "sz_dhbg", name: "東湖網球俱樂部",             city: .shenzhen, district: "羅湖區"),
    TennisCourt(id: "sz_tnhy", name: "泰寧花園網球場",             city: .shenzhen, district: "羅湖區"),
    // ── 羅湖區 ── 社區 / 屋苑
    TennisCourt(id: "sz_bsdhy",  name: "百仕達花園",               city: .shenzhen, district: "羅湖區"),
    TennisCourt(id: "sz_lysz",   name: "龍園山莊",                 city: .shenzhen, district: "羅湖區"),
    TennisCourt(id: "sz_pxhy",   name: "鵬興花園",                 city: .shenzhen, district: "羅湖區"),

    // ── 南山區 ── 公共 / 商業
    TennisCourt(id: "sz_szw",  name: "深圳灣體育中心網球場",       city: .shenzhen, district: "南山區"),
    TennisCourt(id: "sz_nswq", name: "南山網球中心（荔香公園）",   city: .shenzhen, district: "南山區"),
    TennisCourt(id: "sz_hqc",  name: "華僑城網球場",               city: .shenzhen, district: "南山區"),
    TennisCourt(id: "sz_skty", name: "蛇口體育中心網球場",         city: .shenzhen, district: "南山區"),
    TennisCourt(id: "sz_xlty", name: "西麗體育中心",               city: .shenzhen, district: "南山區"),
    TennisCourt(id: "sz_yhwt", name: "粵海街道文體中心",           city: .shenzhen, district: "南山區"),
    TennisCourt(id: "sz_jdwq", name: "金地網球俱樂部",             city: .shenzhen, district: "南山區"),
    // ── 南山區 ── 高校
    TennisCourt(id: "sz_szdx", name: "深圳大學",                   city: .shenzhen, district: "南山區"),
    TennisCourt(id: "sz_nfkj", name: "南方科技大學",               city: .shenzhen, district: "南山區"),
    // ── 南山區 ── 社區 / 屋苑
    TennisCourt(id: "sz_btfn",   name: "波托菲諾純水岸",           city: .shenzhen, district: "南山區"),
    TennisCourt(id: "sz_zxhsw",  name: "中信紅樹灣",               city: .shenzhen, district: "南山區"),
    TennisCourt(id: "sz_jxhy",   name: "錦繡花園",                 city: .shenzhen, district: "南山區"),
    TennisCourt(id: "sz_dclrhy", name: "大沖萊茵花園",             city: .shenzhen, district: "南山區"),

    // ── 寶安區 ──
    TennisCourt(id: "sz_baty", name: "寶安體育中心網球場",         city: .shenzhen, district: "寶安區"),
    TennisCourt(id: "sz_baqn", name: "寶安青少年活動中心網球場",   city: .shenzhen, district: "寶安區"),
    // ── 寶安區 ── 社區 / 屋苑
    TennisCourt(id: "sz_tyj",    name: "桃源居",                   city: .shenzhen, district: "寶安區"),

    // ── 龍華區 ──
    TennisCourt(id: "sz_jsty", name: "簡上體育綜合體",             city: .shenzhen, district: "龍華區"),

    // ── 龍崗區 ──
    TennisCourt(id: "sz_lgty", name: "龍崗體育中心網球場",         city: .shenzhen, district: "龍崗區"),
    TennisCourt(id: "sz_sxlw", name: "神仙嶺網球中心",             city: .shenzhen, district: "龍崗區"),
    TennisCourt(id: "sz_dslc", name: "大生（樂城）體育中心",       city: .shenzhen, district: "龍崗區"),
    // ── 龍崗區 ── 高校
    TennisCourt(id: "sz_gzds", name: "香港中文大學（深圳）",       city: .shenzhen, district: "龍崗區"),
    // ── 龍崗區 ── 社區 / 屋苑
    TennisCourt(id: "sz_zhycsz", name: "中海怡翠山莊",             city: .shenzhen, district: "龍崗區"),
    TennisCourt(id: "sz_wkclg",  name: "萬科城",                   city: .shenzhen, district: "龍崗區"),
    TennisCourt(id: "sz_xyhhy",  name: "新亞洲花園",               city: .shenzhen, district: "龍崗區"),

    // ── 鹽田區 ──
    TennisCourt(id: "sz_ytwq", name: "鹽田網球場",                 city: .shenzhen, district: "鹽田區"),

    // ── 光明區 ──
    TennisCourt(id: "sz_gmty", name: "光明區群眾體育中心",         city: .shenzhen, district: "光明區"),

    // ── 坪山區 ── 高校
    TennisCourt(id: "sz_szjs", name: "深圳技術大學",               city: .shenzhen, district: "坪山區"),

    // ── 大鵬新區 ──
    TennisCourt(id: "sz_dpwq", name: "大鵬體育中心網球場",         city: .shenzhen, district: "大鵬新區"),

    // ╔═══════════════════════════════╗
    // ║           廣  州              ║
    // ╚═══════════════════════════════╝

    // ── 天河區 ── 公共 / 商業
    TennisCourt(id: "gz_thwq", name: "天河網球運動學校",           city: .guangzhou, district: "天河區"),
    TennisCourt(id: "gz_gzwq", name: "廣州網球中心場",             city: .guangzhou, district: "天河區"),
    TennisCourt(id: "gz_thgy", name: "天河公園康體中心",           city: .guangzhou, district: "天河區"),
    TennisCourt(id: "gz_smwq", name: "賽馬場網球場",               city: .guangzhou, district: "天河區"),
    TennisCourt(id: "gz_xhy",  name: "星匯園網球場",               city: .guangzhou, district: "天河區"),
    TennisCourt(id: "gz_hjxc", name: "華景新城會所網球場",         city: .guangzhou, district: "天河區"),
    // ── 天河區 ── 高校
    TennisCourt(id: "gz_hngd", name: "華南農業大學",               city: .guangzhou, district: "天河區"),
    TennisCourt(id: "gz_jndx", name: "暨南大學（天河）",           city: .guangzhou, district: "天河區"),
    // ── 天河區 ── 社區 / 屋苑
    TennisCourt(id: "gz_hjxcxq", name: "匯景新城",                 city: .guangzhou, district: "天河區"),

    // ── 越秀區 ──
    TennisCourt(id: "gz_hydy", name: "花園酒店網球場",             city: .guangzhou, district: "越秀區"),
    TennisCourt(id: "gz_dsty", name: "二沙島體育公園網球場",       city: .guangzhou, district: "越秀區"),
    TennisCourt(id: "gz_dsjy", name: "東山均益球場",               city: .guangzhou, district: "越秀區"),

    // ── 海珠區 ──
    TennisCourt(id: "gz_zhmd", name: "中海名都會所網球場",         city: .guangzhou, district: "海珠區"),
    TennisCourt(id: "gz_hzgy", name: "會展公園網球場",             city: .guangzhou, district: "海珠區"),
    // ── 海珠區 ── 高校
    TennisCourt(id: "gz_zsdx", name: "中山大學（南校區）",         city: .guangzhou, district: "海珠區"),
    // ── 海珠區 ── 社區 / 屋苑
    TennisCourt(id: "gz_zjdj",   name: "珠江帝景",                 city: .guangzhou, district: "海珠區"),

    // ── 荔灣區 ──
    TennisCourt(id: "gz_smwc", name: "沙面網球場",                 city: .guangzhou, district: "荔灣區"),
    TennisCourt(id: "gz_fcwq", name: "芳村網球俱樂部",             city: .guangzhou, district: "荔灣區"),

    // ── 白雲區 ──
    TennisCourt(id: "gz_bywq", name: "白雲體育中心網球場",         city: .guangzhou, district: "白雲區"),
    // ── 白雲區 ── 高校
    TennisCourt(id: "gz_gdwy", name: "廣東外語外貿大學（白雲山）", city: .guangzhou, district: "白雲區"),

    // ── 黃埔區 ──
    TennisCourt(id: "gz_hpty", name: "黃埔體育中心網球場",         city: .guangzhou, district: "黃埔區"),
    TennisCourt(id: "gz_ddwq", name: "頂點網球（VERTEXTENNIS）",   city: .guangzhou, district: "黃埔區"),

    // ── 番禺區 ── 公共 / 商業
    TennisCourt(id: "gz_yycty", name: "亞運城體育館網球場",        city: .guangzhou, district: "番禺區"),
    TennisCourt(id: "gz_bgywq", name: "碧桂園會所網球場",          city: .guangzhou, district: "番禺區"),
    // ── 番禺區 ── 大學城高校
    TennisCourt(id: "gz_zsdxc", name: "中山大學（東校區）",        city: .guangzhou, district: "番禺區"),
    TennisCourt(id: "gz_hnlg",  name: "華南理工大學（大學城）",    city: .guangzhou, district: "番禺區"),
    TennisCourt(id: "gz_hnsf",  name: "華南師範大學（大學城）",    city: .guangzhou, district: "番禺區"),
    TennisCourt(id: "gz_gzdx",  name: "廣州大學（大學城）",        city: .guangzhou, district: "番禺區"),
    TennisCourt(id: "gz_gdgy",  name: "廣東工業大學（大學城）",    city: .guangzhou, district: "番禺區"),
    TennisCourt(id: "gz_gdwyu", name: "廣東外語外貿大學（大學城）", city: .guangzhou, district: "番禺區"),
    // ── 番禺區 ── 社區 / 屋苑
    TennisCourt(id: "gz_qfxc",   name: "祈福新邨",                 city: .guangzhou, district: "番禺區"),
    TennisCourt(id: "gz_xhw",    name: "星河灣",                   city: .guangzhou, district: "番禺區"),
    TennisCourt(id: "gz_yjlhy",  name: "雅居樂花園",               city: .guangzhou, district: "番禺區"),
    TennisCourt(id: "gz_jxhj",   name: "錦繡香江",                 city: .guangzhou, district: "番禺區"),

    // ── 花都區 ──
    TennisCourt(id: "gz_hdty", name: "花都體育中心",               city: .guangzhou, district: "花都區"),

    // ── 南沙區 ──
    TennisCourt(id: "gz_nsgj", name: "南沙國際網球中心",           city: .guangzhou, district: "南沙區"),

    // ── 增城區 ──
    TennisCourt(id: "gz_zcty", name: "增城體育中心",               city: .guangzhou, district: "增城區"),

    // ── 從化區 ──
    TennisCourt(id: "gz_chty", name: "從化體育中心",               city: .guangzhou, district: "從化區"),
]

// MARK: - Court Picker View

private struct CourtPickerView: View {
    @Binding var selected: Set<TennisCourt>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCity: City = .hongKong

    private var filteredCourts: [TennisCourt] {
        let byCityList = allCourts.filter { $0.city == selectedCity }
        if searchText.isEmpty { return byCityList }
        return byCityList.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var groupedCourts: [(String, [TennisCourt])] {
        var seen: Set<String> = []
        var districts: [String] = []
        for court in filteredCourts {
            if seen.insert(court.district).inserted {
                districts.append(court.district)
            }
        }
        return districts.compactMap { district in
            let courts = filteredCourts.filter { $0.district == district }
            return courts.isEmpty ? nil : (district, courts)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("城市", selection: $selectedCity) {
                    ForEach(City.allCases) { city in
                        Text(city.rawValue).tag(city)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)

                List {
                    ForEach(groupedCourts, id: \.0) { district, courts in
                        Section(district) {
                            ForEach(courts) { court in
                                let isSelected = selected.contains(court)
                                Button {
                                    if isSelected {
                                        selected.remove(court)
                                    } else {
                                        selected.insert(court)
                                    }
                                } label: {
                                    HStack {
                                        Text("📍 \(court.name)")
                                            .font(Typography.fieldValue)
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Theme.primary)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(Theme.border)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "搜尋球場")
            }
            .navigationTitle("選擇常去球場")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(Theme.primary)
                }
            }
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
}
