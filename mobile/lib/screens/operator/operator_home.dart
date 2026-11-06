import 'package:flutter/material.dart';

import '../../calc.dart';
import '../../data.dart';
import '../../models.dart';
import '../../offline.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'maintenance_form.dart';
import 'report_form.dart';

class OperatorHome extends StatefulWidget {
  final Profile me;
  final Future<OperatorData> Function(String uid)? loader; // para pruebas
  final Outbox? outbox; // para pruebas
  const OperatorHome({super.key, required this.me, this.loader, this.outbox});
  @override
  State<OperatorHome> createState() => _OperatorHomeState();
}

class _OperatorHomeState extends State<OperatorHome> {
  late Future<OperatorData> _f;
  late final Outbox outbox = widget.outbox ?? Outbox.instance;
  DateTime? _seenSync;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _f = (widget.loader ?? Repo.loadOperator)(widget.me.id);
    outbox.addListener(_onOutbox);
    outbox.init(widget.me.id);
  }

  @override
  void dispose() {
    outbox.removeListener(_onOutbox);
    super.dispose();
  }

  void _onOutbox() {
    if (!mounted) return;
    // Cuando se envió algo pendiente, recargar para ver el pago y datos del servidor.
    if (outbox.lastSync != null && outbox.lastSync != _seenSync && !outbox.syncing) {
      _seenSync = outbox.lastSync;
      _reload();
    } else {
      setState(() {});
    }
  }

  /// Une lo del servidor (o la copia guardada) con lo que está pendiente de enviar.
  OperatorData _merged(OperatorData d) => OperatorData(
    assignments: d.assignments,
    projects: d.projects,
    machines: d.machines,
    reports: outbox.mergeReports(d.reports),
    maintenance: [...outbox.pendingMaintenance(), ...d.maintenance],
    people: d.people,
    cachedAt: d.cachedAt,
  );

  Future<void> _reload() async {
    final f = (widget.loader ?? Repo.loadOperator)(widget.me.id);
    setState(() => _f = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Logo(size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, ${widget.me.display.split(' ').first}', overflow: TextOverflow.ellipsis),
                  Text(
                    roleLabels[widget.me.role]!.toUpperCase(),
                    style: const TextStyle(fontSize: 10, letterSpacing: 1.6, color: Ox.lightGray),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final n = outbox.items.length;
              final msg = n > 0
                  ? 'Tienes $n registro${n == 1 ? '' : 's'} sin enviar. Se guardan en este teléfono y se enviarán cuando vuelvas a entrar con tu usuario. ¿Salir?'
                  : '¿Salir de la app?';
              if (await confirm(context, 'Cerrar sesión', msg, action: 'Salir')) await db.auth.signOut();
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Hoy'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Mantenimiento',
          ),
        ],
      ),
      body: Column(
        children: [
          _syncBanner(),
          Expanded(
            child: FutureBuilder<OperatorData>(
              future: _f,
              builder: (context, snap) {
                if (snap.hasError) return ErrorRetry(snap.error!, _reload);
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final d = _merged(snap.data!);
                if (d.assignments.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.assignment_outlined,
                          title: 'Sin proyecto asignado',
                          body: 'Cuando el administrador te asigne a una máquina y proyecto, aparecerá aquí.',
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: switch (_tab) {
                    0 => _today(d),
                    1 => _history(d),
                    _ => _maintenance(d),
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    await outbox.sync();
    await _reload();
  }

  /// Aviso de señal y registros pendientes.
  Widget _syncBanner() {
    final pending = outbox.pendingCount;
    final failed = outbox.failed;
    if (outbox.online && pending == 0 && failed.isEmpty) return const SizedBox.shrink();
    final Color color;
    final IconData icon;
    final String text;
    if (failed.isNotEmpty) {
      color = Ox.red;
      icon = Icons.error_outline;
      text = '${failed.length} registro${failed.length == 1 ? '' : 's'} no se pudo enviar. Toca para ver.';
    } else if (!outbox.online) {
      color = Ox.yellow;
      icon = Icons.cloud_off;
      text = pending > 0
          ? 'Sin señal · $pending guardado${pending == 1 ? '' : 's'} en el teléfono. Se enviarán solos.'
          : 'Sin señal · puedes seguir registrando, se guardará en el teléfono.';
    } else {
      color = Ox.blue;
      icon = Icons.cloud_upload_outlined;
      text = outbox.syncing
          ? 'Enviando $pending registro${pending == 1 ? '' : 's'}…'
          : '$pending pendiente${pending == 1 ? '' : 's'} de enviar.';
    }
    return Material(
      color: color.withValues(alpha: 0.14),
      child: InkWell(
        onTap: _showOutbox,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              outbox.syncing
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                  : Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showOutbox() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Ox.graphite,
      isScrollControlled: true,
      builder: (c) => ListenableBuilder(
        listenable: outbox,
        builder: (c, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Guardado en el teléfono', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text('Estos registros se envían solos cuando hay señal.', style: TextStyle(color: Ox.lightGray)),
                const SizedBox(height: 12),
                if (outbox.items.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('Todo enviado ✓')),
                for (final it in outbox.items)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        it.kind == 'report' ? Icons.assignment_outlined : Icons.build_outlined,
                        color: it.error == null ? Ox.yellow : Ox.red,
                      ),
                      title: Text(
                        it.kind == 'report'
                            ? 'Reporte ${it.payload['report_date']} · ${it.payload['units_done']} incas'
                            : 'Mantenimiento ${it.payload['log_date']}',
                      ),
                      subtitle: Text(
                        it.error ?? 'Pendiente de enviar',
                        style: TextStyle(color: it.error == null ? Ox.lightGray : Ox.red),
                      ),
                      trailing: it.error == null
                          ? null
                          : PopupMenuButton<String>(
                              color: Ox.graphite,
                              onSelected: (v) async {
                                if (v == 'retry') await outbox.retry(it);
                                if (v == 'del' &&
                                    c.mounted &&
                                    await confirm(
                                      c,
                                      'Descartar',
                                      '¿Borrar este registro del teléfono? No se enviará.',
                                    )) {
                                  await outbox.discard(it);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'retry', child: Text('Reintentar')),
                                PopupMenuItem(value: 'del', child: Text('Descartar')),
                              ],
                            ),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: outbox.syncing || outbox.items.isEmpty ? null : outbox.sync,
                  icon: const Icon(Icons.sync),
                  label: const Text('ENVIAR AHORA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canReport(Assignment a) => a.active && a.operatorId == widget.me.id;

  Future<void> _openReport(OperatorData d, Assignment a, {DailyReport? existing, DateTime? date}) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportForm(
          assignment: a,
          project: d.projects[a.projectId]!,
          machine: d.machines[a.machineId]!,
          helperName: d.people[a.id]?.$2,
          existing: existing,
          date: date,
          outbox: outbox,
        ),
      ),
    );
    if (ok == true) _reload();
  }

  Future<void> _openMaintenance(OperatorData d, Assignment a) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceForm(machine: d.machines[a.machineId]!, projectId: a.projectId, outbox: outbox),
      ),
    );
    if (ok == true) _reload();
  }

  Widget _today(OperatorData d) {
    final today = dayOnly(DateTime.now());
    final active = d.assignments.where((a) => a.active).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          diaSemana(today).toUpperCase(),
          style: const TextStyle(color: Ox.lightGray, letterSpacing: 1.6, fontSize: 12),
        ),
        if (d.cachedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Mostrando datos guardados del ${fechaCorta(d.cachedAt!)} a las ${d.cachedAt!.hour}:${d.cachedAt!.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Ox.yellow, fontSize: 12),
            ),
          ),
        const SizedBox(height: 4),
        if (active.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(icon: Icons.pause_circle_outline, title: 'No tienes asignaciones activas'),
          ),
        for (final a in active) ...[_assignmentCard(d, a, today), const SizedBox(height: 16)],
      ],
    );
  }

  Widget _assignmentCard(OperatorData d, Assignment a, DateTime today) {
    final p = d.projects[a.projectId];
    final m = d.machines[a.machineId];
    if (p == null || m == null) return const SizedBox.shrink();
    final mine = d.reports.where((r) => r.assignmentId == a.id).toList();
    final todayReport = mine.where((r) => dayOnly(r.date) == today).firstOrNull;
    final totalMine = mine.fold<int>(0, (s, r) => s + r.units);
    final people = d.people[a.id];
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final week = mine.where((r) => !dayOnly(r.date).isBefore(weekStart));
    final weekUnits = week.fold<int>(0, (s, r) => s + r.units);
    final isOperator = a.operatorId == widget.me.id;
    final target = a.targetFor(p);
    final myPay = isOperator ? a.operatorDailyPay : a.helperDailyPay;
    final weekPay = week.fold<double>(0, (s, r) => s + (isOperator ? r.operatorPay : r.helperPay));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(p.name, style: Theme.of(context).textTheme.titleLarge)),
                StatusChip(projectStatusLabels[p.status]!, projectStatusColor(p.status)),
              ],
            ),
            if (p.location != null && p.location!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: Ox.lightGray),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(p.location!, style: const TextStyle(color: Ox.lightGray)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            _infoRow(Icons.precision_manufacturing_outlined, 'Máquina', m.label),
            _infoRow(Icons.person_outline, 'Operador', people?.$1 ?? '—'),
            if (m.needsHelper) _infoRow(Icons.group_outlined, 'Ayudante', people?.$2 ?? 'Sin asignar'),
            if (target > 0) _infoRow(Icons.flag_outlined, 'Meta diaria', '${number(target)} ${p.unitName}'),
            _infoRow(Icons.payments_outlined, 'Tu pago por día', quetzal(myPay)),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(child: _mini('Hoy', todayReport == null ? '—' : number(todayReport.units))),
                Expanded(child: _mini('Esta semana', number(weekUnits))),
                Expanded(child: _mini('Total tuyo', number(totalMine))),
              ],
            ),
            if (todayReport != null && (todayReport.pending || todayReport.hasDowntime)) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (todayReport.pending) const StatusChip('Guardado en el teléfono · pendiente de enviar', Ox.yellow),
                  if (todayReport.hasDowntime)
                    StatusChip(
                      'Paro ${numText(todayReport.downtimeHours)} h · ${downtimeReasonLabels[todayReport.downtimeReason] ?? ''}',
                      Ox.blue,
                    ),
                ],
              ),
            ],
            if (target > 0 && todayReport != null) ...[
              const SizedBox(height: 12),
              ProgressBar(todayReport.units / target),
              const SizedBox(height: 4),
              Text(
                todayReport.units >= target
                    ? '¡Meta del día cumplida!'
                    : 'Faltan ${number(target - todayReport.units)} para la meta',
                style: TextStyle(fontSize: 12, color: todayReport.units >= target ? Ox.green : Ox.lightGray),
              ),
            ],
            const SizedBox(height: 6),
            Text('Ganado esta semana: ${quetzal(weekPay)}', style: const TextStyle(fontSize: 12, color: Ox.lightGray)),
            const SizedBox(height: 16),
            if (_canReport(a))
              FilledButton.icon(
                onPressed: () => _openReport(d, a, existing: todayReport, date: today),
                icon: Icon(todayReport == null ? Icons.add_task : Icons.edit),
                label: Text(
                  todayReport == null
                      ? (p.perUnit ? 'REGISTRAR INCAS DE HOY' : 'REGISTRAR DÍA DE TRABAJO')
                      : 'CORREGIR REPORTE DE HOY',
                ),
              ),
            if (_canReport(a)) const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openMaintenance(d, a),
              icon: const Icon(Icons.build_outlined, size: 18),
              label: const Text('Registrar mantenimiento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Ox.yellow),
        const SizedBox(width: 8),
        SizedBox(
          width: 104,
          child: Text(label, style: const TextStyle(color: Ox.lightGray, fontSize: 13)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  Widget _mini(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Ox.lightGray)),
      const SizedBox(height: 2),
      Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Ox.yellow)),
    ],
  );

  Widget _history(OperatorData d) {
    if (d.reports.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          EmptyState(icon: Icons.history, title: 'Aún no hay reportes', body: 'Tus registros diarios aparecerán aquí.'),
        ],
      );
    }
    final asg = {for (final a in d.assignments) a.id: a};
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: d.reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = d.reports[i];
        final p = d.projects[r.projectId];
        final m = d.machines[r.machineId];
        final a = asg[r.assignmentId];
        final editable =
            a != null &&
            _canReport(a) &&
            !dayOnly(r.date).isBefore(dayOnly(DateTime.now()).subtract(const Duration(days: 2)));
        return Card(
          child: ListTile(
            onTap: editable ? () => _openReport(d, a, existing: r) : null,
            title: Text(diaSemana(r.date)),
            subtitle: Text(
              [
                '${p?.name ?? ''} · ${m?.name ?? ''}',
                if (r.hasDowntime)
                  'Paro ${numText(r.downtimeHours)} h · ${downtimeReasonLabels[r.downtimeReason] ?? ''}',
                if (r.notes != null && r.notes!.isNotEmpty) r.notes!,
                if (r.pending) '⏳ Pendiente de enviar',
              ].join('\n'),
            ),
            isThreeLine: r.hasDowntime || r.pending || (r.notes != null && r.notes!.isNotEmpty),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(number(r.units), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Ox.yellow)),
                Text(p?.unitName ?? '', style: const TextStyle(fontSize: 11, color: Ox.lightGray)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _maintenance(OperatorData d) {
    final active = d.assignments.where((a) => a.active).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final a in active)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton.icon(
              onPressed: () => _openMaintenance(d, a),
              icon: const Icon(Icons.add),
              label: Text('NUEVO · ${d.machines[a.machineId]?.name ?? ''}'.toUpperCase()),
            ),
          ),
        const SectionTitle('Historial de la máquina'),
        if (d.maintenance.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Sin mantenimientos registrados', style: TextStyle(color: Ox.lightGray)),
          ),
        for (final l in d.maintenance)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.build_circle_outlined, color: Ox.yellow),
                title: Text(maintenanceTypeLabels[l.type] ?? l.type),
                subtitle: Text(
                  [
                    '${fecha(l.date)} · ${d.machines[l.machineId]?.name ?? ''}',
                    if (l.description.isNotEmpty) l.description,
                    if (l.hourMeter != null) 'Horómetro: ${numText(l.hourMeter)} h',
                    if (l.pending) '⏳ Pendiente de enviar',
                  ].join('\n'),
                ),
                isThreeLine: true,
              ),
            ),
          ),
      ],
    );
  }
}
