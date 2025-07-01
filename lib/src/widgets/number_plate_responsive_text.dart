import 'package:flutter/material.dart';
import 'package:sample/src/widgets/number_plate_font_size.dart';

Widget buildResponsiveText({
  required String text,
  required Color textColor,
  required double maxFontSize,
  required double minFontSize,
  required FontWeight fontWeight,
  required double letterSpacing,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Calculate appropriate font size based on text length and available width
      double fontSize = calculateOptimalFontSize(
        text: text,
        maxWidth: constraints.maxWidth,
        maxFontSize: maxFontSize,
        minFontSize: minFontSize,
        letterSpacing: letterSpacing,
      );

      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    },
  );
}
