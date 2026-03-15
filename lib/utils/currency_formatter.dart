extension CurrencyFormatter on num {
  /// Format angka jadi format rupiah dengan titik sebagai pemisah ribuan
  /// Contoh: 10000 → "10.000", 1500000 → "1.500.000"
  String toRupiah() {
    return toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}