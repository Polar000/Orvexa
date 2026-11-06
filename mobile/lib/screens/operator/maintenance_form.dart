import 'package:flutter/material.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';

class MaintenanceForm extends StatefulWidget {
  final Machine machine;
  final String? projectId;
  const MaintenanceForm({super.key, required this.machine, this.projectId});
  @override
  State<MaintenanceForm> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<MaintenanceForm> {
  final _form = GlobalKey<FormState>();
  final _desc = TextEditingController();
  final _hours = TextEditingController();
  final _cost = TextEditingController();
  String _type = 'preventivo';
  DateTime _date = DateTime.now();
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await guard(
      context,
      () => Repo.addMaintenance(
        machineId: widget.machine.id,
        projectId: widget.projectId,
        date: _date,
        type: _type,
        description: _desc.text.trim(),
        hourMeter: parseNum(_hours.text),
        cost: parseNum(_cost.text) ?? 0,
      ),
      ok: 'Mantenimiento registrado',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mantenimiento')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text(widget.machine.label, style: Theme.of(context).textTheme.titleLarge),
            if (widget.machine.hourMeter != null)
              Text('Último horómetro: ${numText(widget.machine.hourMeter)} h', style: const TextStyle(color: Ox.lightGray)),
            const SizedBox(height: 20),
            Text('Tipo', style: const TextStyle(color: Ox.lightGray)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in maintenanceTypeLabels.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _type == e.key,
                  selectedColor: Ox.yellow,
                  labelStyle: TextStyle(color: _type == e.key ? Ox.black : Ox.white, fontWeight: FontWeight.w600),
                  onSelected: (_) => setState(() => _type = e.key),
                ),
            ]),
            const SizedBox(height: 16),
            DateField(label: 'Fecha', value: _date, last: DateTime.now(), onChanged: (d) => setState(() => _date = d)),
            Field(_desc, '¿Qué se hizo?', hint: 'Ej. cambio de aceite de motor y filtro', maxLines: 3, required: true),
            Field(_hours, 'Horómetro', number: true, decimal: true, suffix: 'h'),
            Field(_cost, 'Costo (si aplica)', number: true, decimal: true, prefix: r'$ '),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const CircularProgressIndicator(color: Ox.black) : const Text('GUARDAR'),
            ),
          ]),
        ),
      );
}
