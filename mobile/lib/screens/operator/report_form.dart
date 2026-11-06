import 'package:flutter/material.dart';

import '../../calc.dart';
import '../../data.dart';
import '../../models.dart';
import '../../offline.dart';
import '../../photos.dart';
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
  final Outbox? outbox; // operador: guarda en el teléfono si no hay señal
  const ReportForm({
    super.key,
    required this.assignment,
    required this.project,
    required this.machine,
    this.helperName,
    this.existing,
    this.date,
    this.asAdmin = false,
    this.outbox,
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
  late bool _paro = (widget.existing?.downtimeHours ?? 0) > 0;
  late String? _reason = widget.existing?.downtimeReason;
  late final _downHours = TextEditingController(
    text: numText(widget.existing?.downtimeHours == 0 ? null : widget.existing?.downtimeHours),
  );
  late bool _payDay = widget.existing?.payDay ?? true;
  late final _meter = TextEditingController(text: numText(widget.existing?.hourMeter));
  late List<String> _local = [...?widget.existing?.localPhotos];
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_paro && _reason == null) {
      toast(context, 'Elige el motivo del paro', error: true);
      return;
    }
    setState(() => _busy = true);
    final units = int.tryParse(_units.text) ?? 0;
    final hours = parseNum(_hours.text);
    final helper = widget.assignment.helperId != null && _helper;
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final downH = _paro ? (parseNum(_downHours.text) ?? 0) : 0.0;
    final reason = _paro ? _reason : null;
    var ok = false;
    if (widget.outbox != null) {
      // Operador: se guarda en el teléfono primero y se envía si hay señal.
      try {
        final sent = await widget.outbox!.saveReport(
          existing: widget.existing,
          assignment: widget.assignment,
          date: _date,
          units: units,
          hours: hours,
          helperPresent: helper,
          notes: notes,
          downtimeHours: downH,
          downtimeReason: reason,
          hourMeter: parseNum(_meter.text),
          photos: widget.existing?.photos ?? const [],
          localPhotos: _local,
        );
        ok = true;
        if (mounted) {
          toast(context, sent ? 'Reporte enviado' : 'Sin señal: quedó guardado en el teléfono y se enviará solo');
        }
      } catch (e) {
        if (mounted) toast(context, friendlyError(e), error: true);
      }
    } else {
      ok = await guard(
        context,
        () => Repo.saveReport(
          id: widget.existing?.id,
          assignmentId: widget.assignment.id,
          date: _date,
          units: units,
          hours: hours,
          helperPresent: helper,
          notes: notes,
          downtimeHours: downH,
          downtimeReason: reason,
          payDay: _payDay,
          hourMeter: parseNum(_meter.text),
        ),
        ok: 'Reporte guardado',
      );
    }
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            Text(
              p.perUnit ? '¿Cuántas ${p.unitName} se hicieron?' : 'Unidades / avance (opcional)',
              style: const TextStyle(color: Ox.lightGray),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
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
                      if (n == null) return 'Ingresa un número (0 si no se trabajó)';
                      if (n > 5000) return 'Revisa la cantidad';
                      if (n == 0 && !_paro) return 'Sin producción: marca abajo el motivo del paro';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _stepBtn('+10', () => _bump(10)),
              ],
            ),
            if (target > 0) ...[
              const SizedBox(height: 10),
              ProgressBar(units / target),
              const SizedBox(height: 4),
              Text(
                '${number(units)} de ${number(target)} (meta diaria de la máquina)',
                style: const TextStyle(fontSize: 12, color: Ox.lightGray),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Field(_hours, 'Horas trabajadas', number: true, decimal: true, suffix: 'h')),
                const SizedBox(width: 10),
                Expanded(
                  child: Field(
                    _meter,
                    'Horómetro al cerrar',
                    number: true,
                    decimal: true,
                    suffix: 'h',
                    hint: widget.machine.hourMeter == null ? null : 'Último: ${numText(widget.machine.hourMeter)}',
                    validator: (v) {
                      final n = parseNum(v ?? '');
                      if (n != null &&
                          widget.machine.hourMeter != null &&
                          n < widget.machine.hourMeter! - 0.05 &&
                          !widget.asAdmin) {
                        return 'Menor al último (${numText(widget.machine.hourMeter)})';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
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
            _paroSection(),
            if (widget.asAdmin)
              Card(
                child: SwitchListTile(
                  value: _payDay,
                  activeThumbColor: Ox.yellow,
                  onChanged: (v) => setState(() => _payDay = v),
                  title: const Text('Pagar este día'),
                  subtitle: const Text('Apágalo si el día no se trabajó y no corresponde pago'),
                ),
              ),
            const SizedBox(height: 12),
            Field(_notes, 'Observaciones', hint: 'Detalles del paro, terreno, fallas…', maxLines: 3),
            if (widget.outbox != null)
              PhotoPicker(
                existing: widget.existing?.photos ?? const [],
                localPaths: _local,
                onChanged: (v) => setState(() => _local = v),
              )
            else
              PhotoStrip(photos: widget.existing?.photos ?? const []),
            const SizedBox(height: 4),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const CircularProgressIndicator(color: Ox.black) : const Text('GUARDAR REPORTE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paroSection() => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            value: _paro,
            activeThumbColor: Ox.yellow,
            onChanged: (v) => setState(() => _paro = v),
            title: const Text('¿Hubo paro o retraso?'),
            subtitle: const Text('Lluvia, falla, falta de material, atraso del cliente…'),
          ),
          if (_paro) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in downtimeReasonLabels.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: _reason == e.key,
                      selectedColor: Ox.yellow,
                      labelStyle: TextStyle(color: _reason == e.key ? Ox.black : Ox.white, fontWeight: FontWeight.w600),
                      onSelected: (_) => setState(() => _reason = e.key),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Field(
                _downHours,
                'Horas perdidas',
                number: true,
                decimal: true,
                suffix: 'h',
                validator: (v) {
                  final n = parseNum(v ?? '');
                  if (n == null || n <= 0) return 'Indica cuántas horas se perdieron';
                  if (n > 24) return 'Máximo 24 h';
                  return null;
                },
              ),
            ),
          ],
        ],
      ),
    ),
  );

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
