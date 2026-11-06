// Documentos PDF: recibo de planilla y reporte de producción para el cliente.
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'calc.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart' show numText;

const _yellow = PdfColor.fromInt(0xFFF5B800);
const _dark = PdfColor.fromInt(0xFF15191C);
const _gray = PdfColor.fromInt(0xFF6B7276);
const _line = PdfColor.fromInt(0xFFDDDFE0);

pw.Widget _header(String title, String subtitle) => pw.Container(
  padding: const pw.EdgeInsets.only(bottom: 12),
  decoration: const pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: _yellow, width: 3)),
  ),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Container(
        width: 34,
        height: 34,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(color: _dark, borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Text(
          'O',
          style: pw.TextStyle(color: _yellow, fontWeight: pw.FontWeight.bold, fontSize: 18),
        ),
      ),
      pw.SizedBox(width: 10),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ORVEXA', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, letterSpacing: 3)),
          pw.Text(
            'HEAVY MACHINERY & INFRASTRUCTURE',
            style: const pw.TextStyle(fontSize: 7, color: _gray, letterSpacing: 1.5),
          ),
        ],
      ),
      pw.Spacer(),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: _gray)),
        ],
      ),
    ],
  ),
);

pw.Widget _kv(String k, String v, {bool bold = false, PdfColor? color}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 3),
  child: pw.Row(
    children: [
      pw.Expanded(
        child: pw.Text(k, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : null)),
      ),
      pw.Text(
        v,
        style: pw.TextStyle(fontSize: bold ? 12 : 10, fontWeight: bold ? pw.FontWeight.bold : null, color: color),
      ),
    ],
  ),
);

/// Recibo de pago de planilla para una persona.
Future<Uint8List> payrollReceiptPdf(
  PayrollPayment p,
  PayrollPeriod period, {
  List<PayrollAdjustment> adjustments = const [],
}) async {
  final doc = pw.Document(title: 'Recibo ${p.personName}', author: 'ORVEXA');
  final roleLabel = p.role == 'ayudante' ? 'Ayudante' : (p.role == 'admin' ? 'Administrador' : 'Operador');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (c) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('RECIBO DE PAGO', 'Periodo ${fecha(period.start)} al ${fecha(period.end)}'),
          pw.SizedBox(height: 20),
          _kv('Nombre', p.personName, bold: true),
          _kv('Puesto', roleLabel),
          _kv('Fecha de pago', fecha(period.paidAt ?? DateTime.now())),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _kv('Días trabajados', '${p.days}'),
                _kv('Salario por días', quetzal(p.gross)),
                if (p.bonuses > 0) _kv('(+) Bonos', quetzal(p.bonuses)),
                if (p.advances > 0) _kv('(-) Adelantos', quetzal(p.advances)),
                if (p.deductions > 0) _kv('(-) Descuentos', quetzal(p.deductions)),
                pw.Divider(color: _line),
                _kv('TOTAL A RECIBIR', quetzal(p.net), bold: true),
              ],
            ),
          ),
          if (adjustments.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('Detalle de ajustes', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            for (final a in adjustments)
              _kv(
                '${fecha(a.date)} - ${adjustmentKindLabels[a.kind]}${(a.note ?? '').isNotEmpty ? ': ${a.note}' : ''}',
                quetzal(a.amount),
              ),
          ],
          pw.Spacer(),
          pw.Row(
            children: [
              pw.Expanded(child: _signature('Recibí conforme')),
              pw.SizedBox(width: 40),
              pw.Expanded(child: _signature('Entregado por ORVEXA')),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text('Generado con ORVEXA Operaciones', style: const pw.TextStyle(fontSize: 7, color: _gray)),
        ],
      ),
    ),
  );
  return doc.save();
}

pw.Widget _signature(String label) => pw.Column(
  children: [
    pw.Container(height: 1, color: PdfColors.black),
    pw.SizedBox(height: 4),
    pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _gray)),
  ],
);

/// Reporte de producción por rango de fechas para el cliente.
Future<Uint8List> clientReportPdf({
  required Project project,
  required List<DailyReport> reports, // ya filtrados por proyecto
  required Map<String, Machine> machines,
  required DateTime from,
  required DateTime to,
  required int unitsToDate, // acumulado del proyecto hasta "to"
  bool includeAmounts = false,
}) async {
  final rs =
      reports.where((r) => !dayOnly(r.date).isBefore(dayOnly(from)) && !dayOnly(r.date).isAfter(dayOnly(to))).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  final units = rs.fold<int>(0, (a, r) => a + r.units);
  final days = rs.map((r) => dateKey(r.date)).toSet().length;
  final down = downtimeSummary(rs);
  final progress = project.totalUnits <= 0 ? null : unitsToDate / project.totalUnits;
  final amount = rs.fold<double>(0, (a, r) => a + reportRevenue(r, project));

  final doc = pw.Document(title: 'Reporte ${project.name}', author: 'ORVEXA');
  final headers = ['Fecha', 'Máquina', project.perUnit ? 'Incas' : 'Unid.', 'Horas', 'Paro', 'Observaciones'];
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(36),
      header: (c) => c.pageNumber == 1
          ? _header('REPORTE DE PRODUCCIÓN', '${fecha(from)} al ${fecha(to)}')
          : pw.Text(
              '${project.name} - ${fecha(from)} al ${fecha(to)}',
              style: const pw.TextStyle(fontSize: 8, color: _gray),
            ),
      footer: (c) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página ${c.pageNumber} de ${c.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: _gray),
        ),
      ),
      build: (c) => [
        pw.SizedBox(height: 14),
        pw.Text(project.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        if ((project.client ?? '').isNotEmpty)
          pw.Text('Cliente: ${project.client}', style: const pw.TextStyle(fontSize: 10)),
        if ((project.location ?? '').isNotEmpty)
          pw.Text('Ubicación: ${project.location}', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 14),
        pw.Row(
          children: [
            _box('${project.perUnit ? 'Incas' : 'Unidades'} en el periodo', number(units)),
            _box('Días trabajados', '$days'),
            _box('Promedio diario', days == 0 ? '-' : number((units / days).round())),
            if (progress != null) _box('Avance total', '${(progress * 100).toStringAsFixed(1)}%'),
            if (includeAmounts) _box('Monto del periodo', money(amount)),
          ],
        ),
        if (progress != null) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Acumulado: ${number(unitsToDate)} de ${number(project.totalUnits)} ${project.unitName}',
            style: const pw.TextStyle(fontSize: 9, color: _gray),
          ),
          pw.SizedBox(height: 4),
          pw.Stack(
            children: [
              pw.Container(
                height: 6,
                decoration: pw.BoxDecoration(color: _line, borderRadius: pw.BorderRadius.circular(3)),
              ),
              pw.Container(
                height: 6,
                width: 540 * progress.clamp(0, 1),
                decoration: pw.BoxDecoration(color: _yellow, borderRadius: pw.BorderRadius.circular(3)),
              ),
            ],
          ),
        ],
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: [
            for (final r in rs)
              [
                fechaCorta(r.date),
                machines[r.machineId]?.name ?? '',
                number(r.units),
                r.hours == null ? '' : numText(r.hours),
                r.hasDowntime ? '${numText(r.downtimeHours)} h ${downtimeReasonLabels[r.downtimeReason] ?? ''}' : '',
                r.notes ?? '',
              ],
            ['TOTAL', '', number(units), '', down.totalHours > 0 ? '${numText(down.totalHours)} h' : '', ''],
          ],
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: _dark),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignments: {2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
          columnWidths: {
            0: const pw.FixedColumnWidth(48),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FixedColumnWidth(40),
            3: const pw.FixedColumnWidth(36),
            4: const pw.FlexColumnWidth(2),
            5: const pw.FlexColumnWidth(3),
          },
          oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF6F7F7)),
          border: null,
        ),
        if (down.lines.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text('Paros en el periodo', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          for (final l in down.lines)
            _kv('${downtimeReasonLabels[l.reason]}  (${l.days} día${l.days == 1 ? '' : 's'})', '${numText(l.hours)} h'),
          if (down.clientHours > 0)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                'Horas no atribuibles a ORVEXA (atraso del cliente / falta de material): ${numText(down.clientHours)} h',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ),
        ],
        pw.SizedBox(height: 30),
        pw.Text(
          'Generado el ${fecha(DateTime.now())} con ORVEXA Operaciones',
          style: const pw.TextStyle(fontSize: 7, color: _gray),
        ),
      ],
    ),
  );
  return doc.save();
}

pw.Widget _box(String label, String value) => pw.Expanded(
  child: pw.Container(
    margin: const pw.EdgeInsets.only(right: 6),
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _line),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: _gray)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  ),
);
