//
//  CalendarService.swift
//  TennisMatch
//
//  EventKit wrapper for "加入日曆" (add match to calendar) flow.
//  Handles iOS 17+ permission prompt and saving to the default calendar.
//

import EventKit
import Foundation

enum CalendarService {
    enum AddError: LocalizedError {
        case accessDenied
        case invalidDate
        case saveFailed(Error)

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "請在設定中允許日曆權限"
            case .invalidDate:
                return "無法解析約球時間"
            case .saveFailed(let e):
                return "保存失敗：\(e.localizedDescription)"
            }
        }
    }

    /// Save an event to the user's default calendar. Throws `AddError` on failure.
    static func addEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String? = nil,
        isAllDay: Bool = false
    ) async throws {
        let store = EKEventStore()
        let granted: Bool
        do {
            granted = try await store.requestFullAccessToEvents()
        } catch {
            throw AddError.accessDenied
        }
        guard granted else { throw AddError.accessDenied }

        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.notes = notes
        event.isAllDay = isAllDay
        event.calendar = store.defaultCalendarForNewEvents

        do {
            try store.save(event, span: .thisEvent, commit: true)
        } catch {
            throw AddError.saveFailed(error)
        }
    }

    // MARK: - Date helpers

    /// Parses `"YYYY/MM/dd - MM/dd"` (tournament range). The end date inherits year/month from start when short.
    static func parseTournamentRange(_ range: String) -> (start: Date, end: Date)? {
        let parts = range.components(separatedBy: " - ")
        guard parts.count == 2 else { return nil }
        let startStr = parts[0].trimmingCharacters(in: .whitespaces)
        let endStr = parts[1].trimmingCharacters(in: .whitespaces)

        // TODO(Phase1.5): migrate to AppDateFormatter — has Locale(identifier: "en_US_POSIX") for strict ISO parsing; needs a dedicated posixYearMonthDay formatter
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy/MM/dd"
        guard let start = df.date(from: startStr) else { return nil }

        // End may be "MM/dd" or "yyyy/MM/dd". Try long first, then short inheriting start's year.
        if let end = df.date(from: endStr) {
            // Event end is exclusive-by-day for all-day events; extend by one day.
            let cal = Calendar.current
            let endOfDay = cal.date(byAdding: .day, value: 1, to: end) ?? end
            return (start, endOfDay)
        }
        df.dateFormat = "MM/dd"
        if let shortEnd = df.date(from: endStr) {
            let cal = Calendar.current
            let startYear = cal.component(.year, from: start)
            var comps = cal.dateComponents([.month, .day], from: shortEnd)
            comps.year = startYear
            if let resolved = cal.date(from: comps) {
                let endOfDay = cal.date(byAdding: .day, value: 1, to: resolved) ?? resolved
                return (start, endOfDay)
            }
        }
        return nil
    }

}
