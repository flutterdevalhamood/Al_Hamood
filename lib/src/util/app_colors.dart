import 'package:flutter/material.dart';
import 'package:sample/src/theme/light_theme.dart';

abstract class Appcolors {
  static Color bottomSheetBgColor(BuildContext context) =>
      ThemedColor(light: LightTheme.textWhiteColor).getColor(context);
  static Color appBarBgColor(BuildContext context) =>
      ThemedColor(light: LightTheme.lightBlueColor).getColor(context);

  static Color textWhiteColor(BuildContext context) =>
      ThemedColor(light: LightTheme.textWhiteColor).getColor(context);
  static Color textColor(BuildContext context) =>
      ThemedColor(light: LightTheme.textBlackColor).getColor(context);

  static Color textLightGrayColor(BuildContext context) =>
      ThemedColor(light: LightTheme.textLightGrayColor).getColor(context);

  static Color primaryBlue(BuildContext context) =>
      ThemedColor(light: LightTheme.primaryBlueColor).getColor(context);

  static Color secondaryBlue(BuildContext context) =>
      ThemedColor(light: LightTheme.secondaryBlueColor).getColor(context);

  static Color borderColor(BuildContext context) =>
      ThemedColor(light: LightTheme.dividerColor).getColor(context);

  static Color borderLightGreyColor(BuildContext context) =>
      ThemedColor(light: LightTheme.borderLightGreyColor).getColor(context);

  static Color get textDarkBlueColor => const Color(0xFF081B63);

  static Color blackColor = const Color(0xFF212121);

  static Color get btnTextColor => const Color(0xFFFFFFFF);

  static Gradient btnGradient = LinearGradient(
    colors: [LightTheme.primaryBlueColor, LightTheme.secondaryBlueColor],
  );

  static Gradient SignInbtnGradient = LinearGradient(
    colors: [Colors.black45, Colors.black12],
  );

  static Gradient btnDisableGradient = LinearGradient(
    colors: [LightTheme.secondaryBlueColor, LightTheme.secondaryBlueColor],
  );

  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF818CF8);
  static const Color accentColor = Color(0xFF4F46E5);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryColor, secondaryColor],
  );

  static const primary = Color(0xFF1A1A2E);
  static const text = Color(0XFF2F384D);
  static const background = Color(0xFFEEF0F4);
  static const disabled = Color(0xFF7995B7);
  static const unselectedIcon = Color(0xffA0A7BA);
  static const transparent = Colors.transparent;

  static const Color darkBlue = Color(0xFF1A1A2E);
}

class ThemedColor {
  final Color light;

  const ThemedColor({required this.light});
  Color getColor(BuildContext context) {
    return light;
  }
}
