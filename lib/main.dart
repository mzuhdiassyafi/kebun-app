import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'screens/analytics.dart';
import 'screens/farm.dart';
import 'screens/harvest.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'theme.dart';
import 'widgets.dart';

void main() => runApp(const KebunApp());

class KebunApp extends StatefulWidget {
  const KebunApp({super.key});

  @override
  State<KebunApp> createState() => _KebunAppState();
}

class _KebunAppState extends State<KebunApp> {
  final state = AppState();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Kebun.io',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        navigatorKey: rootNavKey,
        home: const RootGate(),
      ),
    );
  }
}

final rootNavKey = GlobalKey<NavigatorState>();

/// Selected bottom-nav tab, shared so pushed pages can switch tabs too.
final tabIndex = ValueNotifier<int>(0);

void goToTab(BuildContext context, int i) {
  rootNavKey.currentState?.popUntil((r) => r.isFirst);
  tabIndex.value = i;
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: s.loggedIn ? const Shell() : const LoggedOutScreen());
  }
}

// ---------------------------------------------------------------------------
// Responsive shell
// ---------------------------------------------------------------------------

class NavItem {
  const NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

const navItems = [
  NavItem('Beranda', LucideIcons.house),
  NavItem('Kebun', LucideIcons.sprout),
  NavItem('Analitik', LucideIcons.chartColumn),
  NavItem('Panen', LucideIcons.shoppingBasket),
  NavItem('Profil', LucideIcons.user),
];

enum Layout { phone, tablet, desktop }

Layout layoutOf(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w >= 1100) return Layout.desktop;
  if (w >= 700) return Layout.tablet;
  return Layout.phone;
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  static const _pages = [HomeScreen(), FarmScreen(), AnalyticsScreen(), HarvestScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tabIndex,
      builder: (context, i, _) {
        final body = IndexedStack(index: i, children: [for (final p in _pages) p]);
        return ResponsiveFrame(selected: i, onSelect: (v) => tabIndex.value = v, child: body);
      },
    );
  }
}

/// Bottom nav on phones, rail on tablets, sidebar on desktop.
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child, required this.selected, required this.onSelect, this.showPhoneNav = true});
  final Widget child;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool showPhoneNav;

  @override
  Widget build(BuildContext context) {
    final l = layoutOf(context);
    if (l == Layout.phone) {
      return Scaffold(body: child, bottomNavigationBar: showPhoneNav ? BottomNav(selected: selected, onSelect: onSelect) : null);
    }
    return Scaffold(
      body: Row(children: [
        SideNav(selected: selected, onSelect: onSelect, extended: l == Layout.desktop),
        Expanded(child: child),
      ]),
    );
  }
}

/// Used by pushed pages (Detail Zona, Ternak, Notifikasi): no bottom nav on
/// phones (as in Figma), but keeps the side navigation on larger screens.
class DetailFrame extends StatelessWidget {
  const DetailFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: tabIndex,
        builder: (context, i, _) => ResponsiveFrame(selected: i, onSelect: (v) => goToTab(context, v), showPhoneNav: false, child: child),
      );
}

Route<T> pageRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => DetailFrame(child: page),
      transitionsBuilder: (_, a, __, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(c), child: child),
        );
      },
    );

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(color: KColors.surface, border: Border(top: BorderSide(color: KColors.border))),
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottom > 0 ? bottom : 16),
      child: Row(children: [
        for (var i = 0; i < navItems.length; i++)
          Expanded(
            child: Tap(
              onTap: () => onSelect(i),
              radius: 14,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(navItems[i].icon, size: 24, color: i == selected ? KColors.primary : KColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(
                    navItems[i].label,
                    style: KText.small.copyWith(
                      color: i == selected ? KColors.primary : KColors.textSecondary,
                      fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class SideNav extends StatelessWidget {
  const SideNav({super.key, required this.selected, required this.onSelect, required this.extended});
  final int selected;
  final ValueChanged<int> onSelect;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Container(
      width: extended ? 248 : 92,
      decoration: const BoxDecoration(color: KColors.surface, border: Border(right: BorderSide(color: KColors.border))),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 10, vertical: 20),
          child: Column(crossAxisAlignment: extended ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: KColors.primary, borderRadius: BorderRadius.circular(KRadius.sm)),
                child: const Icon(LucideIcons.sprout, color: Colors.white, size: 22),
              ),
              if (extended) ...[
                const SizedBox(width: 10),
                Text('Kebun.io', style: KText.h18),
              ],
            ]),
            const SizedBox(height: 28),
            for (var i = 0; i < navItems.length; i++) ...[
              _SideItem(item: navItems[i], active: i == selected, extended: extended, onTap: () => onSelect(i)),
              const SizedBox(height: 6),
            ],
            const Spacer(),
            if (extended)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: KColors.primarySoft, borderRadius: BorderRadius.circular(KRadius.md)),
                child: Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: KColors.primary, child: Text(s.userName.characters.first, style: KText.title.copyWith(color: Colors.white))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.userName, style: KText.bodySemi, overflow: TextOverflow.ellipsis),
                      Text(s.farm.name, style: KText.small.copyWith(color: KColors.primaryDark), overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({required this.item, required this.active, required this.extended, required this.onTap});
  final NavItem item;
  final bool active;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? KColors.primary : KColors.textSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(color: active ? KColors.primarySoft : Colors.transparent, borderRadius: BorderRadius.circular(KRadius.md)),
      child: Tap(
        onTap: onTap,
        radius: KRadius.md,
        tooltip: extended ? null : item.label,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: extended ? 14 : 10, vertical: extended ? 12 : 10),
          child: extended
              ? Row(children: [
                  Icon(item.icon, size: 22, color: color),
                  const SizedBox(width: 12),
                  Text(item.label, style: KText.bodySemi.copyWith(color: active ? KColors.primaryDark : KColors.textSecondary)),
                ])
              : Column(children: [
                  Icon(item.icon, size: 24, color: color),
                  const SizedBox(height: 4),
                  Text(item.label, style: KText.small.copyWith(color: color)),
                ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logged-out placeholder (after "Keluar")
// ---------------------------------------------------------------------------

class LoggedOutScreen extends StatelessWidget {
  const LoggedOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: KColors.primary, borderRadius: BorderRadius.circular(KRadius.lg)),
                  child: const Icon(LucideIcons.sprout, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 20),
              Text('Kamu sudah keluar', style: KText.h22, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Masuk lagi untuk memantau kebun dan ternakmu.', style: KText.caption.copyWith(fontSize: 14, height: 20 / 14), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              KButton(
                label: 'Masuk kembali',
                icon: LucideIcons.logIn,
                onTap: () {
                  tabIndex.value = 0;
                  AppScope.read(context).login();
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
