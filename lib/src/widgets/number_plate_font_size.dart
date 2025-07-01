double calculateOptimalFontSize({
  required String text,
  required double maxWidth,
  required double maxFontSize,
  required double minFontSize,
  required double letterSpacing,
}) {
  // Estimate text width factor (approximate)
  double textWidthFactor = text.length * 0.6; // Rough estimate
  double availableWidthFactor = maxWidth / textWidthFactor;

  // Calculate font size based on available space
  double calculatedSize = maxFontSize * availableWidthFactor;

  // Apply constraints
  if (calculatedSize > maxFontSize) {
    return maxFontSize;
  } else if (calculatedSize < minFontSize) {
    return minFontSize;
  } else {
    return calculatedSize;
  }
}
