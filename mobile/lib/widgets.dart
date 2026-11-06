import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'theme.dart';

void toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? Ox.red : Ox.darkGray));
}

/// Ejecuta una acción mostrando el error amigable si falla. Devuelve true si salió bien.
Future<bool> guard(BuildContext context, Future<void> Function() fn, {String? ok}) async {
  try {
    await fn();
    if (ok != null && context.mounted) toast(context, ok);
    return true;
  } catch (e) {
    if (context.mounted) toast(context, friendlyError(e), error: true);
    return false;
  }
}

Future<bool> confirm(BuildContext context, String title, String body, {String action = 'Eliminar'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: Ox.graphite,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(
            action,
            style: const TextStyle(color: Ox.red, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return r == true;
}

class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 40});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Ox.black,
      borderRadius: BorderRadius.circular(size * 0.22),
      border: Border.all(color: Ox.yellow.withValues(alpha: 0.6)),
      boxShadow: [BoxShadow(color: Ox.yellow.withValues(alpha: 0.18), blurRadius: 18)],
    ),
    alignment: Alignment.center,
    child: Text(
      'O',
      style: Theme.of(context).textTheme.headlineSmall
          ?.copyWith(color: Ox.yellow, fontWeight: FontWeight.w900, fontSize: size * 0.5),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(fontSize: 11, letterSpacing: 1.6, color: Ox.lightGray, fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class Kpi extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? color;
  final IconData? icon;
  const Kpi({super.key, required this.label, required this.value, this.sub, this.color, this.icon});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 14, color: Ox.lightGray), const SizedBox(width: 6)],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Ox.lightGray, letterSpacing: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: color ?? Ox.white, fontWeight: FontWeight.w800),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Ox.lightGray),
            ),
          ],
        ],
      ),
    ),
  );
}

class KpiGrid extends StatelessWidget {
  final List<Widget> children;
  const KpiGrid(this.children, {super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (c, box) {
      final cols = box.maxWidth > 700 ? 4 : 2;
      final w = (box.maxWidth - (cols - 1) * 10) / cols;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (final k in children) SizedBox(width: w, child: k)],
      );
    },
  );
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip(this.label, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

Color projectStatusColor(String s) => switch (s) {
  'activo' => Ox.green,
  'planificado' => Ox.blue,
  'pausado' => Ox.yellow,
  _ => Ox.lightGray,
};

Color machineStatusColor(String s) => switch (s) {
  'disponible' => Ox.green,
  'en_proyecto' => Ox.yellow,
  'mantenimiento' => Ox.blue,
  _ => Ox.red,
};

class ProgressBar extends StatelessWidget {
  final double value;
  final double height;
  const ProgressBar(this.value, {super.key, this.height = 8});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: LinearProgressIndicator(
      value: value,
      minHeight: height,
      backgroundColor: Ox.darkGray,
      color: value >= 1 ? Ox.green : Ox.yellow,
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.action});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Ox.darkGray),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Ox.lightGray),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

class ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorRetry(this.error, this.onRetry, {super.key});
  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off,
    title: 'No se pudo cargar',
    body: friendlyError(error),
    action: OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
  );
}

// ------------------------------------------------------------------ campos de formulario
class Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffix;
  final String? prefix;
  final bool number;
  final bool decimal;
  final bool required;
  final int maxLines;
  final bool obscure;
  final String? Function(String?)? validator;
  const Field(
    this.controller,
    this.label, {
    super.key,
    this.hint,
    this.suffix,
    this.prefix,
    this.number = false,
    this.decimal = false,
    this.required = false,
    this.maxLines = 1,
    this.obscure = false,
    this.validator,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      keyboardType: number ? TextInputType.numberWithOptions(decimal: decimal) : null,
      inputFormatters: number
          ? [FilteringTextInputFormatter.allow(decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'))]
          : null,
      decoration: InputDecoration(labelText: label, hintText: hint, suffixText: suffix, prefixText: prefix),
      validator: validator ?? (required ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null : null),
    ),
  );
}

class Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final bool required;
  const Dropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.required = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      initialValue: items.containsKey(value) ? value : null,
      isExpanded: true,
      dropdownColor: Ox.graphite,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final e in items.entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
      validator: required ? (v) => v == null ? 'Obligatorio' : null : null,
    ),
  );
}

class DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? first;
  final DateTime? last;
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.first,
    this.last,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: first ?? DateTime(2020),
          lastDate: last ?? DateTime(2035),
        );
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today, size: 18)),
        child: Text(fecha(value)),
      ),
    ),
  );
}

double? parseNum(String s) => s.trim().isEmpty ? null : double.tryParse(s.trim());
String numText(num? v) => v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());
