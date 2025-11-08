// lib/core/config/api_config.dart
class ApiConfig {
  // Base URL de tu backend (puedes leer de .env o flavors)
  static const String baseUrl = 'http://192.168.100.45:3001';

  // Endpoints de auth
  static const String signInEndpoint = '/auth/login';
  static const String phoneSignInEndpoint = '/auth/phone-login';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String changePasswordEndpoint = '/auth/change-password';
  static const String signUpEndpoint = '/auth/signup';
  static const String confirmSignUpEndpoint = '/auth/phone-verify';
  static const String resendSignUpCodeEndpoint = '/auth/resend-code';

  // Endpoints del menú principal
  static const String mainMenuEndpoint = '/api/modules';

  // Endpoints de usuarios
  static const String usersEndpoint = '/users';
}
