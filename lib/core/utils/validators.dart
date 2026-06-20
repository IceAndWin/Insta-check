class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';
    if (value.length < 2) return 'Username must be at least 2 characters';
    if (value.contains(' ')) return 'Username cannot contain spaces';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? instagramUsername(String? value) {
    if (value == null || value.isEmpty) return 'Enter an Instagram username';
    final regex = RegExp(r'^[a-zA-Z0-9._]{1,30}$');
    if (!regex.hasMatch(value)) return 'Invalid Instagram username';
    return null;
  }
}
