import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/alarm/alarm_bloc.dart';
import '../blocs/alarm/alarm_event.dart';
import '../blocs/alarm/alarm_state.dart';
import '../models/alarm.dart';
import '../models/app_user.dart';
import '../widgets/alarm_tile.dart';
import '../services/firebase_service.dart';
import 'add_edit_alarm_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _clockTimer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    context.read<AlarmBloc>().add(AlarmsLoadRequested(uid: widget.user.uid));
    
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _getNextAlarmMessage(List<Alarm> alarms) {
    final activeAlarms = alarms.where((a) => a.isEnabled).toList();
    if (activeAlarms.isEmpty) return "No active alarms";

    final now = DateTime.now();
    DateTime? soonestAlarmTime;

    for (final alarm in activeAlarms) {
      if (alarm.repeatDays.isEmpty) {
        var alarmDate = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
        if (alarmDate.isBefore(now)) {
          alarmDate = alarmDate.add(const Duration(days: 1));
        }
        if (soonestAlarmTime == null || alarmDate.isBefore(soonestAlarmTime)) {
          soonestAlarmTime = alarmDate;
        }
      } else {
        for (final day in alarm.repeatDays) {
          var alarmDate = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
          while (alarmDate.weekday != day || alarmDate.isBefore(now)) {
            alarmDate = alarmDate.add(const Duration(days: 1));
          }
          if (soonestAlarmTime == null || alarmDate.isBefore(soonestAlarmTime)) {
            soonestAlarmTime = alarmDate;
          }
        }
      }
    }

    if (soonestAlarmTime != null) {
      final difference = soonestAlarmTime.difference(now);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      
      final formattedTime = DateFormat('hh:mm a').format(soonestAlarmTime);
      final dayLabel = soonestAlarmTime.day == now.day ? 'today' : 'tomorrow';

      if (hours == 0) {
        return "Next alarm: $dayLabel at $formattedTime (in $minutes minutes)";
      } else {
        return "Next alarm: $dayLabel at $formattedTime (in ${hours}h ${minutes}m)";
      }
    }

    return "No active alarms";
  }

  @override
  Widget build(BuildContext context) {
    final isCloud = FirebaseService.isInitialized;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F0E17),
                Color(0xFF16152B),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCloud ? const Color(0xFF2EF297) : const Color(0xFFFFB236),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isCloud ? 'Cloud Synced' : 'Local Only',
                                style: TextStyle(
                                  color: isCloud ? const Color(0xFF2EF297) : const Color(0xFFFFB236),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        },
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),
                
                Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C63FF).withOpacity(0.15),
                        const Color(0xFFE285FF).withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('hh:mm:ss').format(_currentTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        DateFormat('a').format(_currentTime),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${DateFormat('EEEE, MMMM d').format(_currentTime)}  |  ${_currentTime.timeZoneName}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<AlarmBloc, AlarmState>(
                        builder: (context, state) {
                          if (state is AlarmsLoaded) {
                            return Text(
                              _getNextAlarmMessage(state.alarms),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFE285FF),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return const Text(
                            'Checking alarms...',
                            style: TextStyle(color: Colors.white38, fontSize: 14),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8.0),
                  child: Text(
                    'Your Alarms',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                Expanded(
                  child: BlocBuilder<AlarmBloc, AlarmState>(
                    builder: (context, state) {
                      if (state is AlarmsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                        );
                      } else if (state is AlarmsLoaded) {
                        final alarms = state.alarms;
                        if (alarms.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.alarm_off, size: 64, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 12),
                                Text(
                                  'No alarms set yet.',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap the + button to add one.',
                                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: alarms.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final alarm = alarms[index];
                            return AlarmTile(
                              alarm: alarm,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => AddEditAlarmScreen(
                                      uid: widget.user.uid,
                                      alarm: alarm,
                                    ),
                                  ),
                                );
                              },
                              onToggle: (value) {
                                context.read<AlarmBloc>().add(
                                      AlarmToggled(uid: widget.user.uid, alarm: alarm),
                                    );
                              },
                              onDelete: () {
                                context.read<AlarmBloc>().add(
                                      AlarmDeleted(uid: widget.user.uid, alarm: alarm),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Alarm "${alarm.label.isNotEmpty ? alarm.label : alarm.time}" deleted'),
                                    backgroundColor: const Color(0xFF6C63FF),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      } else if (state is AlarmOperationFailure) {
                        return Center(
                          child: Text(
                            state.errorMessage,
                            style: const TextStyle(color: Color(0xFFF25F5C)),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFE285FF)],
            ),
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditAlarmScreen(uid: widget.user.uid),
                ),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
