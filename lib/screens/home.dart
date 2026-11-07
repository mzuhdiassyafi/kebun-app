import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'livestock.dart';
import 'notifications.dart';
import 'zone_detail.dart';

String greeting() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 19) return 'Selamat sore';
  return 'Selamat malam';
}

void openAlert(BuildContext context, AlertItem a) {
  final s = AppScope.read(context);
  s.markRead(a);
  if (a.title.contains('Gendut') || a.zoneId == 'ternak') {
    Navigator.of(context).push(pageRoute(const LivestockScreen()));
  } else if (a.zoneId != null) {
    Navigator.of(context).push(pageRoute(ZoneDetailScreen(zoneId: a.zoneId!)));
  } else {
    Navigator.of(context).push(pageRoute(const NotificationsScreen()));
  }
}

void showFarmSwitcher(BuildContext context) {
  final s = AppScope.read(context);
  showSheet(
    context,
    title: 'Pilih kebun',
    subtitle: 'Data di beranda akan mengikuti kebun yang dipilih.',
    builder: (ctx) => Column(children: [
      for (var i = 0; i < s.farms.length; i++) ...[
        FarmOption(
          farm: s.farms[i],
          active: i == s.activeFarm,
          onTap: () {
            s.setFarm(i);
            Navigator.pop(ctx);
            toast(context, 'Beralih ke ${s.farms[i].name}');
          },
        ),
        const SizedBox(height: 10),
      ],
    ]),
  );
}

class FarmOption extends StatelessWidget {
  const FarmOption({super.key, required this.farm, required this.active, required this.onTap});
  final Farm farm;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: cardDecoration(
          color: active ? KColors.primarySoft : KColors.canvas,
          radius: KRadius.md,
          border: active ? KColors.primary : null,
        ),
        child: Tap(
          onTap: onTap,
          radius: KRadius.md,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconChip(icon: LucideIcons.sprout, tint: active ? Colors.white : KColors.primary, soft: active ? KColors.primary : KColors.surface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(farm.name, style: KText.bodySemi, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${farm.area} · ${farm.zones} zona · ${farm.sensors} sensor', style: KText.caption),
                ]),
              ),
              if (active)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(color: KColors.primary, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.check, size: 14, color: Colors.white),
                ),
            ]),
          ),
        ),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = layoutOf(context);
    final wide = l != Layout.phone;
    return SingleChildScrollView(
      child: Column(children: [
        _Hero(wide: wide),
        Centered(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: LayoutBuilder(builder: (context, c) {
              final stats = _StatsSection(columns: c.maxWidth >= 640 && c.maxWidth < 900 ? 4 : 2);
              final alerts = _AlertsSection(alerts: s.alerts.where((a) => a.day == 'Hari ini').take(c.maxWidth >= 900 ? 3 : 2).toList());
              if (c.maxWidth >= 900) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 5, child: stats),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: alerts),
                ]);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [stats, const SizedBox(height: 24), alerts]);
            }),
          ),
        ),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final healthy = s.healthyZones;
    final total = s.zones.length;
    final pct = (healthy / total * 100).round().clamp(0, 100);
    final healthPct = s.zones.any((z) => z.warning) ? 92 : 100;
    return SizedBox(
      height: wide ? 340 : 308,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/hero.jpg', fit: BoxFit.cover, alignment: const Alignment(0, -0.1), filterQuality: FilterQuality.medium),
        // Soft fade into the canvas so the cards sit cleanly on wide screens.
        if (wide)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xB3F6F3EC), Color(0x00F6F3EC), Color(0x00F6F3EC), Color(0xCCF6F3EC)], stops: [0, 0.32, 0.6, 1]),
            ),
          ),
        SafeArea(
          bottom: false,
          child: Centered(
            child: Column(children: [
              SizedBox(height: wide ? 20 : 44 - MediaQuery.paddingOf(context).top.clamp(0, 44)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(children: [
                  Tooltip(
                    message: 'Profil',
                    child: GestureDetector(
                      onTap: () => goToTab(context, 4),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: KColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          alignment: Alignment.center,
                          child: Text(s.userName.characters.first.toUpperCase(), style: KText.h18.copyWith(color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${greeting()}, ${s.userName}', style: KText.caption.copyWith(color: KColors.text)),
                      Tap(
                        onTap: () => showFarmSwitcher(context),
                        radius: 8,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Flexible(child: Text(s.farm.name, style: KText.h18, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronDown, size: 18, color: KColors.text),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  CircleIconButton(
                    icon: LucideIcons.bell,
                    iconSize: 22,
                    tooltip: 'Notifikasi',
                    badge: s.unreadCount > 0,
                    onTap: () => Navigator.of(context).push(pageRoute(const NotificationsScreen())),
                  ),
                ]),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                    child: _OverviewCard(
                      onTap: () => goToTab(context, 1),
                      child: Row(children: [
                        HealthRing(value: healthPct / 100, label: '$healthPct%'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Kesehatan', style: KText.small),
                            const SizedBox(height: 2),
                            Text(pct == 100 ? 'Sangat sehat' : 'Sehat', style: KText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Row(children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: KColors.success, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text('$healthy/$total zona normal', style: KText.small.copyWith(color: KColors.success)),
                                ),
                              ),
                            ]),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OverviewCard(
                      onTap: () => showWeather(context),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Row(children: [
                          const IconChip(icon: LucideIcons.sun, tint: KColors.sun, soft: KColors.sunSoft, size: 36, radius: KRadius.full),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('28°C', style: KText.h18),
                              Text('Cerah berawan', style: KText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(LucideIcons.wind, size: 14, color: KColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('12 km/j', style: KText.small),
                          const SizedBox(width: 10),
                          const Icon(LucideIcons.droplet, size: 14, color: KColors.water),
                          const SizedBox(width: 4),
                          Text('68%', style: KText.small),
                        ]),
                      ]),
                    ),
                  ),
                  if (wide) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OverviewCard(
                        onTap: () => Navigator.of(context).push(pageRoute(const NotificationsScreen())),
                        child: Row(children: [
                          const IconChip(icon: LucideIcons.bell, tint: KColors.danger, soft: KColors.dangerSoft, size: 44, radius: KRadius.full),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Notifikasi', style: KText.small),
                              Text('${s.unreadCount} belum dibaca', style: KText.title, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        height: 88,
        decoration: BoxDecoration(
          color: KColors.surface,
          borderRadius: BorderRadius.circular(KRadius.lg),
          boxShadow: const [BoxShadow(color: Color(0x0F1E2A22), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: Tap(onTap: onTap, radius: KRadius.lg, child: Padding(padding: const EdgeInsets.all(14), child: child)),
      );
}

class HealthRing extends StatelessWidget {
  const HealthRing({super.key, required this.value, required this.label, this.size = 56});
  final double value;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(v),
            child: Center(child: Text(label, style: KText.captionSemi.copyWith(fontWeight: FontWeight.w700))),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final r = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()
      ..color = KColors.primarySoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, Paint()
      ..color = KColors.success
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v;
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.columns});
  final int columns;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    // 72% across all 12 sensors (placeholder); rises when a zone is watered.
    final avgMoisture = 72 + (s.zone('sayur').moisture - 38 + s.zone('tomat').moisture - 72) / 12;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader(title: 'Statistik cepat'),
      const SizedBox(height: 24),
      Grid(columns: columns, children: [
        StatCard(icon: LucideIcons.sprout, tint: KColors.primary, soft: KColors.primarySoft, value: '12', label: 'Jenis tanaman', onTap: () => goToTab(context, 1)),
        StatCard(icon: LucideIcons.pawPrint, tint: KColors.soil, soft: KColors.soilSoft, value: '${s.animalTotal}', label: 'Hewan ternak', onTap: () => Navigator.of(context).push(pageRoute(const LivestockScreen()))),
        StatCard(icon: LucideIcons.droplet, tint: KColors.water, soft: KColors.waterSoft, value: '${avgMoisture.round()}%', label: 'Rata-rata kelembapan', onTap: () => goToTab(context, 2)),
        StatCard(icon: LucideIcons.shoppingBasket, tint: KColors.sun, soft: KColors.sunSoft, value: '${formatKg(s.monthTotal)} kg', label: 'Panen bulan ini', onTap: () => goToTab(context, 3)),
      ]),
    ]);
  }
}

String formatKg(double v) {
  final n = v.round();
  final str = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return buf.toString();
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.alerts});
  final List<AlertItem> alerts;

  @override
  Widget build(BuildContext context) {
    final list = alerts.isEmpty
        ? [
            KCard(
              child: Row(children: [
                const IconChip(icon: LucideIcons.check, tint: KColors.success, soft: KColors.successSoft, radius: KRadius.full),
                const SizedBox(width: 12),
                Expanded(child: Text('Semua aman. Tidak ada peringatan baru.', style: KText.bodyMedium)),
              ]),
            ),
          ]
        : [for (final a in alerts) AlertTile(alert: a, timeSuffix: ' lalu', onTap: () => openAlert(context, a))];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(title: 'Peringatan terbaru', action: 'Lihat semua', onAction: () => Navigator.of(context).push(pageRoute(const NotificationsScreen()))),
      const SizedBox(height: 24),
      for (var i = 0; i < list.length; i++) ...[if (i > 0) const SizedBox(height: 12), list[i]],
    ]);
  }
}

void showWeather(BuildContext context) {
  const days = [
    ('Hari ini', LucideIcons.sun, '28°', '22°', '10%'),
    ('Sab', LucideIcons.cloudSun, '29°', '23°', '20%'),
    ('Min', LucideIcons.cloudRain, '26°', '22°', '70%'),
    ('Sen', LucideIcons.cloudDrizzle, '27°', '22°', '45%'),
    ('Sel', LucideIcons.sun, '30°', '23°', '5%'),
  ];
  showSheet(
    context,
    title: 'Cuaca di kebun',
    subtitle: 'Stasiun cuaca Kebun Lembah Hijau · diperbarui 5 mnt lalu',
    builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      KCard(
        child: Row(children: [
          const IconChip(icon: LucideIcons.sun, tint: KColors.sun, soft: KColors.sunSoft, size: 56, iconSize: 28, radius: KRadius.full),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('28°C', style: KText.display),
              Text('Cerah berawan · terasa 30°C', style: KText.caption),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Angin 12 km/j', style: KText.small),
            const SizedBox(height: 4),
            Text('Kelembapan 68%', style: KText.small),
            const SizedBox(height: 4),
            Text('UV 7 (tinggi)', style: KText.small.copyWith(color: KColors.warning)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      ListCard(children: [
        for (final d in days)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              SizedBox(width: 72, child: Text(d.$1, style: KText.bodyMedium)),
              Icon(d.$2, size: 20, color: d.$2 == LucideIcons.sun ? KColors.sun : KColors.water),
              const SizedBox(width: 10),
              Text('Hujan ${d.$5}', style: KText.caption),
              const Spacer(),
              Text(d.$3, style: KText.bodySemi),
              const SizedBox(width: 8),
              Text(d.$4, style: KText.caption),
            ]),
          ),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: KColors.primarySoft, borderRadius: BorderRadius.circular(KRadius.md)),
        child: Text('Hujan diperkirakan hari Minggu. Penyiraman otomatis Minggu pagi akan dilewati.', style: KText.caption.copyWith(color: KColors.primaryDark)),
      ),
    ]),
  );
}
