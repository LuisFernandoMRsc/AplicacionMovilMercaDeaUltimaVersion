class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  static String? decimal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return 'Ingresa un número válido';
    }
    if (parsed < 0) {
      return 'El valor no puede ser negativo';
    }
    return null;
  }

  static String? optionalDecimal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return 'Ingresa un número válido';
    }
    if (parsed < 0) {
      return 'El valor no puede ser negativo';
    }
    return null;
  }

  static String? optionalPositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return 'Ingresa un número entero';
    }
    if (parsed <= 0) {
      return 'Debe ser mayor a 0';
    }
    return null;
  }
}
