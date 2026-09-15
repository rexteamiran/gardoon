/// ویجت‌های مشترک گردون — دکمه گویی، کارت، تراشه
///
/// نسخه ۱: افکت گویی با گرادیان/سایه ارگانیک (مسیر سازگار — design.md بخش ۴)
/// متن هرگز گویی نمی‌شود — لایه جدا و شارپ.
library;

import 'package:flutter/material.dart';

import '../extensions/fa_numbers.dart';
import '../theme/app_colors.dart';

/// دکمه گویی بزرگ — حس مایع و ارگانیک با گرادیان و موج لبه
class GooeyButton extends StatelessWidget {
  const GooeyButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 72,
    this.color,
    this.textColor,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bg = color ?? colors.primary;
    final fg = textColor ?? (colors.brightness == Brightness.dark ? DarkPalette.bg : Colors.white);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(36),
          ),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [bg.withValues(alpha: 0.92), bg],
          ),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(36),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(36),
            ),
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: fg, size: 26),
                    const SizedBox(width: 10),
                  ],
                  Text(label,
                      style: TextStyle(
                          color: fg,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// کارت سطح با گوشه‌های نرم ارگانیک
class GooeyCard extends StatelessWidget {
  const GooeyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? colors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// تراشه بازیکن — ردیف میزگرد
class PlayerChip extends StatelessWidget {
  const PlayerChip({
    super.key,
    required this.name,
    required this.alive,
    this.selected = false,
    this.disabled = false,
    this.onTap,
    this.badge,
  });

  final String name;
  final bool alive;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bgColor = !alive
        ? colors.subtext.withValues(alpha: 0.15)
        : selected
            ? colors.primary
            : colors.surface;
    final fgColor = !alive
        ? colors.subtext
        : selected
            ? (colors.brightness == Brightness.dark ? DarkPalette.bg : Colors.white)
            : colors.text;

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.primary : colors.subtext.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration: alive ? null : TextDecoration.lineThrough),
              ),
              if (badge case final b?) ...[
                const SizedBox(height: 2),
                Text(b,
                    style: TextStyle(color: fgColor.withValues(alpha: 0.8), fontSize: 11)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// سربرگ گویی فاز — رنگ و آیکون فاز
class PhaseHeader extends StatelessWidget {
  const PhaseHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    this.trailing,
  });

  final String icon;
  final String title;
  final String subtitle;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final c = color ?? colors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c.withValues(alpha: 0.14),
            colors.surface,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
          topRight: Radius.circular(24),
          topLeft: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(color: c.withValues(alpha: 0.7), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: colors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: colors.subtext, fontSize: 13)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// شمارنده ثانیه شمار بزرگ — حلقه‌ای با پیشرفت رنگی
class BigTimer extends StatelessWidget {
  const BigTimer({super.key, required this.remaining, required this.total});

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final progress = total > 0 ? remaining / total : 0.0;
    // رنگ از سبز به طلایی به قرمز با نزدیک شدن به صفر
    final Color ringColor;
    if (progress > 0.5) {
      ringColor = BrandColors.city;
    } else if (progress > 0.2) {
      ringColor = colors.primary;
    } else {
      ringColor = BrandColors.mafia;
    }
    return Column(
      children: [
        SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.surface3,
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remaining.fa,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: ringColor,
                      fontFeatures: const [],
                    ),
                  ),
                  Text(
                    'ثانیه',
                    style: TextStyle(color: colors.subtext, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
