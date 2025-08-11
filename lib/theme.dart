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
            )
          ),
        ),
        appBarTheme: AppBarTheme(
          foregroundColor: Colors.white,
          backgroundColor: colorScheme.primary,
        ),

        dialogTheme: DialogThemeData(
          backgroundColor: colorScheme.surfaceBright,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(9))
          )
        ),
        chipTheme: ChipThemeData(
          color: WidgetStateColor.resolveWith( (Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.outline;
            } else if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return colorScheme.surfaceDim;
          }),
          showCheckmark: true,
          checkmarkColor: Colors.white,
        ),
);