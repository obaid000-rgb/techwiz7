class PasswordChecks {
  final bool length;
  final bool letter;
  final bool number;
  final bool special;
  const PasswordChecks(this.length, this.letter, this.number, this.special);
}

class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static final RegExp _nameChars = RegExp(r'^[A-Za-z0-9 ]+$');
  static final RegExp _letter = RegExp(r'[A-Za-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[^A-Za-z0-9]');
  static final RegExp _keyboardChars = RegExp(r'^[\x21-\x7E]+$');

  /// Display names: English letters, numbers and single spaces, at least 2
  /// letters, 2–30 characters (after trimming). Returns the message for the
  /// first rule that fails, or null when valid.
  static String? validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Name must be 2 to 30 characters';
    if (!_nameChars.hasMatch(name)) {
      return 'Name can only use English letters, numbers, and spaces';
    }
    if (_letter.allMatches(name).length < 2) {
      return 'Name must contain at least 2 English letters';
    }
    if (name.contains('  ')) return 'Remove the extra spaces';
    if (name.length < 2 || name.length > 30) {
      return 'Name must be 2 to 30 characters';
    }
    return null;
  }

  /// New passwords (registration): printable English keyboard characters,
  /// no spaces, 8–64 long, with a letter, a number and a special character.
  static String? validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password must be at least 8 characters';
    if (!_keyboardChars.hasMatch(password)) {
      return 'Use English letters, numbers, and symbols only, no spaces';
    }
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (password.length > 64) return 'Password must be 8 to 64 characters';
    if (!_letter.hasMatch(password)) return 'Add at least one letter';
    if (!_digit.hasMatch(password)) return 'Add at least one number';
    if (!_special.hasMatch(password)) {
      return 'Add at least one special character, like ! @ # \$';
    }
    return null;
  }

  /// The live checklist shown under the Register password field.
  static PasswordChecks passwordChecks(String password) => PasswordChecks(
        password.length >= 8,
        _letter.hasMatch(password),
        _digit.hasMatch(password),
        _special.hasMatch(password.replaceAll(RegExp(r'\s'), '')),
      );

  /// Login only requires a password to be entered, so accounts created
  /// before the new-password rules can still sign in.
  static String? validateLoginPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Password required' : null;
}
