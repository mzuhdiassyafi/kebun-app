import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart' show FarmOption;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _edit(BuildContext context) {
    final s = AppScope.read(context);
    final c = TextEditingController(text: s.userName);
    showSheet(
      context,
      title: 'Ubah profil',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Nama')),
        const SizedBox(height: 12),
        TextField(enabled: false, controller: TextEditingController(text: 'Pemilik'), decoration: const InputDecoration(labelText: 'Peran')),
        const SizedBox(height: 16),
        KButton(
          label: 'Simpan',
          onTap: () {
            if (c.text.trim().isEmpty) return;
            s.rename(c.text.trim());
            Navigator.pop(ctx);
            toast(context, 'Profil diperbarui');
          },
        ),
      ]),
    );
  }

  void _addFarm(BuildContext context) {
    final s = AppScope.read(context);
    final name = TextEditingController();
    final area = TextEditingController();
    showSheet(
      context,
      title: 'Tambah kebun',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Nama kebun')),
        const SizedBox(height: 12),
        TextField(controller: area, decoration: const InputDecoration(labelText: 'Luas', suffixText: 'ha')),
        const SizedBox(height: 16),
        KButton(
          label: 'Tambah',
          icon: LucideIcons.plus,
          onTap: () {
            if (name.text.trim().isEmpty) {
              toast(context, 'Isi nama kebun dulu', icon: LucideIcons.info);
              return;
            }
            s.addFarm(name.text.trim(), '${area.text.trim().isEmpty ? '0,1' : area.text.trim()} ha');
            Navigator.pop(ctx);
            toast(context, '${name.text.trim()} ditambahkan');
          },
        ),
      ]),
    );
  }

  void _devices(BuildContext context) {
    const devices = [
      ('Sensor kelembapan #1', 'Lahan Tomat', '86%'),
      ('Sensor kelembapan #2', 'Lahan Sayur', '72%'),
      ('Sensor suhu & cahaya', 'Lahan Tomat', '64%'),
      ('Sensor pH', 'Lahan Jagung', '15%'),
      ('Level tandon', 'Kolam', '91%'),
      ('Termometer kandang', 'Area Ternak', '58%'),
    ];
    showSheet(
      context,
      title: 'Perangkat & sensor',
      subtitle: '12 aktif · 0 offline',
      builder: (ctx) => ListCard(children: [
        for (final d in devices)
          ListRow(
            leading: const IconChip(icon: LucideIcons.radio, tint: KColors.water, soft: KColors.waterSoft, size: 36, iconSize: 18),
            title: d.$1,
            subtitle: d.$2,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(d.$3 == '15%' ? LucideIcons.batteryLow : LucideIcons.batteryMedium, size: 18, color: d.$3 == '15%' ? KColors.danger : KColors.textSecondary),
              const SizedBox(width: 4),
              Text(d.$3, style: KText.small.copyWith(color: d.$3 == '15%' ? KColors.danger : KColors.textSecondary)),
            ]),
            onTap: () {},
          ),
      ]),
    );
  }

  void _thresholds(BuildContext context) {
    final s = AppScope.read(context);
    var v = s.moistureThreshold;
    showSheet(
      context,
      title: 'Ambang peringatan',
      subtitle: '4 aturan aktif',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          KCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text('Kelembapan tanah minimum', style: KText.bodySemi)),
                Text('${v.round()}%', style: KText.title.copyWith(color: KColors.primary)),
              ]),
              Slider(value: v, min: 20, max: 80, divisions: 60, onChanged: (x) => set(() => v = x)),
            ]),
          ),
          const SizedBox(height: 12),
          ListCard(children: [
            ListRow(leading: const IconChip(icon: LucideIcons.thermometer, tint: KColors.danger, soft: KColors.dangerSoft, size: 36, iconSize: 18), title: 'Suhu udara maksimum', subtitle: '33°C', onTap: () {}),
            ListRow(leading: const IconChip(icon: LucideIcons.droplet, tint: KColors.water, soft: KColors.waterSoft, size: 36, iconSize: 18), title: 'Level tandon minimum', subtitle: '20%', onTap: () {}),
            ListRow(leading: const IconChip(icon: LucideIcons.heart, tint: KColors.sun, soft: KColors.sunSoft, size: 36, iconSize: 18), title: 'Kesehatan ternak', subtitle: 'Di bawah 85%', onTap: () {}),
          ]),
          const SizedBox(height: 16),
          KButton(
            label: 'Simpan',
            onTap: () {
              s.setThreshold(v);
              Navigator.pop(ctx);
              toast(context, 'Ambang peringatan disimpan');
            },
          ),
        ]),
      ),
    );
  }

  void _schedule(BuildContext context) {
    final s = AppScope.read(context);
    const options = ['05.30, 16.30', '06.00, 16.00', '06.00, 12.00, 17.00', '07.00'];
    showSheet(
      context,
      title: 'Jadwal penyiraman',
      subtitle: 'Berlaku untuk semua zona tanaman',
      builder: (ctx) => OptionList(
        options: options,
        selected: s.wateringSchedule,
        onSelect: (v) {
          s.setSchedule(v);
          Navigator.pop(ctx);
          toast(context, 'Jadwal penyiraman: $v', icon: LucideIcons.clock);
        },
      ),
    );
  }

  void _units(BuildContext context) {
    final s = AppScope.read(context);
    showSheet(
      context,
      title: 'Satuan & bahasa',
      builder: (ctx) => OptionList(
        options: const ['kg · Indonesia', 'kg · English', 'lb · English'],
        selected: s.unitLang,
        onSelect: (v) {
          s.setUnitLang(v);
          Navigator.pop(ctx);
          toast(context, 'Disimpan: $v');
        },
      ),
    );
  }

  void _help(BuildContext context) {
    final c = TextEditingController();
    showSheet(
      context,
      title: 'Bantuan & masukan',
      subtitle: 'Ceritakan kendala atau ide kamu. Tim kami membalas dalam 1×24 jam.',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: c, minLines: 3, maxLines: 5, decoration: const InputDecoration(hintText: 'Tulis pesan…')),
        const SizedBox(height: 16),
        KButton(
          label: 'Kirim',
          icon: LucideIcons.send,
          onTap: () {
            Navigator.pop(ctx);
            toast(context, 'Terima kasih! Masukan terkirim.');
          },
        ),
      ]),
    );
  }

  void _about(BuildContext context) {
    showSheet(
      context,
      title: 'Tentang Kebun.io',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: KColors.primary, borderRadius: BorderRadius.circular(KRadius.md)),
            child: const Icon(LucideIcons.sprout, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kebun.io', style: KText.h18),
            Text('Versi 1.0 · web preview', style: KText.caption),
          ]),
        ]),
        const SizedBox(height: 14),
        Text('Pantau tanaman, ternak, sensor dan panen dari satu aplikasi. Data di versi ini adalah data contoh.', style: KText.bodyMedium.copyWith(color: KColors.textSecondary)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);

    final profile = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: KColors.primary, borderRadius: BorderRadius.circular(KRadius.lg)),
      child: Row(children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(s.userName.characters.first.toUpperCase(), style: KText.h22.copyWith(color: KColors.primary)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.userName, style: KText.h18.copyWith(color: Colors.white), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('Pemilik · ${s.farms.length} kebun', style: KText.caption.copyWith(color: KColors.primarySoft)),
          ]),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(KRadius.full)),
          child: Tap(
            onTap: () => _edit(context),
            radius: KRadius.full,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text('Ubah', style: KText.caption.copyWith(color: Colors.white)),
            ),
          ),
        ),
      ]),
    );

    final farms = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(title: 'Kebun saya', action: 'Kelola', onAction: () => _addFarm(context)),
      const SizedBox(height: 20),
      KCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < s.farms.length; i++) ...[
            FarmOption(
              farm: s.farms[i],
              active: i == s.activeFarm,
              onTap: () {
                s.setFarm(i);
                toast(context, 'Kebun aktif: ${s.farms[i].name}');
              },
            ),
            const SizedBox(height: 10),
          ],
          DottedAddButton(label: 'Tambah kebun', onTap: () => _addFarm(context)),
        ]),
      ),
    ]);

    final monitoring = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader(title: 'Pemantauan'),
      const SizedBox(height: 20),
      Container(
        decoration: cardDecoration(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Column(children: [
          SettingsRow(icon: LucideIcons.radio, tint: KColors.water, soft: KColors.waterSoft, label: 'Perangkat & sensor', value: '12 aktif', onTap: () => _devices(context)),
          SettingsRow(icon: LucideIcons.triangleAlert, tint: KColors.warning, soft: KColors.warningSoft, label: 'Ambang peringatan', value: '4 aturan', onTap: () => _thresholds(context)),
          SettingsRow(
            icon: LucideIcons.bell,
            tint: KColors.danger,
            soft: KColors.dangerSoft,
            label: 'Notifikasi push',
            toggle: s.pushNotif,
            onToggle: (v) {
              s.setPush(v);
              toast(context, v ? 'Notifikasi push aktif' : 'Notifikasi push dimatikan', icon: LucideIcons.bell);
            },
          ),
          SettingsRow(icon: LucideIcons.clock, tint: KColors.primary, soft: KColors.primarySoft, label: 'Jadwal penyiraman', value: s.wateringSchedule, divider: false, onTap: () => _schedule(context)),
        ]),
      ),
    ]);

    final account = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader(title: 'Akun'),
      const SizedBox(height: 20),
      Container(
        decoration: cardDecoration(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Column(children: [
          SettingsRow(icon: LucideIcons.tag, tint: KColors.soil, soft: KColors.soilSoft, label: 'Satuan & bahasa', value: s.unitLang, onTap: () => _units(context)),
          SettingsRow(icon: LucideIcons.heart, tint: KColors.sun, soft: KColors.sunSoft, label: 'Bantuan & masukan', onTap: () => _help(context)),
          SettingsRow(icon: LucideIcons.slidersVertical, tint: KColors.textSecondary, soft: KColors.subtle, label: 'Tentang Kebun.io', value: 'v1.0', divider: false, onTap: () => _about(context)),
        ]),
      ),
    ]);

    final logout = Container(
      decoration: BoxDecoration(color: KColors.dangerSoft, borderRadius: BorderRadius.circular(KRadius.md)),
      child: Tap(
        radius: KRadius.md,
        onTap: () async {
          final ok = await confirm(context, title: 'Keluar dari akun?', message: 'Kamu perlu masuk lagi untuk memantau kebun.', ok: 'Keluar', danger: true);
          if (ok && context.mounted) AppScope.read(context).logout();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(child: Text('Keluar', style: KText.title.copyWith(color: KColors.danger))),
        ),
      ),
    );

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 12),
        child: Centered(
          maxWidth: 1000,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const TitleBar(title: 'Profil'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: LayoutBuilder(builder: (context, c) {
                if (c.maxWidth >= 860) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [profile, const SizedBox(height: 20), farms])),
                    const SizedBox(width: 24),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [monitoring, const SizedBox(height: 20), account, const SizedBox(height: 20), logout])),
                  ]);
                }
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  profile,
                  const SizedBox(height: 20),
                  farms,
                  const SizedBox(height: 20),
                  monitoring,
                  const SizedBox(height: 20),
                  account,
                  const SizedBox(height: 20),
                  logout,
                ]);
              }),
            ),
          ]),
        ),
      ),
    );
  }
}

class DottedAddButton extends StatelessWidget {
  const DottedAddButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashedBorder(),
        child: Tap(
          onTap: onTap,
          radius: KRadius.md,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(LucideIcons.plus, size: 18, color: KColors.primary),
              const SizedBox(width: 8),
              Text(label, style: KText.bodySemi.copyWith(color: KColors.primary)),
            ]),
          ),
        ),
      );
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(KRadius.md));
    final path = Path()..addRRect(rrect.deflate(0.5));
    final p = Paint()
      ..color = KColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
