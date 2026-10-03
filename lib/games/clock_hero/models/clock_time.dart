/// A simple wall-clock time (12-hour) used by Clock Hero.
class ClockTime {
  const ClockTime(this.hour, this.minute);

  /// 1..12
  final int hour;

  /// 0..59 (Clock Hero only uses 0 and 30 for kids, and 15/45 when harder)
  final int minute;

  /// e.g. "3:00", "7:30".
  String get label {
    final m = minute.toString().padLeft(2, '0');
    return '$hour:$m';
  }

  /// A friendly spoken form, e.g. "3 o'clock", "half past 7".
  String get spoken {
    if (minute == 0) return "$hour o'clock";
    if (minute == 30) return 'half past $hour';
    if (minute == 15) return 'quarter past $hour';
    if (minute == 45) return 'quarter to ${hour == 12 ? 1 : hour + 1}';
    return label;
  }

  /// Returns the time [hours] later (wrapping around the 12-hour clock),
  /// keeping the same minute. Used for elapsed-time questions.
  ClockTime addHours(int hours) {
    var h = (hour + hours) % 12;
    if (h == 0) h = 12;
    return ClockTime(h, minute);
  }

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}
