import 'package:flutter/material.dart';

import '../../data.dart';
import '../../models.dart';
import '../../offline.dart';
import '../../photos.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Carga de combustible de una máquina (galones, costo en Q, horómetro y foto del ticket).
class FuelForm extends StatefulWidget {
  final Machine machine;
  final String? projectId;
  final Outbox outbox;
  const FuelForm({super.key, required this.machine, this.projectId, required this.outbox});
  @override
  State<FuelForm> createState() => _FuelFormState();
}

class _FuelFormState extends State<FuelForm> {
  final _form = GlobalKey<FormState>();
  final _gal = TextEditingController();
  final _cost = TextEditingController();
  final _meter = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  List<String> _local = [];
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    var done = false;
    try {
      final sent = await widget.outbox.addFuel(
        machineId: widget.machine.id,
        projectId: widget.projectId,
        date: _date,
        gallons: parseNum(_gal.text)!,
        costGtq: parseNum(_cost.text) ?? 0,
        hourMeter: parseNum(_meter.text),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        localPhotos: _local,
      );
      done = true;
      if (mounted) {
        toast(context, sent ? 'Combustible registrado' : 'Sin señal: quedó guardado en el teléfono y se enviará solo');
      }
    } catch (e) {
      if (mounted) toast(context, friendlyError(e), error: true);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (done) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final gal = parseNum(_gal.text) ?? 0;
    final cost = parseNum(_cost.text) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Combustible')),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.machine.label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            DateField(label: 'Fecha', value: _date, last: DateTime.now(), onChanged: (d) => setState(() => _date = d)),
            Row(
              children: [
                Expanded(
                  child: Field(
                    _gal,
                    'Galones',
                    number: true,
                    decimal: true,
                    suffix: 'gal',
                    validator: (v) {
                      final n = parseNum(v ?? '');
                      if (n == null || n <= 0) return 'Obligatorio';
                      if (n > 500) return 'Revisa la cantidad';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Field(_cost, 'Costo total', number: true, decimal: true, prefix: 'Q ')),
              ],
            ),
            if (gal > 0 && cost > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  '${quetzal(cost / gal)} por galón',
                  style: const TextStyle(color: Ox.lightGray, fontSize: 12),
                ),
              ),
            Field(
              _meter,
              'Horómetro',
              number: true,
              decimal: true,
              suffix: 'h',
              hint: widget.machine.hourMeter == null ? null : 'Último: ${numText(widget.machine.hourMeter)}',
            ),
            Field(_notes, 'Notas', hint: 'Gasolinera, quién despachó…'),
            PhotoPicker(localPaths: _local, onChanged: (v) => setState(() => _local = v)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const CircularProgressIndicator(color: Ox.black) : const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }
}
