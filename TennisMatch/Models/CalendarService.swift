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

    /// Parses `"YYYY/MM/dd"` + `"HH:mm - HH:mm"` into a (start, end) pair in the current timezone.
    static func parseDateTimeRange(date: String, timeRange: String) -> (start: Date, end: Date)? {
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        let trimmedDate = date.trimmingCharacters(in: .whitespaces)
        guard let day = df.date(from: trimmedDate) else { return nil }

        let parts = timeRange.components(separatedBy: " - ")
        guard parts.count == 2,
              let start = apply(time: parts[0], to: day),
              let end = apply(time: parts[1], to: day) else { return nil }
        return (start, end)
    }

    /// Parses the combined `"YYYY/MM/dd  HH:mm - HH:mm"` string used by `SignUpMatchInfo.dateTime`.
    static func parseCombinedDateTime(_ combined: String) -> (start: Date, end: Date)? {
        // Split on the double-space separator used by HomeView (line 1222/1169).
        let sep = combined.range(of: "  ") ?? combined.range(of: " ")
        guard let sep else { return nil }
        let datePart = String(combined[..<sep.lowerBound])
        let timePart = String(combined[sep.upperBound...]).trimmingCharacters(in: .whitespaces)
        return parseDateTimeRange(date: datePart, timeRange: timePart)
    }

    /// Builds a (start, end) pair from `"MM/dd"` + `"HH:mm"` + duration hours, using the current year.
    static func parseShortMatch(
        monthDay: String,
        startTime: String,
        durationHours: Int
    ) -> (start: Date, end: Date)? {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let mdParts = monthDay.split(separator: "/")
        let timeParts = startTime.split(separator: ":")
        guard mdParts.count == 2,
              timeParts.count == 2,
              let month = Int(mdParts[0]),
              let day = Int(mdParts[1]),
              let hour = Int(timeParts[0]),
              let minute = Int(timeParts[1]) else { return nil }

        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        guard let start = cal.date(from: comps),
              let end = cal.date(byAdding: .hour, value: durationHours, to: start) else { return nil }
        return (start, end)
    }

    /// Parses `"YYYY/MM/dd - MM/dd"` (tournament range). The end date inherits year/month from start when short.
    static func parseTournamentRange(_ range: String) -> (start: Date, end: Date)? {
        let parts = range.components(separatedBy: " - ")
        guard parts.count == 2 else { return nil }
        let startStr = parts[0].trimmingCharacters(in: .whitespaces)
        let endStr = parts[1].trimmingCharacters(in: .whitespaces)

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

    // MARK: - Private

    private static func apply(time: String, to day: Date) -> Date? {
        let t = time.trimmingCharacters(in: .whitespaces)
        let parts = t.components(separatedBy: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        return Calendar.current.date(
            bySettingHour: hour, minute: minute, second: 0, of: day
        )
    }
}
