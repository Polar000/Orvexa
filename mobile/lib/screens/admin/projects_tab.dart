import 'package:flutter/material.dart';

import '../../calc.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'admin_shell.dart';
import 'project_detail.dart';
import 'project_form.dart';

class ProjectsTab extends StatefulWidget {
  final AdminStore store;
  const ProjectsTab({super.key, required this.store});
  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  String _filter = 'vigentes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'newProject',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectForm(store: widget.store))),
        icon: const Icon(Icons.add),
        label: const Text('Proyecto', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: StoreBuilder(
        store: widget.store,
        builder: (context, d) {
          final list = d.projects.where((p) {
            if (_filter == 'vigentes') return p.status != 'completado';
            if (_filter == 'completados') return p.status == 'completado';
            return true;
          }).toList();
          return RefreshIndicator(
            onRefresh: widget.store.reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'vigentes', label: Text('Vigentes')),
                    ButtonSegment(value: 'completados', label: Text('Completados')),
                    ButtonSegment(value: 'todos', label: Text('Todos')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyState(
                      icon: Icons.folder_open,
                      title: 'No hay proyectos',
                      body: 'Crea un proyecto de hincado o bobcat con el botón “+ Proyecto”.',
                    ),
                  ),
                for (final p in list) ...[
                  ProjectCard(store: widget.store, data: d, project: p),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final AdminStore store;
  final AdminData data;
  final Project project;
  const ProjectCard({super.key, required this.store, required this.data, required this.project});

  @override
  Widget build(BuildContext context) {
    final p = project;
    final st = projectStats(
      p,
      data.reports,
      data.assignments,
      data.maintenance,
      usdToGtq: data.settings.usdToGtq,
      fuel: data.fuel,
    );
    final end = st.estimatedEnd(DateTime.now());
    final machines = data.assignments.where((a) => a.projectId == p.id && a.active).length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetail(store: store, projectId: p.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    p.type == 'hincado' ? Icons.solar_power_outlined : Icons.agriculture_outlined,
                    color: Ox.yellow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(projectStatusLabels[p.status]!, projectStatusColor(p.status)),
                ],
              ),
              if ((p.client ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 28),
                  child: Text(p.client!, style: const TextStyle(color: Ox.lightGray, fontSize: 13)),
                ),
              const SizedBox(height: 14),
              if (p.totalUnits > 0) ...[
                Row(
                  children: [
                    Text(
                      '${number(st.unitsDone)} / ${number(p.totalUnits)} ${p.unitName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${(st.progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Ox.yellow, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ProgressBar(st.progress),
                const SizedBox(height: 10),
              ],
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _meta(Icons.precision_manufacturing_outlined, '$machines máquina${machines == 1 ? '' : 's'}'),
                  if (p.perUnit)
                    _meta(Icons.sell_outlined, '${money(p.pricePerUnit)}/inca')
                  else
                    _meta(Icons.sell_outlined, '${money0(p.dailyRate)}/día'),
                  _meta(Icons.payments_outlined, moneyShort(st.revenue)),
                  if (end != null) _meta(Icons.event_outlined, 'Fin est. ${fechaCorta(end)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData i, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(i, size: 14, color: Ox.lightGray),
      const SizedBox(width: 4),
      Text(t, style: const TextStyle(fontSize: 12, color: Ox.lightGray)),
    ],
  );
}
