import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../calc.dart';
import '../../data.dart';
import '../../models.dart';
import '../../pdf_docs.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'admin_shell.dart';

/// Cierre de planilla por periodo (quincena, semana o rango libre), con adelantos, descuentos y bonos.
class PayrollScreen extends StatefulWidget {
  final AdminStore store;
  const PayrollScreen({super.key, required this.store});
  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Planilla'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Periodos'), icon: Icon(Icons.event_note_outlined)),
              ButtonSegment(value: 1, label: Text('Adelantos y bonos'), icon: Icon(Icons.swap_vert)),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      heroTag: 'payrollFab',
      onPressed: _tab == 0 ? _newPeriod : _newAdjustment,
      icon: const Icon(Icons.add),
      label: Text(_tab == 0 ? 'Periodo' : 'Ajuste', style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: StoreBuilder(
      store: widget.store,
      builder: (context, d) =>
          RefreshIndicator(onRefresh: widget.store.reload, child: _tab == 0 ? _periods(d) : _adjustments(d)),
    ),
  );

  Widget _periods(AdminData d) {
    if (d.periods.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          EmptyState(
            icon: Icons.event_note_outlined,
            title: 'Sin periodos',
            body: 'Crea la quincena (o semana) a pagar con “+ Periodo”. La app calcula días, adelantos y bonos de cada persona.',
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        for (final per in d.periods)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PeriodDetail(store: widget.store, periodId: per.id),
                  ),
                ),
                leading: Icon(
                  per.paid ? Icons.check_circle : Icons.pending_outlined,
                  color: per.paid ? Ox.green : Ox.yellow,
                ),
                title: Text('${fechaCorta(per.start)} al ${fecha(per.end)}'),
                subtitle: Text(per.paid ? 'Pagado el ${fecha(per.paidAt)}' : 'Abierto'),
                trailing: Text(
                  quetzal0(
                    per.paid
                        ? d.payments.where((p) => p.periodId == per.id).fold<double>(0, (a, p) => a + p.net)
                        : payrollPreview(
                            d.reports,
                            d.assignments,
                            d.adjustments,
                            per.start,
                            per.end,
                          ).fold<double>(0, (a, l) => a + l.net),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _adjustments(AdminData d) {
    if (d.adjustments.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          EmptyState(
            icon: Icons.swap_vert,
            title: 'Sin adelantos ni bonos',
            body: 'Registra adelantos, descuentos o bonos; se aplican solos en el periodo que incluye su fecha.',
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        for (final a in d.adjustments)
          Card(
            child: ListTile(
              dense: true,
              leading: Icon(
                a.kind == 'bono' ? Icons.add_circle_outline : Icons.remove_circle_outline,
                color: a.kind == 'bono' ? Ox.green : Ox.yellow,
              ),
              title: Text('${d.personName(a.personId)} · ${adjustmentKindLabels[a.kind]}'),
              subtitle: Text('${fecha(a.date)}${(a.note ?? '').isNotEmpty ? ' · ${a.note}' : ''}'),
              trailing: Text(
                '${a.kind == 'bono' ? '+' : '-'}${quetzal(a.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onLongPress: () async {
                final closed = d.periods.any(
                  (p) => p.paid && !dayOnly(a.date).isBefore(p.start) && !dayOnly(a.date).isAfter(p.end),
                );
                if (closed) {
                  toast(
                    context,
                    'Ese ajuste ya está en un periodo pagado. Reabre el periodo para cambiarlo.',
                    error: true,
                  );
                  return;
                }
                if (!await confirm(
                  context,
                  'Eliminar',
                  '¿Eliminar este ${adjustmentKindLabels[a.kind]!.toLowerCase()}?',
                )) {
                  return;
                }
                if (!mounted) return;
                if (await guard(context, () => Repo.deleteAdjustment(a.id))) widget.store.reload();
              },
            ),
          ),
      ],
    );
  }

  Future<void> _newPeriod() async {
    final d = widget.store.data!;
    final now = DateTime.now();
    final (qs, qe) = quincenaOf(now);
    final (ps, pe) = quincenaOf(qs.subtract(const Duration(days: 1)));
    final weekStart = dayOnly(now).subtract(Duration(days: now.weekday - 1));
    final options = <String, (DateTime, DateTime)>{
      'Quincena actual (${fechaCorta(qs)} – ${fechaCorta(qe)})': (qs, qe),
      'Quincena anterior (${fechaCorta(ps)} – ${fechaCorta(pe)})': (ps, pe),
      'Semana actual (${fechaCorta(weekStart)} – ${fechaCorta(weekStart.add(const Duration(days: 6)))})': (
        weekStart,
        weekStart.add(const Duration(days: 6)),
      ),
    };
    final choice = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: Ox.graphite,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('¿Qué periodo vas a pagar?', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final e in options.entries) ListTile(title: Text(e.key), onTap: () => Navigator.pop(c, e.value)),
            ListTile(title: const Text('Otro rango de fechas…'), onTap: () => Navigator.pop(c, 'custom')),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    (DateTime, DateTime)? range;
    if (choice == 'custom') {
      final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime(now.year + 1),
      );
      if (r != null) range = (r.start, r.end);
    } else {
      range = choice as (DateTime, DateTime);
    }
    if (range == null || !mounted) return;
    final overlap = d.periods.where((p) => !(range!.$2.isBefore(p.start) || range.$1.isAfter(p.end))).toList();
    if (overlap.isNotEmpty) {
      final go = await confirm(
        context,
        'Fechas cruzadas',
        'Ya existe un periodo que cubre parte de esas fechas (${fechaCorta(overlap.first.start)} – ${fechaCorta(overlap.first.end)}). '
            'Si cierras ambos, esos días se pagarían dos veces. ¿Crear de todos modos?',
        action: 'Crear',
      );
      if (!go || !mounted) return;
    }
    if (await guard(context, () => Repo.createPeriod(range!.$1, range.$2), ok: 'Periodo creado')) widget.store.reload();
  }

  Future<void> _newAdjustment() async {
    final d = widget.store.data!;
    final people = {for (final p in d.profiles.where((p) => p.role != UserRole.admin)) p.id: p.display};
    if (people.isEmpty) {
      toast(context, 'Primero crea operadores o ayudantes', error: true);
      return;
    }
    String? person;
    var kind = 'adelanto';
    var date = DateTime.now();
    final amount = TextEditingController();
    final note = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          backgroundColor: Ox.graphite,
          title: const Text('Adelanto, descuento o bono'),
          content: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Dropdown<String>(
                    label: 'Persona',
                    value: person,
                    items: people,
                    required: true,
                    onChanged: (v) => set(() => person = v),
                  ),
                  Dropdown<String>(
                    label: 'Tipo',
                    value: kind,
                    items: adjustmentKindLabels,
                    onChanged: (v) => set(() => kind = v ?? kind),
                  ),
                  Field(
                    amount,
                    'Monto',
                    number: true,
                    decimal: true,
                    prefix: 'Q ',
                    validator: (v) {
                      final n = parseNum(v ?? '');
                      return n == null || n <= 0 ? 'Obligatorio' : null;
                    },
                  ),
                  DateField(label: 'Fecha', value: date, onChanged: (v) => set(() => date = v)),
                  Field(note, 'Nota', hint: 'Ej. adelanto en efectivo'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(c, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final closed = d.periods.any((p) => p.paid && !dayOnly(date).isBefore(p.start) && !dayOnly(date).isAfter(p.end));
    if (closed &&
        !await confirm(
          context,
          'Periodo pagado',
          'Esa fecha cae en un periodo ya pagado; no se aplicará hasta que lo reabras. ¿Guardar igual?',
          action: 'Guardar',
        )) {
      return;
    }
    if (!mounted) return;
    if (await guard(
      context,
      () => Repo.saveAdjustment({
        'person_id': person,
        'kind': kind,
        'amount': parseNum(amount.text),
        'adj_date': dateKey(date),
        'note': note.text.trim().isEmpty ? null : note.text.trim(),
      }),
      ok: 'Guardado',
    )) {
      widget.store.reload();
    }
  }
}

class PeriodDetail extends StatelessWidget {
  final AdminStore store;
  final String periodId;
  const PeriodDetail({super.key, required this.store, required this.periodId});

  @override
  Widget build(BuildContext context) => StoreBuilder(
    store: store,
    builder: (context, d) {
      final per = d.periods.where((p) => p.id == periodId).firstOrNull;
      if (per == null) {
        return const Scaffold(
          body: EmptyState(icon: Icons.delete_outline, title: 'Periodo eliminado'),
        );
      }
      final paid = d.payments.where((p) => p.periodId == per.id).toList();
      final preview = payrollPreview(d.reports, d.assignments, d.adjustments, per.start, per.end);
      final rows = per.paid
          ? [
              for (final p in paid)
                (p.personId, p.personName, p.role, p.days, p.gross, p.bonuses, p.advances, p.deductions, p.net, p),
            ]
          : [
              for (final l in preview)
                (
                  l.personId,
                  d.personName(l.personId),
                  d.profileById[l.personId]?.role.name ?? '',
                  l.days,
                  l.gross,
                  l.bonuses,
                  l.advances,
                  l.deductions,
                  l.net,
                  null,
                ),
            ];
      final total = rows.fold<double>(0, (a, r) => a + r.$9);
      return Scaffold(
        appBar: AppBar(
          title: Text('${fechaCorta(per.start)} – ${fechaCorta(per.end)}'),
          actions: [
            if (!per.paid)
              IconButton(
                tooltip: 'Eliminar periodo',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (!await confirm(
                    context,
                    'Eliminar periodo',
                    '¿Eliminar este periodo? No borra reportes ni adelantos.',
                  )) {
                    return;
                  }
                  if (!context.mounted) return;
                  if (await guard(context, () => Repo.deletePeriod(per.id))) {
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
            Card(
              color: (per.paid ? Ox.green : Ox.yellow).withValues(alpha: 0.08),
              child: ListTile(
                leading: Icon(
                  per.paid ? Icons.check_circle : Icons.pending_outlined,
                  color: per.paid ? Ox.green : Ox.yellow,
                ),
                title: Text(per.paid ? 'Pagado el ${fecha(per.paidAt)}' : 'Vista previa (abierto)'),
                subtitle: Text(
                  per.paid
                      ? 'Montos congelados al cerrar.'
                      : 'Se calcula con los días reportados y los ajustes con fecha en el periodo.',
                ),
                trailing: Text(
                  quetzal0(total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Ox.yellow),
                ),
              ),
            ),
            const SectionTitle('Por persona'),
            if (rows.isEmpty)
              const Text('Nadie tiene días reportados en estas fechas.', style: TextStyle(color: Ox.lightGray)),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            Text(
                              quetzal(r.$9),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Ox.yellow, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            '${roleLabels[roleFrom(r.$3)]} · ${r.$4} días · ${quetzal(r.$5)}',
                            if (r.$6 > 0) '+ bono ${quetzal(r.$6)}',
                            if (r.$7 > 0) '- adelanto ${quetzal(r.$7)}',
                            if (r.$8 > 0) '- descuento ${quetzal(r.$8)}',
                          ].join('  '),
                          style: const TextStyle(color: Ox.lightGray, fontSize: 12),
                        ),
                        if (r.$10 != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.receipt_long_outlined, size: 18),
                              label: const Text('Recibo PDF'),
                              onPressed: () => guard(context, () async {
                                final adj = d.adjustments
                                    .where(
                                      (a) =>
                                          a.personId == r.$1 &&
                                          !dayOnly(a.date).isBefore(per.start) &&
                                          !dayOnly(a.date).isAfter(per.end),
                                    )
                                    .toList();
                                final bytes = await payrollReceiptPdf(r.$10!, per, adjustments: adj);
                                await Printing.sharePdf(
                                  bytes: bytes,
                                  filename: 'recibo_${r.$2.replaceAll(' ', '_')}_${dateKey(per.end)}.pdf',
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (!per.paid)
              FilledButton.icon(
                onPressed: rows.isEmpty
                    ? null
                    : () async {
                        if (!await confirm(
                          context,
                          'Cerrar y marcar pagado',
                          'Se guardan los montos de ${rows.length} persona${rows.length == 1 ? '' : 's'} por ${quetzal(total)}. '
                              'Cada operador verá su recibo en la app.',
                          action: 'Cerrar',
                        )) {
                          return;
                        }
                        if (!context.mounted) return;
                        if (await guard(context, () => Repo.closePayroll(per.id), ok: 'Planilla cerrada')) {
                          store.reload();
                        }
                      },
                icon: const Icon(Icons.lock_outline),
                label: const Text('CERRAR Y MARCAR PAGADO'),
              )
            else
              OutlinedButton.icon(
                onPressed: () async {
                  if (!await confirm(
                    context,
                    'Reabrir periodo',
                    'Se borran los montos guardados y vuelve a calcularse. Úsalo solo para corregir errores.',
                    action: 'Reabrir',
                  )) {
                    return;
                  }
                  if (!context.mounted) return;
                  if (await guard(context, () => Repo.reopenPayroll(per.id), ok: 'Periodo reabierto')) store.reload();
                },
                icon: const Icon(Icons.lock_open),
                label: const Text('Reabrir para corregir'),
              ),
          ],
        ),
      );
    },
  );
}
