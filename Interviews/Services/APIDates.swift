//
//  APIDates.swift
//  Interviews
//

import Foundation

/// The API sends two kinds of date: real moments (interview times, take-home deadlines) and calendar days
/// (application dates from imports, offer respond-by days) sent as UTC midnight. A day must stay the same day in
/// every timezone, so it's kept as local midnight of that day, never as the UTC instant.
nonisolated enum APIDates {
    private static let withFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let withoutFraction = ISO8601DateFormatter()

    /// An ISO timestamp, with or without fractional seconds; nil if it isn't one
    static func instant(_ string: String?) -> Date? {
        guard let string else { return nil }
        return withFraction.date(from: string) ?? withoutFraction.date(from: string)
    }

    /// A UTC-midnight value is a calendar day: local midnight of that day. Anything else is a real moment.
    static func day(_ string: String?, calendar: Calendar = .current) -> Date? {
        guard let instant = instant(string) else { return nil }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let parts = utc.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: instant)
        guard parts.hour == 0, parts.minute == 0, parts.second == 0, (parts.nanosecond ?? 0) < 1_000_000 else { return instant }
        return calendar.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day))
    }

    /// A local calendar day as the server's "yyyy-MM-dd"
    static func dayString(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func instantString(_ date: Date) -> String {
        withFraction.string(from: date)
    }

    static func isOffer(_ stage: String?) -> Bool {
        stage?.trimmingCharacters(in: .whitespaces).lowercased() == "offer"
    }
}
