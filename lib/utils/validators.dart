class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}