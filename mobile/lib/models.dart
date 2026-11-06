// Modelos de datos ORVEXA (espejo de las tablas en Supabase).

double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
int _i(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

enum UserRole { admin, operador, ayudante }

UserRole roleFrom(String? s) => UserRole.values.firstWhere((e) => e.name == s, orElse: () => UserRole.operador);

const roleLabels = {UserRole.admin: 'Administrador', UserRole.operador: 'Operador', UserRole.ayudante: 'Ayudante'};

class Profile {
  final String id;
  final String fullName;
  final String? username;
  final String? phone;
  final UserRole role;
  final bool active;
  Profile({
    required this.id,
    required this.fullName,
    this.username,
    this.phone,
    required this.role,
    required this.active,
  });
  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
    id: m['id'],
    fullName: (m['full_name'] ?? '') as String,
    username: m['username'],
    phone: m['phone'],
    role: roleFrom(m['role']),
    active: m['active'] == true,
  );
  String get display => fullName.isNotEmpty ? fullName : (username ?? 'Sin nombre');
}

const machineTypeLabels = {'hincadora': 'Hincadora', 'bobcat': 'Bobcat', 'otra': 'Otra'};
const machineStatusLabels = {
  'disponible': 'Disponible',
  'en_proyecto': 'En proyecto',
  'mantenimiento': 'Mantenimiento',
  'fuera_servicio': 'Fuera de servicio',
};

class Machine {
  final String id;
  final String name;
  final String? code;
  final String type;
  final String status;
  final double operatorDailyPay;
  final double helperDailyPay;
  final double? hourMeter;
  final String? notes;
  Machine({
    required this.id,
    required this.name,
    this.code,
    required this.type,
    required this.status,
    required this.operatorDailyPay,
    required this.helperDailyPay,
    this.hourMeter,
    this.notes,
  });
  bool get needsHelper => type == 'hincadora';
  factory Machine.fromMap(Map<String, dynamic> m) => Machine(
    id: m['id'],
    name: m['name'] ?? '',
    code: m['code'],
    type: m['type'] ?? 'otra',
    status: m['status'] ?? 'disponible',
    operatorDailyPay: _d(m['operator_daily_pay']),
    helperDailyPay: _d(m['helper_daily_pay']),
    hourMeter: m['hour_meter'] == null ? null : _d(m['hour_meter']),
    notes: m['notes'],
  );
  String get label => code == null || code!.isEmpty ? name : '$name · $code';
}

const projectTypeLabels = {'hincado': 'Hincado', 'bobcat': 'Bobcat', 'otro': 'Otro'};
const projectStatusLabels = {
  'planificado': 'Planificado',
  'activo': 'Activo',
  'pausado': 'Pausado',
  'completado': 'Completado',
};

class Project {
  final String id;
  final String name;
  final String? client;
  final String? location;
  final String type;
  final String status;
  final String billingMode; // por_unidad | por_dia
  final int totalUnits;
  final int dailyTarget;
  final double pricePerUnit;
  final double dailyRate;
  final DateTime? startDate;
  final int workDaysPerWeek;
  final String? notes;
  Project({
    required this.id,
    required this.name,
    this.client,
    this.location,
    required this.type,
    required this.status,
    required this.billingMode,
    required this.totalUnits,
    required this.dailyTarget,
    required this.pricePerUnit,
    required this.dailyRate,
    this.startDate,
    required this.workDaysPerWeek,
    this.notes,
  });
  bool get perUnit => billingMode == 'por_unidad';
  String get unitName => type == 'hincado' ? 'incas' : 'unidades';
  factory Project.fromMap(Map<String, dynamic> m) => Project(
    id: m['id'],
    name: m['name'] ?? '',
    client: m['client'],
    location: m['location'],
    type: m['type'] ?? 'hincado',
    status: m['status'] ?? 'planificado',
    billingMode: m['billing_mode'] ?? 'por_unidad',
    totalUnits: _i(m['total_units']),
    dailyTarget: _i(m['daily_target']),
    pricePerUnit: _d(m['price_per_unit']),
    dailyRate: _d(m['daily_rate']),
    startDate: _date(m['start_date']),
    workDaysPerWeek: _i(m['work_days_per_week'] ?? 6),
    notes: m['notes'],
  );
}

class Assignment {
  final String id;
  final String projectId;
  final String machineId;
  final String? operatorId;
  final String? helperId;
  final double operatorDailyPay;
  final double helperDailyPay;
  final int? dailyTarget; // meta de esta máquina
  final DateTime startDate;
  final DateTime? endDate;
  final bool active;
  Assignment({
    required this.id,
    required this.projectId,
    required this.machineId,
    this.operatorId,
    this.helperId,
    required this.operatorDailyPay,
    required this.helperDailyPay,
    this.dailyTarget,
    required this.startDate,
    this.endDate,
    required this.active,
  });
  int targetFor(Project p) => dailyTarget ?? p.dailyTarget;
  double get dailyLabor => operatorDailyPay + (helperId != null ? helperDailyPay : 0); // Q
  factory Assignment.fromMap(Map<String, dynamic> m) => Assignment(
    id: m['id'],
    projectId: m['project_id'],
    machineId: m['machine_id'],
    operatorId: m['operator_id'],
    helperId: m['helper_id'],
    operatorDailyPay: _d(m['operator_daily_pay']),
    helperDailyPay: _d(m['helper_daily_pay']),
    dailyTarget: m['daily_target'] == null ? null : _i(m['daily_target']),
    startDate: _date(m['start_date']) ?? DateTime.now(),
    endDate: _date(m['end_date']),
    active: m['active'] == true,
  );
}

const downtimeReasonLabels = {
  'lluvia': 'Lluvia / clima',
  'falla_maquina': 'Falla de la máquina',
  'falta_material': 'Falta de material (perfiles)',
  'cliente': 'Atraso del cliente',
  'terreno': 'Terreno (roca, lodo)',
  'combustible': 'Sin combustible',
  'otro': 'Otro',
};

class DailyReport {
  final String id;
  final String assignmentId;
  final String projectId;
  final String machineId;
  final String? operatorId;
  final DateTime date;
  final int units;
  final double? hours;
  final bool helperPresent;
  final String? notes;
  final double operatorPay; // Q
  final double helperPay; // Q
  final double fxRate; // Q por US$ del día del reporte
  final double downtimeHours;
  final String? downtimeReason;
  final bool payDay;
  final List<String> photos; // rutas en el almacenamiento
  final List<String> localPhotos; // fotos aún en el teléfono (pendientes)
  final double? hourMeter;
  final bool pending; // guardado en el teléfono, falta enviarlo
  DailyReport({
    required this.id,
    required this.assignmentId,
    required this.projectId,
    required this.machineId,
    this.operatorId,
    required this.date,
    required this.units,
    this.hours,
    required this.helperPresent,
    this.notes,
    required this.operatorPay,
    required this.helperPay,
    this.fxRate = 7.64,
    this.downtimeHours = 0,
    this.downtimeReason,
    this.payDay = true,
    this.photos = const [],
    this.localPhotos = const [],
    this.hourMeter,
    this.pending = false,
  });
  double get labor => operatorPay + helperPay; // Q
  double get laborUsd => labor / (fxRate <= 0 ? 1 : fxRate);
  bool get hasDowntime => downtimeHours > 0;
  factory DailyReport.fromMap(Map<String, dynamic> m, {bool pending = false}) => DailyReport(
    id: m['id'],
    assignmentId: m['assignment_id'],
    projectId: m['project_id'] ?? '',
    machineId: m['machine_id'] ?? '',
    operatorId: m['operator_id'],
    date: _date(m['report_date']) ?? DateTime.now(),
    units: _i(m['units_done']),
    hours: m['hours_worked'] == null ? null : _d(m['hours_worked']),
    helperPresent: m['helper_present'] != false,
    notes: m['notes'],
    operatorPay: _d(m['operator_pay']),
    helperPay: _d(m['helper_pay']),
    fxRate: m['fx_rate'] == null ? 7.64 : _d(m['fx_rate']),
    downtimeHours: _d(m['downtime_hours']),
    downtimeReason: m['downtime_reason'],
    payDay: m['pay_day'] != false,
    photos: _strings(m['photos']),
    localPhotos: _localPhotos(m),
    hourMeter: m['hour_meter'] == null ? null : _d(m['hour_meter']),
    pending: pending,
  );
}

List<String> _strings(dynamic v) => v == null ? const [] : List<String>.from((v as List).map((e) => e.toString()));
List<String> _localPhotos(Map<String, dynamic> m) => m['_photos_pending'] == null
    ? const []
    : [for (final x in m['_photos_pending'] as List) (x as Map)['local'] as String];

const maintenanceTypeLabels = {
  'preventivo': 'Preventivo',
  'correctivo': 'Correctivo / reparación',
  'cambio_aceite': 'Cambio de aceite',
  'engrase': 'Engrase',
  'filtros': 'Filtros',
  'llantas_orugas': 'Llantas / orugas',
  'otro': 'Otro',
};

class MaintenanceLog {
  final String id;
  final String machineId;
  final String? projectId;
  final String? reportedBy;
  final DateTime date;
  final String type;
  final String description;
  final double? hourMeter;
  final double cost;
  final List<String> photos;
  final List<String> localPhotos;
  final bool pending;
  MaintenanceLog({
    required this.id,
    required this.machineId,
    this.projectId,
    this.reportedBy,
    required this.date,
    required this.type,
    required this.description,
    this.hourMeter,
    required this.cost,
    this.photos = const [],
    this.localPhotos = const [],
    this.pending = false,
  });
  factory MaintenanceLog.fromMap(Map<String, dynamic> m, {bool pending = false}) => MaintenanceLog(
    id: m['id'],
    machineId: m['machine_id'],
    projectId: m['project_id'],
    reportedBy: m['reported_by'],
    date: _date(m['log_date']) ?? DateTime.now(),
    type: m['type'] ?? 'otro',
    description: m['description'] ?? '',
    hourMeter: m['hour_meter'] == null ? null : _d(m['hour_meter']),
    cost: _d(m['cost']),
    photos: _strings(m['photos']),
    localPhotos: _localPhotos(m),
    pending: pending,
  );
}

class MaintenancePlan {
  final String id;
  final String machineId;
  final String type;
  final String label;
  final double intervalHours;
  final double lastDoneHours;
  final DateTime? lastDoneDate;
  MaintenancePlan({
    required this.id,
    required this.machineId,
    required this.type,
    required this.label,
    required this.intervalHours,
    required this.lastDoneHours,
    this.lastDoneDate,
  });
  double get nextAt => lastDoneHours + intervalHours;
  factory MaintenancePlan.fromMap(Map<String, dynamic> m) => MaintenancePlan(
    id: m['id'],
    machineId: m['machine_id'],
    type: m['type'] ?? 'preventivo',
    label: m['label'] ?? '',
    intervalHours: _d(m['interval_hours']),
    lastDoneHours: _d(m['last_done_hours']),
    lastDoneDate: _date(m['last_done_date']),
  );
}

class FuelLog {
  final String id;
  final String machineId;
  final String? projectId;
  final String? reportedBy;
  final DateTime date;
  final double gallons;
  final double costGtq;
  final double? hourMeter;
  final double fxRate;
  final List<String> photos;
  final List<String> localPhotos;
  final String? notes;
  final bool pending;
  FuelLog({
    required this.id,
    required this.machineId,
    this.projectId,
    this.reportedBy,
    required this.date,
    required this.gallons,
    required this.costGtq,
    this.hourMeter,
    this.fxRate = 7.64,
    this.photos = const [],
    this.localPhotos = const [],
    this.notes,
    this.pending = false,
  });
  double get costUsd => costGtq / (fxRate <= 0 ? 1 : fxRate);
  factory FuelLog.fromMap(Map<String, dynamic> m, {bool pending = false}) => FuelLog(
    id: m['id'],
    machineId: m['machine_id'],
    projectId: m['project_id'],
    reportedBy: m['reported_by'],
    date: _date(m['log_date']) ?? DateTime.now(),
    gallons: _d(m['gallons']),
    costGtq: _d(m['cost_gtq']),
    hourMeter: m['hour_meter'] == null ? null : _d(m['hour_meter']),
    fxRate: m['fx_rate'] == null ? 7.64 : _d(m['fx_rate']),
    photos: _strings(m['photos']),
    localPhotos: _localPhotos(m),
    notes: m['notes'],
    pending: pending,
  );
}

const adjustmentKindLabels = {'adelanto': 'Adelanto', 'descuento': 'Descuento', 'bono': 'Bono'};

class PayrollAdjustment {
  final String id;
  final String personId;
  final DateTime date;
  final String kind;
  final double amount; // Q
  final String? note;
  PayrollAdjustment({
    required this.id,
    required this.personId,
    required this.date,
    required this.kind,
    required this.amount,
    this.note,
  });

  /// Efecto sobre el neto: bono suma, adelanto y descuento restan.
  double get signed => kind == 'bono' ? amount : -amount;
  factory PayrollAdjustment.fromMap(Map<String, dynamic> m) => PayrollAdjustment(
    id: m['id'],
    personId: m['person_id'],
    date: _date(m['adj_date']) ?? DateTime.now(),
    kind: m['kind'] ?? 'adelanto',
    amount: _d(m['amount']),
    note: m['note'],
  );
}

class PayrollPeriod {
  final String id;
  final DateTime start;
  final DateTime end;
  final String status; // abierto | pagado
  final DateTime? paidAt;
  final String? notes;
  PayrollPeriod({
    required this.id,
    required this.start,
    required this.end,
    required this.status,
    this.paidAt,
    this.notes,
  });
  bool get paid => status == 'pagado';
  factory PayrollPeriod.fromMap(Map<String, dynamic> m) => PayrollPeriod(
    id: m['id'],
    start: _date(m['start_date']) ?? DateTime.now(),
    end: _date(m['end_date']) ?? DateTime.now(),
    status: m['status'] ?? 'abierto',
    paidAt: _date(m['paid_at']),
    notes: m['notes'],
  );
}

class PayrollPayment {
  final String id;
  final String periodId;
  final String? personId;
  final String personName;
  final String role;
  final int days;
  final double gross, bonuses, advances, deductions, net; // Q
  PayrollPayment({
    required this.id,
    required this.periodId,
    this.personId,
    required this.personName,
    required this.role,
    required this.days,
    required this.gross,
    required this.bonuses,
    required this.advances,
    required this.deductions,
    required this.net,
  });
  factory PayrollPayment.fromMap(Map<String, dynamic> m) => PayrollPayment(
    id: m['id'] ?? '',
    periodId: m['period_id'] ?? '',
    personId: m['person_id'],
    personName: m['person_name'] ?? '',
    role: m['role'] ?? '',
    days: _i(m['days']),
    gross: _d(m['gross']),
    bonuses: _d(m['bonuses']),
    advances: _d(m['advances']),
    deductions: _d(m['deductions']),
    net: _d(m['net']),
  );
}

const expenseCategoryLabels = {
  'renta': 'Renta',
  'seguro': 'Seguros',
  'combustible': 'Combustible',
  'impuesto': 'Impuestos',
  'planilla_extra': 'Planilla (fija / extra)',
  'otro': 'Otro',
};
const recurrenceLabels = {'unica': 'Única vez', 'semanal': 'Semanal', 'mensual': 'Mensual', 'anual': 'Anual'};

class Expense {
  final String id;
  final String category;
  final String description;
  final double amount;
  final String recurrence;
  final DateTime dueDate;
  final DateTime startDate;
  final bool paid;
  final DateTime? paidDate;
  Expense({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.recurrence,
    required this.dueDate,
    required this.startDate,
    required this.paid,
    this.paidDate,
  });
  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'],
    category: m['category'] ?? 'otro',
    description: m['description'] ?? '',
    amount: _d(m['amount']),
    recurrence: m['recurrence'] ?? 'mensual',
    dueDate: _date(m['due_date']) ?? DateTime.now(),
    startDate: _date(m['start_date']) ?? _date(m['due_date']) ?? DateTime.now(),
    paid: m['paid'] == true,
    paidDate: _date(m['paid_date']),
  );
}

class CompanySettings {
  final double incomeTaxPct;
  final double employerSocialPct;
  final double usdToGtq; // tipo de cambio actual
  CompanySettings({required this.incomeTaxPct, required this.employerSocialPct, this.usdToGtq = 7.64});
  double toUsd(double gtq) => gtq / (usdToGtq <= 0 ? 1 : usdToGtq);
  factory CompanySettings.fromMap(Map<String, dynamic>? m) => CompanySettings(
    incomeTaxPct: _d(m?['income_tax_pct'] ?? 5),
    employerSocialPct: _d(m?['employer_social_pct'] ?? 0),
    usdToGtq: _d(m?['usd_to_gtq'] ?? 7.64),
  );
}
