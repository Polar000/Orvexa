// Cálculos de avance, finanzas y proyecciones (funciones puras, probadas en test/).
import 'models.dart';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// ¿Se trabaja ese día? 7 = todos; 6 = descansa domingo; 5 = descansa sábado y domingo;
/// menos de 5 = trabaja de lunes en adelante.
bool isWorkDay(DateTime d, int workDaysPerWeek) => d.weekday <= workDaysPerWeek.clamp(1, 7);

/// Fecha en que se cumplen [days] días laborales empezando en [start] (inclusive).
DateTime addWorkDays(DateTime start, int days, int workDaysPerWeek) {
  var d = dayOnly(start);
  if (days <= 0) return d;
  var counted = 0;
  while (true) {
    if (isWorkDay(d, workDaysPerWeek)) {
      counted++;
      if (counted >= days) return d;
    }
    d = d.add(const Duration(days: 1));
  }
}

int workDaysInRange(DateTime from, DateTime toInclusive, int workDaysPerWeek) {
  var d = dayOnly(from);
  final end = dayOnly(toInclusive);
  var n = 0;
  while (!d.isAfter(end)) {
    if (isWorkDay(d, workDaysPerWeek)) n++;
    d = d.add(const Duration(days: 1));
  }
  return n;
}

/// Ingreso que genera un reporte diario según cómo se cobra el proyecto.
double reportRevenue(DailyReport r, Project p) => p.perUnit ? r.units * p.pricePerUnit : p.dailyRate;

class ProjectStats {
  final Project project;
  final int unitsDone;
  final int reportDays;
  final double revenue;
  final double labor; // US$ (convertido al tipo de cambio de cada reporte)
  final double laborGtq; // Q pagados
  final double maintenance;
  final double fuel; // US$
  final double fuelGallons;
  final double recentPace; // promedio diario de los últimos 7 días con reporte
  final double activeDailyLabor; // US$ por día de las asignaciones activas
  final int activeMachines;

  ProjectStats({
    required this.project,
    required this.unitsDone,
    required this.reportDays,
    required this.revenue,
    required this.labor,
    this.laborGtq = 0,
    required this.maintenance,
    this.fuel = 0,
    this.fuelGallons = 0,
    required this.recentPace,
    required this.activeDailyLabor,
    required this.activeMachines,
  });

  int get remainingUnits => (project.totalUnits - unitsDone).clamp(0, 1 << 31);
  double get progress => project.totalUnits <= 0 ? 0 : (unitsDone / project.totalUnits).clamp(0, 1).toDouble();

  /// Meta diaria total: la del proyecto (ya es del proyecto completo).
  int get plannedDaysTotal => project.dailyTarget <= 0 ? 0 : (project.totalUnits / project.dailyTarget).ceil();

  int get daysRemainingByTarget => project.dailyTarget <= 0 ? 0 : (remainingUnits / project.dailyTarget).ceil();

  int? get daysRemainingByPace => recentPace <= 0 ? null : (remainingUnits / recentPace).ceil();

  DateTime? get plannedEnd => project.startDate == null || plannedDaysTotal == 0
      ? null
      : addWorkDays(project.startDate!, plannedDaysTotal, project.workDaysPerWeek);

  DateTime? estimatedEnd(DateTime today) {
    if (remainingUnits == 0) return null;
    final days = daysRemainingByPace ?? daysRemainingByTarget;
    if (days == 0) return null;
    final from = project.startDate != null && project.startDate!.isAfter(today) ? project.startDate! : today;
    return addWorkDays(from.add(const Duration(days: 1)), days, project.workDaysPerWeek);
  }

  double get contractValue =>
      project.perUnit ? project.totalUnits * project.pricePerUnit : plannedDaysTotal * project.dailyRate;

  double get remainingRevenue => project.perUnit
      ? remainingUnits * project.pricePerUnit
      : daysRemainingByTarget * project.dailyRate * (activeMachines == 0 ? 1 : activeMachines);

  double get remainingLabor => (daysRemainingByPace ?? daysRemainingByTarget) * activeDailyLabor;

  double get profitToDate => revenue - labor - maintenance - fuel;

  /// Costo directo por inca (planilla + mantenimiento + combustible).
  double? get costPerUnit => unitsDone == 0 ? null : (labor + maintenance + fuel) / unitsDone;
  double get projectedProfit => profitToDate + remainingRevenue - remainingLabor;
}

ProjectStats projectStats(
  Project p,
  List<DailyReport> reports,
  List<Assignment> assignments,
  List<MaintenanceLog> maintenance, {
  double usdToGtq = 7.64,
  List<FuelLog> fuel = const [],
}) {
  final fl = fuel.where((f) => f.projectId == p.id);
  final rs = reports.where((r) => r.projectId == p.id).toList();
  final units = rs.fold<int>(0, (a, r) => a + r.units);
  final revenue = rs.fold<double>(0, (a, r) => a + reportRevenue(r, p));
  final labor = rs.fold<double>(0, (a, r) => a + r.laborUsd);
  final laborGtq = rs.fold<double>(0, (a, r) => a + r.labor);
  final maint = maintenance.where((m) => m.projectId == p.id).fold<double>(0, (a, m) => a + m.cost);

  // Ritmo reciente: unidades por día calendario en los últimos 7 días distintos con reporte.
  final byDay = <String, int>{};
  for (final r in rs) {
    byDay.update(dateKey(r.date), (v) => v + r.units, ifAbsent: () => r.units);
  }
  final keys = byDay.keys.toList()..sort();
  final last = keys.length > 7 ? keys.sublist(keys.length - 7) : keys;
  final pace = last.isEmpty ? 0.0 : last.fold<int>(0, (a, k) => a + byDay[k]!) / last.length;

  final active = assignments.where((a) => a.projectId == p.id && a.active).toList();
  return ProjectStats(
    project: p,
    unitsDone: units,
    reportDays: byDay.length,
    revenue: revenue,
    labor: labor,
    laborGtq: laborGtq,
    maintenance: maint,
    fuel: fl.fold<double>(0, (a, f) => a + f.costUsd),
    fuelGallons: fl.fold<double>(0, (a, f) => a + f.gallons),
    recentPace: pace,
    activeDailyLabor: active.fold<double>(0, (a, x) => a + x.dailyLabor) / (usdToGtq <= 0 ? 1 : usdToGtq),
    activeMachines: active.length,
  );
}

/// Monto de una obligación que cae dentro del mes [month].
/// Únicas: cuentan en el mes de su fecha. Recurrentes: desde su fecha de inicio, en el día
/// de vencimiento de cada período (el próximo vencimiento solo sirve para recordar el pago).
double expenseInMonth(Expense e, DateTime month) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1);
  final first = dayOnly(e.recurrence == 'unica' ? e.dueDate : e.startDate);
  if (!first.isBefore(end)) return 0;
  switch (e.recurrence) {
    case 'unica':
      return !first.isBefore(start) ? e.amount : 0;
    case 'mensual':
      return e.amount;
    case 'anual':
      return first.month == month.month ? e.amount : 0;
    case 'semanal':
      var d = first;
      if (d.isBefore(start)) d = d.add(Duration(days: ((start.difference(d).inDays + 6) ~/ 7) * 7));
      var n = 0;
      while (d.isBefore(end)) {
        n++;
        d = d.add(const Duration(days: 7));
      }
      return n * e.amount;
    default:
      return 0;
  }
}

class MonthFinance {
  final DateTime month;
  final double revenue;
  final double labor;
  final double maintenance;
  final double fixed;
  final double taxes;
  final double fuel; // combustible registrado por máquina (US$)
  final bool projected;
  MonthFinance({
    required this.month,
    required this.revenue,
    required this.labor,
    required this.maintenance,
    required this.fixed,
    required this.taxes,
    this.fuel = 0,
    this.projected = false,
  });
  double get costs => labor + maintenance + fixed + taxes + fuel;
  double get profit => revenue - costs;
}

bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// Resultado real de un mes (con lo reportado).
MonthFinance actualMonth(
  DateTime month,
  List<Project> projects,
  List<DailyReport> reports,
  List<MaintenanceLog> maintenance,
  List<Expense> expenses,
  CompanySettings s, {
  List<FuelLog> fuel = const [],
}) {
  final byId = {for (final p in projects) p.id: p};
  final rs = reports.where((r) => _sameMonth(r.date, month));
  var revenue = 0.0, labor = 0.0;
  for (final r in rs) {
    final p = byId[r.projectId];
    if (p != null) revenue += reportRevenue(r, p);
    labor += r.laborUsd;
  }
  labor *= 1 + s.employerSocialPct / 100;
  final maint = maintenance.where((m) => _sameMonth(m.date, month)).fold<double>(0, (a, m) => a + m.cost);
  final fixed = expenses.where((e) => e.category != 'impuesto').fold<double>(0, (a, e) => a + expenseInMonth(e, month));
  final declaredTaxes = expenses
      .where((e) => e.category == 'impuesto')
      .fold<double>(0, (a, e) => a + expenseInMonth(e, month));
  return MonthFinance(
    month: month,
    revenue: revenue,
    labor: labor,
    maintenance: maint,
    fixed: fixed,
    taxes: revenue * s.incomeTaxPct / 100 + declaredTaxes,
    fuel: fuel.where((f) => _sameMonth(f.date, month)).fold<double>(0, (a, f) => a + f.costUsd),
  );
}

/// Proyección de los próximos [months] meses a partir de [today], según la meta diaria
/// y las asignaciones activas de los proyectos activos/planificados.
List<MonthFinance> projectMonths(
  DateTime today,
  int months,
  List<ProjectStats> stats,
  List<Expense> expenses,
  CompanySettings s,
) {
  final remaining = {for (final st in stats) st.project.id: st.remainingUnits.toDouble()};
  final remainingDays = {for (final st in stats) st.project.id: st.daysRemainingByTarget};
  final out = <MonthFinance>[];
  for (var i = 0; i < months; i++) {
    final month = DateTime(today.year, today.month + i, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    var revenue = 0.0, labor = 0.0;
    for (final st in stats) {
      final p = st.project;
      if (p.status != 'activo' && p.status != 'planificado') continue;
      var from = i == 0 ? dayOnly(today).add(const Duration(days: 1)) : month;
      if (p.startDate != null && p.startDate!.isAfter(from)) from = dayOnly(p.startDate!);
      if (from.isAfter(monthEnd)) continue;
      final avail = workDaysInRange(from, monthEnd, p.workDaysPerWeek);
      final days = avail < remainingDays[p.id]! ? avail : remainingDays[p.id]!;
      if (days <= 0) continue;
      remainingDays[p.id] = remainingDays[p.id]! - days;
      final machines = st.activeMachines == 0 ? 1 : st.activeMachines;
      if (p.perUnit) {
        final units = (days * p.dailyTarget).toDouble().clamp(0, remaining[p.id]!).toDouble();
        remaining[p.id] = remaining[p.id]! - units;
        revenue += units * p.pricePerUnit;
      } else {
        revenue += days * p.dailyRate * machines;
      }
      labor += days * st.activeDailyLabor;
    }
    labor *= 1 + s.employerSocialPct / 100;
    final fixed = expenses
        .where((e) => e.category != 'impuesto')
        .fold<double>(0, (a, e) => a + expenseInMonth(e, month));
    final declaredTaxes = expenses
        .where((e) => e.category == 'impuesto')
        .fold<double>(0, (a, e) => a + expenseInMonth(e, month));
    out.add(
      MonthFinance(
        month: month,
        revenue: revenue,
        labor: labor,
        maintenance: 0,
        fixed: fixed,
        taxes: revenue * s.incomeTaxPct / 100 + declaredTaxes,
        projected: true,
      ),
    );
  }
  return out;
}

/// Planilla por persona en un rango: días trabajados y monto en quetzales.
class PayrollLine {
  final String personId;
  int days = 0;
  double amount = 0;
  PayrollLine(this.personId);
}

Map<String, PayrollLine> payroll(List<DailyReport> reports, List<Assignment> assignments, DateTime from, DateTime to) {
  final asg = {for (final a in assignments) a.id: a};
  final out = <String, PayrollLine>{};
  for (final r in reports) {
    final d = dayOnly(r.date);
    if (d.isBefore(dayOnly(from)) || d.isAfter(dayOnly(to))) continue;
    final a = asg[r.assignmentId];
    final op = r.operatorId ?? a?.operatorId;
    if (op != null && r.operatorPay > 0) {
      final l = out.putIfAbsent(op, () => PayrollLine(op));
      l.days++;
      l.amount += r.operatorPay;
    }
    if (a?.helperId != null && r.helperPay > 0) {
      final l = out.putIfAbsent(a!.helperId!, () => PayrollLine(a.helperId!));
      l.days++;
      l.amount += r.helperPay;
    }
  }
  return out;
}

/// Resumen de paros: horas y días por motivo.
class DowntimeLine {
  final String reason;
  double hours = 0;
  int days = 0;
  int zeroDays = 0; // días sin producción
  DowntimeLine(this.reason);
}

class DowntimeSummary {
  final List<DowntimeLine> lines; // ordenado por horas
  DowntimeSummary(this.lines);
  double get totalHours => lines.fold(0, (a, l) => a + l.hours);
  int get totalDays => lines.fold(0, (a, l) => a + l.days);
  DowntimeLine? get top => lines.isEmpty ? null : lines.first;

  /// Horas atribuibles al cliente (atraso del cliente o falta de material que él provee).
  double get clientHours =>
      lines.where((l) => l.reason == 'cliente' || l.reason == 'falta_material').fold(0, (a, l) => a + l.hours);
}

DowntimeSummary downtimeSummary(Iterable<DailyReport> reports) {
  final m = <String, DowntimeLine>{};
  for (final r in reports) {
    if (!r.hasDowntime) continue;
    final l = m.putIfAbsent(r.downtimeReason ?? 'otro', () => DowntimeLine(r.downtimeReason ?? 'otro'));
    l.hours += r.downtimeHours;
    l.days++;
    if (r.units == 0) l.zeroDays++;
  }
  final lines = m.values.toList()..sort((a, b) => b.hours.compareTo(a.hours));
  return DowntimeSummary(lines);
}

// ------------------------------------------------------------------ mantenimiento por horómetro
enum PlanState { ok, soon, overdue }

class PlanStatus {
  final MaintenancePlan plan;
  final double current; // horómetro actual
  PlanStatus(this.plan, this.current);
  double get remaining => plan.nextAt - current;

  /// "Pronto" = faltan 25 h o menos (o el 10 % del intervalo si es mayor).
  PlanState get state {
    if (remaining <= 0) return PlanState.overdue;
    final margin = plan.intervalHours * 0.10 > 25 ? plan.intervalHours * 0.10 : 25;
    return remaining <= margin ? PlanState.soon : PlanState.ok;
  }

  String get text => switch (state) {
    PlanState.overdue => '${plan.label}: vencido por ${_h(-remaining)} h',
    PlanState.soon => '${plan.label}: le toca en ${_h(remaining)} h',
    PlanState.ok => '${plan.label}: en ${_h(remaining)} h',
  };
}

String _h(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

List<PlanStatus> planStatuses(Iterable<MaintenancePlan> plans, Map<String, Machine> machines) {
  final out = [
    for (final p in plans)
      if (machines[p.machineId] != null) PlanStatus(p, machines[p.machineId]!.hourMeter ?? 0),
  ]..sort((a, b) => a.remaining.compareTo(b.remaining));
  return out;
}

// ------------------------------------------------------------------ planilla con ajustes
class PayLine {
  final String personId;
  int days = 0;
  double gross = 0, bonuses = 0, advances = 0, deductions = 0;
  PayLine(this.personId);
  double get net => gross + bonuses - advances - deductions;
}

/// Vista previa de un periodo: misma regla que el cierre en el servidor.
List<PayLine> payrollPreview(
  List<DailyReport> reports,
  List<Assignment> assignments,
  List<PayrollAdjustment> adjustments,
  DateTime from,
  DateTime to,
) {
  final out = <String, PayLine>{};
  for (final l in payroll(reports, assignments, from, to).values) {
    out[l.personId] = PayLine(l.personId)
      ..days = l.days
      ..gross = l.amount;
  }
  for (final a in adjustments) {
    final d = dayOnly(a.date);
    if (d.isBefore(dayOnly(from)) || d.isAfter(dayOnly(to))) continue;
    final l = out.putIfAbsent(a.personId, () => PayLine(a.personId));
    switch (a.kind) {
      case 'bono':
        l.bonuses += a.amount;
      case 'adelanto':
        l.advances += a.amount;
      default:
        l.deductions += a.amount;
    }
  }
  return out.values.toList()..sort((a, b) => b.net.compareTo(a.net));
}

/// Quincena que contiene la fecha (1–15 o 16–fin de mes).
(DateTime, DateTime) quincenaOf(DateTime d) => d.day <= 15
    ? (DateTime(d.year, d.month, 1), DateTime(d.year, d.month, 15))
    : (DateTime(d.year, d.month, 16), DateTime(d.year, d.month + 1, 0));
