import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orvexa_app/calc.dart';
import 'package:orvexa_app/data.dart';
import 'package:orvexa_app/models.dart';
import 'package:orvexa_app/offline.dart';
import 'package:shared_preferences/shared_preferences.dart';

final asg = Assignment(
  id: 'a1',
  projectId: 'p1',
  machineId: 'm1',
  operatorId: 'op1',
  helperId: 'h1',
  operatorDailyPay: 300,
  helperDailyPay: 180,
  startDate: DateTime(2026, 11, 2),
  active: true,
);

/// Servidor falso: puede estar sin señal, rechazar, o aceptar.
class FakeServer {
  bool online = false;
  final sent = <OutboxItem>[];
  String? rejectKind;
  Future<void> send(OutboxItem it) async {
    if (!online) throw Exception('ClientException with SocketException: Failed host lookup');
    if (rejectKind == it.kind) throw AppError('No tienes permiso para esta acción');
    sent.add(OutboxItem.fromJson(it.toJson()));
  }
}

void main() {
  late FakeServer server;
  late StreamController<List<ConnectivityResult>> conn;
  Outbox make() => Outbox(sender: server.send, connectivity: conn.stream);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    server = FakeServer();
    conn = StreamController.broadcast();
  });

  test('sin señal: el reporte queda guardado en el teléfono', () async {
    final o = make();
    await o.init('op1');
    final sent = await o.saveReport(assignment: asg, date: DateTime(2026, 11, 6), units: 210, helperPresent: true);
    expect(sent, false);
    expect(o.online, false);
    expect(o.pendingCount, 1);
    expect(server.sent, isEmpty);
    final pend = o.pendingReports().single;
    expect(pend.units, 210);
    expect(pend.pending, true);
    expect(pend.operatorPay, 300); // se muestra el pago mientras está pendiente
  });

  test('vuelve la señal: se envía solo y se vacía la cola', () async {
    final o = make();
    await o.init('op1');
    await o.saveReport(assignment: asg, date: DateTime(2026, 11, 6), units: 210, helperPresent: true);
    await o.addMaintenance(
      machineId: 'm1',
      date: DateTime(2026, 11, 6),
      type: 'engrase',
      description: 'Engrase general',
    );
    expect(o.pendingCount, 2);
    server.online = true;
    conn.add([ConnectivityResult.mobile]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    while (o.syncing) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(o.pendingCount, 0);
    expect(o.online, true);
    expect(server.sent.map((e) => e.kind), ['report', 'maintenance']); // en el orden en que se hicieron
  });

  test('corregir un reporte que aún no se envía no lo duplica', () async {
    final o = make();
    await o.init('op1');
    await o.saveReport(assignment: asg, date: DateTime(2026, 11, 6), units: 150, helperPresent: true);
    final pending = o.pendingReports().single;
    await o.saveReport(
      existing: pending,
      assignment: asg,
      date: DateTime(2026, 11, 6),
      units: 205,
      helperPresent: false,
      downtimeHours: 2,
      downtimeReason: 'lluvia',
    );
    expect(o.items.length, 1);
    final r = o.pendingReports().single;
    expect(r.units, 205);
    expect(r.helperPay, 0);
    expect(r.downtimeHours, 2);
    expect(r.downtimeReason, 'lluvia');
    server.online = true;
    await o.sync();
    expect(server.sent.single.op, 'insert');
    expect(server.sent.single.payload['units_done'], 205);
  });

  test('los pendientes sobreviven si se cierra la app', () async {
    final o1 = make();
    await o1.init('op1');
    await o1.saveReport(assignment: asg, date: DateTime(2026, 11, 5), units: 190, helperPresent: true);
    final id = o1.items.single.id;
    final o2 = make(); // "se reabre la app"
    await o2.init('op1');
    expect(o2.items.single.id, id);
    server.online = true;
    await o2.sync();
    expect(server.sent.single.id, id); // mismo id: si se reintenta no se duplica en el servidor
  });

  test('cada usuario tiene su propia cola', () async {
    final o1 = make();
    await o1.init('op1');
    await o1.saveReport(assignment: asg, date: DateTime(2026, 11, 5), units: 190, helperPresent: true);
    final o2 = make();
    await o2.init('otro');
    expect(o2.items, isEmpty);
  });

  test('si el servidor rechaza un registro, los demás siguen enviándose', () async {
    final o = make();
    await o.init('op1');
    await o.addMaintenance(machineId: 'm1', date: DateTime(2026, 11, 6), type: 'otro', description: 'x');
    await o.saveReport(assignment: asg, date: DateTime(2026, 11, 6), units: 200, helperPresent: true);
    server.online = true;
    server.rejectKind = 'maintenance';
    await o.sync();
    expect(server.sent.single.kind, 'report');
    expect(o.failed.single.kind, 'maintenance');
    expect(o.failed.single.error, contains('permiso'));
    expect(o.pendingCount, 0);
    await o.discard(o.failed.single);
    expect(o.items, isEmpty);
  });

  test('corregir un reporte que ya está en el servidor manda una actualización', () async {
    final o = make();
    await o.init('op1');
    final serverReport = DailyReport(
      id: 'srv-1',
      assignmentId: 'a1',
      projectId: 'p1',
      machineId: 'm1',
      date: DateTime(2026, 11, 6),
      units: 180,
      helperPresent: true,
      operatorPay: 300,
      helperPay: 180,
    );
    await o.saveReport(
      existing: serverReport,
      assignment: asg,
      date: DateTime(2026, 11, 6),
      units: 220,
      helperPresent: true,
    );
    expect(o.items.single.op, 'update');
    expect(o.items.single.id, 'srv-1');
    final merged = o.mergeReports([serverReport]);
    expect(merged.single.units, 220);
    expect(merged.single.pending, true);
  });

  test('detecta errores de señal vs. errores de datos', () {
    expect(isNetworkError(Exception('SocketException: Failed host lookup')), true);
    expect(isNetworkError(TimeoutException('x')), true);
    expect(isNetworkError(AppError('permiso')), false);
  });

  test('resumen de paros por motivo', () {
    DailyReport rep(int day, int units, double h, String? reason) => DailyReport(
      id: '$day',
      assignmentId: 'a1',
      projectId: 'p1',
      machineId: 'm1',
      date: DateTime(2026, 11, day),
      units: units,
      helperPresent: true,
      operatorPay: 0,
      helperPay: 0,
      downtimeHours: h,
      downtimeReason: reason,
    );
    final s = downtimeSummary([
      rep(2, 200, 0, null),
      rep(3, 0, 9, 'lluvia'),
      rep(4, 120, 3, 'lluvia'),
      rep(5, 150, 4, 'cliente'),
      rep(6, 100, 2, 'falta_material'),
    ]);
    expect(s.totalHours, 18);
    expect(s.totalDays, 4);
    expect(s.top!.reason, 'lluvia');
    expect(s.top!.hours, 12);
    expect(s.top!.zeroDays, 1);
    expect(s.clientHours, 6);
  });

  test('combustible y fotos esperan sin señal; la ruta de la foto no cambia al corregir', () async {
    final o = make();
    await o.init('op1');
    final sent = await o.addFuel(
      machineId: 'm1',
      projectId: 'p1',
      date: DateTime(2026, 11, 6),
      gallons: 15,
      costGtq: 540,
      localPhotos: ['/tel/ticket.jpg'],
    );
    expect(sent, false);
    final fuel = o.pendingFuel().single;
    expect(fuel.gallons, 15);
    expect(fuel.localPhotos, ['/tel/ticket.jpg']);
    final pend = (o.items.single.payload['_photos_pending'] as List).single as Map;
    expect(pend['remote'], startsWith('f/m1/${o.items.single.id}-'));

    await o.saveReport(
      assignment: asg,
      date: DateTime(2026, 11, 6),
      units: 200,
      helperPresent: true,
      localPhotos: ['/tel/a.jpg'],
    );
    final first = ((o.items.last.payload['_photos_pending'] as List).single as Map)['remote'];
    final pr = o.pendingReports().single;
    await o.saveReport(
      existing: pr,
      assignment: asg,
      date: DateTime(2026, 11, 6),
      units: 210,
      helperPresent: true,
      localPhotos: [...pr.localPhotos, '/tel/b.jpg'],
      hourMeter: 1250,
    );
    final photos = (o.items.last.payload['_photos_pending'] as List).cast<Map>();
    expect(photos.length, 2);
    expect(photos.first['remote'], first); // misma ruta: si ya se subió no se duplica
    expect(photos.first['remote'], startsWith('r/a1/'));
    expect(o.pendingReports().single.hourMeter, 1250);
    server.online = true;
    await o.sync();
    expect(server.sent.map((e) => e.kind), ['fuel', 'report']);
  });
}
