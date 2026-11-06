import 'package:flutter/material.dart';
import '../../calc.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'admin_shell.dart';

class ProjectForm extends StatefulWidget {
  final AdminStore store;
  final Project? project;
  const ProjectForm({super.key, required this.store, this.project});
  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final _form = GlobalKey<FormState>();
  late final p = widget.project;
  late final _name = TextEditingController(text: p?.name ?? '');
  late final _client = TextEditingController(text: p?.client ?? '');
  late final _location = TextEditingController(text: p?.location ?? '');
  late final _total = TextEditingController(text: p == null ? '' : p!.totalUnits.toString());
  late final _target = TextEditingController(text: p == null ? '200' : p!.dailyTarget.toString());
  late final _price = TextEditingController(text: p == null ? '' : numText(p!.pricePerUnit));
  late final _rate = TextEditingController(text: p == null ? '' : numText(p!.dailyRate));
  late final _notes = TextEditingController(text: p?.notes ?? '');
  late String _type = p?.type ?? 'hincado';
  late String _status = p?.status ?? 'planificado';
  late String _billing = p?.billingMode ?? 'por_unidad';
  late DateTime? _start = p?.startDate ?? DateTime.now();
  late int _workDays = p?.workDaysPerWeek ?? 6;
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final m = {
      'name': _name.text.trim(),
      'client': _client.text.trim().isEmpty ? null : _client.text.trim(),
      'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
      'type': _type,
      'status': _status,
      'billing_mode': _billing,
      'total_units': int.tryParse(_total.text) ?? 0,
      'daily_target': int.tryParse(_target.text) ?? 0,
      'price_per_unit': parseNum(_price.text) ?? 0,
      'daily_rate': parseNum(_rate.text) ?? 0,
      'start_date': _start == null ? null : dateKey(_start!),
      'work_days_per_week': _workDays,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    };
    final ok = await guard(context, () => Repo.saveProject(p?.id, m), ok: p == null ? 'Proyecto creado' : 'Proyecto actualizado');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      widget.store.reload();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = int.tryParse(_total.text) ?? 0;
    final target = int.tryParse(_target.text) ?? 0;
    final price = parseNum(_price.text) ?? 0;
    final rate = parseNum(_rate.text) ?? 0;
    final days = target > 0 ? (total / target).ceil() : 0;
    final end = _start != null && days > 0 ? addWorkDays(_start!, days, _workDays) : null;
    final value = _billing == 'por_unidad' ? total * price : days * rate;

    return Scaffold(
      appBar: AppBar(title: Text(p == null ? 'Nuevo proyecto' : 'Editar proyecto')),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const SectionTitle('Tipo de trabajo'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'hincado', label: Text('Hincado'), icon: Icon(Icons.solar_power_outlined)),
              ButtonSegment(value: 'bobcat', label: Text('Bobcat'), icon: Icon(Icons.agriculture_outlined)),
              ButtonSegment(value: 'otro', label: Text('Otro')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _billing = _type == 'hincado' ? 'por_unidad' : 'por_dia';
            }),
          ),
          const SectionTitle('Datos'),
          Field(_name, 'Nombre del proyecto', hint: 'Ej. Parque Solar Escuintla F2', required: true),
          Field(_client, 'Cliente'),
          Field(_location, 'Ubicación'),
          Dropdown<String>(
            label: 'Estado',
            value: _status,
            items: projectStatusLabels,
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          const SectionTitle('Cobro (US\$)'),
          Dropdown<String>(
            label: 'Se cobra',
            value: _billing,
            items: const {'por_unidad': 'Por inca / unidad', 'por_dia': 'Por día de máquina'},
            onChanged: (v) => setState(() => _billing = v ?? _billing),
          ),
          if (_billing == 'por_unidad')
            Field(_price, 'Precio por inca', number: true, decimal: true, prefix: r'$ ', hint: '13 – 30', required: true)
          else
            Field(_rate, 'Tarifa por día (por máquina)', number: true, decimal: true, prefix: r'$ ', required: true),
          const SectionTitle('Alcance y tiempo'),
          Field(_total, _type == 'hincado' ? 'Incas totales a trabajar' : 'Unidades totales (opcional)',
              number: true, required: _type == 'hincado'),
          Field(_target, _type == 'hincado' ? 'Meta de incas por día' : 'Meta diaria (opcional)', number: true, hint: 'Ej. 200'),
          DateField(label: 'Fecha de inicio', value: _start, onChanged: (d) => setState(() => _start = d)),
          Dropdown<int>(
            label: 'Días laborales por semana',
            value: _workDays,
            items: const {5: 'Lunes a viernes (5)', 6: 'Lunes a sábado (6)', 7: 'Todos los días (7)'},
            onChanged: (v) => setState(() => _workDays = v ?? _workDays),
          ),
          if (days > 0 || value > 0)
            Card(
              color: Ox.yellow.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('ESTIMADO', style: TextStyle(fontSize: 11, letterSpacing: 1.6, color: Ox.yellow, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (days > 0) Text('$days días laborales a ${number(target)} por día'),
                  if (end != null) Text('Terminaría aprox. el ${fecha(end)}'),
                  if (value > 0) Text('Valor del contrato: ${money(value)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          const SizedBox(height: 12),
          Field(_notes, 'Notas', maxLines: 3),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy ? const CircularProgressIndicator(color: Ox.black) : const Text('GUARDAR PROYECTO'),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
