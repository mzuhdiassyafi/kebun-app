import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class LivestockScreen extends StatefulWidget {
  const LivestockScreen({super.key});

  @override
  State<LivestockScreen> createState() => _LivestockScreenState();
}

class _LivestockScreenState extends State<LivestockScreen> {
  String category = 'Sapi';
  String statusFilter = 'Semua'; // Semua / Sehat / Perlu dicek / Bunting
  bool expanded = false;

  bool _needsCheck(Animal a) => a.health < 85;
  bool _pregnant(Animal a) => a.note?.startsWith('Bunting') ?? false;

  List<Animal> _filtered(AppState s) {
    var list = s.animals.where((a) => a.category == category).toList();
    if (statusFilter == 'Sehat') list = list.where((a) => !_needsCheck(a)).toList();
    if (statusFilter == 'Perlu dicek') list = s.animals.where(_needsCheck).toList();
    if (statusFilter == 'Bunting') list = s.animals.where(_pregnant).toList();
    return list;
  }

  void _openAnimal(Animal a) {
    final s = AppScope.read(context);
    showSheet(
      context,
      title: a.name,
      subtitle: '${a.breed} · ${a.tag}',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          KCard(
            child: Row(children: [
              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: KColors.waterSoft, borderRadius: BorderRadius.circular(KRadius.md)),
                child: Image.asset(animalImage(a.category)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Skor kesehatan', style: KText.caption),
                  Text('${a.health}%', style: KText.display.copyWith(color: a.health < 85 ? KColors.warning : KColors.success)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    Pill(label: a.age, color: KColors.soil, bg: KColors.soilSoft),
                    Pill(label: a.category, color: KColors.soil, bg: KColors.soilSoft),
                    if (a.note != null) Pill(label: a.note!, color: KColors.warning, bg: KColors.warningSoft),
                  ]),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          ListCard(children: [
            ListRow(leading: const IconChip(icon: LucideIcons.syringe, tint: KColors.water, soft: KColors.waterSoft, size: 36, iconSize: 18, radius: KRadius.full), title: 'Vaksin terakhir', subtitle: 'PMK · 12 Okt 2026'),
            ListRow(leading: const IconChip(icon: LucideIcons.scale, tint: KColors.soil, soft: KColors.soilSoft, size: 36, iconSize: 18, radius: KRadius.full), title: 'Berat terakhir', subtitle: a.category == 'Sapi' ? '412 kg · naik 6 kg' : '—'),
            ListRow(leading: const IconChip(icon: LucideIcons.utensils, tint: KColors.primary, soft: KColors.primarySoft, size: 36, iconSize: 18, radius: KRadius.full), title: 'Pakan hari ini', subtitle: 'Hay 8 kg · konsentrat 2 kg'),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: KButton(
                label: 'Tandai dicek',
                style: KButtonStyle.secondary,
                icon: LucideIcons.check,
                onTap: () {
                  a.health = (a.health + 5).clamp(0, 100);
                  s.touch();
                  Navigator.pop(ctx);
                  toast(context, '${a.name} ditandai sudah dicek');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KButton(
                label: 'Hubungi dokter',
                icon: LucideIcons.phone,
                onTap: () {
                  Navigator.pop(ctx);
                  toast(context, 'Permintaan dikirim ke drh. Sari', icon: LucideIcons.phone);
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _addAnimal() {
    final s = AppScope.read(context);
    final name = TextEditingController();
    final breed = TextEditingController();
    var cat = category;
    showSheet(
      context,
      title: 'Tambah ternak',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Jenis', style: KText.captionSemi),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in animalCategories) KChip(label: c.label, active: cat == c.label, onTap: () => set(() => cat = c.label)),
          ]),
          const SizedBox(height: 16),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
          const SizedBox(height: 12),
          TextField(controller: breed, decoration: const InputDecoration(labelText: 'Ras')),
          const SizedBox(height: 16),
          KButton(
            label: 'Simpan',
            icon: LucideIcons.check,
            onTap: () {
              if (name.text.trim().isEmpty) {
                toast(context, 'Isi nama ternak dulu', icon: LucideIcons.info);
                return;
              }
              final count = s.animals.where((a) => a.category == cat).length + 1;
              s.addAnimal(Animal(
                name: name.text.trim(),
                breed: breed.text.trim().isEmpty ? 'Lokal' : breed.text.trim(),
                tag: '${cat.toUpperCase().substring(0, cat == 'Kambing' ? 3 : cat.length)}-${(30 + count).toString().padLeft(3, '0')}',
                age: 'Baru',
                health: 100,
                category: cat,
              ));
              setState(() {
                category = cat;
                statusFilter = 'Semua';
              });
              Navigator.pop(ctx);
              toast(context, '${name.text.trim()} ditambahkan');
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = _filtered(s);
    final shown = expanded ? list : list.take(3).toList();
    final done = s.feeding.where((f) => f.done).length;
    final needCheck = s.animals.where(_needsCheck).length;
    final pregnant = s.animals.where(_pregnant).length;
    final total = s.animalTotal + (s.animals.length - 12);
    final catCount = {for (final c in animalCategories) c.label: c.count + s.animals.where((a) => a.category == c.label).length - _seedCount(c.label)};

    final summary = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: KColors.primary, borderRadius: BorderRadius.circular(KRadius.lg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total ternak', style: KText.caption.copyWith(color: KColors.primarySoft)),
              const SizedBox(height: 2),
              Text('$total ekor', style: KText.display.copyWith(color: Colors.white)),
            ]),
          ),
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(KRadius.md)),
            child: Image.asset(animalImage(category)),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          for (final t in [('Sehat', total - needCheck), ('Perlu dicek', needCheck), ('Bunting', pregnant)]) ...[
            if (t.$1 != 'Sehat') const SizedBox(width: 8),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: statusFilter == t.$1 ? Colors.white.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(KRadius.sm),
                  border: Border.all(color: statusFilter == t.$1 ? Colors.white : Colors.transparent),
                ),
                child: Tap(
                  radius: KRadius.sm,
                  onTap: () => setState(() {
                    statusFilter = statusFilter == t.$1 ? 'Semua' : t.$1;
                    expanded = true;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${t.$2}', style: KText.h18.copyWith(color: Colors.white)),
                      Text(t.$1, style: KText.small.copyWith(color: KColors.primarySoft)),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ]),
    );

    final feeding = KCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Jadwal pakan hari ini', style: KText.title)),
          Text('$done/${s.feeding.length} selesai', style: KText.captionSemi.copyWith(color: KColors.primary)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          for (var i = 0; i < s.feeding.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 6,
                decoration: BoxDecoration(color: s.feeding[i].done ? KColors.primary : KColors.subtle, borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < s.feeding.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _FeedSlot(slot: s.feeding[i], next: !s.feeding[i].done && s.feeding.indexWhere((f) => !f.done) == i)),
          ],
        ]),
      ]),
    );

    final categories = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader(title: 'Kategori'),
      const SizedBox(height: 20),
      Row(children: [
        for (var i = 0; i < animalCategories.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: CategoryTile(
              category: animalCategories[i],
              count: catCount[animalCategories[i].label]!,
              selected: category == animalCategories[i].label && statusFilter == 'Semua',
              onTap: () => setState(() {
                category = animalCategories[i].label;
                statusFilter = 'Semua';
                expanded = false;
              }),
            ),
          ),
        ],
      ]),
    ]);

    final title = switch (statusFilter) {
      'Perlu dicek' => 'Perlu dicek',
      'Bunting' => 'Sedang bunting',
      'Sehat' => '$category sehat',
      _ => '$category kamu',
    };
    final animals = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(
        title: title,
        action: list.length > 3 ? (expanded ? 'Ringkas' : 'Lihat ${statusFilter == 'Semua' ? catCount[category] : list.length}') : null,
        onAction: () => setState(() => expanded = !expanded),
      ),
      const SizedBox(height: 20),
      if (shown.isEmpty) KCard(child: Text('Tidak ada ternak di kategori ini.', style: KText.caption)),
      for (var i = 0; i < shown.length; i++) ...[
        if (i > 0) const SizedBox(height: 12),
        AnimalRow(animal: shown[i], onTap: () => _openAnimal(shown[i])),
      ],
    ]);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12),
          child: Centered(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TopBar(
                title: 'Ternak',
                subtitle: 'Area Ternak · ${s.farm.name}',
                trailing: CircleIconButton(icon: LucideIcons.plus, filled: true, tooltip: 'Tambah ternak', onTap: _addAnimal),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: LayoutBuilder(builder: (context, c) {
                  if (c.maxWidth >= 900) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [summary, const SizedBox(height: 20), feeding, const SizedBox(height: 20), categories])),
                      const SizedBox(width: 24),
                      Expanded(child: animals),
                    ]);
                  }
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    summary,
                    const SizedBox(height: 20),
                    feeding,
                    const SizedBox(height: 20),
                    categories,
                    const SizedBox(height: 20),
                    animals,
                  ]);
                }),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  int _seedCount(String c) => {'Sapi': 5, 'Ayam': 3, 'Domba': 2, 'Kambing': 2}[c]!;
}

class _FeedSlot extends StatelessWidget {
  const _FeedSlot({required this.slot, required this.next});
  final FeedingSlot slot;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context);
    final bg = slot.done ? KColors.canvas : (next ? KColors.sunSoft : KColors.canvas);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(KRadius.sm)),
      child: Tap(
        radius: KRadius.sm,
        tooltip: slot.done ? 'Tandai belum' : 'Tandai selesai',
        onTap: () {
          s.toggleFeeding(slot);
          toast(context, slot.done ? 'Pakan ${slot.label.toLowerCase()} ditandai selesai' : 'Pakan ${slot.label.toLowerCase()} dibatalkan');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(slot.done ? LucideIcons.check : LucideIcons.clock, size: 12, color: slot.done ? KColors.success : KColors.sun),
              const SizedBox(width: 4),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('${slot.label} · ${slot.time}', style: KText.small, maxLines: 1))),
            ]),
            const SizedBox(height: 4),
            Text(slot.food, style: KText.captionSemi, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(slot.done ? 'Selesai' : 'Nanti', style: KText.small.copyWith(color: slot.done ? KColors.success : KColors.sun)),
          ]),
        ),
      ),
    );
  }
}
