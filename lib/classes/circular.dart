import 'package:flutter/material.dart';

class CustomCircularMenuItem extends StatelessWidget {
  /// if icon and animatedIcon are passed, icon will be ignored
  final IconData? icon;
  final Color? color;
  final Color? iconColor;
  final VoidCallback onTap;
  final double iconSize;
  final double padding;
  final double margin;
  final List<BoxShadow>? boxShadow;
  final bool enableBadge;
  final double? badgeRightOffet;
  final double? badgeLeftOffet;
  final double? badgeTopOffet;
  final double? badgeBottomOffet;
  final double? badgeRadius;
  final TextStyle? badgeTextStyle;
  final String? badgeLabel;
  final Color? badgeTextColor;
  final Color? badgeColor;
  final String? label;
  final TextStyle? labelStyle;

  /// if animatedIcon and icon are passed, icon will be ignored
  final AnimatedIcon? animatedIcon;

  /// creates a menu item .
  /// [onTap] must not be null.
  /// [padding] and [margin]  must be equal or greater than zero.
  CustomCircularMenuItem({
    required this.onTap,
    this.icon,
    this.color,
    this.iconSize = 30,
    this.boxShadow,
    this.iconColor,
    this.animatedIcon,
    this.padding = 10,
    this.margin = 10,
    this.enableBadge = false,
    this.badgeBottomOffet,
    this.badgeLeftOffet,
    this.badgeRightOffet,
    this.badgeTopOffet,
    this.badgeRadius,
    this.badgeTextStyle,
    this.badgeLabel,
    this.badgeTextColor,
    this.badgeColor,
    this.label,
    this.labelStyle,
  })  : assert(padding >= 0.0),
        assert(margin >= 0.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: color ?? Theme.of(context).primaryColor,
                blurRadius: 10,
              ),
            ],
        shape: BoxShape.circle,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              animatedIcon ??
                  Icon(
                    icon,
                    size: iconSize,
                    color: iconColor ?? Colors.white,
                  ),
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label!,
                    style: labelStyle ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}