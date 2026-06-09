class Alarm {
  final String id;
  final String label;
  final String time;
  final int hour;
  final int minute;
  final bool isEnabled;
  final List<int> repeatDays;
  final int snoozeMinutes;
  final DateTime createdAt;

  Alarm({
    required this.id,
    required this.label,
    required this.time,
    required this.hour,
    required this.minute,
    required this.isEnabled,
    required this.repeatDays,
    required this.snoozeMinutes,
    required this.createdAt,
  });

  Alarm copyWith({
    String? id,
    String? label,
    String? time,
    int? hour,
    int? minute,
    bool? isEnabled,
    List<int>? repeatDays,
    int? snoozeMinutes,
    DateTime? createdAt,
  }) {
    return Alarm(
      id: id ?? this.id,
      label: label ?? this.label,
      time: time ?? this.time,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'time': time,
      'hour': hour,
      'minute': minute,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays,
      'snoozeMinutes': snoozeMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      time: map['time'] ?? '',
      hour: map['hour'] ?? 0,
      minute: map['minute'] ?? 0,
      isEnabled: map['isEnabled'] ?? true,
      repeatDays: List<int>.from(map['repeatDays'] ?? []),
      snoozeMinutes: map['snoozeMinutes'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
