import Foundation

/// Centralized date formatting utilities
enum DateFormatting {
    // MARK: - Formatters

    /// ISO8601 formatter for parsing API dates
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// ISO8601 formatter without fractional seconds (fallback)
    private static let iso8601FormatterNoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Standard date formatter for display
    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Short date formatter
    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    /// Full date and time formatter
    private static let fullFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Relative date formatter
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    // MARK: - Parsing

    /// Parse an ISO8601 date string to Date
    static func parse(_ dateString: String) -> Date? {
        // Try with fractional seconds first
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        // Fall back to without fractional seconds
        return iso8601FormatterNoFractional.date(from: dateString)
    }

    // MARK: - Formatting

    /// Format a date for display (e.g., "Mar 15, 2024")
    static func display(_ date: Date) -> String {
        displayFormatter.string(from: date)
    }

    /// Format a date string for display, returns nil if parsing fails
    static func display(_ dateString: String) -> String? {
        guard let date = parse(dateString) else { return nil }
        return display(date)
    }

    /// Format a date as short format (e.g., "3/15/24")
    static func short(_ date: Date) -> String {
        shortFormatter.string(from: date)
    }

    /// Format a date string as short format
    static func short(_ dateString: String) -> String? {
        guard let date = parse(dateString) else { return nil }
        return short(date)
    }

    /// Format a date with time (e.g., "Mar 15, 2024 at 3:30 PM")
    static func full(_ date: Date) -> String {
        fullFormatter.string(from: date)
    }

    /// Format a date string with time
    static func full(_ dateString: String) -> String? {
        guard let date = parse(dateString) else { return nil }
        return full(date)
    }

    /// Format a date as relative (e.g., "2 days ago", "in 3 hours")
    static func relative(_ date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// Format a date string as relative
    static func relative(_ dateString: String) -> String? {
        guard let date = parse(dateString) else { return nil }
        return relative(date)
    }

    /// Format hours as human-readable duration (e.g., "12h 30m")
    static func duration(hours: Float) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60

        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else {
            return "\(m)m"
        }
    }
}

// MARK: - String Extension

extension String {
    /// Convenience accessor for parsing and formatting dates
    var asDate: Date? {
        DateFormatting.parse(self)
    }

    /// Format as display date
    var displayDate: String? {
        DateFormatting.display(self)
    }

    /// Format as relative date
    var relativeDate: String? {
        DateFormatting.relative(self)
    }
}
