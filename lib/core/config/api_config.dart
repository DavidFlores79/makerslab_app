// lib/core/config/api_config.dart
class ApiConfig {
  // Base URL de tu backend (puedes leer de .env o flavors)
  static const String baseUrl = 'https://makerslab-backend.onrender.com';

  // Endpoints de auth
  static const String signInEndpoint = '/auth/login';
  static const String phoneSignInEndpoint = '/auth/phone-login';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String changePasswordEndpoint = '/auth/change-password';
  static const String signUpEndpoint = '/auth/signup';
  static const String verifyRegistrationEndpoint = '/auth/verify-registration';
  static const String resendCodeEndpoint = '/auth/resend-code';
  
  // Legacy endpoints (kept for backward compatibility)
  static const String confirmSignUpEndpoint = '/auth/phone-verify';

  // Endpoints del menú principal
  static const String mainMenuEndpoint = '/api/modules';

  // Endpoints de usuarios
  static const String usersEndpoint = '/api/users';

  // Endpoints de catálogos
  static const String countriesEndpoint = '/api/countries';
}
