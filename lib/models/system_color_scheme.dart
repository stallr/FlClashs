import 'package:fl_clash/common/constant.dart';
import 'package:flutter/material.dart';

@immutable
class SystemColorSchemes {
  final ColorScheme? lightColorScheme;
  final ColorScheme? darkColorScheme;

  const SystemColorSchemes({
    this.lightColorScheme,
    this.darkColorScheme,
  });

  getSystemColorSchemeForBrightness(Brightness? brightness) {
    if (brightness == Brightness.dark) {
      return darkColorScheme != null
          ? ColorScheme.fromSeed(
              seedColor: darkColorScheme!.primary,
              brightness: Brightness.dark,
            )
          : ColorScheme.fromSeed(
              seedColor: defaultPrimaryColor,
              brightness: Brightness.dark,
            );
    }
    return lightColorScheme != null
        ? ColorScheme.fromSeed(seedColor: darkColorScheme!.primary)
        : ColorScheme.fromSeed(seedColor: defaultPrimaryColor);
  }
}
