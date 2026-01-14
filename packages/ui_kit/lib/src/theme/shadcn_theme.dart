import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ShadcnAppTheme {
  static ShadThemeData get lightTheme {
    return ShadThemeData(
      brightness: Brightness.light,
      colorScheme: const ShadZincColorScheme.light(),
      textTheme: ShadTextTheme(family: 'SF Pro Display'),
    );
  }

  static ShadThemeData get darkTheme {
    return ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: const ShadZincColorScheme.dark(),
      textTheme: ShadTextTheme(family: 'SF Pro Display'),
    );
  }
}
