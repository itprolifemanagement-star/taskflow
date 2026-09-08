import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String department,
  }) {
    return ApiService.post('auth/register.php', {
      'full_name': fullName,
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
      'department': department,
    });
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required int userId,
    required String otp,
    String purpose = 'register',
  }) {
    return ApiService.post('auth/verify_otp.php', {
      'user_id': userId,
      'otp': otp,
      'purpose': purpose,
    });
  }

  static Future<Map<String, dynamic>> resendOtp({
    required int userId,
    String purpose = 'register',
  }) {
    return ApiService.post('auth/resend_otp.php', {'user_id': userId, 'purpose': purpose});
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiService.post('auth/login.php', {
      'email': email,
      'password': password,
      'device_info': 'flutter_app',
    });
    if (res['success'] == true && res['token'] != null) {
      await ApiService.saveToken(res['token']);
    }
    return res;
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) {
    return ApiService.post('auth/forgot_password.php', {'email': email});
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) {
    return ApiService.post('auth/reset_password.php', {
      'reset_token': resetToken,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
  }

  static Future<void> logout() async {
    await ApiService.post('auth/logout.php', {});
    await ApiService.clearToken();
  }

  static AppUser? parseUser(Map<String, dynamic> res) {
    if (res['user'] == null) return null;
    return AppUser.fromJson(res['user']);
  }
}
