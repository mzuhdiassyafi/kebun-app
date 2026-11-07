import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Severity? filter; // null = semua

  void _settings() {
    final s = AppScope.read(context);
    showSheet(
      context,
      title: 'Pengaturan notifikasi',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            decoration: cardDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              SettingsRow(
                icon: LucideIcons.bell,
                tint: KColors.danger,
                soft: KColors.dangerSoft,
                label: 'Notifikasi push',
                toggle: s.pushNotif,
                onToggle: (v) {
                  s.setPush(v);
                  set(() {});
                },
              ),
              SettingsRow(
                icon: LucideIcons.checkCheck,
                tint: KColors.primary,
                soft: KColors.primarySoft,
                label: 'Tandai semua dibaca',
                divider: false,
                onTap: () {
                  s.markAllRead();
                  Navigator.pop(ctx);
                  toast(context, 'Semua notifikasi ditandai dibaca');
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _detail(AlertItem a) {
    final s = AppScope.read(context);
    s.markRead(a);
    final (icon, tint, soft) = severityStyle(a.severity);
    showSheet(
      context,
      title: a.title,
      subtitle: '${a.day} · ${a.time} lalu',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        KCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconChip(icon: icon, tint: tint, soft: soft, radius: KRadius.full),
            const SizedBox(width: 12),
            Expanded(child: Text(a.description, style: KText.bodyMedium)),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: KButton(
              label: 'Tandai belum dibaca',
              style: KButtonStyle.ghost,
              height: 50,
              onTap: () {
                s.markRead(a, false);
                Navigator.pop(ctx);
              },
            ),
          ),
          if (a.zoneId != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: KButton(
                label: 'Buka',
                icon: LucideIcons.arrowRight,
                height: 50,
                onTap: () {
                  Navigator.pop(ctx);
                  openAlert(context, a);
                },
              ),
            ),
          ],
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final showBanner = s.criticalBannerVisible && !s.tankRefilled;
    final kritis = showBanner ? 1 : 0;
    final warn = s.alerts.where((a) => a.severity == Severity.peringatan).length;
    final info = s.alerts.where((a) => a.severity == Severity.info).length;
    final items = s.alerts.where((a) => filter == null || a.severity == filter).toList();
    final days = <String>[];
    for (final a in items) {
      if (!days.contains(a.day)) days.add(a.day);
    }

    final children = <Widget>[];
    if (showBanner && (filter == null || filter == Severity.kritis)) {
      children.add(_CriticalBanner(
        onSnooze: () {
          s.snoozeBanner(true);
          toast(context, 'Diingatkan lagi 1 jam', action: 'Batal', onAction: () => s.snoozeBanner(false), icon: LucideIcons.clock);
        },
        onRefill: () async {
          final ok = await confirm(context, title: 'Isi tandon sekarang?', message: 'Pompa sumur akan menyala ±25 menit untuk mengisi tandon hingga 2.000 L.', ok: 'Isi tandon', danger: true);
          if (ok && context.mounted) {
            s.refillTank();
            toast(context, 'Pompa dinyalakan. Tandon sedang diisi.');
          }
        },
      ));
      children.add(const SizedBox(height: 4));
    }
    if (filter == Severity.kritis && !showBanner) {
      children.add(KCard(child: Text('Tidak ada notifikasi kritis. 👍', style: KText.bodyMedium)));
    }
    for (final d in days) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(d.toUpperCase(), style: KText.small.copyWith(letterSpacing: 0.4)),
      ));
      for (final a in items.where((a) => a.day == d)) {
        children.add(Dismissible(
          key: ValueKey(a.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: KColors.dangerSoft, borderRadius: BorderRadius.circular(KRadius.md)),
            child: const Icon(LucideIcons.trash2, color: KColors.danger),
          ),
          onDismissed: (_) {
            final idx = s.alerts.indexOf(a);
            s.removeAlert(a);
            toast(context, 'Notifikasi dihapus', action: 'Urungkan', onAction: () => s.restoreAlert(a, idx), icon: LucideIcons.trash2);
          },
          child: AlertTile(alert: a, onTap: () => _detail(a)),
        ));
      }
    }
    if (items.isEmpty && filter != Severity.kritis) {
      children.add(KCard(child: Text('Belum ada notifikasi di kategori ini.', style: KText.caption)));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12),
          child: Centered(
            maxWidth: 760,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TopBar(title: 'Notifikasi', trailing: CircleIconButton(icon: LucideIcons.slidersVertical, tooltip: 'Pengaturan', onTap: _settings)),
              ChipRow(children: [
                KChip(label: 'Semua · ${kritis + warn + info}', active: filter == null, onTap: () => setState(() => filter = null)),
                KChip(label: 'Kritis · $kritis', active: filter == Severity.kritis, onTap: () => setState(() => filter = Severity.kritis)),
                KChip(label: 'Peringatan · $warn', active: filter == Severity.peringatan, onTap: () => setState(() => filter = Severity.peringatan)),
                KChip(label: 'Info · $info', active: filter == Severity.info, onTap: () => setState(() => filter = Severity.info)),
              ]),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 12), children[i]],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CriticalBanner extends StatelessWidget {
  const _CriticalBanner({required this.onSnooze, required this.onRefill});
  final VoidCallback onSnooze;
  final VoidCallback onRefill;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: KColors.dangerSoft, borderRadius: BorderRadius.circular(KRadius.lg), border: Border.all(color: KColors.danger)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const IconChip(icon: LucideIcons.droplet, tint: Colors.white, soft: KColors.danger, radius: KRadius.full),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tandon air hampir kosong', style: KText.title.copyWith(color: KColors.danger)),
                const SizedBox(height: 2),
                Text('Sisa 12% (240 L). Penyiraman otomatis sore bisa gagal.', style: KText.caption.copyWith(color: KColors.text)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: KButton(label: 'Ingatkan nanti', style: KButtonStyle.ghost, height: 44, compact: true, onTap: onSnooze)),
            const SizedBox(width: 8),
            Expanded(child: KButton(label: 'Isi tandon', style: KButtonStyle.danger, height: 44, compact: true, onTap: onRefill)),
          ]),
        ]),
      );
}
