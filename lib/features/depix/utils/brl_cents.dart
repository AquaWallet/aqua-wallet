extension BrlCentsExtension on int {
  double get asBrl => this / 100.0;
  String get formattedBrl => asBrl.toStringAsFixed(2);
}
