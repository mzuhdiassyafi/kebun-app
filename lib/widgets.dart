import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// Primitives
// ---------------------------------------------------------------------------

/// A tappable surface with ripple, hover cursor and a light press scale.
class Tap extends StatefulWidget {
  const Tap({super.key, required this.child, this.onTap, this.radius = KRadius.md, this.tooltip, this.onLongPress});
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;
  final String? tooltip;

  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    Widget w = AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 110),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          onTap: widget.onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onTap!();
                },
          onLongPress: widget.onLongPress,
          onHighlightChanged: (v) => setState(() => _down = v),
          hoverColor: KColors.text.withValues(alpha: 0.03),
          splashColor: KColors.primary.withValues(alpha: 0.08),
          highlightColor: KColors.primary.withValues(alpha: 0.04),
          child: widget.child,
        ),
      ),
    );
    if (widget.tooltip != null) w = Tooltip(message: widget.tooltip!, child: w);
    return w;
  }
}

BoxDecoration cardDecoration({Color color = KColors.surface, double radius = KRadius.lg, Color? border = KColors.border, double borderWidth = 1}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border == null ? null : Border.all(color: border, width: borderWidth),
    );

/// White rounded card with the design's 1px border.
class KCard extends StatelessWidget {
  const KCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = KRadius.lg, this.color = KColors.surface, this.border = KColors.border, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final Color? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inner = Padding(padding: padding, child: child);
    return Container(
      decoration: cardDecoration(color: color, radius: radius, border: border),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? inner : Tap(onTap: onTap, radius: radius, child: inner),
    );
  }
}

class IconChip extends StatelessWidget {
  const IconChip({super.key, required this.icon, required this.tint, required this.soft, this.size = 40, this.iconSize = 20, this.radius = KRadius.sm});
  final IconData icon;
  final Color tint;
  final Color soft;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(radius)),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: tint),
      );
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.color = KColors.textSecondary, this.bg = KColors.subtle, this.icon, this.padding = const EdgeInsets.fromLTRB(8, 4, 10, 4)});
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: icon == null ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4) : padding,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(KRadius.full)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(label, style: KText.small.copyWith(color: color)),
        ]),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.warning, this.normalLabel = 'Normal', this.warnLabel = 'Perhatian', this.compact = false});
  final bool warning;
  final String normalLabel;
  final String warnLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
        decoration: BoxDecoration(color: warning ? KColors.warningSoft : KColors.successSoft, borderRadius: BorderRadius.circular(KRadius.full)),
        child: Text(warning ? warnLabel : normalLabel, style: KText.small.copyWith(color: warning ? KColors.warning : KColors.success)),
      );
}

/// Round 44px icon button (white with border, or filled).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, required this.onTap, this.filled = false, this.tooltip, this.badge = false, this.size = 44, this.iconSize = 20});
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final String? tooltip;
  final bool badge;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? KColors.primary : KColors.surface,
          shape: BoxShape.circle,
          border: filled || badge ? null : Border.all(color: KColors.border),
        ),
        child: Tap(
          onTap: onTap,
          radius: size,
          tooltip: tooltip,
          child: Center(child: Icon(icon, size: iconSize, color: filled ? Colors.white : KColors.text)),
        ),
      ),
      if (badge)
        Positioned(
          right: 9,
          top: 9,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: KColors.danger, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
          ),
        ),
    ]);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 24,
        child: Row(children: [
          Expanded(child: Text(title, style: KText.h18, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (action != null)
            Tap(
              onTap: onAction,
              radius: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Text(action!, style: KText.captionSemi.copyWith(color: onAction == null ? KColors.textSecondary : KColors.primary)),
              ),
            ),
        ]),
      );
}

/// Filter chip (State = Active / Default).
class KChip extends StatelessWidget {
  const KChip({super.key, required this.label, required this.active, required this.onTap, this.icon});
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : KColors.text;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active ? KColors.text : KColors.surface,
        borderRadius: BorderRadius.circular(KRadius.full),
        border: Border.all(color: active ? KColors.text : KColors.border),
      ),
      child: Tap(
        onTap: onTap,
        radius: KRadius.full,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
            Text(label, style: KText.captionSemi.copyWith(color: fg)),
          ]),
        ),
      ),
    );
  }
}

class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children, this.padding = const EdgeInsets.symmetric(horizontal: 16)});
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 8), children[i]],
        ]),
      );
}

enum KButtonStyle { primary, secondary, danger, ghost }

class KButton extends StatelessWidget {
  const KButton({super.key, required this.label, required this.onTap, this.icon, this.style = KButtonStyle.primary, this.loading = false, this.height = 54, this.compact = false});
  final bool compact;
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final KButtonStyle style;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (style) {
      KButtonStyle.primary => (KColors.primary, Colors.white),
      KButtonStyle.secondary => (KColors.primarySoft, KColors.primary),
      KButtonStyle.danger => (KColors.danger, Colors.white),
      KButtonStyle.ghost => (KColors.surface, KColors.text),
    };
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: onTap == null ? 0.5 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(compact ? KRadius.sm : KRadius.md)),
        child: Tap(
          onTap: loading ? null : onTap,
          radius: compact ? KRadius.sm : KRadius.md,
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (loading)
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg))
              else if (icon != null)
                Icon(icon, size: 20, color: fg),
              if (loading || icon != null) const SizedBox(width: 8),
              Flexible(child: Text(label, style: (compact ? (style == KButtonStyle.ghost ? KText.bodyMedium : KText.bodySemi) : KText.title).copyWith(color: fg), overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// iOS-style toggle from the Settings Row component (44 x 26).
class KToggle extends StatelessWidget {
  const KToggle({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: value,
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: value ? KColors.primary : const Color(0xFFD5CFC2), borderRadius: BorderRadius.circular(13)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ),
            ),
          ),
        ),
      );
}

class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.items, required this.index, required this.onChanged});
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: KColors.subtle, borderRadius: BorderRadius.circular(KRadius.full)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(color: i == index ? KColors.surface : Colors.transparent, borderRadius: BorderRadius.circular(KRadius.full)),
              child: Tap(
                onTap: () => onChanged(i),
                radius: KRadius.full,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(items[i], style: KText.small.copyWith(color: i == index ? KColors.text : KColors.textSecondary)),
                ),
              ),
            ),
          ],
        ]),
      );
}

/// List card with rows separated by hairlines (Activity, History, Reports).
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: cardDecoration(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Column(children: [
          for (var i = 0; i < children.length; i++)
            Container(
              decoration: BoxDecoration(border: i < children.length - 1 ? const Border(bottom: BorderSide(color: KColors.border)) : null),
              child: children[i],
            ),
        ]),
      );
}

class ListRow extends StatelessWidget {
  const ListRow({super.key, required this.leading, required this.title, required this.subtitle, this.trailing, this.onTap});
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        radius: 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: KText.bodySemi, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: KText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ]),
        ),
      );
}

// ---------------------------------------------------------------------------
// Composite components (match Figma components)
// ---------------------------------------------------------------------------

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.icon, required this.tint, required this.soft, required this.value, required this.label, required this.onTap});
  final IconData icon;
  final Color tint;
  final Color soft;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => KCard(
        onTap: onTap,
        child: SizedBox(
          height: 98,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconChip(icon: icon, tint: tint, soft: soft),
              const Spacer(),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: KColors.subtle, shape: BoxShape.circle),
                child: const Icon(LucideIcons.chevronRight, size: 14, color: KColors.text),
              ),
            ]),
            const Spacer(),
            Text(value, style: KText.h22, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: KText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}

(IconData, Color, Color) severityStyle(Severity s) => switch (s) {
      Severity.kritis => (LucideIcons.octagonAlert, KColors.danger, KColors.dangerSoft),
      Severity.peringatan => (LucideIcons.triangleAlert, KColors.warning, KColors.warningSoft),
      Severity.info => (LucideIcons.check, KColors.success, KColors.successSoft),
    };

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, required this.onTap, this.timeSuffix = ''});
  final AlertItem alert;
  final VoidCallback onTap;
  final String timeSuffix;

  @override
  Widget build(BuildContext context) {
    final (icon, tint, soft) = severityStyle(alert.severity);
    return KCard(
      radius: KRadius.md,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconChip(icon: icon, tint: tint, soft: soft, radius: KRadius.full),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(alert.title, style: KText.bodySemi, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Padding(padding: const EdgeInsets.only(top: 1), child: Text('${alert.time}$timeSuffix', style: KText.small)),
            ]),
            const SizedBox(height: 2),
            Text(alert.description, style: KText.caption),
          ]),
        ),
        if (!alert.read) ...[
          const SizedBox(width: 6),
          Container(margin: const EdgeInsets.only(top: 22), width: 8, height: 8, decoration: const BoxDecoration(color: KColors.primary, shape: BoxShape.circle)),
        ],
      ]),
    );
  }
}

class ZoneRow extends StatelessWidget {
  const ZoneRow({super.key, required this.zone, required this.onTap, this.selected = false});
  final Zone zone;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: cardDecoration(radius: KRadius.md, border: selected ? KColors.primary : KColors.border, borderWidth: selected ? 1.5 : 1),
        child: Tap(
          onTap: onTap,
          radius: KRadius.md,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(children: [
              IconChip(icon: zone.icon, tint: zone.iconTint, soft: zone.iconSoft, size: 44, iconSize: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(zone.name, style: KText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(zone.summary, style: KText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const SizedBox(width: 12),
              StatusBadge(warning: zone.warning),
              const SizedBox(width: 12),
              const Icon(LucideIcons.chevronRight, size: 20, color: KColors.textSecondary),
            ]),
          ),
        ),
      );
}

class SensorTile extends StatelessWidget {
  const SensorTile({super.key, required this.icon, required this.tint, required this.soft, required this.value, required this.label, required this.warning, required this.onTap});
  final IconData icon;
  final Color tint;
  final Color soft;
  final String value;
  final String label;
  final bool warning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => KCard(
        radius: KRadius.md,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconChip(icon: icon, tint: tint, soft: soft, size: 32, iconSize: 16, radius: KRadius.full),
            const Spacer(),
            StatusBadge(warning: warning, compact: true),
          ]),
          const SizedBox(height: 10),
          Text(value, style: KText.h18),
          const SizedBox(height: 10),
          Text(label, style: KText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      );
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.count, required this.selected, required this.onTap});
  final AnimalCategory category;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: cardDecoration(border: selected ? KColors.primary : KColors.border, borderWidth: selected ? 2 : 1),
        child: Tap(
          onTap: onTap,
          radius: KRadius.lg,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
            child: Column(children: [
              Image.asset(category.image, width: 52, height: 52, filterQuality: FilterQuality.medium),
              const SizedBox(height: 2),
              Text('$count', style: KText.h18.copyWith(color: selected ? KColors.primaryDark : KColors.text)),
              const SizedBox(height: 2),
              Text(category.label, style: KText.caption),
            ]),
          ),
        ),
      );
}

String animalImage(String category) => animalCategories.firstWhere((c) => c.label == category, orElse: () => animalCategories.first).image;

class AnimalRow extends StatelessWidget {
  const AnimalRow({super.key, required this.animal, required this.onTap});
  final Animal animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final low = animal.health < 85;
    return KCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: KColors.waterSoft, borderRadius: BorderRadius.circular(KRadius.md)),
          padding: const EdgeInsets.all(6),
          child: Image.asset(animalImage(animal.category), filterQuality: FilterQuality.medium),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(animal.name, style: KText.title),
            Text(animal.breed, style: KText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 4, children: [
              Pill(label: animal.tag, color: KColors.soil, bg: KColors.soilSoft),
              Pill(label: animal.age, color: KColors.soil, bg: KColors.soilSoft),
            ]),
          ]),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Pill(
            icon: LucideIcons.heart,
            label: '${animal.health}%',
            color: low ? KColors.warning : KColors.success,
            bg: low ? KColors.warningSoft : KColors.successSoft,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          ),
          const SizedBox(height: 10),
          const Icon(LucideIcons.chevronRight, size: 20, color: KColors.textSecondary),
        ]),
      ]),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.icon, required this.tint, required this.soft, required this.label, this.value = '', this.toggle, this.onToggle, this.onTap, this.divider = true});
  final IconData icon;
  final Color tint;
  final Color soft;
  final String label;
  final String value;
  final bool? toggle;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) => Column(children: [
        Tap(
          onTap: toggle != null ? () => onToggle?.call(!toggle!) : onTap,
          radius: 12,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              IconChip(icon: icon, tint: tint, soft: soft, size: 36, iconSize: 18),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: KText.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (value.isNotEmpty) ...[const SizedBox(width: 8), Text(value, style: KText.caption)],
              if (toggle != null) ...[const SizedBox(width: 12), KToggle(value: toggle!, onChanged: (v) => onToggle?.call(v))] else ...[
                const SizedBox(width: 12),
                const Icon(LucideIcons.chevronRight, size: 20, color: KColors.textSecondary),
              ],
            ]),
          ),
        ),
        if (divider) const Padding(padding: EdgeInsets.only(left: 48), child: Divider(height: 1, thickness: 1, color: KColors.border)),
      ]);
}

// ---------------------------------------------------------------------------
// Page chrome
// ---------------------------------------------------------------------------

/// Big title bar used on tab roots (Kebun, Panen, Analitik, Profil).
class TitleBar extends StatelessWidget {
  const TitleBar({super.key, required this.title, this.subtitle, this.subtitleIcon, this.trailing});
  final String title;
  final String? subtitle;
  final IconData? subtitleIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: KText.display),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  if (subtitleIcon != null) ...[Icon(subtitleIcon, size: 14, color: KColors.textSecondary), const SizedBox(width: 4)],
                  Flexible(child: Text(subtitle!, style: KText.caption, overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ]),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ]),
      );
}

/// Centered top bar with back button used on pushed pages.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(children: [
          CircleIconButton(icon: LucideIcons.chevronLeft, tooltip: 'Kembali', onTap: () => Navigator.of(context).maybePop()),
          Expanded(
            child: Column(children: [
              Text(title, style: KText.h18, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null) Text(subtitle!, style: KText.caption, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          trailing ?? const SizedBox(width: 44),
        ]),
      );
}

/// Centers page content and caps its width on large screens.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 1120, this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 32), this.gap = 20});
  final List<Widget> children;
  final double maxWidth;
  final EdgeInsets padding;
  final double gap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
        ]),
      );
}

class Centered extends StatelessWidget {
  const Centered({super.key, required this.child, this.maxWidth = 1120});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Simple responsive grid that keeps equal-width cells with a fixed gap.
class Grid extends StatelessWidget {
  const Grid({super.key, required this.children, required this.columns, this.gap = 16, this.runGap});
  final List<Widget> children;
  final int columns;
  final double gap;
  final double? runGap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = <Widget>[];
      for (var j = 0; j < columns; j++) {
        if (j > 0) cells.add(SizedBox(width: gap));
        final idx = i + j;
        cells.add(Expanded(child: idx < children.length ? children[idx] : const SizedBox()));
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: runGap ?? gap));
      rows.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)));
    }
    return Column(children: rows);
  }
}

// ---------------------------------------------------------------------------
// Feedback helpers
// ---------------------------------------------------------------------------

void toast(BuildContext context, String msg, {String? action, VoidCallback? onAction, IconData icon = LucideIcons.circleCheck}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Row(children: [Icon(icon, size: 18, color: const Color(0xFF9FE0B5)), const SizedBox(width: 10), Expanded(child: Text(msg))]),
    action: action == null ? null : SnackBarAction(label: action, onPressed: onAction ?? () {}),
    width: MediaQuery.sizeOf(context).width > 600 ? 420 : null,
    duration: const Duration(seconds: 3),
  ));
}

Future<T?> showSheet<T>(BuildContext context, {required String title, required Widget Function(BuildContext) builder, String? subtitle}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: KText.h18),
          if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: KText.caption)],
          const SizedBox(height: 16),
          builder(ctx),
        ]),
      ),
    ),
  );
}

Future<bool> confirm(BuildContext context, {required String title, required String message, String ok = 'Ya', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(children: [
          Expanded(child: KButton(label: 'Batal', height: 46, style: KButtonStyle.ghost, onTap: () => Navigator.pop(ctx, false))),
          const SizedBox(width: 10),
          Expanded(child: KButton(label: ok, height: 46, style: danger ? KButtonStyle.danger : KButtonStyle.primary, onTap: () => Navigator.pop(ctx, true))),
        ]),
      ],
    ),
  );
  return r ?? false;
}

/// Option list used inside sheets (single choice).
class OptionList extends StatelessWidget {
  const OptionList({super.key, required this.options, required this.selected, required this.onSelect});
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        decoration: cardDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          for (var i = 0; i < options.length; i++)
            Container(
              decoration: BoxDecoration(border: i < options.length - 1 ? const Border(bottom: BorderSide(color: KColors.border)) : null),
              child: Tap(
                onTap: () => onSelect(options[i]),
                radius: 10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    Expanded(child: Text(options[i], style: KText.bodyMedium)),
                    if (options[i] == selected) const Icon(LucideIcons.check, size: 18, color: KColors.primary),
                  ]),
                ),
              ),
            ),
        ]),
      );
}
