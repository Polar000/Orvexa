// Recordatorio diario al operador: "¿Ya registraste tus incas de hoy?"
// Son notificaciones del propio teléfono (funcionan sin internet y sin servidor).
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'calc.dart';

class Reminders {
  /// Se apaga en pruebas.
  static bool enabled = !kIsWeb;
  static const hour = 17; // 5:00 pm
  static const _baseId = 100;
  static const _days = 7;
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Guatemala'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  /// Programa los recordatorios de los próximos 7 días laborales a las 5 pm,
  /// saltando hoy si ya reportó. Se vuelve a programar cada vez que abre la app.
  static Future<void> scheduleOperator({
    required bool hasActiveAssignment,
    required bool reportedToday,
    int workDaysPerWeek = 6,
  }) async {
    if (!enabled) return;
    try {
      await _init();
      for (var i = 0; i < _days; i++) {
        await _plugin.cancel(id: _baseId + i);
      }
      if (!hasActiveAssignment) return;
      final now = tz.TZDateTime.now(tz.local);
      for (var i = 0; i < _days; i++) {
        final day = now.add(Duration(days: i));
        final at = tz.TZDateTime(tz.local, day.year, day.month, day.day, hour);
        if (!at.isAfter(now)) continue;
        if (i == 0 && reportedToday) continue;
        if (!isWorkDay(DateTime(at.year, at.month, at.day), workDaysPerWeek)) continue;
        await _plugin.zonedSchedule(
          id: _baseId + i,
          scheduledDate: at,
          title: 'ORVEXA',
          body: '¿Ya registraste las incas de hoy? Toma 1 minuto.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'recordatorio_diario',
              'Recordatorio diario',
              channelDescription: 'Aviso para registrar la producción del día',
              importance: Importance.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('No se pudieron programar recordatorios: $e');
    }
  }

  static Future<void> cancelAll() async {
    if (!enabled || !_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
