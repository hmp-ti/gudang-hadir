class AppValidators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kolom ini wajib diisi';
    }
    return null;
  }

  static String? number(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Let required validator handle empty
    }
    if (int.tryParse(value) == null) {
      return 'Harus berupa angka';
    }
    return null;
  }
}
