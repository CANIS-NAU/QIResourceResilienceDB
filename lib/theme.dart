import 'package:flutter/material.dart';

Color seedColor = Color(0xFF4890F7);

ColorScheme colorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
);

ThemeData theme = ThemeData(
  colorScheme: colorScheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: colorScheme.onPrimary,
      backgroundColor: colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(5),
      ),
    ),
  ),
  appBarTheme: AppBarTheme(
    foregroundColor: Colors.white,
    backgroundColor: colorScheme.primary,
  ),

  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadiusGeometry.all(Radius.circular(5)),
    ),
  ),
  chipTheme: ChipThemeData.fromDefaults(
    brightness: Brightness.light,
    secondaryColor: colorScheme.primary,
    labelStyle: TextStyle(),
  ),
);
