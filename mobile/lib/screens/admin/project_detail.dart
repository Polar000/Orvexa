import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../calc.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';

import 'package:printing/printing.dart';

import '../../pdf_docs.dart';
import '../operator/report_form.dart';
import 'admin_shell.dart';
import 'assignment_form.dart';
import 'project_form.dart';

class ProjectDetail extends StatelessWidget {
  final AdminStore store;
  final String projectId;
  const ProjectDetail({super.key, required this.store, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      store: store,
      builder: (context, d) {
        final p = d.projectById[projectId];
        if (p == null) {
          return const Scaffold(
            body: EmptyState(icon: Icons.delete_outline, title: 'Proyecto eliminado'),
          );
        }
        final st = projectStats(
          p,
          d.reports,
          d.assignments,
          d.maintenance,
          usdToGtq: d.settings.usdToGtq,
          fuel: d.fuel,
        );
        final asg = d.assignments.where((a) => a.projectId == p.id).toList();
        final reports = d.reports.where((r) => r.projectId == p.id).toList();
        final today = DateTime.now();
        final end = st.estimatedEnd(today);

        return Scaffold(
          appBar: AppBar(
            title: Text(p.name, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'Reporte PDF para el cliente',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: reports.isEmpty ? null : () => _clientPdf(context, d, p, reports),
              ),
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectForm(store: store, project: p),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (!await confirm(
                    context,
                    'Eliminar proyecto',
                    'Se borrarán también sus asignaciones y reportes diarios. Esta acción no se puede deshacer.',
                  )) {
                    return;
                  }
                  if (!context.mounted) return;
                  if (await guard(context, () => Repo.deleteProject(p.id), ok: 'Proyecto eliminado')) {
                    store.reload();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'assign',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssignmentForm(store: store, project: p),
              ),
            ),
            icon: const Icon(Icons.add_link),
            label: const Text('Asignar máquina', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: RefreshIndicator(
            onRefresh: store.reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(projectStatusLabels[p.status]!, projectStatusColor(p.status)),
                    StatusChip(projectTypeLabels[p.type]!, Ox.lightGray),
                    if ((p.client ?? '').isNotEmpty) StatusChip(p.client!, Ox.lightGray),
                  ],
                ),
                if ((p.location ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(p.location!, style: const TextStyle(color: Ox.lightGray)),
                ],
                if (p.totalUnits > 0) ...[
                  const SectionTitle('Avance'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                number(st.unitsDone),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Ox.yellow),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6, left: 6),
                                child: Text(
                                  'de ${number(p.totalUnits)} ${p.unitName}',
                                  style: const TextStyle(color: Ox.lightGray),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(st.progress * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ProgressBar(st.progress, height: 10),
                          const SizedBox(height: 12),
                          _line('Faltan', '${number(st.remainingUnits)} ${p.unitName}'),
                          _line('Meta diaria', p.dailyTarget > 0 ? '${number(p.dailyTarget)} / día' : '—'),
                          _line(
                            'Ritmo real (últ. 7 días)',
                            st.recentPace > 0 ? '${number(st.recentPace.round())} / día' : 'Sin datos',
                          ),
                          _line(
                            'Días estimados restantes',
                            '${st.daysRemainingByPace ?? st.daysRemainingByTarget}${st.daysRemainingByPace != null ? ' (por ritmo real)' : ' (por meta)'}',
                          ),
                          _line('Fin planificado', fecha(st.plannedEnd)),
                          _line(
                            'Fin estimado',
                            st.remainingUnits == 0 ? 'Terminado' : fecha(end),
                            color: end != null && st.plannedEnd != null && end.isAfter(st.plannedEnd!)
                                ? Ox.red
                                : Ox.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SectionTitle('Dinero (US\$)'),
                KpiGrid([
                  Kpi(label: 'Valor contrato', value: moneyShort(st.contractValue), icon: Icons.description_outlined),
                  Kpi(
                    label: 'Facturable a la fecha',
                    value: moneyShort(st.revenue),
                    color: Ox.yellow,
                    icon: Icons.trending_up,
                  ),
                  Kpi(
                    label: 'Planilla pagada',
                    value: moneyShort(st.labor),
                    sub: quetzal0(st.laborGtq),
                    icon: Icons.groups_outlined,
                  ),
                  Kpi(label: 'Mantenimiento', value: moneyShort(st.maintenance), icon: Icons.build_outlined),
                  if (st.fuel > 0)
                    Kpi(
                      label: 'Combustible',
                      value: moneyShort(st.fuel),
                      sub: '${numText(st.fuelGallons.roundToDouble())} galones',
                      icon: Icons.local_gas_station_outlined,
                    ),
                  if (st.costPerUnit != null && p.perUnit)
                    Kpi(
                      label: 'Costo directo por inca',
                      value: money(st.costPerUnit!),
                      sub: 'Cobro ${money(p.pricePerUnit)} · margen ${money(p.pricePerUnit - st.costPerUnit!)}',
                      color: st.costPerUnit! < p.pricePerUnit ? Ox.green : Ox.red,
                      icon: Icons.calculate_outlined,
                    ),
                  Kpi(
                    label: 'Utilidad a la fecha',
                    value: moneyShort(st.profitToDate),
                    color: st.profitToDate >= 0 ? Ox.green : Ox.red,
                    icon: Icons.savings_outlined,
                  ),
                  Kpi(
                    label: 'Utilidad proyectada',
                    value: moneyShort(st.projectedProfit),
                    sub: 'Antes de gastos fijos e impuestos',
                    color: st.projectedProfit >= 0 ? Ox.green : Ox.red,
                    icon: Icons.auto_graph,
                  ),
                ]),
                if (reports.isNotEmpty) ...[
                  const SectionTitle('Producción diaria'),
                  Card(
                    child: Padding(padding: const EdgeInsets.fromLTRB(8, 16, 16, 8), child: _dailyChart(reports, p)),
                  ),
                ],
                _downtimeCard(context, reports),
                SectionTitle('Máquinas asignadas (${asg.where((a) => a.active).length})'),
                if (asg.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Sin máquinas. Usa “Asignar máquina” para agregar una con su operador y ayudante.',
                      style: TextStyle(color: Ox.lightGray),
                    ),
                  ),
                for (final a in asg) _assignmentTile(context, d, p, a),
                if (reports.isNotEmpty) ...[
                  const SectionTitle('Últimos reportes'),
                  for (final r in reports.take(30)) _reportTile(context, d, p, r),
                ],
                if ((p.notes ?? '').isNotEmpty) ...[
                  const SectionTitle('Notas'),
                  Text(p.notes!, style: const TextStyle(color: Ox.lightGray)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Paros del proyecto agrupados por motivo.
  Widget _downtimeCard(BuildContext context, List<DailyReport> reports) {
    final sum = downtimeSummary(reports);
    if (sum.lines.isEmpty) return const SizedBox.shrink();
    final maxH = sum.lines.first.hours;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Paros · ${numText(sum.totalHours)} h en ${sum.totalDays} día${sum.totalDays == 1 ? '' : 's'}'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final l in sum.lines) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          downtimeReasonLabels[l.reason] ?? l.reason,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${numText(l.hours)} h · ${l.days} día${l.days == 1 ? '' : 's'}',
                        style: const TextStyle(color: Ox.lightGray, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxH == 0 ? 0 : l.hours / maxH,
                      minHeight: 6,
                      backgroundColor: Ox.darkGray,
                      color: l.reason == 'cliente' || l.reason == 'falta_material' ? Ox.blue : Ox.lightGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (sum.clientHours > 0)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Ox.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Ox.blue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${numText(sum.clientHours)} h perdidas por atraso del cliente o falta de material. '
                            'Te sirve como respaldo para reclamar tiempo o cobro.',
                            style: const TextStyle(fontSize: 12, color: Ox.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Elige el rango de fechas y comparte el PDF de producción para el cliente.
  Future<void> _clientPdf(BuildContext context, AdminData d, Project p, List<DailyReport> reports) async {
    final now = DateTime.now();
    final first = reports.map((r) => r.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(Duration(days: now.weekday - 1 + 7)),
        end: now,
      ),
      helpText: 'Periodo del reporte',
      saveText: 'Siguiente',
    );
    if (range == null || !context.mounted) return;
    final withAmounts = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Ox.graphite,
        title: const Text('¿Incluir montos?'),
        content: const Text('Puedes mostrar el monto en US\$ del periodo (incas × precio) o solo la producción.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Solo producción')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Incluir montos')),
        ],
      ),
    );
    if (withAmounts == null || !context.mounted) return;
    final toDate = reports
        .where((r) => !dayOnly(r.date).isAfter(dayOnly(range.end)))
        .fold<int>(0, (a, r) => a + r.units);
    await guard(context, () async {
      final bytes = await clientReportPdf(
        project: p,
        reports: reports,
        machines: d.machineById,
        from: range.start,
        to: range.end,
        unitsToDate: toDate,
        includeAmounts: withAmounts,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_${p.name.replaceAll(' ', '_')}_${dateKey(range.end)}.pdf',
      );
    });
  }

  Widget _line(String a, String b, {Color? color}) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(a, style: const TextStyle(color: Ox.lightGray)),
        ),
        Text(
          b,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    ),
  );

  Widget _dailyChart(List<DailyReport> reports, Project p) {
    final byDay = <String, int>{};
    for (final r in reports) {
      byDay.update(dateKey(r.date), (v) => v + r.units, ifAbsent: () => r.units);
    }
    final keys = byDay.keys.toList()..sort();
    final last = keys.length > 21 ? keys.sublist(keys.length - 21) : keys;
    final maxY = [...last.map((k) => byDay[k]!.toDouble()), p.dailyTarget.toDouble()].reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.15 + 1,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: Ox.darkGray, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (p.dailyTarget > 0)
                HorizontalLine(
                  y: p.dailyTarget.toDouble(),
                  color: Ox.lightGray,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: const TextStyle(color: Ox.lightGray, fontSize: 10),
                    labelResolver: (_) => 'meta',
                  ),
                ),
            ],
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, m) => v == m.max
                    ? const SizedBox.shrink()
                    : Text(number(v.round()), style: const TextStyle(fontSize: 10, color: Ox.lightGray)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i >= last.length || (last.length > 10 && i % 3 != 0)) return const SizedBox.shrink();
                  final d = DateTime.parse(last[i]);
                  return Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10, color: Ox.lightGray));
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Ox.darkGray,
              getTooltipItem: (g, _, r, _) => BarTooltipItem(
                '${number(r.toY.round())} ${p.unitName}',
                const TextStyle(color: Ox.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < last.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: byDay[last[i]]!.toDouble(),
                    width: last.length > 14 ? 8 : 14,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    color: p.dailyTarget > 0 && byDay[last[i]]! >= p.dailyTarget
                        ? Ox.yellow
                        : Ox.yellow.withValues(alpha: 0.5),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _assignmentTile(BuildContext context, AdminData d, Project p, Assignment a) {
    final m = d.machineById[a.machineId];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.precision_manufacturing_outlined, color: Ox.yellow, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(m?.label ?? 'Máquina', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  StatusChip(a.active ? 'Activa' : 'Finalizada', a.active ? Ox.green : Ox.lightGray),
                ],
              ),
              const SizedBox(height: 8),
              Text('Operador: ${d.personName(a.operatorId)} · ${quetzal(a.operatorDailyPay)}/día'),
              if (a.targetFor(p) > 0) Text('Meta: ${number(a.targetFor(p))} ${p.unitName}/día'),
              if (a.helperId != null) Text('Ayudante: ${d.personName(a.helperId)} · ${quetzal(a.helperDailyPay)}/día'),
              Text(
                'Desde ${fecha(a.startDate)}${a.endDate != null ? ' hasta ${fecha(a.endDate)}' : ''}',
                style: const TextStyle(color: Ox.lightGray, fontSize: 12),
              ),
              if (a.active) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Editar'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignmentForm(store: store, project: p, assignment: a),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add_task, size: 16),
                      label: const Text('Cargar reporte'),
                      onPressed: m == null
                          ? null
                          : () async {
                              final ok = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportForm(
                                    assignment: a,
                                    project: p,
                                    machine: m,
                                    helperName: a.helperId == null ? null : d.personName(a.helperId),
                                    asAdmin: true,
                                  ),
                                ),
                              );
                              if (ok == true) store.reload();
                            },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.link_off, size: 16, color: Ox.red),
                      label: const Text('Finalizar', style: TextStyle(color: Ox.red)),
                      onPressed: () async {
                        if (!await confirm(
                          context,
                          'Finalizar asignación',
                          'La máquina quedará libre y el operador ya no podrá reportar en este proyecto.',
                          action: 'Finalizar',
                        )) {
                          return;
                        }
                        if (!context.mounted) return;
                        if (await guard(context, () => Repo.endAssignment(a))) store.reload();
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportTile(BuildContext context, AdminData d, Project p, DailyReport r) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Card(
      child: ListTile(
        dense: true,
        title: Text('${diaSemana(r.date)} · ${d.machineById[r.machineId]?.name ?? ''}'),
        subtitle: Text(
          [
            d.personName(r.operatorId),
            if (r.hours != null) '${numText(r.hours)} h',
            'Planilla ${quetzal(r.labor)}',
            if (r.hasDowntime) 'paro ${numText(r.downtimeHours)} h (${downtimeReasonLabels[r.downtimeReason] ?? ''})',
            if (!r.payDay) 'día no pagado',
            if (!r.helperPresent) 'ayudante ausente',
            if ((r.notes ?? '').isNotEmpty) r.notes!,
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (r.photos.isNotEmpty) ...[
              const Icon(Icons.photo_outlined, size: 16, color: Ox.lightGray),
              const SizedBox(width: 6),
            ],
            Text(number(r.units), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Ox.yellow)),
          ],
        ),
        onTap: () async {
          final a = d.assignments.where((x) => x.id == r.assignmentId).firstOrNull;
          final m = d.machineById[r.machineId];
          if (a == null || m == null) return;
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ReportForm(
                assignment: a,
                project: p,
                machine: m,
                helperName: a.helperId == null ? null : d.personName(a.helperId),
                existing: r,
                asAdmin: true,
              ),
            ),
          );
          if (ok == true) store.reload();
        },
        onLongPress: () async {
          if (!await confirm(context, 'Eliminar reporte', '¿Eliminar el reporte del ${fecha(r.date)}?')) return;
          if (!context.mounted) return;
          if (await guard(context, () => Repo.deleteReport(r.id), ok: 'Reporte eliminado')) store.reload();
        },
      ),
    ),
  );
}
