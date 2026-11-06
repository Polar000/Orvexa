import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orvexa_app/models.dart';
import 'package:orvexa_app/pdf_docs.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  test('recibo y reporte de cliente se generan', () async {
    final period = PayrollPeriod(
      id: 'x',
      start: DateTime(2026, 11, 1),
      end: DateTime(2026, 11, 15),
      status: 'pagado',
      paidAt: DateTime(2026, 11, 15),
    );
    final pay = PayrollPayment(
      id: 'p',
      periodId: 'x',
      personName: 'Juan Pérez Gómez',
      role: 'operador',
      days: 12,
      gross: 3600,
      bonuses: 150,
      advances: 500,
      deductions: 0,
      net: 3250,
    );
    final receipt = await payrollReceiptPdf(
      pay,
      period,
      adjustments: [
        PayrollAdjustment(
          id: 'a',
          personId: 'op',
          date: DateTime(2026, 11, 4),
          kind: 'adelanto',
          amount: 500,
          note: 'Adelanto en efectivo',
        ),
        PayrollAdjustment(
          id: 'b',
          personId: 'op',
          date: DateTime(2026, 11, 10),
          kind: 'bono',
          amount: 150,
          note: 'Meta cumplida',
        ),
      ],
    );
    expect(receipt.length, greaterThan(1000));
    final project = Project(
      id: 'p1',
      name: 'Parque Solar Escuintla F2',
      client: 'SolarGT S.A.',
      location: 'Masagua, Escuintla',
      type: 'hincado',
      status: 'activo',
      billingMode: 'por_unidad',
      totalUnits: 24000,
      dailyTarget: 400,
      pricePerUnit: 18.5,
      dailyRate: 0,
      workDaysPerWeek: 6,
    );
    final machines = {
      'm1': Machine(
        id: 'm1',
        name: 'Hincadora HWL600R #1',
        type: 'hincadora',
        status: 'en_proyecto',
        operatorDailyPay: 300,
        helperDailyPay: 180,
      ),
      'm2': Machine(
        id: 'm2',
        name: 'Hincadora HWL600R #2',
        type: 'hincadora',
        status: 'en_proyecto',
        operatorDailyPay: 300,
        helperDailyPay: 180,
      ),
    };
    final reports = [
      for (var d = 2; d <= 14; d++)
        if (DateTime(2026, 11, d).weekday != 7)
          for (final m in ['m1', 'm2'])
            DailyReport(
              id: '$d$m',
              assignmentId: 'a',
              projectId: 'p1',
              machineId: m,
              date: DateTime(2026, 11, d),
              units: d == 5 ? 0 : 190 + d,
              hours: d == 5 ? 0 : 9,
              helperPresent: true,
              operatorPay: 300,
              helperPay: 180,
              downtimeHours: d == 5 ? 9 : (d == 9 && m == 'm1' ? 3 : 0),
              downtimeReason: d == 5 ? 'lluvia' : (d == 9 && m == 'm1' ? 'falta_material' : null),
              notes: d == 9 && m == 'm1' ? 'Sin perfiles C hasta las 11 am' : null,
            ),
    ];
    final report = await clientReportPdf(
      project: project,
      reports: reports,
      machines: machines,
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 15),
      unitsToDate: 13803,
      includeAmounts: true,
    );
    expect(report.length, greaterThan(1000));
    final dir = Platform.environment['PDF_OUT'];
    if (dir != null) {
      File('$dir/recibo.pdf').writeAsBytesSync(receipt);
      File('$dir/reporte_cliente.pdf').writeAsBytesSync(report);
    }
  });
}
