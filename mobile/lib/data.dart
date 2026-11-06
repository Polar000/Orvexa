import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'offline.dart';

SupabaseClient get db => Supabase.instance.client;

/// Usuarios sin "@" se convierten en usuario@orvexa.app (los crea el admin).
String loginEmail(String userOrEmail) {
  final u = userOrEmail.trim().toLowerCase();
  return u.contains('@') ? u : '${u.replaceAll(RegExp(r'[^a-z0-9._-]'), '')}@orvexa.app';
}

class AppError implements Exception {
  final String message;
  AppError(this.message);
  @override
  String toString() => message;
}

String friendlyError(Object e) {
  if (e is AppError) return e.message;
  if (e is AuthException) {
    if (e.message.toLowerCase().contains('invalid login')) return 'Usuario o contraseña incorrectos';
    return e.message;
  }
  if (e is PostgrestException) {
    if (e.code == '23505') return 'Ya existe un registro para ese día / dato duplicado';
    if (e.code == '23503') return 'No se puede borrar: está siendo usado en otro registro';
    if (e.code == '42501') return 'No tienes permiso para esta acción';
    return e.message;
  }
  if (e is FunctionException) {
    final d = e.details;
    if (d is Map && d['error'] != null) return d['error'].toString();
    return 'Error del servidor (${e.status})';
  }
  final s = e.toString();
  if (s.contains('SocketException') || s.contains('Failed host lookup') || s.contains('ClientException')) {
    return 'Sin conexión a internet';
  }
  return s;
}

class Repo {
  // ------------------------------------------------------------ sesión
  static Future<Profile?> myProfile() async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final m = await db.from('profiles').select().eq('id', uid).maybeSingle();
      if (m != null) await LocalCache.put('profile_$uid', m);
      return m == null ? null : Profile.fromMap(m);
    } catch (e) {
      // Sin señal: usar el perfil guardado para que el operador pueda seguir trabajando.
      if (!isNetworkError(e)) rethrow;
      final c = await LocalCache.get('profile_$uid');
      if (c == null) rethrow;
      return Profile.fromMap(Map<String, dynamic>.from(c.$1));
    }
  }

  static Future<bool> needsSetup() async => (await db.rpc('needs_setup')) == true;

  static Future<void> signIn(String user, String password) =>
      db.auth.signInWithPassword(email: loginEmail(user), password: password);

  static Future<Map<String, dynamic>> _adminUsers(Map<String, dynamic> body) async {
    final res = await db.functions.invoke('admin-users', body: body);
    final data = res.data;
    if (data is Map && data['error'] != null) throw AppError(data['error'].toString());
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> bootstrapAdmin(String fullName, String username, String password) =>
      _adminUsers({'action': 'bootstrap', 'full_name': fullName, 'username': username, 'password': password});

  static Future<void> createUser({
    required String fullName,
    required String username,
    required String password,
    required UserRole role,
    String? phone,
  }) =>
      _adminUsers({
        'action': 'create',
        'full_name': fullName,
        'username': username,
        'password': password,
        'role': role.name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });

  static Future<void> updateUser(String id, Map<String, dynamic> patch) => _adminUsers({'action': 'update', 'id': id, ...patch});

  static Future<void> setPassword(String id, String password) =>
      _adminUsers({'action': 'password', 'id': id, 'password': password});

  // ------------------------------------------------------------ admin: todo junto
  static Future<AdminData> loadAdmin() async {
    final since = DateTime.now().subtract(const Duration(days: 400));
    final r = await Future.wait([
      db.from('profiles').select().order('full_name'),
      db.from('machines').select().order('name'),
      db.from('projects').select().order('created_at', ascending: false),
      db.from('assignments').select().order('created_at', ascending: false),
      db.from('daily_reports').select().gte('report_date', dateKey(since)).order('report_date', ascending: false),
      db.from('maintenance_logs').select().order('log_date', ascending: false),
      db.from('expenses').select().order('due_date'),
      db.from('company_settings').select().eq('id', 1).maybeSingle(),
    ]);
    List<Map<String, dynamic>> l(int i) => List<Map<String, dynamic>>.from(r[i] as List);
    return AdminData(
      profiles: l(0).map(Profile.fromMap).toList(),
      machines: l(1).map(Machine.fromMap).toList(),
      projects: l(2).map(Project.fromMap).toList(),
      assignments: l(3).map(Assignment.fromMap).toList(),
      reports: l(4).map(DailyReport.fromMap).toList(),
      maintenance: l(5).map(MaintenanceLog.fromMap).toList(),
      expenses: l(6).map(Expense.fromMap).toList(),
      settings: CompanySettings.fromMap(r[7] as Map<String, dynamic>?),
    );
  }

  static Future<void> saveMachine(String? id, Map<String, dynamic> m) async {
    id == null ? await db.from('machines').insert(m) : await db.from('machines').update(m).eq('id', id);
  }

  static Future<void> deleteMachine(String id) => db.from('machines').delete().eq('id', id);

  static Future<void> saveProject(String? id, Map<String, dynamic> m) async {
    id == null ? await db.from('projects').insert(m) : await db.from('projects').update(m).eq('id', id);
  }

  static Future<void> deleteProject(String id) => db.from('projects').delete().eq('id', id);

  static Future<void> saveAssignment(String? id, Map<String, dynamic> m) async {
    if (id == null) {
      await db.from('assignments').insert(m);
      await db.from('machines').update({'status': 'en_proyecto'}).eq('id', m['machine_id']);
    } else {
      await db.from('assignments').update(m).eq('id', id);
    }
  }

  static Future<void> endAssignment(Assignment a) async {
    await db.from('assignments').update({'active': false, 'end_date': dateKey(DateTime.now())}).eq('id', a.id);
    final others = await db.from('assignments').select('id').eq('machine_id', a.machineId).eq('active', true);
    if ((others as List).isEmpty) {
      await db.from('machines').update({'status': 'disponible'}).eq('id', a.machineId).eq('status', 'en_proyecto');
    }
  }

  static Future<void> saveExpense(String? id, Map<String, dynamic> m) async {
    id == null ? await db.from('expenses').insert(m) : await db.from('expenses').update(m).eq('id', id);
  }

  static Future<void> deleteExpense(String id) => db.from('expenses').delete().eq('id', id);

  static Future<void> saveSettings(Map<String, dynamic> m) =>
      db.from('company_settings').update({...m, 'updated_at': DateTime.now().toIso8601String()}).eq('id', 1);

  static Future<void> deleteReport(String id) => db.from('daily_reports').delete().eq('id', id);

  // ------------------------------------------------------------ operador
  /// Datos del operador. Con señal los guarda en el teléfono; sin señal usa la última copia.
  static Future<OperatorData> loadOperator(String uid) async {
    try {
      final raw = await _fetchOperatorRaw(uid).timeout(const Duration(seconds: 20));
      await LocalCache.put('operator_$uid', raw);
      return OperatorData.fromRaw(raw);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final c = await LocalCache.get('operator_$uid');
      if (c == null) rethrow;
      return OperatorData.fromRaw(Map<String, dynamic>.from(c.$1), cachedAt: c.$2);
    }
  }

  static Future<Map<String, dynamic>> _fetchOperatorRaw(String uid) async {
    final asg = List<Map<String, dynamic>>.from(await db
        .from('assignments')
        .select()
        .or('operator_id.eq.$uid,helper_id.eq.$uid')
        .order('active', ascending: false)
        .order('start_date', ascending: false));
    if (asg.isEmpty) return {'assignments': [], 'projects': [], 'machines': [], 'reports': [], 'maintenance': [], 'people': {}};
    final pIds = asg.map((a) => a['project_id']).toSet().toList();
    final mIds = asg.map((a) => a['machine_id']).toSet().toList();
    final aIds = asg.map((a) => a['id'] as String).toList();
    final r = await Future.wait([
      db.from('projects').select().inFilter('id', pIds),
      db.from('machines').select().inFilter('id', mIds),
      db.from('daily_reports').select().inFilter('assignment_id', aIds).order('report_date', ascending: false).limit(400),
      db.from('maintenance_logs').select().inFilter('machine_id', mIds).order('log_date', ascending: false).limit(60),
      Future.wait(aIds.map((id) => db.rpc('assignment_people', params: {'p_assignment': id}))),
    ]);
    final peopleRows = r[4];
    final people = <String, dynamic>{};
    for (var i = 0; i < aIds.length; i++) {
      final rows = peopleRows[i] as List;
      if (rows.isNotEmpty) people[aIds[i]] = [rows.first['operator_name'], rows.first['helper_name']];
    }
    return {'assignments': asg, 'projects': r[0], 'machines': r[1], 'reports': r[2], 'maintenance': r[3], 'people': people};
  }

  static Future<void> saveReport({
    String? id,
    required String assignmentId,
    required DateTime date,
    required int units,
    double? hours,
    required bool helperPresent,
    String? notes,
    double downtimeHours = 0,
    String? downtimeReason,
    bool payDay = true,
  }) async {
    final m = {
      'downtime_hours': downtimeHours,
      'downtime_reason': downtimeHours > 0 ? downtimeReason : null,
      'pay_day': payDay,
      'assignment_id': assignmentId,
      'report_date': dateKey(date),
      'units_done': units,
      'hours_worked': hours,
      'helper_present': helperPresent,
      'notes': notes,
    };
    id == null ? await db.from('daily_reports').insert(m) : await db.from('daily_reports').update(m).eq('id', id);
  }

  static Future<void> addMaintenance({
    required String machineId,
    String? projectId,
    required DateTime date,
    required String type,
    required String description,
    double? hourMeter,
    double cost = 0,
  }) =>
      db.from('maintenance_logs').insert({
        'machine_id': machineId,
        'project_id': projectId,
        'log_date': dateKey(date),
        'type': type,
        'description': description,
        'hour_meter': hourMeter,
        'cost': cost,
      });

  static Future<void> deleteMaintenance(String id) => db.from('maintenance_logs').delete().eq('id', id);
}

class AdminData {
  final List<Profile> profiles;
  final List<Machine> machines;
  final List<Project> projects;
  final List<Assignment> assignments;
  final List<DailyReport> reports;
  final List<MaintenanceLog> maintenance;
  final List<Expense> expenses;
  final CompanySettings settings;
  AdminData({
    required this.profiles,
    required this.machines,
    required this.projects,
    required this.assignments,
    required this.reports,
    required this.maintenance,
    required this.expenses,
    required this.settings,
  });
  late final Map<String, Profile> profileById = {for (final p in profiles) p.id: p};
  late final Map<String, Machine> machineById = {for (final m in machines) m.id: m};
  late final Map<String, Project> projectById = {for (final p in projects) p.id: p};
  String personName(String? id) => id == null ? '—' : (profileById[id]?.display ?? 'Usuario eliminado');
}

class OperatorData {
  final DateTime? cachedAt; // si viene de la copia guardada (sin señal)
  final List<Assignment> assignments;
  final Map<String, Project> projects;
  final Map<String, Machine> machines;
  final List<DailyReport> reports;
  final List<MaintenanceLog> maintenance;
  final Map<String, (String?, String?)> people; // assignmentId -> (operador, ayudante)
  OperatorData({
    required this.assignments,
    required this.projects,
    required this.machines,
    required this.reports,
    required this.maintenance,
    required this.people,
    this.cachedAt,
  });

  factory OperatorData.fromRaw(Map<String, dynamic> raw, {DateTime? cachedAt}) {
    List<Map<String, dynamic>> l(String k) =>
        (raw[k] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final people = <String, (String?, String?)>{};
    (raw['people'] as Map? ?? {}).forEach((k, v) {
      final list = v as List;
      people[k as String] = (list[0] as String?, list[1] as String?);
    });
    return OperatorData(
      assignments: l('assignments').map(Assignment.fromMap).toList(),
      projects: {for (final m in l('projects')) m['id'] as String: Project.fromMap(m)},
      machines: {for (final m in l('machines')) m['id'] as String: Machine.fromMap(m)},
      reports: l('reports').map((m) => DailyReport.fromMap(m)).toList(),
      maintenance: l('maintenance').map((m) => MaintenanceLog.fromMap(m)).toList(),
      people: people,
      cachedAt: cachedAt,
    );
  }
}
