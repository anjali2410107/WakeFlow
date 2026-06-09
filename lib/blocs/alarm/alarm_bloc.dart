import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import 'alarm_event.dart';
import 'alarm_state.dart';

class AlarmBloc extends Bloc<AlarmEvent, AlarmState> {
  final DatabaseService _databaseService;
  StreamSubscription? _alarmsSubscription;

  AlarmBloc({required DatabaseService databaseService})
      : _databaseService = databaseService,
        super(AlarmsLoading()) {
    on<AlarmsLoadRequested>(_onAlarmsLoadRequested);
    on<AlarmsListUpdated>(_onAlarmsListUpdated);
    on<AlarmAdded>(_onAlarmAdded);
    on<AlarmUpdated>(_onAlarmUpdated);
    on<AlarmDeleted>(_onAlarmDeleted);
    on<AlarmToggled>(_onAlarmToggled);
  }

  Future<void> _onAlarmsLoadRequested(
      AlarmsLoadRequested event, Emitter<AlarmState> emit) async {
    emit(AlarmsLoading());
    await _alarmsSubscription?.cancel();
    
    _alarmsSubscription = _databaseService.getAlarmsStream(event.uid).listen(
      (alarms) {
        add(AlarmsListUpdated(alarms));
      },
      onError: (error) {
        emit(AlarmOperationFailure("Failed to load alarms: $error"));
      },
    );
  }

  void _onAlarmsListUpdated(AlarmsListUpdated event, Emitter<AlarmState> emit) {
    emit(AlarmsLoaded(event.alarms));
  }

  Future<void> _onAlarmAdded(AlarmAdded event, Emitter<AlarmState> emit) async {
    try {
      await _databaseService.saveAlarm(event.uid, event.alarm);
      await NotificationService.scheduleAlarm(event.alarm);
    } catch (e) {
      emit(AlarmOperationFailure("Failed to add alarm: $e"));
    }
  }

  Future<void> _onAlarmUpdated(AlarmUpdated event, Emitter<AlarmState> emit) async {
    try {
      await _databaseService.saveAlarm(event.uid, event.alarm);
      await NotificationService.scheduleAlarm(event.alarm);
    } catch (e) {
      emit(AlarmOperationFailure("Failed to update alarm: $e"));
    }
  }

  Future<void> _onAlarmDeleted(AlarmDeleted event, Emitter<AlarmState> emit) async {
    try {
      await _databaseService.deleteAlarm(event.uid, event.alarm.id);
      await NotificationService.cancelAlarm(event.alarm);
    } catch (e) {
      emit(AlarmOperationFailure("Failed to delete alarm: $e"));
    }
  }

  Future<void> _onAlarmToggled(AlarmToggled event, Emitter<AlarmState> emit) async {
    try {
      final updatedAlarm = event.alarm.copyWith(isEnabled: !event.alarm.isEnabled);
      await _databaseService.saveAlarm(event.uid, updatedAlarm);
      await NotificationService.scheduleAlarm(updatedAlarm);
    } catch (e) {
      emit(AlarmOperationFailure("Failed to toggle alarm: $e"));
    }
  }

  @override
  Future<void> close() {
    _alarmsSubscription?.cancel();
    return super.close();
  }
}
