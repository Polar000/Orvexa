import 'package:flutter/material.dart';

import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../../calc.dart';
import '../../offline.dart';
import '../../photos.dart';
import '../operator/fuel_form.dart';
import '../operator/maintenance_form.dart';
import 'admin_shell.dart';
import 'assignment_form.dart';
import 'project_detail.dart';

class MachinesTab extends StatelessWidget {
  final AdminStore store;
  const MachinesTab({super.key, required this.store});

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      heroTag: 'newMachine',
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MachineForm(store: store))),
      icon: const Icon(Icons.add),
      label: const Text('Máquina', style: TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: StoreBuilder(
      store: store,
      builder: (context, d) {
        if (d.machines.isEmpty) {
          return const EmptyState(
            icon: Icons.precision_manufacturing_outlined,
            title: 'Sin máquinas',
            body: 'Agrega tus hincadoras, bobcats y demás equipo con el botón “+ Máquina”.',
          );
        }
        return RefreshIndicator(
          onRefresh: store.reload,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: d.machines.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = d.machines[i];
              final a = d.assignments.where((x) => x.machineId == m.id && x.active).firstOrNull;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MachineDetail(store: store, machineId: m.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Ox.black,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Ox.darkGray),
                          ),
                          child: Icon(
                            m.type == 'hincadora' ? Icons.solar_power_outlined : Icons.agriculture_outlined,
                            color: Ox.yellow,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                a == null
                                    ? '${machineTypeLabels[m.type]} · sin asignar'
                                    : '${d.projectById[a.projectId]?.name ?? ''} · ${d.personName(a.operatorId)}',
                                style: const TextStyle(color: Ox.lightGray, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        StatusChip(machineStatusLabels[m.status]!, machineStatusColor(m.status)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class MachineForm extends StatefulWidget {
  final AdminStore store;
  final Machine? machine;
  const MachineForm({super.key, required this.store, this.machine});
  @override
  State<MachineForm> createState() => _MachineFormState();
}

class _MachineFormState extends State<MachineForm> {
  final _form = GlobalKey<FormState>();
  late final m = widget.machine;
  late final _name = TextEditingController(text: m?.name ?? '');
  late final _code = TextEditingController(text: m?.code ?? '');
  late final _op = TextEditingController(text: m == null ? '' : numText(m!.operatorDailyPay));
  late final _hp = TextEditingController(text: m == null ? '' : numText(m!.helperDailyPay));
  late final _hours = TextEditingController(text: numText(m?.hourMeter));
  late final _notes = TextEditingController(text: m?.notes ?? '');
  late String _type = m?.type ?? 'hincadora';
  late String _status = m?.status ?? 'disponible';
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await guard(
      context,
      () => Repo.saveMachine(m?.id, {
        'name': _name.text.trim(),
        'code': _code.text.trim().isEmpty ? null : _code.text.trim(),
        'type': _type,
        'status': _status,
        'operator_daily_pay': parseNum(_op.text) ?? 0,
        'helper_daily_pay': _type == 'hincadora' ? (parseNum(_hp.text) ?? 0) : 0,
        'hour_meter': parseNum(_hours.text),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      }),
      ok: m == null ? 'Máquina agregada' : 'Máquina actualizada',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      widget.store.reload();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(m == null ? 'Nueva máquina' : 'Editar máquina')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'hincadora', label: Text('Hincadora')),
              ButtonSegment(value: 'bobcat', label: Text('Bobcat')),
              ButtonSegment(value: 'otra', label: Text('Otra')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          Field(_name, 'Nombre', hint: 'Ej. Hincadora HWL600R #2', required: true),
          Field(_code, 'Código / placa / serie'),
          Dropdown<String>(
            label: 'Estado',
            value: _status,
            items: machineStatusLabels,
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          const SectionTitle('Pago diario sugerido (quetzales)'),
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'Se usa por defecto al asignar la máquina; se puede cambiar en cada asignación.',
              style: TextStyle(color: Ox.lightGray, fontSize: 12),
            ),
          ),
          Field(_op, 'Operador por día', number: true, decimal: true, prefix: 'Q '),
          if (_type == 'hincadora') Field(_hp, 'Ayudante por día', number: true, decimal: true, prefix: 'Q '),
          Field(_hours, 'Horómetro actual', number: true, decimal: true, suffix: 'h'),
          Field(_notes, 'Notas', maxLines: 3),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy ? const CircularProgressIndicator(color: Ox.black) : const Text('GUARDAR MÁQUINA'),
          ),
        ],
      ),
    ),
  );
}

class MachineDetail extends StatelessWidget {
  final AdminStore store;
  final String machineId;
  const MachineDetail({super.key, required this.store, required this.machineId});

  @override
  Widget build(BuildContext context) => StoreBuilder(
    store: store,
    builder: (context, d) {
      final m = d.machineById[machineId];
      if (m == null) {
        return const Scaffold(
          body: EmptyState(icon: Icons.delete_outline, title: 'Máquina eliminada'),
        );
      }
      final asg = d.assignments.where((a) => a.machineId == m.id).toList();
      final active = asg.where((a) => a.active).firstOrNull;
      final logs = d.maintenance.where((l) => l.machineId == m.id).toList();
      final reports = d.reports.where((r) => r.machineId == m.id).toList();
      final units = reports.fold<int>(0, (s, r) => s + r.units);
      final maintCost = logs.fold<double>(0, (s, l) => s + l.cost);
      final fuel = d.fuel.where((f) => f.machineId == m.id).toList();
      final fuelQ = fuel.fold<double>(0, (s, f) => s + f.costGtq);
      final fuelGal = fuel.fold<double>(0, (s, f) => s + f.gallons);
      final plans = planStatuses(d.plans.where((p) => p.machineId == m.id), d.machineById);

      return Scaffold(
        appBar: AppBar(
          title: Text(m.name, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MachineForm(store: store, machine: m),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (!await confirm(context, 'Eliminar máquina', '¿Eliminar ${m.name}?')) return;
                if (!context.mounted) return;
                if (await guard(context, () => Repo.deleteMachine(m.id), ok: 'Máquina eliminada')) {
                  store.reload();
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: [
                StatusChip(machineStatusLabels[m.status]!, machineStatusColor(m.status)),
                StatusChip(machineTypeLabels[m.type]!, Ox.lightGray),
                if ((m.code ?? '').isNotEmpty) StatusChip(m.code!, Ox.lightGray),
              ],
            ),
            const SizedBox(height: 16),
            KpiGrid([
              Kpi(
                label: 'Producción total',
                value: number(units),
                sub: '${reports.length} días reportados',
                icon: Icons.bar_chart,
              ),
              Kpi(
                label: 'Horómetro',
                value: m.hourMeter == null ? '—' : '${numText(m.hourMeter)} h',
                icon: Icons.speed,
              ),
              Kpi(label: 'Pago operador / día', value: quetzal(m.operatorDailyPay), icon: Icons.person_outline),
              if (m.needsHelper)
                Kpi(label: 'Pago ayudante / día', value: quetzal(m.helperDailyPay), icon: Icons.group_outlined),
              Kpi(label: 'Gasto mantenimiento', value: moneyShort(maintCost), icon: Icons.build_outlined),
              Kpi(
                label: 'Combustible',
                value: quetzal0(fuelQ),
                sub: '${numText(fuelGal.roundToDouble())} galones',
                icon: Icons.local_gas_station_outlined,
              ),
              if (units > 0 && fuelQ > 0)
                Kpi(
                  label: 'Combustible por inca',
                  value: quetzal(fuelQ / units),
                  sub: '${(fuelGal / units).toStringAsFixed(3)} gal/inca',
                  icon: Icons.calculate_outlined,
                ),
            ]),
            SectionTitle(
              'Mantenimiento por horómetro',
              trailing: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Plan'),
                onPressed: () => _editPlan(context, m),
              ),
            ),
            if (plans.isEmpty)
              const Text(
                'Agrega planes como "Cambio de aceite cada 250 h" para recibir avisos.',
                style: TextStyle(color: Ox.lightGray),
              ),
            if (plans.isNotEmpty)
              Card(
                child: Column(
                  children: [
                    for (final x in plans)
                      ListTile(
                        dense: true,
                        onTap: () => _editPlan(context, m, plan: x.plan),
                        leading: Icon(
                          x.state == PlanState.overdue
                              ? Icons.warning_amber
                              : (x.state == PlanState.soon ? Icons.schedule : Icons.check_circle_outline),
                          color: x.state == PlanState.overdue
                              ? Ox.red
                              : (x.state == PlanState.soon ? Ox.yellow : Ox.green),
                        ),
                        title: Text(x.plan.label),
                        subtitle: Text(
                          'Cada ${numText(x.plan.intervalHours)} h · último a las ${numText(x.plan.lastDoneHours)} h'
                          '${x.plan.lastDoneDate != null ? ' (${fecha(x.plan.lastDoneDate)})' : ''}',
                        ),
                        trailing: Text(
                          x.remaining <= 0
                              ? 'Vencido ${numText((-x.remaining).roundToDouble())} h'
                              : 'En ${numText(x.remaining.roundToDouble())} h',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: x.state == PlanState.overdue
                                ? Ox.red
                                : (x.state == PlanState.soon ? Ox.yellow : null),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (plans.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Al registrar un mantenimiento del mismo tipo, el contador se reinicia solo.',
                  style: TextStyle(fontSize: 11, color: Ox.lightGray),
                ),
              ),
            const SectionTitle('Asignación actual'),
            if (active == null) ...[
              const Text('Libre', style: TextStyle(color: Ox.lightGray)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_link),
                label: const Text('Asignar a un proyecto'),
                onPressed: () => _pickProject(context, d, m),
              ),
            ] else
              Card(
                child: ListTile(
                  title: Text(d.projectById[active.projectId]?.name ?? ''),
                  subtitle: Text(
                    'Operador: ${d.personName(active.operatorId)}'
                    '${active.helperId != null ? '\nAyudante: ${d.personName(active.helperId)}' : ''}',
                  ),
                  isThreeLine: active.helperId != null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectDetail(store: store, projectId: active.projectId),
                    ),
                  ),
                ),
              ),
            SectionTitle(
              'Mantenimientos (${logs.length})',
              trailing: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar'),
                onPressed: () async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MaintenanceForm(machine: m, projectId: active?.projectId, outbox: Outbox.instance),
                    ),
                  );
                  if (ok == true) store.reload();
                },
              ),
            ),
            if (logs.isEmpty) const Text('Sin registros', style: TextStyle(color: Ox.lightGray)),
            for (final l in logs)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Card(
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.build_circle_outlined, color: Ox.yellow),
                        title: Text('${maintenanceTypeLabels[l.type]} · ${fecha(l.date)}'),
                        subtitle: Text(
                          [
                            if (l.description.isNotEmpty) l.description,
                            if (l.hourMeter != null) '${numText(l.hourMeter)} h',
                            'por ${d.personName(l.reportedBy)}',
                          ].join(' · '),
                        ),
                        trailing: l.cost > 0 ? Text(money(l.cost)) : null,
                        onLongPress: () async {
                          if (!await confirm(context, 'Eliminar', '¿Eliminar este mantenimiento?')) return;
                          if (!context.mounted) return;
                          if (await guard(context, () => Repo.deleteMaintenance(l.id))) store.reload();
                        },
                      ),
                      if (l.photos.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: PhotoStrip(photos: l.photos),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            SectionTitle(
              'Combustible (${fuel.length})',
              trailing: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar'),
                onPressed: () async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FuelForm(machine: m, projectId: active?.projectId, outbox: Outbox.instance),
                    ),
                  );
                  if (ok == true) store.reload();
                },
              ),
            ),
            if (fuel.isEmpty) const Text('Sin registros', style: TextStyle(color: Ox.lightGray)),
            for (final f in fuel.take(30))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Card(
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.local_gas_station_outlined, color: Ox.yellow),
                        title: Text('${numText(f.gallons)} gal · ${quetzal(f.costGtq)} · ${fecha(f.date)}'),
                        subtitle: Text(
                          [
                            if (f.hourMeter != null) '${numText(f.hourMeter)} h',
                            'por ${d.personName(f.reportedBy)}',
                            if ((f.notes ?? '').isNotEmpty) f.notes!,
                          ].join(' · '),
                        ),
                        onLongPress: () async {
                          if (!await confirm(context, 'Eliminar', '¿Eliminar este registro de combustible?')) return;
                          if (!context.mounted) return;
                          if (await guard(context, () => Repo.deleteFuel(f.id))) store.reload();
                        },
                      ),
                      if (f.photos.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: PhotoStrip(photos: f.photos),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if ((m.notes ?? '').isNotEmpty) ...[
              const SectionTitle('Notas'),
              Text(m.notes!, style: const TextStyle(color: Ox.lightGray)),
            ],
          ],
        ),
      );
    },
  );

  Future<void> _editPlan(BuildContext context, Machine m, {MaintenancePlan? plan}) async {
    final label = TextEditingController(text: plan?.label ?? '');
    final interval = TextEditingController(text: plan == null ? '' : numText(plan.intervalHours));
    final last = TextEditingController(text: plan == null ? numText(m.hourMeter ?? 0) : numText(plan.lastDoneHours));
    var type = plan?.type ?? 'cambio_aceite';
    final key = GlobalKey<FormState>();
    final res = await showDialog<String>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          backgroundColor: Ox.graphite,
          title: Text(plan == null ? 'Nuevo plan' : 'Editar plan'),
          content: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Dropdown<String>(
                    label: 'Tipo (reinicia al registrar este tipo)',
                    value: type,
                    items: maintenanceTypeLabels,
                    onChanged: (v) => set(() {
                      type = v ?? type;
                      if (label.text.isEmpty) label.text = maintenanceTypeLabels[type]!;
                    }),
                  ),
                  Field(label, 'Nombre', hint: 'Ej. Aceite de motor', required: true),
                  Field(
                    interval,
                    'Cada cuántas horas',
                    number: true,
                    decimal: true,
                    suffix: 'h',
                    validator: (v) {
                      final n = parseNum(v ?? '');
                      return n == null || n <= 0 ? 'Obligatorio' : null;
                    },
                  ),
                  Field(last, 'Último hecho a las', number: true, decimal: true, suffix: 'h'),
                ],
              ),
            ),
          ),
          actions: [
            if (plan != null)
              TextButton(
                onPressed: () => Navigator.pop(c, 'del'),
                child: const Text('Eliminar', style: TextStyle(color: Ox.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(c, 'save');
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || res == null) return;
    final ok = res == 'del'
        ? await guard(context, () => Repo.deletePlan(plan!.id))
        : await guard(
            context,
            () => Repo.savePlan(plan?.id, {
              'machine_id': m.id,
              'type': type,
              'label': label.text.trim(),
              'interval_hours': parseNum(interval.text),
              'last_done_hours': parseNum(last.text) ?? 0,
            }),
            ok: 'Plan guardado',
          );
    if (ok) store.reload();
  }

  Future<void> _pickProject(BuildContext context, AdminData d, Machine m) async {
    final projects = d.projects.where((p) => p.status != 'completado').toList();
    if (projects.isEmpty) {
      toast(context, 'Primero crea un proyecto', error: true);
      return;
    }
    final p = await showModalBottomSheet<Project>(
      context: context,
      backgroundColor: Ox.graphite,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('¿A qué proyecto?', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final p in projects)
              ListTile(
                title: Text(p.name),
                subtitle: Text(projectStatusLabels[p.status]!),
                onTap: () => Navigator.pop(c, p),
              ),
          ],
        ),
      ),
    );
    if (p != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssignmentForm(store: store, project: p, machineId: m.id),
        ),
      );
    }
  }
}
