import '../../models/alarm.dart';

abstract class AlarmEvent {}

class AlarmsLoadRequested extends AlarmEvent {
  final String uid;

  AlarmsLoadRequested({required this.uid});
}

class AlarmAdded extends AlarmEvent {
  final String uid;
  final Alarm alarm;

  AlarmAdded({required this.uid, required this.alarm});
}

class AlarmUpdated extends AlarmEvent {
  final String uid;
  final Alarm alarm;

  AlarmUpdated({required this.uid, required this.alarm});
}

class AlarmDeleted extends AlarmEvent {
  final String uid;
  final Alarm alarm;

  AlarmDeleted({required this.uid, required this.alarm});
}

class AlarmToggled extends AlarmEvent {
  final String uid;
  final Alarm alarm;

  AlarmToggled({required this.uid, required this.alarm});
}

class AlarmsListUpdated extends AlarmEvent {
  final List<Alarm> alarms;

  AlarmsListUpdated(this.alarms);
}
