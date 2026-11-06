import 'package:flutter_test/flutter_test.dart';
import 'package:orvexa_app/calc.dart';
import 'package:orvexa_app/models.dart';

Project proj({
  int total = 10000,
  int target = 200,
  double price = 20,
  DateTime? start,
  int wd = 6,
  String billing = 'por_unidad',
  double rate = 0,
}) => Project(
  id: 'p1',
  name: 'Parque Solar',
  type: 'hincado',
  status: 'activo',
  billingMode: billing,
  totalUnits: total,
  dailyTarget: target,
  pricePerUnit: price,
  dailyRate: rate,
  startDate: start ?? DateTime(2026, 11, 2), // lunes
  workDaysPerWeek: wd,
);

Assignment asg({String id = 'a1', bool helper = true}) => Assignment(
  id: id,
  projectId: 'p1',
  machineId: 'm1',
  operatorId: 'op1',
  helperId: helper ? 'h1' : null,
  operatorDailyPay: 40,
  helperDailyPay: 25,
  startDate: DateTime(2026, 11, 2),
  active: true,
);

DailyReport rep(DateTime d, int units, {bool helper = true, double fx = 1}) => DailyReport(
  id: '${d.day}',
  assignmentId: 'a1',
  projectId: 'p1',
  machineId: 'm1',
  operatorId: 'op1',
  date: d,
  units: units,
  helperPresent: helper,
  operatorPay: 40,
  helperPay: helper ? 25 : 0,
  fxRate: fx,
);

Expense exp(String rec, DateTime due, {double amount = 100, String cat = 'renta', DateTime? start}) => Expense(
  id: 'e',
  category: cat,
  description: 'x',
  amount: amount,
  recurrence: rec,
  dueDate: due,
  startDate: start ?? due,
  paid: false,
);

void main() {
  test('días laborales saltan domingo con 6 días/semana', () {
    // lun 2 nov + 6 días laborales = sáb 7 nov; el 7º es lun 9 (salta domingo 8)
    expect(addWorkDays(DateTime(2026, 11, 2), 6, 6), DateTime(2026, 11, 7));
    expect(addWorkDays(DateTime(2026, 11, 2), 7, 6), DateTime(2026, 11, 9));
    expect(addWorkDays(DateTime(2026, 11, 2), 6, 5), DateTime(2026, 11, 9));
    expect(workDaysInRange(DateTime(2026, 11, 1), DateTime(2026, 11, 30), 6), 25);
  });

  test('10,000 incas a 200/día = 50 días, contrato a \$20 = \$200,000', () {
    final st = projectStats(proj(), [], [asg()], [], usdToGtq: 1);
    expect(st.plannedDaysTotal, 50);
    expect(st.contractValue, 200000);
    // 50 días laborales de lun-sáb desde lun 2 nov
    expect(st.plannedEnd, addWorkDays(DateTime(2026, 11, 2), 50, 6));
  });

  test('avance, ingresos, planilla y proyección', () {
    final reports = [
      rep(DateTime(2026, 11, 2), 180),
      rep(DateTime(2026, 11, 3), 210),
      rep(DateTime(2026, 11, 4), 210, helper: false),
    ];
    final st = projectStats(proj(), reports, [asg()], [], usdToGtq: 1);
    expect(st.unitsDone, 600);
    expect(st.revenue, 600 * 20);
    expect(st.labor, 40 + 25 + 40 + 25 + 40); // ayudante faltó el 4
    expect(st.remainingUnits, 9400);
    expect(st.recentPace, 200);
    expect(st.daysRemainingByPace, 47);
    expect(st.remainingRevenue, 9400 * 20);
    expect(st.remainingLabor, 47 * 65);
    expect(st.projectedProfit, closeTo(12000 - 170 + 188000 - 47 * 65, 0.001));
  });

  test('cobro por día (bobcat)', () {
    final p = proj(billing: 'por_dia', rate: 350, total: 0, target: 0);
    final st = projectStats(
      p,
      [rep(DateTime(2026, 11, 2), 0), rep(DateTime(2026, 11, 3), 0)],
      [asg(helper: false)],
      [],
    );
    expect(st.revenue, 700);
  });

  test('obligaciones por mes', () {
    final nov = DateTime(2026, 11, 1);
    expect(expenseInMonth(exp('mensual', DateTime(2026, 10, 15)), nov), 100);
    expect(expenseInMonth(exp('mensual', DateTime(2026, 12, 15)), nov), 0);
    // mensual ya pagada: el próximo vencimiento avanzó pero sigue contando desde su inicio
    expect(expenseInMonth(exp('mensual', DateTime(2026, 12, 15), start: DateTime(2026, 9, 15)), nov), 100);
    expect(expenseInMonth(exp('unica', DateTime(2026, 11, 20)), nov), 100);
    expect(expenseInMonth(exp('unica', DateTime(2026, 10, 20)), nov), 0);
    expect(expenseInMonth(exp('anual', DateTime(2025, 11, 5)), nov), 100);
    expect(expenseInMonth(exp('anual', DateTime(2025, 10, 5)), nov), 0);
    // semanal desde lun 2 nov: 2, 9, 16, 23, 30 = 5 pagos
    expect(expenseInMonth(exp('semanal', DateTime(2026, 11, 2)), nov), 500);
    expect(expenseInMonth(exp('semanal', DateTime(2026, 10, 26)), nov), 500);
  });

  test('mes real con impuestos y carga patronal', () {
    final s = CompanySettings(incomeTaxPct: 5, employerSocialPct: 10);
    final m = actualMonth(
      DateTime(2026, 11, 1),
      [proj()],
      [rep(DateTime(2026, 11, 2), 200)],
      [
        MaintenanceLog(
          id: 'x',
          machineId: 'm1',
          date: DateTime(2026, 11, 3),
          type: 'engrase',
          description: '',
          cost: 30,
        ),
      ],
      [
        exp('mensual', DateTime(2026, 11, 1), amount: 500),
        exp('unica', DateTime(2026, 11, 10), amount: 200, cat: 'impuesto'),
      ],
      s,
    );
    expect(m.revenue, 4000);
    expect(m.labor, closeTo(65 * 1.1, 0.001));
    expect(m.maintenance, 30);
    expect(m.fixed, 500);
    expect(m.taxes, 200 + 200); // 5% de 4000 + impuesto registrado
    expect(m.profit, closeTo(4000 - 71.5 - 30 - 500 - 400, 0.001));
  });

  test('proyección se detiene al completar las incas', () {
    final s = CompanySettings(incomeTaxPct: 0, employerSocialPct: 0);
    final p = proj(total: 2000, target: 200, start: DateTime(2026, 11, 9));
    final st = projectStats(p, [], [asg()], [], usdToGtq: 1);
    final months = projectMonths(DateTime(2026, 11, 6), 3, [st], [], s);
    final totalRevenue = months.fold<double>(0, (a, m) => a + m.revenue);
    expect(totalRevenue, 2000 * 20);
    expect(months.fold<double>(0, (a, m) => a + m.labor), 10 * 65);
    expect(months[1].revenue, 0); // termina en noviembre
  });

  test('planilla por persona', () {
    final lines = payroll(
      [rep(DateTime(2026, 11, 2), 100), rep(DateTime(2026, 11, 3), 100, helper: false)],
      [asg()],
      DateTime(2026, 11, 1),
      DateTime(2026, 11, 30),
    );
    expect(lines['op1']!.days, 2);
    expect(lines['op1']!.amount, 80);
    expect(lines['h1']!.days, 1);
    expect(lines['h1']!.amount, 25);
  });

  test('planilla en quetzales se convierte a dólares con el tipo de cambio del reporte', () {
    // Operador Q300 + ayudante Q182 = Q482 a 7.64 → $63.09
    final r = DailyReport(
      id: 'r',
      assignmentId: 'a1',
      projectId: 'p1',
      machineId: 'm1',
      date: DateTime(2026, 11, 2),
      units: 200,
      helperPresent: true,
      operatorPay: 300,
      helperPay: 182,
      fxRate: 7.64,
    );
    expect(r.labor, 482);
    expect(r.laborUsd, closeTo(63.089, 0.001));
    final a = Assignment(
      id: 'a1',
      projectId: 'p1',
      machineId: 'm1',
      operatorId: 'op1',
      helperId: 'h1',
      operatorDailyPay: 300,
      helperDailyPay: 182,
      startDate: DateTime(2026, 11, 2),
      active: true,
    );
    final st = projectStats(proj(), [r], [a], [], usdToGtq: 7.64);
    expect(st.labor, closeTo(63.089, 0.001));
    expect(st.laborGtq, 482);
    expect(st.activeDailyLabor, closeTo(63.089, 0.001));
    final m = actualMonth(
      DateTime(2026, 11, 1),
      [proj()],
      [r],
      [],
      [],
      CompanySettings(incomeTaxPct: 0, employerSocialPct: 0, usdToGtq: 8),
    );
    expect(m.labor, closeTo(63.089, 0.001)); // usa el tipo de cambio guardado en el reporte, no el actual
  });

  test('mantenimiento por horómetro: ok, pronto y vencido', () {
    final m = {
      'm1': Machine(
        id: 'm1',
        name: 'M',
        type: 'hincadora',
        status: 'en_proyecto',
        operatorDailyPay: 0,
        helperDailyPay: 0,
        hourMeter: 1130,
      ),
    };
    MaintenancePlan plan(double last, double every) => MaintenancePlan(
      id: 'x',
      machineId: 'm1',
      type: 'cambio_aceite',
      label: 'Aceite',
      intervalHours: every,
      lastDoneHours: last,
    );
    expect(PlanStatus(plan(1000, 250), 1130).state, PlanState.ok); // faltan 120
    expect(PlanStatus(plan(900, 250), 1130).state, PlanState.soon); // faltan 20
    expect(PlanStatus(plan(850, 250), 1130).state, PlanState.overdue); // pasado 30
    expect(PlanStatus(plan(850, 250), 1130).text, contains('vencido por 30 h'));
    expect(PlanStatus(plan(0, 1000), 1130).state, PlanState.overdue);
    final st = planStatuses([plan(1000, 250), plan(850, 250)], m);
    expect(st.first.state, PlanState.overdue); // ordenado por urgencia
  });

  test('vista previa de planilla = cierre del servidor', () {
    final a = Assignment(
      id: 'a1',
      projectId: 'p1',
      machineId: 'm1',
      operatorId: 'op',
      helperId: 'ay',
      operatorDailyPay: 300,
      helperDailyPay: 180,
      startDate: DateTime(2026, 11, 1),
      active: true,
    );
    DailyReport r(int day, {bool helper = true, bool paid = true}) => DailyReport(
      id: '$day',
      assignmentId: 'a1',
      projectId: 'p1',
      machineId: 'm1',
      operatorId: 'op',
      date: DateTime(2026, 11, day),
      units: 200,
      helperPresent: helper,
      operatorPay: paid ? 300 : 0,
      helperPay: paid && helper ? 180 : 0,
      payDay: paid,
    );
    final adj = [
      PayrollAdjustment(id: '1', personId: 'op', date: DateTime(2026, 11, 4), kind: 'adelanto', amount: 200),
      PayrollAdjustment(id: '2', personId: 'ay', date: DateTime(2026, 11, 5), kind: 'bono', amount: 50),
      PayrollAdjustment(id: '3', personId: 'op', date: DateTime(2026, 12, 1), kind: 'descuento', amount: 99), // fuera
    ];
    final lines = payrollPreview(
      [r(2), r(3, helper: false), r(6, paid: false)],
      [a],
      adj,
      DateTime(2026, 11, 1),
      DateTime(2026, 11, 15),
    );
    final op = lines.firstWhere((l) => l.personId == 'op');
    final ay = lines.firstWhere((l) => l.personId == 'ay');
    expect(op.days, 2); // el día no pagado no cuenta
    expect(op.net, 400); // 2 × 300 − 200
    expect(ay.days, 1);
    expect(ay.net, 230); // 180 + 50
  });

  test('quincenas', () {
    expect(quincenaOf(DateTime(2026, 11, 6)), (DateTime(2026, 11, 1), DateTime(2026, 11, 15)));
    expect(quincenaOf(DateTime(2026, 11, 20)), (DateTime(2026, 11, 16), DateTime(2026, 11, 30)));
    expect(quincenaOf(DateTime(2026, 2, 28)).$2, DateTime(2026, 2, 28));
  });

  test('combustible entra en costos del mes y del proyecto', () {
    final f = FuelLog(
      id: 'f',
      machineId: 'm1',
      projectId: 'p1',
      date: DateTime(2026, 11, 3),
      gallons: 20,
      costGtq: 764,
      fxRate: 7.64,
    );
    expect(f.costUsd, closeTo(100, 0.001));
    final m = actualMonth(
      DateTime(2026, 11, 1),
      [proj()],
      [rep(DateTime(2026, 11, 2), 200)],
      [],
      [],
      CompanySettings(incomeTaxPct: 0, employerSocialPct: 0),
      fuel: [f],
    );
    expect(m.fuel, closeTo(100, 0.001));
    expect(m.costs, closeTo(65 + 100, 0.001));
    final st = projectStats(proj(), [rep(DateTime(2026, 11, 2), 200)], [asg()], [], usdToGtq: 1, fuel: [f]);
    expect(st.fuel, closeTo(100, 0.001));
    expect(st.costPerUnit, closeTo((65 + 100) / 200, 0.0001));
  });
}
