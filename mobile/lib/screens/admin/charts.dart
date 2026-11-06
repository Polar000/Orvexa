import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../calc.dart';
import '../../models.dart';
import '../../theme.dart';

const _axis = TextStyle(fontSize: 10, color: Ox.lightGray);

FlTitlesData _titles({required Widget Function(double, TitleMeta) bottom, String Function(double)? left}) =>
    FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          getTitlesWidget: (v, m) => v == m.max || v == m.min
              ? const SizedBox.shrink()
              : Text(left?.call(v) ?? number(v.round()), style: _axis),
        ),
      ),
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: bottom)),
    );

FlGridData get _grid => FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) => const FlLine(color: Ox.darkGray, strokeWidth: 1),
);

/// Producción diaria (todas las máquinas) de los últimos [days] días.
class ProductionChart extends StatelessWidget {
  final List<DailyReport> reports;
  final int days;
  final int target;
  const ProductionChart({super.key, required this.reports, this.days = 14, this.target = 0});

  @override
  Widget build(BuildContext context) {
    final today = dayOnly(DateTime.now());
    final dates = [for (var i = days - 1; i >= 0; i--) today.subtract(Duration(days: i))];
    final totals = {for (final d in dates) dateKey(d): 0};
    for (final r in reports) {
      final k = dateKey(r.date);
      if (totals.containsKey(k)) totals[k] = totals[k]! + r.units;
    }
    final values = dates.map((d) => totals[dateKey(d)]!.toDouble()).toList();
    final maxY = [...values, target.toDouble(), 10.0].reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.15,
          gridData: _grid,
          borderData: FlBorderData(show: false),
          titlesData: _titles(
            bottom: (v, m) {
              final i = v.toInt();
              if (i < 0 || i >= dates.length || (i % 2 != (dates.length - 1) % 2)) return const SizedBox.shrink();
              return Text('${dates[i].day}', style: _axis);
            },
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (target > 0)
                HorizontalLine(
                  y: target.toDouble(),
                  color: Ox.lightGray,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: _axis,
                    labelResolver: (_) => 'meta',
                  ),
                ),
            ],
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Ox.darkGray,
              getTooltipItem: (g, _, r, _) => BarTooltipItem(
                '${fechaCorta(dates[g.x])}\n${number(r.toY.round())} incas',
                const TextStyle(color: Ox.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < dates.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: 12,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    color: target > 0 && values[i] >= target ? Ox.yellow : Ox.yellow.withValues(alpha: 0.55),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Ingresos vs costos por mes: meses reales en sólido y proyectados en tono claro.
class MonthsChart extends StatelessWidget {
  final List<MonthFinance> months;
  const MonthsChart({super.key, required this.months});

  @override
  Widget build(BuildContext context) {
    final maxY = [
      for (final m in months) ...[m.revenue, m.costs],
      100.0,
    ].reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.15,
              gridData: _grid,
              borderData: FlBorderData(show: false),
              titlesData: _titles(
                left: (v) => moneyShort(v),
                bottom: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i >= months.length) return const SizedBox.shrink();
                  return Text(
                    mesCorto(months[i].month),
                    style: _axis.copyWith(color: months[i].projected ? Ox.yellow : Ox.lightGray),
                  );
                },
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Ox.darkGray,
                  getTooltipItem: (g, _, r, ri) {
                    final m = months[g.x];
                    return BarTooltipItem(
                      '${ri == 0 ? 'Ingresos' : 'Costos'}${m.projected ? ' (proy.)' : ''}\n${money0(r.toY)}',
                      const TextStyle(color: Ox.white, fontSize: 12, fontWeight: FontWeight.w700),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < months.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: months[i].revenue,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        color: months[i].projected ? Ox.yellow.withValues(alpha: 0.4) : Ox.yellow,
                      ),
                      BarChartRodData(
                        toY: months[i].costs,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        color: months[i].projected ? Ox.lightGray.withValues(alpha: 0.35) : Ox.lightGray,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 16,
          children: [
            _Legend(Ox.yellow, 'Ingresos'),
            _Legend(Ox.lightGray, 'Costos (planilla, gastos, impuestos)'),
            _Legend(Color(0x66F5B800), 'Proyectado'),
          ],
        ),
      ],
    );
  }
}

/// Utilidad acumulada proyectada (línea).
class CumulativeProfitChart extends StatelessWidget {
  final List<MonthFinance> months;
  const CumulativeProfitChart({super.key, required this.months});
  @override
  Widget build(BuildContext context) {
    var acc = 0.0;
    final spots = <FlSpot>[];
    for (var i = 0; i < months.length; i++) {
      acc += months[i].profit;
      spots.add(FlSpot(i.toDouble(), acc));
    }
    final ys = [...spots.map((s) => s.y), 0.0];
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() * 0.15 + 100;
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: _grid,
          borderData: FlBorderData(show: false),
          titlesData: _titles(
            left: (v) => moneyShort(v),
            bottom: (v, m) {
              final i = v.toInt();
              if (v != i.toDouble() || i < 0 || i >= months.length) return const SizedBox.shrink();
              return Text(mesCorto(months[i].month), style: _axis);
            },
          ),
          extraLinesData: ExtraLinesData(horizontalLines: [HorizontalLine(y: 0, color: Ox.darkGray, strokeWidth: 1.5)]),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Ox.darkGray,
              getTooltipItems: (s) => [
                for (final x in s)
                  LineTooltipItem(
                    money0(x.y),
                    const TextStyle(color: Ox.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: acc >= 0 ? Ox.green : Ox.red,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: (acc >= 0 ? Ox.green : Ox.red).withValues(alpha: 0.08)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 5),
      Text(label, style: _axis),
    ],
  );
}
