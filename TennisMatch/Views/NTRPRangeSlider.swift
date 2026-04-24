//
//  NTRPRangeSlider.swift
//  TennisMatch
//
//  共用 NTRP 雙滑桿組件 — 替代 CreateMatchView / EditProfileView / MatchFilterPanelView 中的重複實現
//

import SwiftUI

struct NTRPRangeSlider: View {
    @Binding var low: Double
    @Binding var high: Double
    var range: ClosedRange<Double> = 1.0...7.0
    var step: Double = 0.5

    /// 滑桿兩端的數值範圍
    private var rangeSpan: Double { range.upperBound - range.lowerBound }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(String(format: "%.1f", range.lowerBound))
                .font(Typography.captionMedium)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 28)

            GeometryReader { geo in
                let width = geo.size.width
                let lowX = (low - range.lowerBound) / rangeSpan * width
                let highX = (high - range.lowerBound) / rangeSpan * width

                ZStack(alignment: .leading) {
                    // 背景軌道
                    Capsule()
                        .fill(Theme.inputBorder)
                        .frame(height: 4)

                    // 選中區間
                    Capsule()
                        .fill(Theme.primary)
                        .frame(width: max(0, highX - lowX), height: 4)
                        .offset(x: lowX)

                    // 低值滑塊
                    sliderThumb
                        .position(x: lowX, y: geo.size.height / 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let raw = value.location.x / width * rangeSpan + range.lowerBound
                                    let snapped = (raw / step).rounded() * step
                                    low = min(max(snapped, range.lowerBound), high)
                                }
                        )

                    // 高值滑塊
                    sliderThumb
                        .position(x: highX, y: geo.size.height / 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let raw = value.location.x / width * rangeSpan + range.lowerBound
                                    let snapped = (raw / step).rounded() * step
                                    high = max(min(snapped, range.upperBound), low)
                                }
                        )
                }
            }
            .frame(height: 44)

            Text(String(format: "%.1f", range.upperBound))
                .font(Typography.captionMedium)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 28)
        }
    }

    private var sliderThumb: some View {
        Circle()
            .fill(.white)
            .frame(width: 24, height: 24)
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            .overlay {
                Circle()
                    .fill(Theme.primary)
                    .frame(width: 10, height: 10)
            }
            // 擴大觸控區域到 44pt（HIG 最小觸控目標）
            .contentShape(Circle().scale(44.0 / 24.0))
    }
}
