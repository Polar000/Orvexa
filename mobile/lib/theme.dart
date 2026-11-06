import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Paleta de la landing ORVEXA
class Ox {
  static const black = Color(0xFF080A0B);
  static const graphite = Color(0xFF15191C);
  static const darkGray = Color(0xFF252B2F);
  static const white = Color(0xFFF5F6F3);
  static const lightGray = Color(0xFF9BA2A6);
  static const yellow = Color(0xFFF5B800);
  static const brightYellow = Color(0xFFFFD23F);
  static const green = Color(0xFF3FBF7F);
  static const red = Color(0xFFE5534B);
  static const blue = Color(0xFF5AA9E6);
}

/// En pruebas se desactiva para no descargar fuentes.
bool useGoogleFonts = true;

ThemeData orvexaTheme({String testFont = 'TestSans'}) {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  final body = useGoogleFonts ? GoogleFonts.inter().fontFamily : testFont;
  final head = useGoogleFonts ? GoogleFonts.spaceGrotesk().fontFamily : testFont;
  final text = base.textTheme.apply(fontFamily: body, bodyColor: Ox.white, displayColor: Ox.white);
  final heading = text.apply(fontFamily: head);
  return base.copyWith(
    scaffoldBackgroundColor: Ox.black,
    colorScheme: const ColorScheme.dark(
      primary: Ox.yellow,
      onPrimary: Ox.black,
      secondary: Ox.brightYellow,
      surface: Ox.graphite,
      onSurface: Ox.white,
      error: Ox.red,
      outline: Ox.darkGray,
    ),
    textTheme: text.copyWith(
      headlineLarge: heading.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium: heading.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      headlineSmall: heading.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: heading.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: heading.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Ox.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: head, fontSize: 20, fontWeight: FontWeight.w800, color: Ox.white, letterSpacing: 0.5),
    ),
    cardTheme: CardThemeData(
      color: Ox.graphite,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Ox.darkGray)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Ox.graphite,
      labelStyle: const TextStyle(color: Ox.lightGray),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Ox.darkGray)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Ox.darkGray)),
      focusedBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Ox.yellow, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Ox.yellow,
        foregroundColor: Ox.black,
        minimumSize: const Size.fromHeight(52),
        textStyle: TextStyle(fontFamily: head, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Ox.white,
        side: const BorderSide(color: Ox.darkGray),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Ox.graphite,
      indicatorColor: Ox.yellow.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: s.contains(WidgetState.selected) ? Ox.yellow : Ox.lightGray),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Ox.yellow : Ox.lightGray),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Ox.yellow, foregroundColor: Ox.black),
    dividerTheme: const DividerThemeData(color: Ox.darkGray, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

final _money = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);
final _money0 = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 0);
final _compact = NumberFormat.compactCurrency(locale: 'en_US', symbol: r'$');
final _num = NumberFormat.decimalPattern('en_US');

String money(num v) => _money.format(v);
String money0(num v) => _money0.format(v);
String moneyShort(num v) => v.abs() >= 10000 ? _compact.format(v) : _money0.format(v);
String number(num v) => _num.format(v);

const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
String fecha(DateTime? d) => d == null ? '—' : '${d.day} ${_meses[d.month - 1]} ${d.year}';
String fechaCorta(DateTime d) => '${d.day} ${_meses[d.month - 1]}';
String diaSemana(DateTime d) => '${_dias[d.weekday - 1]} ${d.day} ${_meses[d.month - 1]}';
String mesCorto(DateTime d) => _meses[d.month - 1];
String mesLargo(DateTime d) {
  const m = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
  return '${m[d.month - 1]} ${d.year}';
}
