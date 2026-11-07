import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'farm.dart';

class ZoneDetailScreen extends StatefulWidget {
  const ZoneDetailScreen({super.key, required this.zoneId});
  final String zoneId;

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  int range = 0; // 0 = 7H, 1 = 30H
  int? selectedBar;
  bool refreshing = false;
  String updated = 'Diperbarui 2 mnt lalu';

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      refreshing = false;
      updated = 'Diperbarui baru saja';
    });
    toast(context, 'Data sensor diperbarui');
  }

  List<_SensorData> _sensors(Zone z, double threshold) {
    switch (z.kind) {
      case ZoneKind.water:
        return [
          _SensorData(LucideIcons.droplet, KColors.water, KColors.waterSoft, '12%', 'Level tandon', true, 'Tandon 2.000 L, sisa 240 L.'),
          _SensorData(LucideIcons.thermometer, KColors.danger, KColors.dangerSoft, '${z.temp.round()}°C', 'Suhu air', false, 'Ideal untuk ikan nila 25–30°C.'),
          _SensorData(LucideIcons.leaf, KColors.soil, KColors.soilSoft, z.ph.toStringAsFixed(1).replaceAll('.', ','), 'pH air', false, 'Rentang normal 6,5–8,5.'),
          _SensorData(LucideIcons.waves, KColors.primary, KColors.primarySoft, '80%', 'Level kolam', false, 'Kolam terisi 80% dari kapasitas.'),
        ];
      case ZoneKind.storage:
        return [
          _SensorData(LucideIcons.thermometer, KColors.danger, KColors.dangerSoft, '${z.temp.round()}°C', 'Suhu gudang', false, 'Aman untuk pakan & pupuk (< 32°C).'),
          _SensorData(LucideIcons.droplet, KColors.water, KColors.waterSoft, '64%', 'Kelembapan udara', false, 'Di bawah 70%, pakan tidak mudah berjamur.'),
          _SensorData(LucideIcons.package, KColors.soil, KColors.soilSoft, '320 kg', 'Stok pakan', false, 'Cukup untuk ±9 hari.'),
          _SensorData(LucideIcons.leaf, KColors.primary, KColors.primarySoft, '6 sak', 'Stok pupuk', false, 'NPK 4 sak, kompos 2 sak.'),
        ];
      default:
        return [
          _SensorData(LucideIcons.droplet, KColors.water, KColors.waterSoft, '${z.moisture.round()}%', 'Kelembapan tanah', z.moisture < threshold,
              'Batas minimum ${threshold.round()}%. ${z.moisture < threshold ? 'Segera siram zona ini.' : 'Kondisi aman.'}'),
          _SensorData(LucideIcons.thermometer, KColors.danger, KColors.dangerSoft, '${z.temp.round()}°C', 'Suhu udara', z.temp > 33, 'Rentang ideal 20–32°C.'),
          _SensorData(LucideIcons.sun, KColors.sun, KColors.sunSoft, '${z.light} lux', 'Intensitas cahaya', false, 'Rata-rata siang hari, sensor cahaya #2.'),
          _SensorData(LucideIcons.leaf, KColors.soil, KColors.soilSoft, z.ph.toStringAsFixed(1).replaceAll('.', ','), 'pH tanah', z.ph < 5.5 || z.ph > 7.5, 'Rentang ideal 5,5–7,5.'),
        ];
    }
  }

  void _openSettings(Zone z) {
    final s = AppScope.read(context);
    var threshold = s.moistureThreshold;
    var duration = 15.0;
    showSheet(
      context,
      title: 'Pengaturan ${z.name}',
      subtitle: 'Atur kapan peringatan dikirim dan durasi penyiraman.',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          KCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Batas minimum kelembapan', style: KText.bodySemi)),
                Text('${threshold.round()}%', style: KText.title.copyWith(color: KColors.primary)),
              ]),
              Slider(value: threshold, min: 20, max: 80, divisions: 60, onChanged: (v) => set(() => threshold = v)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('Durasi siram manual', style: KText.bodySemi)),
                Text('${duration.round()} menit', style: KText.title.copyWith(color: KColors.primary)),
              ]),
              Slider(value: duration, min: 5, max: 30, divisions: 5, onChanged: (v) => set(() => duration = v)),
            ]),
          ),
          const SizedBox(height: 16),
          KButton(
            label: 'Simpan',
            onTap: () {
              s.setThreshold(threshold);
              Navigator.pop(ctx);
              toast(context, 'Batas kelembapan disimpan: ${threshold.round()}%');
            },
          ),
        ]),
      ),
    );
  }

  void _openLog(Zone z) {
    final s = AppScope.read(context);
    final types = [
      ('Penyiraman', LucideIcons.droplet, KColors.water, KColors.waterSoft),
      ('Pemupukan', LucideIcons.leaf, KColors.primary, KColors.primarySoft),
      ('Cek hama', LucideIcons.triangleAlert, KColors.warning, KColors.warningSoft),
      ('Catatan', LucideIcons.pencil, KColors.soil, KColors.soilSoft),
    ];
    var type = 0;
    final note = TextEditingController();
    showSheet(
      context,
      title: 'Catat aktivitas',
      subtitle: '${z.name} · hari ini',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < types.length; i++) KChip(label: types[i].$1, icon: types[i].$2, active: type == i, onTap: () => set(() => type = i)),
          ]),
          const SizedBox(height: 16),
          TextField(controller: note, minLines: 2, maxLines: 4, decoration: const InputDecoration(hintText: 'Contoh: NPK 2 kg, siram 15 menit…')),
          const SizedBox(height: 16),
          KButton(
            label: 'Simpan aktivitas',
            icon: LucideIcons.check,
            onTap: () {
              final t = types[type];
              final detail = note.text.trim().isEmpty ? 'Baru saja · oleh ${s.userName}' : 'Baru saja · ${note.text.trim()}';
              s.addActivity(z, Activity(t.$1 == 'Catatan' ? 'Catatan lapangan' : t.$1, detail, t.$2, t.$3, t.$4));
              Navigator.pop(ctx);
              toast(context, 'Aktivitas dicatat');
            },
          ),
        ]),
      ),
    );
  }

  void _openHistory(Zone z) {
    showSheet(
      context,
      title: 'Riwayat aktivitas',
      subtitle: z.name,
      builder: (ctx) => z.activities.isEmpty
          ? Text('Belum ada aktivitas.', style: KText.caption)
          : ListCard(children: [for (final a in z.activities) _activityRow(a)]),
    );
  }

  Widget _activityRow(Activity a) => ListRow(
        leading: IconChip(icon: a.icon, tint: a.tint, soft: a.soft, size: 36, iconSize: 18, radius: KRadius.full),
        title: a.title,
        subtitle: a.subtitle,
        onTap: () {},
      );

  void _sensorInfo(_SensorData d) {
    showSheet(
      context,
      title: d.label,
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        KCard(
          child: Row(children: [
            IconChip(icon: d.icon, tint: d.tint, soft: d.soft, size: 48, iconSize: 24, radius: KRadius.full),
            const SizedBox(width: 14),
            Expanded(child: Text(d.value, style: KText.display)),
            StatusBadge(warning: d.warning),
          ]),
        ),
        const SizedBox(height: 12),
        Text(d.hint, style: KText.bodyMedium.copyWith(color: KColors.textSecondary)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final z = s.zone(widget.zoneId);
    final sensors = _sensors(z, s.moistureThreshold);
    final watering = s.wateringNow.contains(z.id);
    final isCrop = z.kind == ZoneKind.crop || z.kind == ZoneKind.house;

    final hero = _ZoneHero(zone: z);
    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(z.variety ?? z.name, style: KText.h22),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        Pill(icon: LucideIcons.map, label: z.area),
        if (isCrop) Pill(icon: LucideIcons.calendar, label: 'Tanam ${z.planted}'),
        if (z.harvestIn != null) Pill(icon: LucideIcons.shoppingBasket, label: z.harvestIn!.startsWith('±') ? 'Panen ${z.harvestIn}' : z.harvestIn!),
        if (!isCrop) Pill(icon: LucideIcons.radio, label: '${z.sensors} sensor'),
      ]),
    ]);

    final sensorSection = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(title: 'Sensor saat ini', action: refreshing ? 'Memperbarui…' : updated, onAction: refreshing ? null : _refresh),
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, c) => Grid(
          columns: c.maxWidth >= 640 ? 4 : 2,
          children: [
            for (final d in sensors) SensorTile(icon: d.icon, tint: d.tint, soft: d.soft, value: d.value, label: d.label, warning: d.warning, onTap: () => _sensorInfo(d)),
          ],
        ),
      ),
    ]);

    final chart = isCrop
        ? _MoistureChart(
            zone: z,
            threshold: s.moistureThreshold,
            range: range,
            selected: selectedBar,
            onRange: (v) => setState(() {
              range = v;
              selectedBar = null;
            }),
            onSelect: (i) => setState(() => selectedBar = i),
          )
        : null;

    final activity = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(title: 'Aktivitas terakhir', action: 'Riwayat', onAction: () => _openHistory(z)),
      const SizedBox(height: 20),
      if (z.activities.isEmpty)
        KCard(child: Text('Belum ada aktivitas di zona ini. Ketuk "Catat" untuk menambahkan.', style: KText.caption))
      else
        ListCard(children: [for (final a in z.activities.take(3)) _activityRow(a)]),
    ]);

    final actions = Row(children: [
      Expanded(child: KButton(label: 'Catat', icon: LucideIcons.plus, style: KButtonStyle.secondary, onTap: () => _openLog(z))),
      const SizedBox(width: 12),
      Expanded(
        child: KButton(
          label: watering ? 'Menyiram…' : (z.kind == ZoneKind.water ? 'Isi tandon' : 'Siram sekarang'),
          icon: LucideIcons.droplet,
          loading: watering,
          onTap: z.kind == ZoneKind.storage
              ? null
              : () async {
                  if (z.kind == ZoneKind.water) {
                    s.refillTank();
                    toast(context, 'Pompa pengisian tandon dinyalakan');
                    return;
                  }
                  toast(context, 'Penyiraman ${z.name} dimulai', icon: LucideIcons.droplet);
                  await s.waterNow(z);
                  if (context.mounted) toast(context, 'Selesai. Kelembapan naik ke ${z.moisture.round()}%');
                },
        ),
      ),
    ]);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12),
          child: Centered(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TopBar(
                title: z.name,
                subtitle: 'Zona ${z.number} · ${s.farm.name}',
                trailing: CircleIconButton(icon: LucideIcons.slidersVertical, tooltip: 'Pengaturan zona', onTap: () => _openSettings(z)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: LayoutBuilder(builder: (context, c) {
                  if (c.maxWidth >= 900) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [hero, const SizedBox(height: 20), info, const SizedBox(height: 20), sensorSection])),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          if (chart != null) ...[chart, const SizedBox(height: 20)],
                          activity,
                          const SizedBox(height: 20),
                          actions,
                        ]),
                      ),
                    ]);
                  }
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    hero,
                    const SizedBox(height: 20),
                    info,
                    const SizedBox(height: 20),
                    sensorSection,
                    if (chart != null) ...[const SizedBox(height: 20), chart],
                    const SizedBox(height: 20),
                    activity,
                    const SizedBox(height: 20),
                    actions,
                  ]);
                }),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SensorData {
  _SensorData(this.icon, this.tint, this.soft, this.value, this.label, this.warning, this.hint);
  final IconData icon;
  final Color tint;
  final Color soft;
  final String value;
  final String label;
  final bool warning;
  final String hint;
}

class _ZoneHero extends StatelessWidget {
  const _ZoneHero({required this.zone});
  final Zone zone;

  @override
  Widget build(BuildContext context) {
    final img = zone.id == 'tomat'
        ? Image.asset('assets/images/zone_tomat.png', fit: BoxFit.cover, filterQuality: FilterQuality.medium)
        : _MapCrop(rect: zone.mapRect);
    return ClipRRect(
      borderRadius: BorderRadius.circular(KRadius.lg),
      child: SizedBox(
        height: 176,
        child: Stack(fit: StackFit.expand, children: [
          img,
          Positioned(
            left: 12,
            top: 12,
            child: Pill(
              icon: zone.warning ? LucideIcons.triangleAlert : LucideIcons.check,
              label: zone.warning ? 'Perhatian' : 'Sehat',
              color: zone.warning ? KColors.warning : KColors.success,
              bg: Colors.white,
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Pill(icon: LucideIcons.radio, label: '${zone.sensors} sensor aktif', color: KColors.text, bg: Colors.white),
          ),
        ]),
      ),
    );
  }
}

/// Shows the part of the farm map that belongs to a zone, zoomed to fill.
class _MapCrop extends StatelessWidget {
  const _MapCrop({required this.rect});
  final Rect rect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final scale = math.max(c.maxWidth / rect.width, c.maxHeight / rect.height);
        final dx = -rect.left * scale - (rect.width * scale - c.maxWidth) / 2;
        final dy = -rect.top * scale - (rect.height * scale - c.maxHeight) / 2;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: SizedBox(
                width: FarmMap.designSize.width * scale,
                height: FarmMap.designSize.height * scale,
                child: Image.asset('assets/images/farm_map.png', fit: BoxFit.fill, filterQuality: FilterQuality.medium),
              ),
            ),
          ),
        );
      });
}

class _MoistureChart extends StatelessWidget {
  const _MoistureChart({required this.zone, required this.threshold, required this.range, required this.selected, required this.onRange, required this.onSelect});
  final Zone zone;
  final double threshold;
  final int range;
  final int? selected;
  final ValueChanged<int> onRange;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final List<double> values;
    final List<String> labels;
    if (range == 0) {
      values = zone.moisture7;
      labels = const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    } else {
      // 30 days summarised as weekly averages (placeholder data).
      final base = zone.moisture7.reduce((a, b) => a + b) / 7;
      values = [base - 3, base + 2, base - 1, base + 4, zone.moisture7.last];
      labels = const ['Mg 1', 'Mg 2', 'Mg 3', 'Mg 4', 'Ini'];
    }
    final sel = selected ?? values.length - 1;
    final avg = values.reduce((a, b) => a + b) / values.length;

    return KCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(range == 0 ? 'Kelembapan 7 hari' : 'Kelembapan 30 hari', style: KText.title),
              const SizedBox(height: 2),
              Text('Rata-rata ${avg.round()}% · batas minimum ${threshold.round()}%', style: KText.caption),
            ]),
          ),
          const SizedBox(width: 8),
          Segmented(items: const ['7H', '30H'], index: range, onChanged: onRange),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: LayoutBuilder(builder: (context, c) {
            const plotH = 126.0; // above the day labels
            final slot = c.maxWidth / values.length;
            final barW = math.min(28.0, slot * 0.6);
            double barH(double v) => math.min(v * 1.2, plotH - 26);
            final thY = plotH - barH(threshold);
            return Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: 0,
                right: 0,
                top: thY,
                child: CustomPaint(size: Size(c.maxWidth, 1.5), painter: _DashPainter(KColors.warning)),
              ),
              for (var i = 0; i < values.length; i++) ...[
                Positioned(
                  left: slot * i,
                  width: slot,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(i),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Column(children: [
                        const Spacer(),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: values[i]),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: barW,
                            height: barH(v),
                            decoration: BoxDecoration(
                              color: i == sel ? KColors.primary : (values[i] < threshold ? KColors.warningSoft : KColors.primarySoft),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(labels[i], style: KText.small.copyWith(color: i == sel ? KColors.text : KColors.textSecondary)),
                      ]),
                    ),
                  ),
                ),
              ],
              // value pill above selected bar
              Builder(builder: (_) {
                final h = barH(values[sel]);
                return Positioned(
                  left: slot * sel + slot / 2 - 21,
                  top: 150 - 24 - h - 28,
                  child: IgnorePointer(
                    child: Container(
                      width: 42,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(color: KColors.primary, borderRadius: BorderRadius.circular(KRadius.full)),
                      alignment: Alignment.center,
                      child: Text('${values[sel].round()}%', style: KText.small.copyWith(color: Colors.white)),
                    ),
                  ),
                );
              }),
            ]);
          }),
        ),
      ]),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + 4, size.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
