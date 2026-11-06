import 'package:flutter/material.dart';
import '../../calc.dart';
import '../../data.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'admin_shell.dart';
import 'charts.dart';
import 'project_detail.dart';
import 'projects_tab.dart';

class DashboardTab extends StatelessWidget {
  final AdminStore store;
  const DashboardTab({super.key, required this.store});

  @override
  Widget build(BuildContext context) => StoreBuilder(
        store: store,
        builder: (context, d) {
          final now = DateTime.now();
          final today = dayOnly(now);
          final month = DateTime(now.year, now.month, 1);
          final active = d.projects.where((p) => p.status == 'activo').toList();
          final stats = d.projects.map((p) => projectStats(p, d.reports, d.assignments, d.maintenance)).toList();
          final unitsToday = d.reports.where((r) => dayOnly(r.date) == today).fold<int>(0, (s, r) => s + r.units);
          final targetToday = active.where((p) => isWorkDay(today, p.workDaysPerWeek)).fold<int>(0, (s, p) => s + p.dailyTarget);
          final unitsMonth = d.reports
              .where((r) => r.date.year == now.year && r.date.month == now.month)
              .fold<int>(0, (s, r) => s + r.units);
          final thisMonth = actualMonth(month, d.projects, d.reports, d.maintenance, d.expenses, d.settings);
          final history = [
            for (var i = 5; i >= 1; i--)
              actualMonth(DateTime(now.year, now.month - i, 1), d.projects, d.reports, d.maintenance, d.expenses, d.settings),
            thisMonth,
          ];
          // Mes 0 = resto del mes actual (consume avance pendiente); se muestran los 3 siguientes.
          final future = projectMonths(now, 4, stats, d.expenses, d.settings).skip(1).toList();
          // Alertas
          final activeAsg = d.assignments.where((a) => a.active && d.projectById[a.projectId]?.status == 'activo').toList();
          final missing = activeAsg
              .where((a) =>
                  isWorkDay(today, d.projectById[a.projectId]!.workDaysPerWeek) &&
                  !d.reports.any((r) => r.assignmentId == a.id && dayOnly(r.date) == today))
              .toList();
          final inMaint = d.machines.where((m) => m.status == 'mantenimiento' || m.status == 'fuera_servicio').toList();
          final overdue = d.expenses.where((e) => (!e.paid || e.recurrence != 'unica') && dayOnly(e.dueDate).isBefore(today)).toList();

          if (d.projects.isEmpty && d.machines.isEmpty) return _onboarding(context, d);

          return RefreshIndicator(
            onRefresh: store.reload,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
              Text(diaSemana(today).toUpperCase(), style: const TextStyle(color: Ox.lightGray, letterSpacing: 1.6, fontSize: 12)),
              const SizedBox(height: 12),
              KpiGrid([
                Kpi(
                  label: 'Incas hoy',
                  value: number(unitsToday),
                  sub: targetToday > 0 ? 'Meta ${number(targetToday)}' : null,
                  color: targetToday > 0 && unitsToday >= targetToday ? Ox.green : Ox.yellow,
                  icon: Icons.today,
                ),
                Kpi(label: 'Incas del mes', value: number(unitsMonth), icon: Icons.calendar_month),
                Kpi(label: 'Ingresos del mes', value: moneyShort(thisMonth.revenue), color: Ox.yellow, icon: Icons.trending_up),
                Kpi(
                  label: 'Utilidad del mes',
                  value: moneyShort(thisMonth.profit),
                  sub: 'Costos ${moneyShort(thisMonth.costs)}',
                  color: thisMonth.profit >= 0 ? Ox.green : Ox.red,
                  icon: Icons.savings_outlined,
                ),
              ]),
              if (missing.isNotEmpty || inMaint.isNotEmpty || overdue.isNotEmpty) ...[
                const SectionTitle('Atención'),
                if (missing.isNotEmpty)
                  _alert(Icons.pending_actions, Ox.yellow, '${missing.length} máquina${missing.length == 1 ? '' : 's'} sin reporte hoy',
                      missing.map((a) => '${d.machineById[a.machineId]?.name} (${d.personName(a.operatorId)})').join(', ')),
                if (inMaint.isNotEmpty)
                  _alert(Icons.build_outlined, Ox.blue, '${inMaint.length} en mantenimiento / fuera de servicio',
                      inMaint.map((m) => m.name).join(', ')),
                if (overdue.isNotEmpty)
                  _alert(Icons.warning_amber, Ox.red, '${overdue.length} obligación${overdue.length == 1 ? '' : 'es'} vencida${overdue.length == 1 ? '' : 's'}',
                      overdue.map((e) => '${e.description} ${money0(e.amount)}').join(', ')),
              ],
              const SectionTitle('Producción · últimos 14 días'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: ProductionChart(reports: d.reports, target: targetToday),
                ),
              ),
              const SectionTitle('Ingresos vs costos · real y proyección'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
                  child: MonthsChart(months: [...history, ...future]),
                ),
              ),
              SectionTitle('Proyectos activos (${active.length})'),
              if (active.isEmpty) const Text('No hay proyectos activos', style: TextStyle(color: Ox.lightGray)),
              for (final p in active) ...[ProjectCard(store: store, data: d, project: p), const SizedBox(height: 10)],
              if (active.isNotEmpty) ...[
                const SectionTitle('Proyección de proyectos activos'),
                Card(
                  child: Column(children: [
                    for (final st in stats.where((s) => s.project.status == 'activo'))
                      ListTile(
                        dense: true,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ProjectDetail(store: store, projectId: st.project.id))),
                        title: Text(st.project.name),
                        subtitle: Text('Por facturar ${moneyShort(st.remainingRevenue)} · planilla restante ${moneyShort(st.remainingLabor)}'),
                        trailing: Text(moneyShort(st.projectedProfit),
                            style: TextStyle(fontWeight: FontWeight.w800, color: st.projectedProfit >= 0 ? Ox.green : Ox.red)),
                      ),
                  ]),
                ),
              ],
            ]),
          );
        },
      );

  Widget _alert(IconData icon, Color color, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),
      );

  Widget _onboarding(BuildContext context, AdminData d) => ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 20),
        Text('Bienvenido a ORVEXA', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Para empezar:', style: TextStyle(color: Ox.lightGray)),
        const SizedBox(height: 20),
        _step('1', 'Agrega tus máquinas', 'Pestaña Máquinas · con el pago diario del operador y ayudante.'),
        _step('2', 'Crea a tu personal', 'Pestaña Personal · operadores y ayudantes con su usuario y contraseña.'),
        _step('3', 'Crea un proyecto', 'Pestaña Proyectos · incas totales, meta diaria y precio por inca.'),
        _step('4', 'Asigna la máquina', 'Dentro del proyecto · máquina + operador + ayudante.'),
        _step('5', 'Registra obligaciones', 'Pestaña Finanzas · renta, seguros, combustible, impuestos.'),
      ]);

  Widget _step(String n, String t, String b) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 14, backgroundColor: Ox.yellow, child: Text(n, style: const TextStyle(color: Ox.black, fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(b, style: const TextStyle(color: Ox.lightGray)),
            ]),
          ),
        ]),
      );
}
