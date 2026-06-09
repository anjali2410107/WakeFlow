import '../../models/alarm.dart';

abstract class AlarmState {}

class AlarmsLoading extends AlarmState {}

class AlarmsLoaded extends AlarmState {
  final List<Alarm> alarms;

  AlarmsLoaded(this.alarms);
}

class AlarmOperationSuccess extends AlarmState {}

class AlarmOperationFailure extends AlarmState {
  final String errorMessage;

  AlarmOperationFailure(this.errorMessage);
}
