// Modo sin señal: los reportes y mantenimientos del operador se guardan en el teléfono
// y se envían solos cuando vuelve la conexión.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data.dart';
import 'models.dart';

/// UUID v4 generado en el teléfono: permite reintentar el envío sin duplicar registros.
String newId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

/// ¿El error es por falta de señal (reintentar luego) y no por datos inválidos?
bool isNetworkError(Object e) {
  if (e is TimeoutException) return true;
  if (e is AuthRetryableFetchException) return true;
  if (e is PostgrestException || e is AppError) return false;
  final s = e.toString();
  return s.contains('SocketException') ||
      s.contains('ClientException') ||
      s.contains('Failed host lookup') ||
      s.contains('Connection refused') ||
      s.contains('Connection reset') ||
      s.contains('Connection closed') ||
      s.contains('Network is unreachable') ||
      s.contains('HandshakeException') ||
      s.contains('XMLHttpRequest');
}

class OutboxItem {
  final String id; // id del registro en la base
  final String kind; // report | maintenance
  final String op; // insert | update
  Map<String, dynamic> payload;
  final DateTime createdAt;
  String? error; // rechazado por el servidor (no por señal)
  OutboxItem({required this.id, required this.kind, required this.op, required this.payload, DateTime? createdAt, this.error})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() =>
      {'id': id, 'kind': kind, 'op': op, 'payload': payload, 'createdAt': createdAt.toIso8601String(), 'error': error};
  factory OutboxItem.fromJson(Map<String, dynamic> m) => OutboxItem(
        id: m['id'],
        kind: m['kind'],
        op: m['op'],
        payload: Map<String, dynamic>.from(m['payload']),
        createdAt: DateTime.tryParse(m['createdAt'] ?? ''),
        error: m['error'],
      );

  String get reportKey => '${payload['assignment_id']}|${payload['report_date']}';
}

/// Envía un registro al servidor. Se puede reemplazar en pruebas.
typedef OutboxSender = Future<void> Function(OutboxItem item);

Future<void> supabaseSender(OutboxItem it) async {
  final table = it.kind == 'report' ? 'daily_reports' : 'maintenance_logs';
  if (it.op == 'insert') {
    try {
      final payload = Map<String, dynamic>.from(it.payload)
        ..remove('operator_pay')
        ..remove('helper_pay');
      await db.from(table).insert({...payload, 'id': it.id}).timeout(const Duration(seconds: 20));
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
      // ¿Ya se había enviado (se perdió la respuesta)? Entonces está bien.
      final row = await db.from(table).select('id').eq('id', it.id).maybeSingle();
      if (row != null) return;
      throw AppError('Ya existe un reporte de ese día en el servidor. Ábrelo desde el historial para corregirlo.');
    }
  } else {
    final payload = Map<String, dynamic>.from(it.payload)
      ..remove('project_id')
      ..remove('machine_id')
      ..remove('operator_pay')
      ..remove('helper_pay');
    final rows = await db.from(table).update(payload).eq('id', it.id).select('id').timeout(const Duration(seconds: 20));
    if ((rows as List).isEmpty) {
      throw AppError('No se pudo corregir: solo se pueden corregir reportes de los últimos 2 días.');
    }
  }
}

class Outbox extends ChangeNotifier {
  Outbox({OutboxSender? sender, Stream<List<ConnectivityResult>>? connectivity})
      : _sender = sender ?? supabaseSender,
        _connStream = connectivity;
  static Outbox instance = Outbox();

  final OutboxSender _sender;
  final Stream<List<ConnectivityResult>>? _connStream;
  SharedPreferences? _prefs;
  String? _uid;
  StreamSubscription? _conn;
  Timer? _timer;

  List<OutboxItem> items = [];
  bool online = true;
  bool syncing = false;
  DateTime? lastSync;

  int get pendingCount => items.where((i) => i.error == null).length;
  List<OutboxItem> get failed => items.where((i) => i.error != null).toList();
  String get _key => 'orvexa_outbox_v1_$_uid';

  Future<void> init(String uid) async {
    if (_uid == uid && _prefs != null) return;
    _uid = uid;
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    items = raw == null
        ? []
        : (jsonDecode(raw) as List).map((e) => OutboxItem.fromJson(Map<String, dynamic>.from(e))).toList();
    notifyListeners();
    _conn?.cancel();
    try {
      _conn = (_connStream ?? Connectivity().onConnectivityChanged).listen((r) {
        if (r.any((x) => x != ConnectivityResult.none)) sync();
      });
    } catch (_) {}
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (pendingCount > 0) sync();
    });
    if (pendingCount > 0) unawaited(sync());
  }

  Future<void> _persist() async => _prefs?.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));

  /// Guarda el reporte en el teléfono e intenta enviarlo. Devuelve true si ya llegó al servidor.
  Future<bool> saveReport({
    DailyReport? existing,
    required Assignment assignment,
    required DateTime date,
    required int units,
    double? hours,
    required bool helperPresent,
    String? notes,
    double downtimeHours = 0,
    String? downtimeReason,
  }) async {
    final payload = <String, dynamic>{
      'assignment_id': assignment.id,
      'project_id': assignment.projectId,
      'machine_id': assignment.machineId,
      'report_date': dateKey(date),
      'units_done': units,
      'hours_worked': hours,
      'helper_present': helperPresent,
      'notes': notes,
      'downtime_hours': downtimeHours,
      'downtime_reason': downtimeHours > 0 ? downtimeReason : null,
      // Solo para mostrarlo mientras está pendiente; el servidor recalcula el pago.
      'operator_pay': assignment.operatorDailyPay,
      'helper_pay': assignment.helperId != null && helperPresent ? assignment.helperDailyPay : 0,
    };
    OutboxItem? item;
    if (existing != null) {
      item = items.where((i) => i.id == existing.id).firstOrNull;
    }
    item ??= items.where((i) => i.kind == 'report' && i.op == 'insert' && i.reportKey == '${assignment.id}|${dateKey(date)}').firstOrNull;
    if (item != null) {
      item.payload = payload; // corrige lo que aún no se envía
      item.error = null;
    } else {
      item = OutboxItem(
        id: existing?.id ?? newId(),
        kind: 'report',
        op: existing == null ? 'insert' : 'update',
        payload: payload,
      );
      items.add(item);
    }
    await _persist();
    notifyListeners();
    await sync();
    return !items.any((i) => i.id == item!.id);
  }

  Future<bool> addMaintenance({
    required String machineId,
    String? projectId,
    required DateTime date,
    required String type,
    required String description,
    double? hourMeter,
    double cost = 0,
  }) async {
    final item = OutboxItem(id: newId(), kind: 'maintenance', op: 'insert', payload: {
      'machine_id': machineId,
      'project_id': projectId,
      'log_date': dateKey(date),
      'type': type,
      'description': description,
      'hour_meter': hourMeter,
      'cost': cost,
    });
    items.add(item);
    await _persist();
    notifyListeners();
    await sync();
    return !items.any((i) => i.id == item.id);
  }

  Future<void>? _running;
  bool _again = false;

  /// Envía en orden lo pendiente. Si no hay señal se detiene y lo intenta más tarde.
  /// Si se pide de nuevo mientras está enviando, da otra vuelta al terminar.
  Future<void> sync() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _syncLoop().whenComplete(() => _running = null);
  }

  Future<void> _syncLoop() async {
    syncing = true;
    notifyListeners();
    try {
      do {
        _again = false;
        await _syncOnce();
      } while (_again);
    } finally {
      syncing = false;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> _syncOnce() async {
    var sentAny = false;
    for (final it in List.of(items)) {
      if (it.error != null || !items.contains(it)) continue;
      try {
        await _sender(it);
        items.remove(it);
        online = true;
        sentAny = true;
      } catch (e) {
        if (isNetworkError(e)) {
          online = false;
          return;
        }
        it.error = friendlyError(e);
      }
    }
    if (items.every((i) => i.error != null)) online = true;
    if (sentAny) lastSync = DateTime.now();
  }

  Future<void> retry(OutboxItem it) async {
    it.error = null;
    await _persist();
    await sync();
  }

  Future<void> discard(OutboxItem it) async {
    items.remove(it);
    await _persist();
    notifyListeners();
  }

  List<DailyReport> pendingReports() => [
        for (final i in items.where((i) => i.kind == 'report'))
          DailyReport.fromMap({...i.payload, 'id': i.id}, pending: true),
      ];

  List<MaintenanceLog> pendingMaintenance() => [
        for (final i in items.where((i) => i.kind == 'maintenance'))
          MaintenanceLog.fromMap({...i.payload, 'id': i.id}, pending: true),
      ];

  /// Une lo del servidor con lo pendiente (lo pendiente gana).
  List<DailyReport> mergeReports(List<DailyReport> server) {
    final pend = pendingReports();
    final ids = pend.map((r) => r.id).toSet();
    final keys = pend.map((r) => '${r.assignmentId}|${dateKey(r.date)}').toSet();
    final out = [
      ...server.where((r) => !ids.contains(r.id) && !keys.contains('${r.assignmentId}|${dateKey(r.date)}')),
      ...pend,
    ]..sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  @override
  void dispose() {
    _conn?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}

// ------------------------------------------------------------------ caché de lectura
class LocalCache {
  static Future<void> put(String key, Object value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('orvexa_cache_$key', jsonEncode({'at': DateTime.now().toIso8601String(), 'v': value}));
  }

  static Future<(dynamic, DateTime)?> get(String key) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('orvexa_cache_$key');
    if (s == null) return null;
    final m = jsonDecode(s);
    return (m['v'], DateTime.tryParse(m['at'] ?? '') ?? DateTime.now());
  }
}

/// Para depurar en consola.
void logOutbox(String msg) {
  if (kDebugMode) debugPrint('[outbox] $msg');
}
