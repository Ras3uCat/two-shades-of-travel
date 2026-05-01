String slugify(String text) {
  final sb = StringBuffer();
  bool prevDash = false;
  for (final ch in text.toLowerCase().split('')) {
    final c = ch.codeUnitAt(0);
    final isAlNum = (c >= 97 && c <= 122) || (c >= 48 && c <= 57);
    final isDash = ch == '-' || ch == ' ';
    if (isAlNum) {
      sb.write(ch);
      prevDash = false;
    } else if (isDash && !prevDash && sb.isNotEmpty) {
      sb.write('-');
      prevDash = true;
    }
  }
  return sb.toString().trimRight();
}
