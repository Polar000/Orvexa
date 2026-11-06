import 'package:flutter/material.dart';

import '../../data.dart';
import '../../models.dart';
import '../../offline.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'dashboard_tab.dart';
import 'finance_tab.dart';
import 'machines_tab.dart';
import 'people_tab.dart';
import 'projects_tab.dart';

/// Datos del admin compartidos entre pestañas y pantallas de detalle.
class AdminStore extends ChangeNotifier {
  AdminData? data;
  Object? error;
  bool loading = false;

  Future<void> reload() async {
    loading = true;
    notifyListeners();
    try {
      data = await Repo.loadAdmin();
      error = null;
    } catch (e) {
      error = e;
    }
    loading = false;
    notifyListeners();
  }
}

/// Reconstruye cuando cambian los datos del admin.
class StoreBuilder extends StatelessWidget {
  final AdminStore store;
  final Widget Function(BuildContext, AdminData) builder;
  const StoreBuilder({super.key, required this.store, required this.builder});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final d = store.data;
      if (d == null) {
        if (store.error != null) return ErrorRetry(store.error!, store.reload);
        return const Center(child: CircularProgressIndicator());
      }
      return builder(context, d);
    },
  );
}

class AdminShell extends StatefulWidget {
  final Profile me;
  final AdminStore? store; // para pruebas
  const AdminShell({super.key, required this.me, this.store});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late final AdminStore store = widget.store ?? AdminStore();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    if (widget.store == null) {
      store.reload();
      Outbox.instance.init(widget.me.id); // mantenimiento y combustible con fotos también desde el admin
    }
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  static const _titles = ['Panel', 'Proyectos', 'Máquinas', 'Personal', 'Finanzas'];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(store: store),
      ProjectsTab(store: store),
      MachinesTab(store: store),
      PeopleTab(store: store, me: widget.me),
      FinanceTab(store: store),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [const Logo(size: 30), const SizedBox(width: 10), Text(_titles[_tab])]),
        actions: [
          ListenableBuilder(
            listenable: store,
            builder: (_, _) => store.loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh), onPressed: store.reload),
          ),
          PopupMenuButton<String>(
            color: Ox.graphite,
            onSelected: (v) async {
              if (v == 'out' && await confirm(context, 'Cerrar sesión', '¿Salir de la app?', action: 'Salir')) {
                await db.auth.signOut();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text(widget.me.display)),
              const PopupMenuItem(value: 'out', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Proyectos',
          ),
          NavigationDestination(
            icon: Icon(Icons.precision_manufacturing_outlined),
            selectedIcon: Icon(Icons.precision_manufacturing),
            label: 'Máquinas',
          ),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Personal'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Finanzas',
          ),
        ],
      ),
    );
  }
}
