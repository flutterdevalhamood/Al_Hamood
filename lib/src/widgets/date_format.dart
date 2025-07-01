String formatDate(String dateString) {
  try {
    if (dateString == 'N/A' || dateString.isEmpty) return 'N/A';

    // Handle special dates like "9999-09-09"
    if (dateString.startsWith('9999')) return 'No Expiry';

    final date = DateTime.parse(dateString);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  } catch (e) {
    return dateString;
  }
}
