import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart' show formatKg;

class _MonthData {
  const _MonthData(this.name, this.weeks, this.split, this.delta, this.up);
  final String name;
  final List<double> weeks;
  final List<double> split; // tomat, sayur, jagung
  final String delta;
  final bool up;
}

const _pastMonths = {
  'Agustus 2026': _MonthData('Agustus 2026', [180, 240, 260, 210], [420, 300, 170], '+4% vs Jul', true),
  'September 2026': _MonthData('September 2026', [220, 260, 300, 250], [480, 340, 210], '+16% vs Agu', true),
  'Oktober 2026': _MonthData('Oktober 2026', [190, 300, 330, 323], [560, 383, 200], '+11% vs Sep', true),
};

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  String month = 'November 2026';
  int? week;
  int upcomingSel = 0;
  String? category;
  bool showAll = false;
  final Set<int> reminders = {0};

  _MonthData _data(AppState s) {
    if (_pastMonths.containsKey(month)) return _pastMonths[month]!;
    final extra = s.monthTotal - 1280;
    return _MonthData(
      'November 2026',
      [210 + extra, 340, 410, 320],
      [s.categoryTotal('Tomat'), s.categoryTotal('Sayur'), s.categoryTotal('Jagung')],
      '+12% vs Okt',
      true,
    );
  }

  void _pickMonth() {
    final months = [..._pastMonths.keys, 'November 2026'];
    showSheet(
      context,
      title: 'Pilih bulan',
      builder: (ctx) => OptionList(
        options: months.reversed.toList(),
        selected: month,
        onSelect: (m) {
          setState(() {
            month = m;
            week = null;
            category = null;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _calendar() {
    final s = AppScope.read(context);
    showSheet(
      context,
      title: 'Kalender panen',
      subtitle: 'Aktifkan pengingat H-1 sebelum panen.',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => ListCard(children: [
          for (var i = 0; i < s.upcoming.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                _DateBox(day: s.upcoming[i].day, month: s.upcoming[i].month, active: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.upcoming[i].crop, style: KText.bodySemi),
                    Text('${s.upcoming[i].zone} · ${s.upcoming[i].estimate}', style: KText.caption),
                  ]),
                ),
                KToggle(
                  value: reminders.contains(i),
                  onChanged: (v) {
                    set(() {});
                    setState(() => v ? reminders.add(i) : reminders.remove(i));
                    toast(context, v ? 'Pengingat ${s.upcoming[i].crop} aktif' : 'Pengingat dimatikan', icon: LucideIcons.bell);
                  },
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  void _harvestDetail(Harvest h) {
    final s = AppScope.read(context);
    showSheet(
      context,
      title: h.crop,
      subtitle: '${h.zone} · ${h.date}',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        KCard(
          child: Row(children: [
            IconChip(icon: LucideIcons.shoppingBasket, tint: h.tint, soft: h.soft, size: 48, iconSize: 24),
            const SizedBox(width: 14),
            Expanded(child: Text('${formatKg(h.kg)} kg', style: KText.display)),
            Pill(label: h.grade, color: h.grade == 'Grade A' ? KColors.success : KColors.sun, bg: h.grade == 'Grade A' ? KColors.successSoft : KColors.sunSoft),
          ]),
        ),
        const SizedBox(height: 12),
        Text('Estimasi nilai jual: Rp ${formatKg(h.kg * (h.category == 'Tomat' ? 9 : h.category == 'Sayur' ? 12 : 6))}.000', style: KText.bodyMedium.copyWith(color: KColors.textSecondary)),
        const SizedBox(height: 16),
        KButton(
          label: 'Hapus catatan',
          icon: LucideIcons.trash2,
          style: KButtonStyle.ghost,
          onTap: () async {
            final ok = await confirm(ctx, title: 'Hapus catatan panen?', message: '${h.crop} ${formatKg(h.kg)} kg akan dihapus dari riwayat.', ok: 'Hapus', danger: true);
            if (!ok) return;
            final idx = s.harvests.indexOf(h);
            s.harvests.remove(h);
            s.touch();
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) {
              toast(context, 'Catatan dihapus', action: 'Urungkan', onAction: () {
                s.harvests.insert(idx, h);
                s.touch();
              });
            }
          },
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = _data(s);
    final total = d.weeks.reduce((a, b) => a + b);
    final maxIdx = d.weeks.indexOf(d.weeks.reduce((a, b) => a > b ? a : b));
    final selWeek = week ?? maxIdx;
    final isNow = month == 'November 2026';
    var history = isNow ? s.harvests : <Harvest>[];
    if (category != null) history = history.where((h) => h.category == category).toList();
    final shownHistory = showAll ? history : history.take(3).toList();

    final summary = KCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isNow ? 'Total panen bulan ini' : 'Total panen ${d.name.split(' ').first}', style: KText.caption),
              const SizedBox(height: 2),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: total, end: total),
                duration: const Duration(milliseconds: 400),
                builder: (_, v, __) => Text('${formatKg(v)} kg', style: KText.display),
              ),
            ]),
          ),
          Pill(label: d.delta, color: KColors.success, bg: KColors.successSoft),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < d.weeks.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => week = i),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Tooltip(
                      message: 'Minggu ${i + 1}: ${formatKg(d.weeks[i])} kg',
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: 56,
                          height: (d.weeks[i] * 0.19).clamp(8, 86),
                          decoration: BoxDecoration(
                            color: i == selWeek ? KColors.sun : KColors.sunSoft,
                            borderRadius: BorderRadius.circular(KRadius.sm),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Mg ${i + 1} · ${formatKg(d.weeks[i])}', style: KText.small.copyWith(color: i == selWeek ? KColors.text : KColors.textSecondary)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          for (final (i, c) in [(0, 'Tomat'), (1, 'Sayur'), (2, 'Jagung')]) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: category == c ? KColors.surface : KColors.canvas,
                  borderRadius: BorderRadius.circular(KRadius.sm),
                  border: Border.all(color: category == c ? _catColor(c) : Colors.transparent, width: 1.5),
                ),
                child: Tap(
                  radius: KRadius.sm,
                  tooltip: 'Filter riwayat: $c',
                  onTap: () => setState(() => category = category == c ? null : c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _catColor(c), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(c, style: KText.small),
                      ]),
                      const SizedBox(height: 2),
                      Text('${formatKg(d.split[i])} kg', style: KText.title),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ]),
    );

    final schedule = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(title: 'Jadwal panen', action: 'Kalender', onAction: _calendar),
      const SizedBox(height: 20),
      LayoutBuilder(builder: (context, c) {
        final count = c.maxWidth >= 560 ? 3 : 2;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _UpcomingCard(item: s.upcoming[i], active: upcomingSel == i, reminder: reminders.contains(i), onTap: () => setState(() => upcomingSel = i))),
          ],
        ]);
      }),
    ]);

    final historySection = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(
        title: category == null ? 'Riwayat panen' : 'Riwayat · $category',
        action: history.length > 3 ? (showAll ? 'Ringkas' : 'Semua') : (category != null ? 'Hapus filter' : null),
        onAction: () => setState(() {
          if (history.length > 3) {
            showAll = !showAll;
          } else {
            category = null;
          }
        }),
      ),
      const SizedBox(height: 20),
      if (shownHistory.isEmpty)
        KCard(child: Text(isNow ? 'Belum ada panen untuk filter ini.' : 'Riwayat rinci hanya tersedia untuk bulan berjalan.', style: KText.caption))
      else
        ListCard(children: [
          for (final h in shownHistory)
            ListRow(
              leading: IconChip(icon: LucideIcons.shoppingBasket, tint: h.tint, soft: h.soft),
              title: h.crop,
              subtitle: '${h.zone} · ${h.date}',
              onTap: () => _harvestDetail(h),
              trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${formatKg(h.kg)} kg', style: KText.title),
                const SizedBox(height: 2),
                Text(h.grade, style: KText.small.copyWith(color: h.grade == 'Grade A' ? KColors.success : KColors.sun)),
              ]),
            ),
        ]),
    ]);

    final cta = KButton(label: 'Catat panen baru', icon: LucideIcons.plus, onTap: () => showHarvestForm(context));

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 12),
        child: Centered(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TitleBar(
              title: 'Panen',
              subtitle: month,
              trailing: CircleIconButton(icon: LucideIcons.calendar, tooltip: 'Pilih bulan', onTap: _pickMonth),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: LayoutBuilder(builder: (context, c) {
                if (c.maxWidth >= 900) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [summary, const SizedBox(height: 20), schedule])),
                    const SizedBox(width: 24),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [historySection, const SizedBox(height: 20), cta])),
                  ]);
                }
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  summary,
                  const SizedBox(height: 20),
                  schedule,
                  const SizedBox(height: 20),
                  historySection,
                  const SizedBox(height: 20),
                  cta,
                ]);
              }),
            ),
          ]),
        ),
      ),
    );
  }
}

Color _catColor(String c) => switch (c) {
      'Tomat' => KColors.danger,
      'Sayur' => KColors.primary,
      _ => KColors.sun,
    };

class _DateBox extends StatelessWidget {
  const _DateBox({required this.day, required this.month, required this.active});
  final int day;
  final String month;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 52,
        decoration: BoxDecoration(color: active ? Colors.white.withValues(alpha: 0.16) : KColors.canvas, borderRadius: BorderRadius.circular(KRadius.sm)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$day', style: KText.h18.copyWith(color: active ? Colors.white : KColors.text)),
          Text(month, style: KText.small.copyWith(color: active ? KColors.primarySoft : KColors.textSecondary)),
        ]),
      );
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.item, required this.active, required this.reminder, required this.onTap});
  final UpcomingHarvest item;
  final bool active;
  final bool reminder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: cardDecoration(color: active ? KColors.primary : KColors.surface, border: active ? null : KColors.border),
        child: Tap(
          onTap: onTap,
          radius: KRadius.lg,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _DateBox(day: item.day, month: item.month, active: active),
                const Spacer(),
                if (reminder) Icon(LucideIcons.bellRing, size: 16, color: active ? Colors.white : KColors.primary),
              ]),
              const SizedBox(height: 12),
              Text(item.crop, style: KText.title.copyWith(color: active ? Colors.white : KColors.text), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${item.zone} · ${item.estimate}', style: KText.caption.copyWith(color: active ? KColors.primarySoft : KColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      );
}

/// "Catat panen baru" form.
void showHarvestForm(BuildContext context) {
  final s = AppScope.read(context);
  const crops = [
    ('Tomat Servo', 'Lahan Tomat', 'Tomat'),
    ('Selada keriting', 'Lahan Sayur', 'Sayur'),
    ('Bayam', 'Lahan Sayur', 'Sayur'),
    ('Jagung manis', 'Lahan Jagung', 'Jagung'),
  ];
  var crop = 0;
  var grade = 'Grade A';
  final kg = TextEditingController();
  String? error;
  showSheet(
    context,
    title: 'Catat panen baru',
    subtitle: 'Hari ini · ${s.farm.name}',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Tanaman', style: KText.captionSemi),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < crops.length; i++) KChip(label: crops[i].$1, active: crop == i, onTap: () => set(() => crop = i)),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: kg,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: InputDecoration(labelText: 'Berat (kg)', suffixText: 'kg', errorText: error),
          onChanged: (_) => set(() => error = null),
        ),
        const SizedBox(height: 16),
        Text('Kualitas', style: KText.captionSemi),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final g in ['Grade A', 'Grade B', 'Grade C']) KChip(label: g, active: grade == g, onTap: () => set(() => grade = g)),
        ]),
        const SizedBox(height: 20),
        KButton(
          label: 'Simpan panen',
          icon: LucideIcons.check,
          onTap: () {
            final v = double.tryParse(kg.text.replaceAll(',', '.'));
            if (v == null || v <= 0) {
              set(() => error = 'Masukkan berat yang valid');
              return;
            }
            final c = crops[crop];
            s.addHarvest(Harvest(crop: c.$1, zone: c.$2, date: '7 Nov', kg: v, grade: grade, category: c.$3));
            Navigator.pop(ctx);
            toast(context, 'Panen ${c.$1} ${formatKg(v)} kg dicatat');
          },
        ),
      ]),
    ),
  );
}
