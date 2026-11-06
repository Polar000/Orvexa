import 'package:flutter/material.dart';
import '../../calc.dart';
import '../../data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'admin_shell.dart';

class PeopleTab extends StatelessWidget {
  final AdminStore store;
  final Profile me;
  const PeopleTab({super.key, required this.store, required this.me});

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'newPerson',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PersonForm(store: store))),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Usuario', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: StoreBuilder(
          store: store,
          builder: (context, d) {
            final now = DateTime.now();
            final from = DateTime(now.year, now.month, 1);
            final pay = payroll(d.reports, d.assignments, from, now);
            final groups = {
              UserRole.operador: d.profiles.where((p) => p.role == UserRole.operador).toList(),
              UserRole.ayudante: d.profiles.where((p) => p.role == UserRole.ayudante).toList(),
              UserRole.admin: d.profiles.where((p) => p.role == UserRole.admin).toList(),
            };
            final totalPay = pay.values.fold<double>(0, (s, l) => s + l.amount);
            return RefreshIndicator(
              onRefresh: store.reload,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined, color: Ox.yellow),
                    title: Text('Planilla de ${mesLargo(now).toLowerCase()}'),
                    subtitle: const Text('Según días reportados'),
                    trailing: Text(quetzal(totalPay), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Ox.yellow)),
                  ),
                ),
                for (final g in groups.entries)
                  if (g.value.isNotEmpty) ...[
                    SectionTitle('${const {UserRole.operador: 'Operadores', UserRole.ayudante: 'Ayudantes', UserRole.admin: 'Administradores'}[g.key]} (${g.value.length})'),
                    for (final p in g.value) _tile(context, d, p, pay[p.id]),
                  ],
              ]),
            );
          },
        ),
      );

  Widget _tile(BuildContext context, AdminData d, Profile p, PayrollLine? pay) {
    final a = d.assignments.where((x) => x.active && (x.operatorId == p.id || x.helperId == p.id)).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PersonForm(store: store, person: p, me: me))),
          leading: CircleAvatar(
            backgroundColor: p.active ? Ox.yellow.withValues(alpha: 0.15) : Ox.darkGray,
            child: Text(p.display.isEmpty ? '?' : p.display[0].toUpperCase(),
                style: TextStyle(color: p.active ? Ox.yellow : Ox.lightGray, fontWeight: FontWeight.w800)),
          ),
          title: Text(p.display + (p.active ? '' : ' (inactivo)')),
          subtitle: Text([
            '@${p.username ?? ''}',
            if (a != null) '${d.machineById[a.machineId]?.name ?? ''} · ${d.projectById[a.projectId]?.name ?? ''}' else if (p.role != UserRole.admin) 'Sin asignar',
          ].join('\n')),
          isThreeLine: true,
          trailing: pay == null
              ? null
              : Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(quetzal0(pay.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${pay.days} días', style: const TextStyle(fontSize: 11, color: Ox.lightGray)),
                ]),
        ),
      ),
    );
  }
}

class PersonForm extends StatefulWidget {
  final AdminStore store;
  final Profile? person;
  final Profile? me;
  const PersonForm({super.key, required this.store, this.person, this.me});
  @override
  State<PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<PersonForm> {
  final _form = GlobalKey<FormState>();
  late final p = widget.person;
  late final _name = TextEditingController(text: p?.fullName ?? '');
  late final _user = TextEditingController(text: p?.username ?? '');
  late final _phone = TextEditingController(text: p?.phone ?? '');
  final _pass = TextEditingController();
  late UserRole _role = p?.role ?? UserRole.operador;
  late bool _active = p?.active ?? true;
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await guard(context, () async {
      if (p == null) {
        await Repo.createUser(
          fullName: _name.text.trim(),
          username: _user.text.trim(),
          password: _pass.text,
          role: _role,
          phone: _phone.text.trim(),
        );
      } else {
        await Repo.updateUser(p!.id, {
          'full_name': _name.text.trim(),
          'role': _role.name,
          'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          'active': _active,
        });
        if (_pass.text.isNotEmpty) await Repo.setPassword(p!.id, _pass.text);
      }
    }, ok: p == null ? 'Usuario creado' : 'Usuario actualizado');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      widget.store.reload();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = p != null && widget.me?.id == p!.id;
    return Scaffold(
      appBar: AppBar(title: Text(p == null ? 'Nuevo usuario' : 'Editar usuario')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const SectionTitle('Rol'),
          SegmentedButton<UserRole>(
            segments: const [
              ButtonSegment(value: UserRole.operador, label: Text('Operador')),
              ButtonSegment(value: UserRole.ayudante, label: Text('Ayudante')),
              ButtonSegment(value: UserRole.admin, label: Text('Admin')),
            ],
            selected: {_role},
            onSelectionChanged: isMe ? null : (s) => setState(() => _role = s.first),
          ),
          const SizedBox(height: 16),
          Field(_name, 'Nombre completo', required: true),
          if (p == null)
            Field(_user, 'Usuario para entrar', hint: 'ej. jperez (sin espacios)', validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'Obligatorio';
              if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(t) && !t.contains('@')) return 'Solo letras, números, punto o guion';
              return null;
            })
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Text('Usuario: @${p!.username ?? ''}', style: const TextStyle(color: Ox.lightGray)),
            ),
          Field(_phone, 'Teléfono'),
          Field(
            _pass,
            p == null ? 'Contraseña' : 'Nueva contraseña (dejar vacío para no cambiar)',
            obscure: true,
            validator: (v) {
              if (p != null && (v ?? '').isEmpty) return null;
              return (v ?? '').length < 6 ? 'Mínimo 6 caracteres' : null;
            },
          ),
          if (p != null && !isMe)
            Card(
              child: SwitchListTile(
                value: _active,
                activeThumbColor: Ox.yellow,
                title: const Text('Activo'),
                subtitle: const Text('Si lo desactivas ya no podrá entrar a la app'),
                onChanged: (v) => setState(() => _active = v),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy ? const CircularProgressIndicator(color: Ox.black) : const Text('GUARDAR'),
          ),
          if (p == null)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Comparte el usuario y la contraseña con la persona. Podrá entrar desde su teléfono.',
                  style: TextStyle(color: Ox.lightGray, fontSize: 12), textAlign: TextAlign.center),
            ),
        ]),
      ),
    );
  }
}
