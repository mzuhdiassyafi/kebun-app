import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class _Series {
  const _Series({
    required this.labels,
    required this.a,
    required this.b,
    required this.min,
    required this.max,
    required this.unit,
    required this.headline,
    required this.delta,
    required this.deltaGood,
    this.threshold,
    this.thresholdLabel,
  });
  final List<String> labels;
  final List<double> a; // Lahan Tomat
  final List<double> b; // Lahan Sayur
  final double min;
  final double max;
  final String unit;
  final String headline;
  final String delta;
  final bool deltaGood;
  final double? threshold;
  final String? thresholdLabel;
}

const _metrics = ['Kelembapan', 'Suhu', 'Cahaya'];
const _metricIcons = [LucideIcons.droplet, LucideIcons.thermometer, LucideIcons.sun];
const _metricTitles = ['Kelembapan tanah rata-rata', 'Suhu udara rata-rata', 'Intensitas cahaya rata-rata'];
const _periods = ['7 hari', '30 hari', '3 bulan', '1 tahun'];
const _periodRange = ['31 Okt – 6 Nov 2026', '8 Okt – 6 Nov 2026', 'Agu – Nov 2026', 'Des 2025 – Nov 2026'];

List<String> _labelsFor(int p) => switch (p) {
      0 => const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
      1 => const ['Mg 1', 'Mg 2', 'Mg 3', 'Mg 4', 'Ini'],
      2 => const ['Agu', 'Sep', 'Okt', 'Nov'],
      _ => const ['Des', 'Feb', 'Apr', 'Jun', 'Agu', 'Okt', 'Nov'],
    };

List<double> _wave(List<double> base, int n, double shift) {
  return List.generate(n, (i) {
    final t = i / math.max(1, n - 1) * (base.length - 1);
    final lo = t.floor(), hi = math.min(t.ceil(), base.length - 1);
    final v = base[lo] + (base[hi] - base[lo]) * (t - lo);
    return v + math.sin(i * 1.7 + shift) * 2.2;
  });
}

_Series _series(int metric, int period) {
  final labels = _labelsFor(period);
  final n = labels.length;
  switch (metric) {
    case 0:
      final a = period == 0 ? const [67.8, 73.8, 69.8, 62.9, 57.9, 65.8, 71.8] : _wave(const [70, 66, 64, 68, 72], n, 0.4);
      final b = period == 0 ? const [52.1, 49.1, 44.1, 41.1, 39.1, 42.2, 38.2] : _wave(const [58, 55, 50, 44, 38], n, 1.3);
      return _Series(
        labels: labels,
        a: a,
        b: b,
        min: 20,
        max: 100,
        unit: '%',
        headline: ['61%', '63%', '64%', '62%'][period],
        delta: ['−4% minggu lalu', '−2% bulan lalu', '+1% kuartal lalu', '+3% tahun lalu'][period],
        deltaGood: period >= 2,
        threshold: 45,
        thresholdLabel: 'Batas 45%',
      );
    case 1:
      final a = period == 0 ? const [28.4, 29.1, 30.2, 31.0, 30.4, 29.2, 29.0] : _wave(const [27, 28, 30, 31, 29], n, 0.9);
      final b = period == 0 ? const [29.0, 30.1, 31.2, 32.1, 31.4, 30.3, 30.2] : _wave(const [28, 29, 31, 32, 30], n, 2.0);
      return _Series(
        labels: labels,
        a: a,
        b: b,
        min: 20,
        max: 40,
        unit: '°C',
        headline: ['30°C', '29°C', '29°C', '28°C'][period],
        delta: ['+1°C minggu lalu', '+0,5°C bulan lalu', '−1°C kuartal lalu', '+0,8°C tahun lalu'][period],
        deltaGood: false,
        threshold: 33,
        thresholdLabel: 'Batas 33°C',
      );
    default:
      final a = period == 0 ? const [32.0, 35.0, 30.0, 28.0, 36.0, 38.0, 34.0] : _wave(const [30, 34, 36, 33, 35], n, 0.2);
      final b = period == 0 ? const [30.0, 33.0, 29.0, 27.0, 34.0, 36.0, 31.0] : _wave(const [28, 31, 34, 31, 33], n, 1.1);
      return _Series(
        labels: labels,
        a: a,
        b: b,
        min: 0,
        max: 50,
        unit: ' klx',
        headline: ['33 klx', '32 klx', '33 klx', '31 klx'][period],
        delta: ['+6% minggu lalu', '+3% bulan lalu', '+2% kuartal lalu', '−1% tahun lalu'][period],
        deltaGood: true,
      );
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int period = 0;
  int metric = 0;
  int compareMetric = 0;
  int? hover;

  void _pickRange() {
    showSheet(
      context,
      title: 'Rentang waktu',
      builder: (ctx) => OptionList(
        options: [for (var i = 0; i < _periods.length; i++) '${_periods[i]} · ${_periodRange[i]}'],
        selected: '${_periods[period]} · ${_periodRange[period]}',
        onSelect: (v) {
          setState(() {
            period = _periods.indexWhere((p) => v.startsWith(p));
            hover = null;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = _series(metric, period);

    final trend = KCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: KColors.canvas, borderRadius: BorderRadius.circular(KRadius.full)),
          child: Row(children: [
            for (var i = 0; i < _metrics.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                flex: i == 0 ? 4 : 3,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: metric == i ? KColors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(KRadius.full),
                    boxShadow: metric == i ? const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))] : null,
                  ),
                  child: Tap(
                    radius: KRadius.full,
                    onTap: () => setState(() {
                      metric = i;
                      hover = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(_metricIcons[i], size: 14, color: metric == i ? [KColors.water, KColors.danger, KColors.sun][i] : KColors.textSecondary),
                        const SizedBox(width: 6),
                        Flexible(child: Text(_metrics[i], style: KText.caption.copyWith(color: metric == i ? KColors.text : KColors.textSecondary), overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_metricTitles[metric], style: KText.caption),
              const SizedBox(height: 2),
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
                Text(d.headline, style: KText.display),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: d.deltaGood ? KColors.successSoft : KColors.warningSoft, borderRadius: BorderRadius.circular(KRadius.full)),
                  child: Text(d.delta, style: KText.small.copyWith(color: d.deltaGood ? KColors.success : KColors.warning)),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (c, l) in [(KColors.primary, 'Lahan Tomat'), (KColors.warning, 'Lahan Sayur')]) ...[
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(l, style: KText.small),
              ]),
              const SizedBox(height: 4),
            ],
          ]),
        ]),
        const SizedBox(height: 14),
        _LineChart(series: d, hover: hover, onHover: (i) => setState(() => hover = i)),
      ]),
    );

    final insights = [
      'Lahan Sayur 34% lebih kering dari Lahan Tomat dan 4 hari di bawah batas. Coba tambah 5 menit penyiraman pagi.',
      'Suhu Lahan Sayur sempat 32°C hari Kamis. Pertimbangkan paranet 30% untuk selada saat siang.',
      'Cahaya cukup untuk semua zona. Lahan Tomat mendapat 38 klx di hari Sabtu, ideal untuk pembuahan.',
    ];
    final insight = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: KColors.primarySoft, borderRadius: BorderRadius.circular(KRadius.lg)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const IconChip(icon: LucideIcons.leaf, tint: Colors.white, soft: KColors.primary, radius: KRadius.full),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Insight minggu ini', style: KText.title.copyWith(color: KColors.primaryDark)),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(insights[metric], key: ValueKey(metric), style: KText.caption.copyWith(color: KColors.primaryDark)),
            ),
          ]),
        ),
      ]),
    );

    final compareData = switch (compareMetric) {
      0 => [
          ('Lahan Tomat', s.zone('tomat').moisture, 100.0, '%', s.zone('tomat').moisture < s.moistureThreshold),
          ('Rumah Kebun', s.zone('rumah').moisture, 100.0, '%', false),
          ('Lahan Jagung', s.zone('jagung').moisture, 100.0, '%', s.zone('jagung').moisture < s.moistureThreshold),
          ('Lahan Sayur', s.zone('sayur').moisture, 100.0, '%', s.zone('sayur').moisture < s.moistureThreshold),
        ],
      1 => [('Lahan Jagung', 31.0, 40.0, '°C', false), ('Lahan Sayur', 30.0, 40.0, '°C', false), ('Lahan Tomat', 29.0, 40.0, '°C', false), ('Rumah Kebun', 28.0, 40.0, '°C', false)],
      _ => [('Lahan Jagung', 980.0, 1000.0, ' lux', false), ('Lahan Sayur', 910.0, 1000.0, ' lux', false), ('Lahan Tomat', 840.0, 1000.0, ' lux', false), ('Rumah Kebun', 650.0, 1000.0, ' lux', true)],
    };
    final compare = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(title: 'Bandingkan zona', action: _metrics[compareMetric], onAction: () => setState(() => compareMetric = (compareMetric + 1) % 3)),
      const SizedBox(height: 20),
      KCard(
        child: Column(children: [
          for (var i = 0; i < compareData.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _CompareBar(label: compareData[i].$1, value: compareData[i].$2, max: compareData[i].$3, unit: compareData[i].$4, warning: compareData[i].$5),
          ],
        ]),
      ),
    ]);

    final reports = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(title: 'Laporan', action: 'Semua', onAction: () => _allReports(s)),
      const SizedBox(height: 20),
      ListCard(children: [for (final r in s.reports) _reportRow(s, r)]),
    ]);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 12),
        child: Centered(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TitleBar(
              title: 'Analitik',
              subtitle: _periodRange[period],
              trailing: CircleIconButton(icon: LucideIcons.calendar, tooltip: 'Rentang waktu', onTap: _pickRange),
            ),
            ChipRow(children: [
              for (var i = 0; i < _periods.length; i++)
                KChip(
                  label: _periods[i],
                  active: period == i,
                  onTap: () => setState(() {
                    period = i;
                    hover = null;
                  }),
                ),
            ]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: LayoutBuilder(builder: (context, c) {
                if (c.maxWidth >= 900) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [trend, const SizedBox(height: 20), insight])),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [compare, const SizedBox(height: 20), reports])),
                  ]);
                }
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  trend,
                  const SizedBox(height: 20),
                  insight,
                  const SizedBox(height: 20),
                  compare,
                  const SizedBox(height: 20),
                  reports,
                ]);
              }),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _reportRow(AppState s, Report r) {
    final done = r.progress >= 1;
    final busy = r.progress > 0 && !done;
    return ListRow(
      leading: const IconChip(icon: LucideIcons.chartColumn, tint: KColors.water, soft: KColors.waterSoft),
      title: r.title,
      subtitle: r.meta,
      onTap: () => done ? toast(context, '${r.title} dibuka', icon: LucideIcons.fileText) : s.download(r),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 76,
        height: 28,
        decoration: BoxDecoration(color: done ? KColors.primary : KColors.primarySoft, borderRadius: BorderRadius.circular(KRadius.full)),
        clipBehavior: Clip.antiAlias,
        child: Tap(
          radius: KRadius.full,
          onTap: () async {
            if (done) {
              toast(context, '${r.title} dibuka', icon: LucideIcons.fileText);
              return;
            }
            await s.download(r);
            if (mounted) toast(context, '${r.title} tersimpan di Unduhan', icon: LucideIcons.download);
          },
          child: Stack(children: [
            if (busy) FractionallySizedBox(widthFactor: r.progress, child: Container(color: KColors.primary.withValues(alpha: 0.25))),
            Center(
              child: done
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.check, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('Buka', style: KText.captionSemi.copyWith(color: Colors.white)),
                    ])
                  : Text(busy ? '${(r.progress * 100).round()}%' : 'Unduh', style: KText.captionSemi.copyWith(color: KColors.primary)),
            ),
          ]),
        ),
      ),
    );
  }

  void _allReports(AppState s) {
    showSheet(
      context,
      title: 'Semua laporan',
      builder: (ctx) => AnimatedBuilder(
        animation: s,
        builder: (_, __) => ListCard(children: [
          for (final r in s.reports) _reportRow(s, r),
          ListRow(
            leading: const IconChip(icon: LucideIcons.chartColumn, tint: KColors.water, soft: KColors.waterSoft),
            title: 'Laporan bulanan September',
            subtitle: '1 – 30 Sep · PDF, 3,1 MB',
            trailing: const Pill(label: 'Arsip'),
          ),
        ]),
      ),
    );
  }
}

class _CompareBar extends StatelessWidget {
  const _CompareBar({required this.label, required this.value, required this.max, required this.unit, required this.warning});
  final String label;
  final double value;
  final double max;
  final String unit;
  final bool warning;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(label, style: KText.bodyMedium)),
          Text('${value.round()}$unit', style: KText.bodySemi.copyWith(fontWeight: FontWeight.w700, color: warning ? KColors.warning : KColors.text)),
        ]),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, c) => Container(
            height: 10,
            decoration: BoxDecoration(color: KColors.subtle, borderRadius: BorderRadius.circular(5)),
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              width: c.maxWidth * (value / max).clamp(0, 1),
              decoration: BoxDecoration(color: warning ? KColors.warning : KColors.primary, borderRadius: BorderRadius.circular(5)),
            ),
          ),
        ),
      ]);
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.series, required this.hover, required this.onHover});
  final _Series series;
  final int? hover;
  final ValueChanged<int?> onHover;

  int _indexAt(double x, double w) {
    const pad = 8.0;
    final n = series.a.length;
    final step = (w - pad * 2) / (n - 1);
    return ((x - pad) / step).round().clamp(0, n - 1);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 166,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return MouseRegion(
          onHover: (e) => onHover(_indexAt(e.localPosition.dx, w)),
          onExit: (_) => onHover(null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (e) => onHover(_indexAt(e.localPosition.dx, w)),
            onHorizontalDragUpdate: (e) => onHover(_indexAt(e.localPosition.dx, w)),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(series.headline + series.labels.length.toString() + series.unit),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, t, __) => Stack(clipBehavior: Clip.none, children: [
                CustomPaint(size: Size(w, 150), painter: _ChartPainter(series, hover, t)),
                if (series.thresholdLabel != null)
                  Positioned(
                    left: 0,
                    top: _y(series.threshold!, 150) - 16,
                    child: Text(series.thresholdLabel!, style: KText.small.copyWith(color: KColors.warning)),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Row(children: [
                    for (var i = 0; i < series.labels.length; i++)
                      Expanded(
                        child: Text(
                          series.labels[i],
                          textAlign: i == 0 ? TextAlign.left : (i == series.labels.length - 1 ? TextAlign.right : TextAlign.center),
                          style: KText.small.copyWith(color: i == (hover ?? series.labels.length - 1) ? KColors.text : KColors.textSecondary),
                        ),
                      ),
                  ]),
                ),
                if (hover != null) _tooltip(w),
              ]),
            ),
          ),
        );
      }),
    );
  }

  double _y(double v, double h) => 8 + (h - 20) * (1 - (v - series.min) / (series.max - series.min));

  Widget _tooltip(double w) {
    const pad = 8.0;
    final n = series.a.length;
    final x = pad + (w - pad * 2) * hover! / (n - 1);
    const tw = 118.0;
    final left = (x - tw / 2).clamp(0.0, w - tw);
    String f(double v) => v.toStringAsFixed(series.unit == '°C' ? 1 : 0).replaceAll('.', ',');
    return Positioned(
      left: left,
      top: -6,
      child: IgnorePointer(
        child: Container(
          width: tw,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: KColors.text, borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(series.labels[hover!], style: KText.small.copyWith(color: Colors.white70)),
            const SizedBox(height: 2),
            Text('Tomat  ${f(series.a[hover!])}${series.unit}', style: KText.small.copyWith(color: const Color(0xFF9FE0B5))),
            Text('Sayur  ${f(series.b[hover!])}${series.unit}', style: KText.small.copyWith(color: const Color(0xFFF5C46A))),
          ]),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.s, this.hover, this.t);
  final _Series s;
  final int? hover;
  final double t;

  double y(double v, double h) => 8 + (h - 20) * (1 - (v - s.min) / (s.max - s.min));

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    const pad = 8.0;
    final w = size.width;
    final grid = Paint()
      ..color = KColors.border
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final gy = 8 + (h - 20) * i / 4;
      canvas.drawLine(Offset(0, gy), Offset(w, gy), grid);
    }
    if (s.threshold != null) {
      final ty = y(s.threshold!, h);
      final p = Paint()
        ..color = KColors.warning
        ..strokeWidth = 1.5;
      for (double x = 0; x < w; x += 8) {
        canvas.drawLine(Offset(x, ty), Offset(math.min(x + 4, w), ty), p);
      }
    }
    final n = s.a.length;
    Offset pt(int i, List<double> d) {
      final base = y(s.min + (s.max - s.min) * 0.0, h);
      final target = y(d[i], h);
      return Offset(pad + (w - pad * 2) * i / (n - 1), base + (target - base) * t);
    }

    Path line(List<double> d) {
      final p = Path()..moveTo(pt(0, d).dx, pt(0, d).dy);
      for (var i = 1; i < n; i++) {
        p.lineTo(pt(i, d).dx, pt(i, d).dy);
      }
      return p;
    }

    final area = line(s.a)
      ..lineTo(pt(n - 1, s.a).dx, h - 12)
      ..lineTo(pt(0, s.a).dx, h - 12)
      ..close();
    canvas.drawPath(area, Paint()..color = KColors.primary.withValues(alpha: 0.10));

    for (final (d, c) in [(s.a, KColors.primary), (s.b, KColors.warning)]) {
      canvas.drawPath(
        line(d),
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    final idx = hover ?? n - 1;
    if (hover != null) {
      final x = pt(idx, s.a).dx;
      canvas.drawLine(Offset(x, 8), Offset(x, h - 12), Paint()
        ..color = KColors.text.withValues(alpha: 0.15)
        ..strokeWidth = 1);
    }
    for (final (d, c) in [(s.a, KColors.primary), (s.b, KColors.warning)]) {
      final p = pt(idx, d);
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 5, Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.s != s || old.hover != hover || old.t != t;
}
