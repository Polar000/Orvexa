import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'data.dart';
import 'models.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/login_screen.dart';
import 'screens/operator/operator_home.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  runApp(const OrvexaApp());
}

class OrvexaApp extends StatelessWidget {
  const OrvexaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ORVEXA Operaciones',
    debugShowCheckedModeBanner: false,
    theme: orvexaTheme(),
    locale: const Locale('es'),
    supportedLocales: const [Locale('es'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const AuthGate(),
  );
}

/// Decide qué ver según la sesión y el rol del usuario.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<Profile?>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
    db.auth.onAuthStateChange.listen((e) {
      if (e.event == AuthChangeEvent.signedIn || e.event == AuthChangeEvent.signedOut) {
        if (mounted) setState(_load);
      }
    });
  }

  void _load() => _profile = db.auth.currentSession == null ? Future.value(null) : Repo.myProfile();

  @override
  Widget build(BuildContext context) {
    if (db.auth.currentSession == null) return const LoginScreen();
    return FutureBuilder<Profile?>(
      future: _profile,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(body: ErrorRetry(snap.error!, () => setState(_load)));
        }
        final p = snap.data;
        if (p == null || !p.active) {
          return Scaffold(
            body: EmptyState(
              icon: Icons.lock_outline,
              title: 'Cuenta sin acceso',
              body: 'Tu usuario está desactivado o pendiente. Pide al administrador que lo active.',
              action: OutlinedButton(onPressed: () => db.auth.signOut(), child: const Text('Cerrar sesión')),
            ),
          );
        }
        return p.role == UserRole.admin ? AdminShell(me: p) : OperatorHome(me: p);
      },
    );
  }
}
