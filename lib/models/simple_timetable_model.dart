class TimeSlot {
  final String startTime; // e.g. "08:00 AM"
  final String endTime; // e.g. "08:30 AM"
  final String subject; // e.g. "Maths"
  final String key; // original key, e.g. "t_8_00_8_30"

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.key,
  });
}

class SimpleTimetableModel {
  final int id;
  final String day;
  final String grade;
  final List<TimeSlot> slots;

  SimpleTimetableModel({
    required this.id,
    required this.day,
    required this.grade,
    required this.slots,
  });

  factory SimpleTimetableModel.fromJson(Map<String, dynamic> json) {
    final slots = <TimeSlot>[];

    // All keys that start with "t_" are time slots
    final timeKeys = json.keys.where((k) => k.startsWith('t_')).toList();

    // Sort by start time in minutes (24-hour aware)
    timeKeys.sort((a, b) => _keyToMinutes24(a).compareTo(_keyToMinutes24(b)));

    for (final key in timeKeys) {
      final subject = json[key] as String? ?? '';
      if (subject.isEmpty) continue;

      final parsed = _parseKey(key);
      if (parsed != null) {
        slots.add(
          TimeSlot(
            startTime: parsed['start']!,
            endTime: parsed['end']!,
            subject: subject,
            key: key,
          ),
        );
      }
    }

    return SimpleTimetableModel(
      id: json['id'] ?? 0,
      day: json['day'] ?? '',
      grade: json['grade'] ?? '',
      slots: slots,
    );
  }

  /// Convert key to minutes in 24-hour context.
  /// School starts at 8 AM, so hours 1–6 are treated as PM (13–18).
  /// Hour 12 = noon (12 PM). Hours 7–12 = AM side (7–12).
  static int _keyToMinutes24(String key) {
    final parts = key.split('_');
    if (parts.length < 3) return 0;
    int hour = int.tryParse(parts[1]) ?? 0;
    final minute = int.tryParse(parts[2]) ?? 0;

    // Convert to 24-hour:
    // School hours run from ~8 AM. Hours 1-6 must be afternoon (PM).
    if (hour >= 1 && hour <= 6) {
      hour += 12; // 1 PM → 13, 2 PM → 14 …
    }
    return hour * 60 + minute;
  }

  /// Parse a key like "t_8_00_8_30" into human-readable times.
  static Map<String, String>? _parseKey(String key) {
    final parts = key.split('_');
    // Expected parts: ['t', startH, startM, endH, endM]
    if (parts.length < 5) return null;

    final startH = int.tryParse(parts[1]);
    final startM = int.tryParse(parts[2]);
    final endH = int.tryParse(parts[3]);
    final endM = int.tryParse(parts[4]);

    if (startH == null || startM == null || endH == null || endM == null) {
      return null;
    }

    return {
      'start': _formatTime(startH, startM),
      'end': _formatTime(endH, endM),
    };
  }

  /// Format a raw hour/minute pair to "08:00 AM" / "01:00 PM".
  /// Hours 1–6 are PM, 7–11 are AM, 12 is noon (PM), 0 is midnight (AM).
  static String _formatTime(int hour, int minute) {
    String period;
    int display;

    if (hour == 0) {
      period = 'AM';
      display = 12;
    } else if (hour == 12) {
      period = 'PM';
      display = 12;
    } else if (hour >= 1 && hour <= 6) {
      // School afternoon: 1 → 1 PM, 2 → 2 PM, …
      period = 'PM';
      display = hour;
    } else if (hour > 12) {
      period = 'PM';
      display = hour - 12;
    } else {
      period = 'AM';
      display = hour;
    }

    return '${display.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
