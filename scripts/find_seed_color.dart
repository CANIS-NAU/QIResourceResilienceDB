import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

Color seedColor = Colors.red;

double perceptualDifference(Hct a, Hct b) {
  final hueDiff = (a.hue - b.hue).abs();
  final chromaDiff = (a.chroma - b.chroma).abs();
  final toneDiff = (a.tone - b.tone).abs();

  return hueDiff + chromaDiff + toneDiff; 
}

void findSeedForPrimary(Color targetColor) {
  final targetHct = Hct.fromInt(targetColor.toARGB32());
  final tolerance = 10;

  for (double chroma = 40; chroma <= 80; chroma += 1) {
    for (double tone = 60; tone <= 100; tone += 1) {
      final seedHct = Hct.from(targetHct.hue, chroma, tone);
      final seedColor = Color(seedHct.toInt());

      final palette = CorePalette.of(seedColor.toARGB32());
      final generatedPrimary = Color(palette.primary.get(40));
      final generatedHct = Hct.fromInt(generatedPrimary.toARGB32());

      final diff = perceptualDifference(targetHct, generatedHct);
      if (diff < tolerance) {
        final hexSeed = seedColor.toARGB32().toRadixString(16).padLeft(8, '0');
        final hexPrimary = generatedPrimary.toARGB32().toRadixString(16).padLeft(8, '0');
        final hexTarget = targetColor.toARGB32().toRadixString(16).padLeft(8, '0');

        print("Match Found!\n"
        "\tTarget Color:    0x$hexTarget\n"
        "\tGenerated Color: 0x$hexPrimary\n"
        "\tSeed Color:      0x$hexSeed\n"
        "\tHue: ${targetHct.hue.toStringAsFixed(2)}, Chroma: $chroma, Tone: $tone");
        return;
      } else {
        print("Not within tolerance: $diff");
      }
    }
  }
}



void main() {
  findSeedForPrimary(seedColor);
}