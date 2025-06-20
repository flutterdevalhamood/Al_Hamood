import 'package:flutter/material.dart';

class ImageConstants {
  static const String assetsDir = "lib/src/assets";
  static String background(BuildContext context) =>
      const ThemedImages(light: "$assetsDir/bg_light.png").getImage(context);

  static String sample(BuildContext context) =>
      const ThemedImages(light: "$assetsDir/sample.svg").getImage(context);
}

class ThemedImages {
  final String light;

  const ThemedImages({required this.light});

  String getImage(BuildContext context) {
    return light;
  }
}
