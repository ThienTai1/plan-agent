import 'package:rrule/rrule.dart';

class RepeatRule {
  final int interval;
  final String unit; // day|week|month|year
  final int atMinutes; // minutes from 00:00 in target timezone
  final String startDateIso; // yyyy-mm-dd
  final String? endDateIso; // yyyy-mm-dd or null for never
  final int? remainingOccurrences; // null = infinite
  final int timezoneOffsetMinutes; // e.g. GMT+7 => 420
  final bool stopDuplicating;
  final String? nextOccurrenceIso; // local-ish DateTime iso

  const RepeatRule({
    required this.interval,
    required this.unit,
    required this.atMinutes,
    required this.startDateIso,
    required this.endDateIso,
    required this.remainingOccurrences,
    required this.timezoneOffsetMinutes,
    required this.stopDuplicating,
    required this.nextOccurrenceIso,
  });

  factory RepeatRule.fromJson(Map<String, dynamic> json) {
    return RepeatRule(
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      unit: (json['unit'] as String?) ?? 'day',
      atMinutes: (json['at_minutes'] as num?)?.toInt() ?? 0,
      startDateIso: (json['start_date'] as String?) ?? _todayIso(),
      endDateIso: json['end_date'] as String?,
      remainingOccurrences: (json['remaining_occurrences'] as num?)?.toInt(),
      timezoneOffsetMinutes: (json['tz_offset_minutes'] as num?)?.toInt() ?? 0,
      stopDuplicating: (json['stop_duplicating'] as bool?) ?? false,
      nextOccurrenceIso: json['next_occurrence'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'interval': interval,
    'unit': unit,
    'at_minutes': atMinutes,
    'start_date': startDateIso,
    'end_date': endDateIso,
    'remaining_occurrences': remainingOccurrences,
    'tz_offset_minutes': timezoneOffsetMinutes,
    'stop_duplicating': stopDuplicating,
    'next_occurrence': nextOccurrenceIso,
  };

  RepeatRule copyWith({
    int? interval,
    String? unit,
    int? atMinutes,
    String? startDateIso,
    String? endDateIso,
    int? remainingOccurrences,
    int? timezoneOffsetMinutes,
    bool? stopDuplicating,
    String? nextOccurrenceIso,
  }) {
    return RepeatRule(
      interval: interval ?? this.interval,
      unit: unit ?? this.unit,
      atMinutes: atMinutes ?? this.atMinutes,
      startDateIso: startDateIso ?? this.startDateIso,
      endDateIso: endDateIso ?? this.endDateIso,
      remainingOccurrences: remainingOccurrences ?? this.remainingOccurrences,
      timezoneOffsetMinutes:
          timezoneOffsetMinutes ?? this.timezoneOffsetMinutes,
      stopDuplicating: stopDuplicating ?? this.stopDuplicating,
      nextOccurrenceIso: nextOccurrenceIso ?? this.nextOccurrenceIso,
    );
  }
}

String _todayIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

DateTime? parseDateIso(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

DateTime? parseDateTimeIso(String iso) => DateTime.tryParse(iso);

DateTime? computeNextOccurrence({
  required RepeatRule rule,
  required DateTime now,
}) {
  if (rule.stopDuplicating) return null;
  final remaining = rule.remainingOccurrences;
  if (remaining != null && remaining <= 0) return null;

  final startDate = parseDateIso(rule.startDateIso);
  if (startDate == null) return null;

  // 1. Construct Frequency
  Frequency frequency;
  switch (rule.unit) {
    case 'week':
      frequency = Frequency.weekly;
      break;
    case 'month':
      frequency = Frequency.monthly;
      break;
    case 'year':
      frequency = Frequency.yearly;
      break;
    case 'day':
    default:
      frequency = Frequency.daily;
      break;
  }

  // 2. Construct RecurrenceRule
  // Note: rrule package uses 'until' as inclusive.
  // We need to parse endDateIso if present.
  DateTime? untilDate;
  if (rule.endDateIso != null) {
    final e = parseDateIso(rule.endDateIso!);
    if (e != null) {
      // Set to end of day in target timezone conceptual time
      untilDate = DateTime.utc(e.year, e.month, e.day, 23, 59, 59);
    }
  }

  final rrule = RecurrenceRule(
    frequency: frequency,
    interval: rule.interval,
    until: untilDate,
    count: rule.remainingOccurrences,
  );

  // 3. Determine DTSTART in "Target Timezone" (conceptual)
  // We treat this as a UTC DateTime for rrule calculation to avoid
  // local timezone interference, effectively "floating" time.
  final startHour = rule.atMinutes ~/ 60;
  final startMinute = rule.atMinutes % 60;

  final dtStart = DateTime.utc(
    startDate.year,
    startDate.month,
    startDate.day,
    startHour,
    startMinute,
  );

  // 4. Project 'now' to Target Timezone
  final nowUtc = now.toUtc();
  final nowTarget = nowUtc.add(Duration(minutes: rule.timezoneOffsetMinutes));

  try {
    // rrule.getInstances returns occurrences >= start.
    // We want the first instance strictly AFTER nowTarget.

    // Optimization: If dtStart is already in the future relative to nowTarget,
    // then dtStart is the next occurrence.
    if (dtStart.isAfter(nowTarget)) {
      final absoluteUtc = dtStart.subtract(
        Duration(minutes: rule.timezoneOffsetMinutes),
      );
      return absoluteUtc.toLocal();
    }

    final instances = rrule.getInstances(start: dtStart);

    DateTime? next;
    int checks = 0;
    for (final instance in instances) {
      if (instance.isAfter(nowTarget)) {
        next = instance;
        break;
      }
      checks++;
      if (checks > 1000) break; // Safety break
    }

    if (next == null) return null;

    final absoluteUtc = next.subtract(
      Duration(minutes: rule.timezoneOffsetMinutes),
    );
    return absoluteUtc.toLocal();
  } catch (e) {
    return null;
  }
}
