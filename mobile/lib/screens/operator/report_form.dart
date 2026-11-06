import 'package:flutter/material.dart';
import '../../calc.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Registro diario de producción (incas hechas, horas, ayudante presente).
class ReportForm extends StatefulWidget {
  final Assignment assignment;
  final Project project;
  final Machine machine;
  final String? helperName;
  final DailyReport? existing;
  final DateTime? date;
  final bool asAdmin;
  const ReportForm({
    super.key,
    required this.assignment,
    required this.project,
    required this.machine,
    this.helperName,
    this.existing,
    this.date,
    this.asAdmin = false,
  });
  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final _form = GlobalKey<FormState>();
  late final _units = TextEditingController(text: widget.existing?.units.toString() ?? '');
  late final _hours = TextEditingController(text: numText(widget.existing?.hours));
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late DateTime _date = widget.existing?.date ?? widget.date ?? DateTime.now();
  late bool _helper = widget.existing?.helperPresent ?? true;
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await guard(
      context,
      () => Repo.saveReport(
        id: widget.existing?.id,
        assignmentId: widget.assignment.id,
        date: _date,
        units: int.tryParse(_units.text) ?? 0,
        hours: parseNum(_hours.text),
        helperPresent: widget.assignment.helperId != null && _helper,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
      ok: 'Reporte guardado',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  void _bump(int delta) {
    final v = (int.tryParse(_units.text) ?? 0) + delta;
    _units.text = (v < 0 ? 0 : v).toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final units = int.tryParse(_units.text) ?? 0;
    final today = dayOnly(DateTime.now());
    final target = widget.assignment.targetFor(p);
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Reporte del día' : 'Corregir reporte')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(p.name, style: Theme.of(context).textTheme.titleLarge),
          Text(widget.machine.label, style: const TextStyle(color: Ox.lightGray)),
          const SizedBox(height: 20),
          DateField(
            label: 'Fecha',
            value: _date,
            first: widget.asAdmin ? DateTime(2020) : today.subtract(const Duration(days: 2)),
            last: today,
            onChanged: (d) => setState(() => _date = d),
          ),
          Text(p.perUnit ? '¿Cuántas ${p.unitName} se hicieron?' : 'Unidades / avance (opcional)',
              style: const TextStyle(color: Ox.lightGray)),
          const SizedBox(height: 8),
          Row(children: [
            _stepBtn('-10', () => _bump(-10)),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _units,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (_) => setState(() {}),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Ox.yellow),
                decoration: const InputDecoration(hintText: '0'),
                validator: (v) {
                  if (!p.perUnit) return null;
                  final n = int.tryParse(v ?? '');
                  if (n == null) return 'Ingresa un número';
                  if (n > 5000) return 'Revisa la cantidad';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            _stepBtn('+10', () => _bump(10)),
          ]),
          if (target > 0) ...[
            const SizedBox(height: 10),
            ProgressBar(units / target),
            const SizedBox(height: 4),
            Text('${number(units)} de ${number(target)} (meta diaria de la máquina)',
                style: const TextStyle(fontSize: 12, color: Ox.lightGray)),
          ],
          const SizedBox(height: 20),
          Field(_hours, 'Horas trabajadas', number: true, decimal: true, suffix: 'h'),
          if (widget.assignment.helperId != null)
            Card(
              child: SwitchListTile(
                value: _helper,
                activeThumbColor: Ox.yellow,
                onChanged: (v) => setState(() => _helper = v),
                title: Text('Ayudante presente${widget.helperName != null ? ' · ${widget.helperName}' : ''}'),
                subtitle: const Text('Si faltó, no se le cuenta el día'),
              ),
            ),
          const SizedBox(height: 12),
          Field(_notes, 'Observaciones', hint: 'Terreno, clima, paros, fallas…', maxLines: 3),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy ? const CircularProgressIndicator(color: Ox.black) : const Text('GUARDAR REPORTE'),
          ),
        ]),
      ),
    );
  }

  Widget _stepBtn(String label, VoidCallback onTap) => SizedBox(
        width: 64,
        height: 56,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(64, 56)),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}
