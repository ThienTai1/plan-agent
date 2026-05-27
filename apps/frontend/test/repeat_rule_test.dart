import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/domain/models/repeat_rule.dart';

void main() {
  group('RepeatRule with rrule', () {
    final localOffset = DateTime.now().timeZoneOffset.inMinutes;

    test('Daily recurrence', () {
      final rule = RepeatRule(
        interval: 1,
        unit: 'day',
        atMinutes: 9 * 60, // 09:00
        startDateIso: '2025-01-01',
        endDateIso: null,
        remainingOccurrences: null,
        timezoneOffsetMinutes: localOffset, // Use local offset
        stopDuplicating: false,
        nextOccurrenceIso: null,
      );

      final now = DateTime(2025, 1, 1, 8, 0); // 08:00 Local
      final next = computeNextOccurrence(rule: rule, now: now);

      // Should be today at 09:00 Local
      expect(next, DateTime(2025, 1, 1, 9, 0));

      final nowAfter = DateTime(2025, 1, 1, 10, 0); // 10:00 Local
      final nextAfter = computeNextOccurrence(rule: rule, now: nowAfter);

      // Should be tomorrow at 09:00 Local
      expect(nextAfter, DateTime(2025, 1, 2, 9, 0));
    });

    test('Weekly recurrence', () {
      final rule = RepeatRule(
        interval: 1,
        unit: 'week',
        atMinutes: 10 * 60, // 10:00
        startDateIso: '2025-01-01', // Wednesday
        endDateIso: null,
        remainingOccurrences: null,
        timezoneOffsetMinutes: localOffset,
        stopDuplicating: false,
        nextOccurrenceIso: null,
      );

      // 2025-01-01 is Wednesday.

      final now = DateTime(2025, 1, 1, 9, 0);
      final next = computeNextOccurrence(rule: rule, now: now);
      expect(next, DateTime(2025, 1, 1, 10, 0)); // Today

      final nowAfter = DateTime(2025, 1, 1, 11, 0);
      final nextAfter = computeNextOccurrence(rule: rule, now: nowAfter);
      expect(nextAfter, DateTime(2025, 1, 8, 10, 0)); // Next Wed
    });

    test('Recurrence with count limit', () {
      final rule = RepeatRule(
        interval: 1,
        unit: 'day',
        atMinutes: 12 * 60,
        startDateIso: '2025-01-01',
        endDateIso: null,
        remainingOccurrences: 2,
        timezoneOffsetMinutes: localOffset, // Use local offset
        stopDuplicating: false,
        nextOccurrenceIso: null,
      );

      expect(
        computeNextOccurrence(rule: rule, now: DateTime(2025, 1, 1, 10, 0)),
        DateTime(2025, 1, 1, 12, 0),
      );

      expect(
        computeNextOccurrence(rule: rule, now: DateTime(2025, 1, 1, 13, 0)),
        DateTime(2025, 1, 2, 12, 0),
      );

      expect(
        computeNextOccurrence(rule: rule, now: DateTime(2025, 1, 2, 13, 0)),
        null,
      );
    });
  });
}
