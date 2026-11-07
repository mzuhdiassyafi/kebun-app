import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'livestock.dart';
import 'zone_detail.dart';

void openZone(BuildContext context, Zone z) {
  if (z.kind == ZoneKind.livestock) {
    Navigator.of(context).push(pageRoute(const LivestockScreen()));
  } else {
    Navigator.of(context).push(pageRoute(ZoneDetailScreen(zoneId: z.id)));
  }
}

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

enum ZoneSort { status, name, moisture }

class _FarmScreenState extends State<FarmScreen> {
  String filter = 'all';
  String? selected;
  bool showLabels = true;
  bool showSensors = true;
  ZoneSort sort = ZoneSort.status;

  static const filters = [
    ('all', 'Semua zona', LucideIcons.map),
    ('tomat', 'Lahan Tomat', LucideIcons.sprout),
    ('ternak', 'Area Ternak', LucideIcons.pawPrint),
    ('kolam', 'Kolam', LucideIcons.droplet),
    ('sayur', 'Lahan Sayur', LucideIcons.sprout),
    ('jagung', 'Lahan Jagung', LucideIcons.sprout),
  ];

  List<Zone> _zones(AppState s) {
    var list = [...s.zones];
    if (filter != 'all') list = list.where((z) => z.id == filter).toList();
    switch (sort) {
      case ZoneSort.status:
        list.sort((a, b) => (b.warning ? 1 : 0) - (a.warning ? 1 : 0));
      case ZoneSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case ZoneSort.moisture:
        list = list.where((z) => z.kind == ZoneKind.crop || z.kind == ZoneKind.house).toList()..sort((a, b) => a.moisture.compareTo(b.moisture));
    }
    return list;
  }

  void _select(String id) {
    setState(() {
      selected = selected == id ? null : id;
    });
  }

  void _openSort() {
    final labels = {ZoneSort.status: 'Status (perlu perhatian dulu)', ZoneSort.name: 'Nama (A–Z)', ZoneSort.moisture: 'Kelembapan terendah'};
    showSheet(
      context,
      title: 'Urutkan zona',
      builder: (ctx) => OptionList(
        options: labels.values.toList(),
        selected: labels[sort]!,
        onSelect: (v) {
          setState(() => sort = labels.entries.firstWhere((e) => e.value == v).key);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _openSettings() {
    showSheet(
      context,
      title: 'Tampilan peta',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: cardDecoration(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: [
            SettingsRow(
              icon: LucideIcons.tag,
              tint: KColors.soil,
              soft: KColors.soilSoft,
              label: 'Tampilkan label zona',
              toggle: showLabels,
              onToggle: (v) {
                setState(() => showLabels = v);
                setSheet(() {});
              },
            ),
            SettingsRow(
              icon: LucideIcons.radio,
              tint: KColors.water,
              soft: KColors.waterSoft,
              label: 'Sorot zona bermasalah',
              toggle: showSensors,
              divider: false,
              onToggle: (v) {
                setState(() => showSensors = v);
                setSheet(() {});
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final zones = _zones(s);
    final sel = selected == null ? null : s.zone(selected!);
    final cropCount = s.zones.where((z) => z.kind == ZoneKind.crop).length;

    final map = FarmMap(
      zones: s.zones,
      selected: selected ?? (filter == 'all' ? null : filter),
      showLabels: showLabels,
      showSensors: showSensors,
      onTapZone: (z) => _select(z.id),
    );

    final hint = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: sel == null
          ? Container(
              key: const ValueKey('hint'),
              padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
              decoration: BoxDecoration(color: KColors.primarySoft, borderRadius: BorderRadius.circular(KRadius.md)),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.map, size: 18, color: KColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ketuk area untuk lihat detail', style: KText.bodySemi.copyWith(color: KColors.primaryDark)),
                    const SizedBox(height: 2),
                    Text('${s.zones.length} zona · $cropCount jenis tanaman · ${s.animalTotal} hewan', style: KText.caption.copyWith(color: KColors.primary)),
                  ]),
                ),
              ]),
            )
          : Container(
              key: ValueKey(sel.id),
              decoration: cardDecoration(radius: KRadius.md, border: KColors.primary, borderWidth: 1.5),
              child: Tap(
                onTap: () => openZone(context, sel),
                radius: KRadius.md,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(children: [
                    IconChip(icon: sel.icon, tint: sel.iconTint, soft: sel.iconSoft, size: 36, iconSize: 18, radius: KRadius.full),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(sel.name, style: KText.bodySemi),
                        const SizedBox(height: 2),
                        Text(sel.summary, style: KText.caption, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: KColors.primary, borderRadius: BorderRadius.circular(KRadius.full)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Lihat detail', style: KText.captionSemi.copyWith(color: Colors.white)),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronRight, size: 14, color: Colors.white),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
    );

    final list = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(title: filter == 'all' ? 'Semua zona' : 'Zona terpilih', action: 'Urutkan', onAction: _openSort),
      const SizedBox(height: 16),
      for (var i = 0; i < zones.length; i++) ...[
        if (i > 0) const SizedBox(height: 16),
        ZoneRow(zone: zones[i], selected: zones[i].id == selected, onTap: () => openZone(context, zones[i])),
      ],
    ]);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 12),
        child: Centered(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TitleBar(
              title: 'Kebun Saya',
              subtitle: '${s.farm.name} · ${s.farm.area}',
              subtitleIcon: LucideIcons.mapPin,
              trailing: CircleIconButton(icon: LucideIcons.slidersVertical, tooltip: 'Tampilan peta', onTap: _openSettings),
            ),
            ChipRow(children: [
              for (final f in filters)
                KChip(
                  label: f.$2,
                  icon: f.$3,
                  active: filter == f.$1,
                  onTap: () => setState(() {
                    filter = f.$1;
                    selected = null;
                  }),
                ),
            ]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: LayoutBuilder(builder: (context, c) {
                if (c.maxWidth >= 820) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: (c.maxWidth * 0.48).clamp(360, 520), child: map),
                    const SizedBox(width: 24),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [hint, const SizedBox(height: 16), list])),
                  ]);
                }
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: map)),
                  const SizedBox(height: 16),
                  hint,
                  const SizedBox(height: 16),
                  list,
                ]);
              }),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The illustrated farm map from Figma with tappable zones and label pins.
class FarmMap extends StatelessWidget {
  const FarmMap({super.key, required this.zones, required this.selected, required this.onTapZone, this.showLabels = true, this.showSensors = true});
  final List<Zone> zones;
  final String? selected;
  final ValueChanged<Zone> onTapZone;
  final bool showLabels;
  final bool showSensors;

  static const designSize = Size(358, 430);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: designSize.width / designSize.height,
      child: LayoutBuilder(builder: (context, c) {
        final k = c.maxWidth / designSize.width;
        return ClipRRect(
          borderRadius: BorderRadius.circular(KRadius.lg),
          child: Stack(children: [
            Positioned.fill(child: Image.asset('assets/images/farm_map.png', fit: BoxFit.fill, filterQuality: FilterQuality.medium)),
            if (showSensors)
              for (final z in zones.where((z) => z.warning))
                Positioned(
                  left: z.mapRect.left * k,
                  top: z.mapRect.top * k,
                  width: z.mapRect.width * k,
                  height: z.mapRect.height * k,
                  child: IgnorePointer(child: _PulseOverlay()),
                ),
            for (final z in zones)
              Positioned(
                left: z.mapRect.left * k,
                top: z.mapRect.top * k,
                width: z.mapRect.width * k,
                height: z.mapRect.height * k,
                child: _ZoneHit(zone: z, selected: z.id == selected, dimmed: selected != null && z.id != selected, onTap: () => onTapZone(z)),
              ),
            if (showLabels)
              for (final z in zones)
                Positioned(
                  left: z.pin.dx * k,
                  top: z.pin.dy * k,
                  child: IgnorePointer(
                    child: Transform.scale(
                      alignment: Alignment.topLeft,
                      scale: k.clamp(0.85, 1.25),
                      child: _Pin(label: z.name == 'Rumah Kebun' ? 'Rumah' : z.name, warning: z.warning, active: z.id == selected),
                    ),
                  ),
                ),
          ]),
        );
      }),
    );
  }
}

class _ZoneHit extends StatefulWidget {
  const _ZoneHit({required this.zone, required this.selected, required this.dimmed, required this.onTap});
  final Zone zone;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  State<_ZoneHit> createState() => _ZoneHitState();
}

class _ZoneHitState extends State<_ZoneHit> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Tooltip(
          message: '${widget.zone.name} · ${widget.zone.status}',
          waitDuration: const Duration(milliseconds: 500),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: widget.dimmed ? const Color(0x33F6F3EC) : (hover ? const Color(0x14FFFFFF) : Colors.transparent),
              border: widget.selected
                  ? Border.all(color: KColors.primary, width: 3)
                  : (hover ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2) : null),
              boxShadow: widget.selected ? const [BoxShadow(color: Color(0x332F7D4F), blurRadius: 12)] : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.label, required this.warning, required this.active});
  final String label;
  final bool warning;
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
        decoration: BoxDecoration(
          color: active ? KColors.text : Colors.white,
          borderRadius: BorderRadius.circular(KRadius.full),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: warning ? KColors.warning : KColors.success, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: KText.small.copyWith(color: active ? Colors.white : KColors.text)),
        ]),
      );
}

class _PulseOverlay extends StatefulWidget {
  @override
  State<_PulseOverlay> createState() => _PulseOverlayState();
}

class _PulseOverlayState extends State<_PulseOverlay> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, __) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: KColors.warning.withValues(alpha: 0.06 + 0.12 * c.value),
          ),
        ),
      );
}
