import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;
  bool _setup = false; // no hay admin todavía
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    Repo.needsSetup()
        .then((v) {
          if (mounted) setState(() => _setup = v);
        })
        .catchError((_) {});
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await guard(context, () async {
      if (_setup) await Repo.bootstrapAdmin(_name.text.trim(), _user.text.trim(), _pass.text);
      await Repo.signIn(_user.text, _pass.text);
    });
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Logo(size: 48),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ORVEXA',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(letterSpacing: 4, fontWeight: FontWeight.w900),
                            ),
                            const Text(
                              'OPERACIONES DE CAMPO',
                              style: TextStyle(fontSize: 10, letterSpacing: 2.4, color: Ox.lightGray),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _setup ? 'Crea el administrador' : 'Iniciar sesión',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _setup
                          ? 'Primera vez: esta cuenta controlará proyectos, máquinas y personal.'
                          : 'Usa el usuario y la contraseña que te dio el administrador. Si no tienes, pídeselo.',
                      style: const TextStyle(color: Ox.lightGray),
                    ),
                    const SizedBox(height: 24),
                    if (_setup) Field(_name, 'Nombre completo', required: true),
                    Field(_user, 'Usuario', hint: 'ej. jperez', required: true),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _pass,
                        obscureText: _hide,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(_hide ? Icons.visibility : Icons.visibility_off, size: 20),
                            onPressed: () => setState(() => _hide = !_hide),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Ox.black),
                            )
                          : Text(_setup ? 'CREAR Y ENTRAR' : 'ENTRAR'),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'THE POWER BEHIND THE PROJECT',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, letterSpacing: 2.4, color: Ox.darkGray),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
