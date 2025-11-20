class PXAppValidators {
  PXAppValidators._(); // 👈 constructor privado para que no se instancie

  /// required field
  /// Validates that the field is not empty.
  static String? requiredField(String? value) {
    if (value == null || value.isEmpty) {
      return "Este campo es obligatorio";
    }
    return null;
  }

  /// validate name not empty and more than 1 caracter
  /// Validates that the name is not empty and has more than 1 character.
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return "El nombre es obligatorio";
    }
    if (value.length < 2) {
      return "El nombre debe tener más de 1 carácter";
    }
    return null;
  }

  /// Valida un concepto no vacío y con más de 2 caracteres.
  static String? concept(String? value) {
    if (value == null || value.isEmpty) {
      return "El concepto es obligatorio";
    }
    if (value.length < 3) {
      return "El concepto debe tener más de 2 caracteres";
    }
    return null;
  }

  /// Valida un número de teléfono de exactamente 10 dígitos (ej. México).
  static String? phone(String? value, {int length = 10}) {
    if (value == null || value.isEmpty) {
      return "El teléfono es obligatorio";
    }
    final regex = RegExp(r'^[0-9]+$');
    if (!regex.hasMatch(value)) {
      return "Solo se permiten números";
    }
    if (value.length != length) {
      return "Debe tener $length dígitos";
    }
    return null;
  }

  /// valida que cambos telefonos sean iguales
  static String? confirmPhone(String? value, String? phone) {
    if (value == null || value.isEmpty) {
      return "El teléfono es obligatorio";
    }
    if (value != phone) {
      return "Los teléfonos no coinciden";
    }
    return null;
  }

  /// Valida contraseña segura:
  /// Mínimo 8 caracteres, con mayúscula, minúscula, número y especial.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return "La contraseña es obligatoria";
    }
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.,;:])[A-Za-z\d@$!%*?&.,;:]{8,}$',
    );
    if (!regex.hasMatch(value)) {
      return "Debe tener 8 caracteres, una mayúscula, "
          "una minúscula, un número y un caracter especial";
    }
    return null;
  }

  /// Valida que los passwords sean iguales
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return "La confirmación de la contraseña es obligatoria";
    }
    if (value != password) {
      return "Las contraseñas no coinciden";
    }
    return null;
  }

  /// Valida email simple.
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return "El correo es obligatorio";
    }
    // Trim whitespace
    final trimmedValue = value.trim();

    // Check for spaces in the email
    if (trimmedValue.contains(' ')) {
      return "El correo no puede contener espacios";
    }

    // Validate email format (no spaces allowed)
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(trimmedValue)) {
      return "Correo inválido";
    }
    return null;
  }

  /// Convierte cualquier validador en opcional.
  /// Si el campo está vacío, no valida. Si tiene valor, aplica el validador.
  static String? optional(String? value, String? Function(String?) validator) {
    // Si está vacío o es null, es válido (opcional)
    if (value == null || value.isEmpty) {
      return null;
    }
    // Si hay valor, aplica el validador
    return validator(value);
  }

  /// Password mínimo 8 caracteres (para login)
  static String? passwordLogin(String? value) {
    if (value == null || value.isEmpty) {
      return "La contraseña es obligatoria";
    }
    if (value.length < 8) {
      return "Debe tener al menos 8 caracteres";
    }
    return null;
  }

  /// Password con validaciones progresivas (para registro)
  static List<String> passwordRegister(String? value) {
    final errors = <String>[];

    if (value == null || value.isEmpty) {
      errors.add("La contraseña es obligatoria");
      return errors;
    }

    if (value.length < 8) {
      errors.add("Mínimo 8 caracteres");
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      errors.add("Debe contener una mayúscula");
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      errors.add("Debe contener una minúscula");
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      errors.add("Debe contener un número");
    }
    if (!RegExp(r'[@$!%*?&.,;:]').hasMatch(value)) {
      errors.add("Debe contener un caracter especial");
    }

    return errors;
  }

  /// validate clabe
  static String? clabe(String? value) {
    if (value == null || value.isEmpty) {
      return "La CLABE es obligatoria";
    }
    final regex = RegExp(r'^\d{18}$');
    if (!regex.hasMatch(value)) {
      return "La CLABE debe tener 18 dígitos";
    }
    return null;
  }

  //validate amount with maxAmount
  static String? amount(String? value, {double? maxAmount, double? minAmount}) {
    if (value == null || value.isEmpty) {
      return "El monto es obligatorio";
    }
    final regex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!regex.hasMatch(value)) {
      return "Monto inválido";
    }
    if (maxAmount != null) {
      final amount = double.tryParse(value);
      if (amount != null && amount > maxAmount) {
        return "El monto no puede ser mayor a $maxAmount";
      }
    }

    if (minAmount != null) {
      final amount = double.tryParse(value);
      if (amount != null && amount < minAmount) {
        return "El monto no puede ser menor a $minAmount";
      }
    }
    return null;
  }

  /// Valida fecha de nacimiento en formato dd/mm/yyyy y mayor de 18 años.
  /// También acepta dd-mm-yyyy o dd.mm.yyyy
  static String? birthdate(String? value) {
    if (value == null || value.isEmpty) {
      return "La fecha de nacimiento es obligatoria";
    }
    final regex = RegExp(
      r'^(0[1-9]|[12][0-9]|3[01])[\/.-](0[1-9]|1[0-2])[\/.-](19|20)\d\d$',
    );
    if (!regex.hasMatch(value)) {
      return "Formato de fecha inválido";
    }
    final parts = value.split(RegExp(r'[\/.-]'));
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day != null && month != null && year != null) {
      final birthdate = DateTime(year, month, day);
      if (birthdate
          .add(const Duration(days: 365 * 18))
          .isAfter(DateTime.now())) {
        return "Debes ser mayor de 18 años";
      }
    }
    return null;
  }
}
