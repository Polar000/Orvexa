import 'package:flutter/material.dart';

import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'admin_shell.dart';

/// Asigna una máquina a un proyecto con su operador (y ayudante si es hincadora) y el pago diario.
class AssignmentForm extends StatefulWidget {
  final AdminStore store;
  final Project project;
  final Assignment? assignment;
  final String? machineId;
  const AssignmentForm({super.key, required this.store, required this.project, this.assignment, this.machineId});
  @override
  State<AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<AssignmentForm> {
  final _form = GlobalKey<FormState>();
  late final a = widget.assignment;
  late String? _machine = a?.machineId ?? widget.machineId;
  late String? _operator = a?.operatorId;
  late String? _helper = a?.helperId;
  late final _opPay = TextEditingController(text: a == null ? '' : numText(a!.operatorDailyPay));
  late final _hpPay = TextEditingController(text: a == null ? '' : numText(a!.helperDailyPay));
  late final _target = TextEditingController(text: a?.dailyTarget?.toString() ?? _suggestedTarget());
  late DateTime _start = a?.startDate ?? DateTime.now();

  /// Reparte la meta del proyecto entre sus máquinas activas (incluyendo esta nueva).
  String _suggestedTarget() {
    final p = widget.project;
    if (p.dailyTarget <= 0) return '';
    final n = (widget.store.data?.assignments.where((x) => x.projectId == p.id && x.active).length ?? 0) + 1;
    return (p.dailyTarget / n).ceil().toString();
  }

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (a == null && _machine != null) {
      final m = widget.store.data?.machineById[_machine];
      if (m != null) _applyMachineDefaults(m);
    }
  }

  void _applyMachineDefaults(Machine m) {
    _opPay.text = numText(m.operatorDailyPay);
    _hpPay.text = numText(m.helperDailyPay);
    if (!m.needsHelper) _helper = null;
  }

  Future<void> _save(AdminData d) async {
    if (!_form.currentState!.validate()) return;
    final m = d.machineById[_machine]!;
    // Avisar si la máquina u operador ya están ocupados en otro proyecto
    final busy = d.assignments.where(
      (x) =>
          x.active && x.id != a?.id && (x.machineId == _machine || (x.operatorId != null && x.operatorId == _operator)),
    );
    if (busy.isNotEmpty) {
      final names = busy.map((x) => d.projectById[x.projectId]?.name ?? '').toSet().join(', ');
      final go = await confirm(
        context,
        'Ya está asignado',
        'La máquina o el operador tienen una asignación activa en: $names. ¿Asignar de todos modos?',
        action: 'Asignar',
      );
      if (!go || !mounted) return;
    }
    setState(() => _busy = true);
    final ok = await guard(
      context,
      () => Repo.saveAssignment(a?.id, {
        'project_id': widget.project.id,
        'machine_id': _machine,
        'operator_id': _operator,
        'helper_id': m.needsHelper ? _helper : null,
        'operator_daily_pay': parseNum(_opPay.text) ?? 0,
        'helper_daily_pay': m.needsHelper && _helper != null ? (parseNum(_hpPay.text) ?? 0) : 0,
        'start_date': dateKey(_start),
        'daily_target': int.tryParse(_target.text),
      }),
      ok: 'Asignación guardada',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      widget.store.reload();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.store.data!;
    final machine = _machine == null ? null : d.machineById[_machine];
    final operators = {
      for (final p in d.profiles.where((p) => p.active && p.role != UserRole.ayudante)) p.id: p.display,
    };
    final helpers = {for (final p in d.profiles.where((p) => p.active && p.role != UserRole.admin)) p.id: p.display};
    final machines = {
      for (final m in d.machines.where((m) => m.status != 'fuera_servicio' || m.id == _machine))
        m.id: '${m.label} · ${machineTypeLabels[m.type]} · ${machineStatusLabels[m.status]}',
    };
    final daily =
        (parseNum(_opPay.text) ?? 0) +
        (machine?.needsHelper == true && _helper != null ? (parseNum(_hpPay.text) ?? 0) : 0);

    return Scaffold(
      appBar: AppBar(title: Text(a == null ? 'Asignar máquina' : 'Editar asignación')),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.project.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (machines.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Primero agrega una máquina en la pestaña Máquinas.', style: TextStyle(color: Ox.red)),
              ),
            Dropdown<String>(
              label: 'Máquina',
              value: _machine,
              items: machines,
              required: true,
              onChanged: (v) => setState(() {
                _machine = v;
                final m = v == null ? null : d.machineById[v];
                if (m != null) _applyMachineDefaults(m);
              }),
            ),
            if (operators.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('No hay operadores. Créalos en la pestaña Personal.', style: TextStyle(color: Ox.red)),
              ),
            Dropdown<String>(
              label: 'Operador',
              value: _operator,
              items: operators,
              required: true,
              onChanged: (v) => setState(() => _operator = v),
            ),
            Field(_opPay, 'Pago diario al operador', number: true, decimal: true, prefix: 'Q ', required: true),
            if (machine?.needsHelper == true) ...[
              const SectionTitle('Ayudante (hincadora)'),
              Dropdown<String?>(
                label: 'Ayudante',
                value: _helper,
                items: {null: 'Sin ayudante', ...helpers},
                onChanged: (v) => setState(() => _helper = v),
              ),
              if (_helper != null) Field(_hpPay, 'Pago diario al ayudante', number: true, decimal: true, prefix: 'Q '),
            ],
            Field(
              _target,
              'Meta diaria de esta máquina',
              number: true,
              suffix: widget.project.unitName,
              hint: widget.project.dailyTarget > 0 ? 'Meta del proyecto: ${widget.project.dailyTarget}/día' : null,
            ),
            DateField(label: 'Inicia', value: _start, onChanged: (v) => setState(() => _start = v)),
            Card(
              color: Ox.yellow.withValues(alpha: 0.08),
              child: ListTile(
                title: const Text('Costo de planilla por día'),
                subtitle: Text('Solo los días con reporte · ≈ ${money(d.settings.toUsd(daily))}'),
                trailing: Text(
                  quetzal(daily),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Ox.yellow),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : () => _save(d),
              child: _busy ? const CircularProgressIndicator(color: Ox.black) : const Text('GUARDAR ASIGNACIÓN'),
            ),
          ],
        ),
      ),
    );
  }
}
