// Portal del cliente (contratante): avance de sus proyectos, fotos de obra e informe PDF.
// Solo ve producción, horas y paros. No ve precios, pagos, personal ni notas internas.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../calc.dart';
import '../../data.dart';
import '../../models.dart';
import '../../pdf_docs.dart';
import '../../photos.dart';
import '../../theme.dart';
import '../../widgets.dart';

class ClientHome extends StatefulWidget {
  final Profile me;
  final Future<ClientData> Function()? loader; // para pruebas
  final Future<ClientProjectData> Function(String projectId)? projectLoader;
  const ClientHome({super.key, required this.me, this.loader, this.projectLoader});
  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  late Future<ClientData> _f = _load();
  Future<ClientData> _load() => (widget.loader ?? Repo.loadClient)();

  void _reload() {
    setState(() {
      _f = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Logo(size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.me.display, overflow: TextOverflow.ellipsis),
                  const Text('AVANCE DE OBRA', style: TextStyle(fontSize: 10, letterSpacing: 1.6, color: Ox.lightGray)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              if (await confirm(context, 'Cerrar sesión', '¿Salir de la app?', action: 'Salir')) {
                await db.auth.signOut();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<ClientData>(
        future: _f,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return ErrorRetry(snap.error!, _reload);
          final d = snap.data!;
          if (d.projects.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const EmptyState(
                  icon: Icons.hourglass_empty,
                  title: 'Aún no tienes proyectos',
                  body: 'Cuando ORVEXA te dé acceso a tu proyecto, aquí verás el avance día a día.',
                ),
                CompanyCard(d.company),
              ],
            );
          }
          if (d.projects.length == 1) {
            final p = d.projects.first;
            return ClientProjectView(
              project: p,
              company: d.company,
              activeMachines: d.activeMachines[p.id] ?? 0,
              loader: widget.projectLoader,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionTitle('Tus proyectos'),
                for (final p in d.projects)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        title: Text(p.name),
                        subtitle: Text(
                          [
                            projectStatusLabels[p.status] ?? '',
                            if ((p.location ?? '').isNotEmpty) p.location!,
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: Text(p.name, overflow: TextOverflow.ellipsis)),
                              body: ClientProjectView(
                                project: p,
                                company: d.company,
                                activeMachines: d.activeMachines[p.id] ?? 0,
                                loader: widget.projectLoader,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                CompanyCard(d.company),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Carga la producción del proyecto y la muestra.
class ClientProjectView extends StatefulWidget {
  final Project project;
  final CompanyInfo company;
  final int activeMachines;
  final Future<ClientProjectData> Function(String projectId)? loader;
  const ClientProjectView({
    super.key,
    required this.project,
    required this.company,
    required this.activeMachines,
    this.loader,
  });
  @override
  State<ClientProjectView> createState() => _ClientProjectViewState();
}

class _ClientProjectViewState extends State<ClientProjectView> {
  late Future<ClientProjectData> _f = _load();
  Future<ClientProjectData> _load() => (widget.loader ?? Repo.loadClientProject)(widget.project.id);

  @override
  Widget build(BuildContext context) => FutureBuilder<ClientProjectData>(
    future: _f,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snap.hasError) {
        return ErrorRetry(
          snap.error!,
          () => setState(() {
            _f = _load();
          }),
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          final f = _load();
          setState(() {
            _f = f;
          });
          await f;
        },
        child: ClientProgressBody(
          project: widget.project,
          data: snap.data!,
          company: widget.company,
          activeMachines: widget.activeMachines,
        ),
      );
    },
  );
}

class ClientProgressBody extends StatelessWidget {
  final Project project;
  final ClientProjectData data;
  final CompanyInfo company;
  final int activeMachines;
  const ClientProgressBody({
    super.key,
    required this.project,
    required this.data,
    required this.company,
    required this.activeMachines,
  });

  @override
  Widget build(BuildContext context) {
    final p = project;
    final reports = data.reports;
    final st = projectStats(p, reports, const [], const []);
    final today = DateTime.now();
    final end = st.estimatedEnd(today);
    final days = reports.map((r) => dateKey(r.date)).toSet().length;
    final down = downtimeSummary(reports);
    final photos = [
      for (final r in [...reports]..sort((a, b) => b.date.compareTo(a.date)))
        for (final ph in r.photos) (ph, r.date),
    ].take(12).toList();
    final recent = _byDay(reports).take(7).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(projectStatusLabels[p.status] ?? p.status, projectStatusColor(p.status)),
            StatusChip(projectTypeLabels[p.type] ?? p.type, Ox.lightGray),
          ],
        ),
        const SizedBox(height: 10),
        Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
        if ((p.location ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(p.location!, style: const TextStyle(color: Ox.lightGray)),
          ),
        const SectionTitle('Avance'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.totalUnits > 0) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(st.progress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Ox.yellow),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${number(st.unitsDone)} de ${number(p.totalUnits)} ${p.unitName}',
                          style: const TextStyle(color: Ox.lightGray),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ProgressBar(st.progress, height: 12),
                  const SizedBox(height: 14),
                  _line('Faltan', '${number(st.remainingUnits)} ${p.unitName}'),
                ] else
                  _line('Trabajado', '${number(st.unitsDone)} ${p.unitName}'),
                _line('Inicio', fecha(p.startDate)),
                if (p.totalUnits > 0)
                  _line(
                    'Fin estimado',
                    st.remainingUnits == 0 ? 'Terminado' : (end == null ? 'Por calcular' : fecha(end)),
                    color: Ox.yellow,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        KpiGrid([
          Kpi(label: 'Días trabajados', value: '$days', icon: Icons.calendar_month_outlined),
          Kpi(
            label: 'Promedio diario',
            value: days == 0 ? '—' : number((st.unitsDone / days).round()),
            sub: p.dailyTarget > 0 ? 'Meta ${number(p.dailyTarget)} / día' : null,
            icon: Icons.speed,
          ),
          Kpi(
            label: 'Ritmo últimos 7 días',
            value: st.recentPace > 0 ? number(st.recentPace.round()) : '—',
            sub: '${p.unitName} por día',
            icon: Icons.trending_up,
          ),
          Kpi(label: 'Máquinas en obra', value: '$activeMachines', icon: Icons.precision_manufacturing_outlined),
        ]),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: reports.isEmpty ? null : () => _downloadPdf(context, st.unitsDone),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('DESCARGAR INFORME PDF'),
        ),
        if (reports.isNotEmpty) ...[
          const SectionTitle('Producción diaria'),
          Card(
            child: Padding(padding: const EdgeInsets.fromLTRB(8, 16, 16, 8), child: _chart(reports, p)),
          ),
        ],
        if (photos.isNotEmpty) ...[
          const SectionTitle('Fotos de obra'),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final (path, date) in photos)
                Stack(
                  fit: StackFit.expand,
                  children: [
                    RemotePhoto(path, size: 200),
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Ox.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(fechaCorta(date), style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        if (recent.isNotEmpty) ...[
          const SectionTitle('Últimos días'),
          Card(
            child: Column(
              children: [
                for (final d in recent)
                  ListTile(
                    dense: true,
                    title: Text(diaSemana(d.date)),
                    subtitle: Text(
                      [
                        d.machines.join(', '),
                        if (d.downtime > 0) 'Paro ${numText(d.downtime)} h · ${d.reasons.join(', ')}',
                      ].where((s) => s.isNotEmpty).join('\n'),
                    ),
                    trailing: Text(
                      '${number(d.units)} ${p.unitName}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (down.lines.isNotEmpty) ...[
          const SectionTitle('Horas sin trabajar'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final l in down.lines)
                    _line(
                      '${downtimeReasonLabels[l.reason] ?? l.reason} (${l.days} día${l.days == 1 ? '' : 's'})',
                      '${numText(l.hours)} h',
                    ),
                ],
              ),
            ),
          ),
        ],
        if (reports.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Todavía no hay días reportados. El avance aparecerá aquí desde el primer día de trabajo.',
              style: TextStyle(color: Ox.lightGray),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 24),
        CompanyCard(company),
      ],
    );
  }

  Future<void> _downloadPdf(BuildContext context, int unitsDone) async {
    final now = DateTime.now();
    final first = data.reports.map((r) => r.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Ox.graphite,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('¿Qué periodo quieres en el informe?', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final (k, label) in [
              ('todo', 'Todo el proyecto'),
              ('semana', 'Últimos 7 días'),
              ('mes', 'Este mes'),
              ('elegir', 'Elegir fechas…'),
            ])
              ListTile(title: Text(label), onTap: () => Navigator.pop(c, k)),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    DateTimeRange? range = switch (choice) {
      'todo' => DateTimeRange(start: first, end: now),
      'semana' => DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now),
      'mes' => DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      _ => null,
    };
    range ??= await showDateRangePicker(
      context: context,
      firstDate: dayOnly(first),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now),
      helpText: 'Periodo del informe',
      saveText: 'Descargar',
    );
    if (range == null || !context.mounted) return;
    final r = range;
    final toDate = data.reports
        .where((x) => !dayOnly(x.date).isAfter(dayOnly(r.end)))
        .fold<int>(0, (a, x) => a + x.units);
    await guard(context, () async {
      final bytes = await clientReportPdf(
        project: project,
        reports: data.reports,
        machines: data.machines,
        from: r.start,
        to: r.end,
        unitsToDate: toDate,
        includeNotes: false,
        company: company,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'avance_${project.name.replaceAll(RegExp(r'\s+'), '_')}_${dateKey(r.end)}.pdf',
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

  List<_Day> _byDay(List<DailyReport> rs) {
    final m = <String, _Day>{};
    for (final r in rs) {
      final d = m.putIfAbsent(dateKey(r.date), () => _Day(dayOnly(r.date)));
      d.units += r.units;
      d.downtime += r.downtimeHours;
      final name = data.machines[r.machineId]?.name;
      if (name != null && name.isNotEmpty) d.machines.add(name);
      if (r.downtimeReason != null) d.reasons.add(downtimeReasonLabels[r.downtimeReason] ?? r.downtimeReason!);
    }
    return m.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Widget _chart(List<DailyReport> reports, Project p) {
    final days = _byDay(reports).take(14).toList().reversed.toList();
    final maxY = [...days.map((d) => d.units.toDouble()), p.dailyTarget.toDouble()].reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.15 + 1,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: Ox.darkGray, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: p.dailyTarget > 0
              ? ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: p.dailyTarget.toDouble(),
                      color: Ox.lightGray,
                      strokeWidth: 1,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(fontSize: 10, color: Ox.lightGray),
                        labelResolver: (_) => 'Meta',
                      ),
                    ),
                  ],
                )
              : null,
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
                  if (i < 0 || i >= days.length || (days.length > 7 && i.isOdd)) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${days[i].date.day}', style: const TextStyle(fontSize: 10, color: Ox.lightGray)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < days.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: days[i].units.toDouble(),
                    width: days.length > 10 ? 10 : 16,
                    color: p.dailyTarget > 0 && days[i].units < p.dailyTarget ? Ox.lightGray : Ox.yellow,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Day {
  final DateTime date;
  int units = 0;
  double downtime = 0;
  final Set<String> machines = {};
  final Set<String> reasons = {};
  _Day(this.date);
}

/// Espacio con los datos de la empresa, al pie de la pantalla del cliente.
class CompanyCard extends StatelessWidget {
  final CompanyInfo c;
  const CompanyCard(this.c, {super.key});
  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Ox.lightGray),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Ox.lightGray, fontSize: 13)),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Ox.graphite,
        border: Border(top: BorderSide(color: Ox.yellow, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.companyName, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          if (c.legalName != null) Text(c.legalName!, style: const TextStyle(color: Ox.lightGray, fontSize: 13)),
          if (c.nit != null) row(Icons.badge_outlined, 'NIT ${c.nit}'),
          if (c.address != null) row(Icons.place_outlined, c.address!),
          if (c.phone != null) row(Icons.phone_outlined, c.phone!),
          if (c.email != null) row(Icons.mail_outline, c.email!),
          if (c.website != null) row(Icons.language, c.website!),
        ],
      ),
    );
  }
}
