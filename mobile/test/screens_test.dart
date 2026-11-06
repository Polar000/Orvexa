// Renderiza las pantallas principales con datos de ejemplo en tamaño de teléfono.
// Falla si algún texto se desborda. Genera capturas con: flutter test --update-goldens test/screens_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orvexa_app/calc.dart';
import 'package:orvexa_app/data.dart';
import 'package:orvexa_app/models.dart';
import 'package:orvexa_app/screens/admin/admin_shell.dart';
import 'package:orvexa_app/screens/admin/project_detail.dart';
import 'package:orvexa_app/screens/operator/operator_home.dart';
import 'package:orvexa_app/screens/operator/report_form.dart';
import 'package:orvexa_app/theme.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File(f).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Profile _p(String id, String name, UserRole r) => Profile(id: id, fullName: name, username: id, role: r, active: true);

AdminData demo() {
  final today = dayOnly(DateTime.now());
  final profiles = [
    _p('adm', 'Bryan Martínez', UserRole.admin),
    _p('op1', 'Juan Pérez', UserRole.operador),
    _p('op2', 'Carlos López', UserRole.operador),
    _p('op3', 'Mario García', UserRole.operador),
    _p('ay1', 'Pedro Gómez', UserRole.ayudante),
    _p('ay2', 'Luis Hernández', UserRole.ayudante),
  ];
  final machines = [
    Machine(id: 'm1', name: 'Hincadora HWL600R #1', code: 'HWL-01', type: 'hincadora', status: 'en_proyecto', operatorDailyPay: 40, helperDailyPay: 25, hourMeter: 1250),
    Machine(id: 'm2', name: 'Hincadora HWL600R #2', code: 'HWL-02', type: 'hincadora', status: 'en_proyecto', operatorDailyPay: 40, helperDailyPay: 25),
    Machine(id: 'm3', name: 'Bobcat S650', code: 'BC-01', type: 'bobcat', status: 'en_proyecto', operatorDailyPay: 35, helperDailyPay: 0),
    Machine(id: 'm4', name: 'Hincadora PD-10', type: 'hincadora', status: 'mantenimiento', operatorDailyPay: 38, helperDailyPay: 22),
  ];
  final projects = [
    Project(id: 'p1', name: 'Parque Solar Escuintla F2', client: 'SolarGT S.A.', location: 'Masagua, Escuintla', type: 'hincado', status: 'activo', billingMode: 'por_unidad', totalUnits: 24000, dailyTarget: 400, pricePerUnit: 18.5, dailyRate: 0, startDate: today.subtract(const Duration(days: 40)), workDaysPerWeek: 6),
    Project(id: 'p2', name: 'Nivelación Planta Norte', client: 'Constructora Atlas', type: 'bobcat', status: 'activo', billingMode: 'por_dia', totalUnits: 0, dailyTarget: 0, pricePerUnit: 0, dailyRate: 320, startDate: today.subtract(const Duration(days: 12)), workDaysPerWeek: 6),
    Project(id: 'p3', name: 'Solar Jutiapa 30MW', client: 'Energía Verde', type: 'hincado', status: 'planificado', billingMode: 'por_unidad', totalUnits: 15000, dailyTarget: 200, pricePerUnit: 22, dailyRate: 0, startDate: today.add(const Duration(days: 20)), workDaysPerWeek: 6),
  ];
  final assignments = [
    Assignment(id: 'a1', projectId: 'p1', machineId: 'm1', operatorId: 'op1', helperId: 'ay1', operatorDailyPay: 40, helperDailyPay: 25, dailyTarget: 200, startDate: projects[0].startDate!, active: true),
    Assignment(id: 'a2', projectId: 'p1', machineId: 'm2', operatorId: 'op2', helperId: 'ay2', operatorDailyPay: 40, helperDailyPay: 25, dailyTarget: 200, startDate: projects[0].startDate!, active: true),
    Assignment(id: 'a3', projectId: 'p2', machineId: 'm3', operatorId: 'op3', operatorDailyPay: 35, helperDailyPay: 0, startDate: projects[1].startDate!, active: true),
  ];
  final reports = <DailyReport>[];
  var n = 0;
  for (var i = 1; i <= 40; i++) {
    final d = today.subtract(Duration(days: i));
    if (d.weekday == 7) continue;
    for (final a in assignments.take(2)) {
      final u = 170 + ((i * 37 + a.id.hashCode) % 60);
      reports.add(DailyReport(id: '${n++}', assignmentId: a.id, projectId: 'p1', machineId: a.machineId, operatorId: a.operatorId, date: d, units: u, hours: 9, helperPresent: i % 9 != 0, operatorPay: 40, helperPay: i % 9 != 0 ? 25 : 0));
    }
    if (i <= 12) {
      reports.add(DailyReport(id: '${n++}', assignmentId: 'a3', projectId: 'p2', machineId: 'm3', operatorId: 'op3', date: d, units: 0, hours: 8, helperPresent: false, operatorPay: 35, helperPay: 0));
    }
  }
  reports.add(DailyReport(id: '${n++}', assignmentId: 'a1', projectId: 'p1', machineId: 'm1', operatorId: 'op1', date: today, units: 215, hours: 9, helperPresent: true, operatorPay: 40, helperPay: 25, notes: 'Terreno duro en fila 14'));
  final expenses = [
    Expense(id: 'e1', category: 'renta', description: 'Renta de bodega', amount: 1200, recurrence: 'mensual', dueDate: DateTime(today.year, today.month + 1, 5), startDate: DateTime(2026, 1, 5), paid: false),
    Expense(id: 'e2', category: 'seguro', description: 'Seguro de flota', amount: 650, recurrence: 'mensual', dueDate: today.subtract(const Duration(days: 2)), startDate: DateTime(2026, 1, 1), paid: false),
    Expense(id: 'e3', category: 'combustible', description: 'Diésel', amount: 900, recurrence: 'semanal', dueDate: today.add(const Duration(days: 3)), startDate: DateTime(2026, 6, 1), paid: false),
    Expense(id: 'e4', category: 'impuesto', description: 'ISR trimestral', amount: 3000, recurrence: 'unica', dueDate: DateTime(today.year, today.month + 1, 20), startDate: DateTime(today.year, today.month + 1, 20), paid: false),
  ];
  final maint = [
    MaintenanceLog(id: 'x1', machineId: 'm1', projectId: 'p1', reportedBy: 'op1', date: today.subtract(const Duration(days: 3)), type: 'cambio_aceite', description: 'Aceite 15W40 y filtro', hourMeter: 1250, cost: 180),
  ];
  return AdminData(
    profiles: profiles,
    machines: machines,
    projects: projects,
    assignments: assignments,
    reports: reports,
    maintenance: maint,
    expenses: expenses,
    settings: CompanySettings(incomeTaxPct: 5, employerSocialPct: 12.67),
  );
}

Widget app(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: orvexaTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

void main() {
  setUpAll(() async {
    useGoogleFonts = false;
    await initializeDateFormatting('es');
    const r = '/opt/flutter/bin/cache/artifacts/material_fonts';
    await _loadFont('TestSans', ['$r/Roboto-Regular.ttf', '$r/Roboto-Medium.ttf', '$r/Roboto-Bold.ttf', '$r/Roboto-Black.ttf']);
    await _loadFont('MaterialIcons', ['$r/MaterialIcons-Regular.otf']);
  });

  Future<void> phone(WidgetTester t, {double h = 844}) async {
    t.view.physicalSize = Size(390 * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
  }

  testWidgets('admin: todas las pestañas', (t) async {
    await phone(t, h: 1700);
    final store = AdminStore()..data = demo();
    await t.pumpWidget(app(AdminShell(me: demo().profiles.first, store: store)));
    await t.pumpAndSettle();
    const names = ['panel', 'proyectos', 'maquinas', 'personal', 'finanzas'];
    final labels = ['Panel', 'Proyectos', 'Máquinas', 'Personal', 'Finanzas'];
    for (var i = 0; i < names.length; i++) {
      await t.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(labels[i])));
      await t.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/admin_${i}_${names[i]}.png'));
    }
  });

  testWidgets('admin: detalle de proyecto', (t) async {
    await phone(t, h: 2000);
    final store = AdminStore()..data = demo();
    await t.pumpWidget(app(ProjectDetail(store: store, projectId: 'p1')));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/admin_5_proyecto.png'));
  });

  testWidgets('operador: inicio y reporte', (t) async {
    await phone(t, h: 900);
    final d = demo();
    Future<OperatorData> loader(String _) async => OperatorData(
          assignments: [d.assignments.first],
          projects: {'p1': d.projects.first},
          machines: {'m1': d.machines.first},
          reports: d.reports.where((r) => r.assignmentId == 'a1').toList(),
          maintenance: d.maintenance,
          people: {'a1': ('Juan Pérez', 'Pedro Gómez')},
        );
    await t.pumpWidget(app(OperatorHome(me: d.profiles[1], loader: loader)));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/operador_1_hoy.png'));
    await t.tap(find.text('Historial'));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/operador_2_historial.png'));

    await t.pumpWidget(app(ReportForm(
      assignment: d.assignments.first,
      project: d.projects.first,
      machine: d.machines.first,
      helperName: 'Pedro Gómez',
      date: DateTime.now(),
    )));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField).first, '185');
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/operador_3_reporte.png'));
  });
}
