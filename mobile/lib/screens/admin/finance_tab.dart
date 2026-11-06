import 'package:flutter/material.dart';

import '../../calc.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'admin_shell.dart';
import 'charts.dart';

class FinanceTab extends StatefulWidget {
  final AdminStore store;
  const FinanceTab({super.key, required this.store});
  @override
  State<FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      heroTag: 'newExpense',
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseForm(store: widget.store))),
      icon: const Icon(Icons.add),
      label: const Text('Obligación', style: TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: StoreBuilder(
      store: widget.store,
      builder: (context, d) {
        final now = DateTime.now();
        final m = actualMonth(_month, d.projects, d.reports, d.maintenance, d.expenses, d.settings, fuel: d.fuel);
        final stats = d.projects
            .map(
              (p) =>
                  projectStats(p, d.reports, d.assignments, d.maintenance, usdToGtq: d.settings.usdToGtq, fuel: d.fuel),
            )
            .toList();
        final proj = projectMonths(now, 7, stats, d.expenses, d.settings).skip(1).toList();
        final projTotal = proj.fold<double>(0, (s, x) => s + x.profit);
        final monthEnd = DateTime(_month.year, _month.month + 1, 0);
        final pay = payroll(d.reports, d.assignments, _month, monthEnd).values.toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
        final isCurrent = _month.year == now.year && _month.month == now.month;

        return RefreshIndicator(
          onRefresh: widget.store.reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1)),
                  ),
                  Expanded(
                    child: Text(
                      mesLargo(_month),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: isCurrent
                        ? null
                        : () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Ingresos (incas / días facturables)', m.revenue, color: Ox.yellow, bold: true),
                      const Divider(height: 20),
                      _row(
                        'Planilla operadores y ayudantes',
                        -m.labor,
                        note: [
                          'pagada en quetzales, convertida a US\$',
                          if (d.settings.employerSocialPct > 0)
                            'incluye ${numText(d.settings.employerSocialPct)}% patronal',
                        ].join(' · '),
                      ),
                      _row('Mantenimiento', -m.maintenance),
                      if (m.fuel > 0) _row('Combustible (registrado por máquina)', -m.fuel),
                      _row('Gastos fijos (renta, seguros, combustible…)', -m.fixed),
                      _row(
                        'Impuestos',
                        -m.taxes,
                        note: '${numText(d.settings.incomeTaxPct)}% sobre ingresos + impuestos registrados',
                      ),
                      const Divider(height: 20),
                      _row('Utilidad', m.profit, color: m.profit >= 0 ? Ox.green : Ox.red, bold: true),
                      if (m.revenue > 0)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Margen ${(m.profit / m.revenue * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(color: Ox.lightGray, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SectionTitle(
                'Proyección · próximos 6 meses',
                trailing: Text(
                  moneyShort(projTotal),
                  style: TextStyle(color: projTotal >= 0 ? Ox.green : Ox.red, fontWeight: FontWeight.w800),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
                  child: Column(
                    children: [
                      MonthsChart(months: proj),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text('Utilidad acumulada', style: TextStyle(fontSize: 12, color: Ox.lightGray)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CumulativeProfitChart(months: proj),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(8, 8, 0, 0),
                        child: Text(
                          'Basado en la meta diaria y las asignaciones activas de cada proyecto activo o planificado, '
                          'hasta completar sus incas. Incluye obligaciones recurrentes e impuesto sobre ingresos.',
                          style: TextStyle(fontSize: 11, color: Ox.lightGray),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SectionTitle('Obligaciones'),
              ..._expenses(context, d),
              SectionTitle('Planilla de ${mesLargo(_month).toLowerCase()}'),
              if (pay.isEmpty) const Text('Sin días reportados en este mes', style: TextStyle(color: Ox.lightGray)),
              if (pay.isNotEmpty)
                Card(
                  child: Column(
                    children: [
                      for (final l in pay)
                        ListTile(
                          dense: true,
                          title: Text(d.personName(l.personId)),
                          subtitle: Text('${l.days} días · ${roleLabels[d.profileById[l.personId]?.role] ?? ''}'),
                          trailing: Text(quetzal(l.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
              const SectionTitle('Tipo de cambio e impuestos'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.percent, color: Ox.yellow),
                  title: Text('Tipo de cambio: Q${numText(d.settings.usdToGtq)} por US\$1'),
                  subtitle: Text(
                    'Impuesto sobre ingresos: ${numText(d.settings.incomeTaxPct)}% · '
                    'carga patronal: ${numText(d.settings.employerSocialPct)}%',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editSettings(context, d.settings),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  List<Widget> _expenses(BuildContext context, AdminData d) {
    if (d.expenses.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Agrega renta, seguros, combustible, impuestos y otras obligaciones con “+ Obligación”.',
            style: TextStyle(color: Ox.lightGray),
          ),
        ),
      ];
    }
    final today = dayOnly(DateTime.now());
    final pending = d.expenses.where((e) => !(e.recurrence == 'unica' && e.paid)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final paid = d.expenses.where((e) => e.recurrence == 'unica' && e.paid).toList();
    Widget tile(Expense e) {
      final overdue = !(e.recurrence == 'unica' && e.paid) && dayOnly(e.dueDate).isBefore(today);
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Card(
          child: ListTile(
            dense: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExpenseForm(store: widget.store, expense: e),
              ),
            ),
            leading: Icon(_icon(e.category), color: overdue ? Ox.red : Ox.yellow),
            title: Text(e.description),
            subtitle: Text(
              '${expenseCategoryLabels[e.category]} · ${recurrenceLabels[e.recurrence]} · '
              '${e.recurrence == 'unica' && e.paid ? 'pagado ${fecha(e.paidDate)}' : '${overdue ? 'VENCIDO ' : 'vence '}${fecha(e.dueDate)}'}',
              style: TextStyle(color: overdue ? Ox.red : null),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(money0(e.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                if (!(e.recurrence == 'unica' && e.paid))
                  IconButton(
                    tooltip: 'Marcar pagado',
                    icon: const Icon(Icons.check_circle_outline, color: Ox.green),
                    onPressed: () => _markPaid(context, e),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return [
      for (final e in pending) tile(e),
      if (paid.isNotEmpty)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('Pagadas (${paid.length})', style: const TextStyle(color: Ox.lightGray, fontSize: 13)),
          children: [for (final e in paid) tile(e)],
        ),
    ];
  }

  IconData _icon(String c) => switch (c) {
    'renta' => Icons.home_work_outlined,
    'seguro' => Icons.shield_outlined,
    'combustible' => Icons.local_gas_station_outlined,
    'impuesto' => Icons.account_balance_outlined,
    'planilla_extra' => Icons.groups_outlined,
    _ => Icons.receipt_long_outlined,
  };

  /// Pago único: queda pagado. Recurrente: se registra y pasa al siguiente vencimiento.
  Future<void> _markPaid(BuildContext context, Expense e) async {
    final next = switch (e.recurrence) {
      'semanal' => e.dueDate.add(const Duration(days: 7)),
      'mensual' => DateTime(e.dueDate.year, e.dueDate.month + 1, e.dueDate.day),
      'anual' => DateTime(e.dueDate.year + 1, e.dueDate.month, e.dueDate.day),
      _ => e.dueDate,
    };
    final patch = e.recurrence == 'unica'
        ? {'paid': true, 'paid_date': dateKey(DateTime.now())}
        : {'paid_date': dateKey(DateTime.now()), 'due_date': dateKey(next)};
    final ok = await guard(
      context,
      () => Repo.saveExpense(e.id, patch),
      ok: e.recurrence == 'unica' ? 'Marcado como pagado' : 'Pagado · próximo vencimiento ${fecha(next)}',
    );
    if (ok) widget.store.reload();
  }

  Future<void> _editSettings(BuildContext context, CompanySettings s) async {
    final tax = TextEditingController(text: numText(s.incomeTaxPct));
    final social = TextEditingController(text: numText(s.employerSocialPct));
    final fx = TextEditingController(text: numText(s.usdToGtq));
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Ox.graphite,
        title: const Text('Tipo de cambio e impuestos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Field(fx, 'Quetzales por 1 US\$', number: true, decimal: true, prefix: 'Q '),
            Field(tax, 'Impuesto sobre ingresos', number: true, decimal: true, suffix: '%'),
            Field(social, 'Carga patronal sobre planilla (ej. IGSS)', number: true, decimal: true, suffix: '%'),
            const Text(
              'Consulta a tu contador el porcentaje que aplica a tu régimen.',
              style: TextStyle(fontSize: 12, color: Ox.lightGray),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (await guard(
      context,
      () => Repo.saveSettings({
        'income_tax_pct': parseNum(tax.text) ?? 0,
        'employer_social_pct': parseNum(social.text) ?? 0,
        if ((parseNum(fx.text) ?? 0) > 0) 'usd_to_gtq': parseNum(fx.text),
      }),
      ok: 'Guardado',
    )) {
      widget.store.reload();
    }
  }

  Widget _row(String label, double v, {Color? color, bool bold = false, String? note}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
              if (note != null) Text(note, style: const TextStyle(fontSize: 11, color: Ox.lightGray)),
            ],
          ),
        ),
        Text(
          money(v),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color,
            fontSize: bold ? 17 : 14,
          ),
        ),
      ],
    ),
  );
}

class ExpenseForm extends StatefulWidget {
  final AdminStore store;
  final Expense? expense;
  const ExpenseForm({super.key, required this.store, this.expense});
  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _form = GlobalKey<FormState>();
  late final e = widget.expense;
  late final _desc = TextEditingController(text: e?.description ?? '');
  late final _amount = TextEditingController(text: e == null ? '' : numText(e!.amount));
  late String _cat = e?.category ?? 'renta';
  late String _rec = e?.recurrence ?? 'mensual';
  late DateTime _due = e?.dueDate ?? DateTime.now();
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await guard(
      context,
      () => Repo.saveExpense(e?.id, {
        'description': _desc.text.trim(),
        'amount': parseNum(_amount.text) ?? 0,
        'category': _cat,
        'recurrence': _rec,
        'due_date': dateKey(_due),
        if (e == null) 'start_date': dateKey(_due),
      }),
      ok: 'Guardado',
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
    appBar: AppBar(
      title: Text(e == null ? 'Nueva obligación' : 'Editar obligación'),
      actions: [
        if (e != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (!await confirm(context, 'Eliminar', '¿Eliminar “${e!.description}”?')) return;
              if (!context.mounted) return;
              if (await guard(context, () => Repo.deleteExpense(e!.id))) {
                widget.store.reload();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
      ],
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Dropdown<String>(
            label: 'Categoría',
            value: _cat,
            items: expenseCategoryLabels,
            onChanged: (v) => setState(() => _cat = v ?? _cat),
          ),
          Field(_desc, 'Descripción', hint: 'Ej. Renta de bodega, seguro hincadora #1, ISR trimestral', required: true),
          Field(_amount, 'Monto', number: true, decimal: true, prefix: r'$ ', required: true),
          Dropdown<String>(
            label: 'Se paga',
            value: _rec,
            items: recurrenceLabels,
            onChanged: (v) => setState(() => _rec = v ?? _rec),
          ),
          DateField(
            label: _rec == 'unica' ? 'Fecha de pago' : 'Próximo vencimiento',
            value: _due,
            onChanged: (v) => setState(() => _due = v),
          ),
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
