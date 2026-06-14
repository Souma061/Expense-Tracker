import 'dart:async';
import 'dart:convert';

import 'package:expense_tracker/config/app_config.dart';
import 'package:expense_tracker/models/init_shared_pref.dart';
import 'package:http/http.dart' as http;

class AuthServices {
  static const baseUrl = "${AppConfig.baseUrl}/auth";

  static Future<Map<String, dynamic>> register({
    required String first_name,
    required String last_name,
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/register");
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              'first_name': first_name,
              'last_name': last_name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['data']?['token'] as String?;
        if (token != null) await InitSheredPref.instance.setToken(token);

        await InitSheredPref.instance.setProfileEmail(email);
        await InitSheredPref.instance.setProfileName(
          '$first_name $last_name'.trim(),
        );

        return data;
      } else {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Server is taking too long. Please try again later.',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/login");
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['data']?['token'] as String?;
        if (token != null) await InitSheredPref.instance.setToken(token);

        final user = data['data']?['user'] as Map<String, dynamic>?;
        if (user != null) {
          final userEmail = user['email'] as String?;
          final firstName = user['first_name'] as String?;
          final lastName = user['last_name'] as String?;
          final name = '${firstName ?? ""} ${lastName ?? ""}'.trim();

          if (userEmail != null)
            await InitSheredPref.instance.setProfileEmail(userEmail);
          if (name.isNotEmpty)
            await InitSheredPref.instance.setProfileName(name);
        }

        return data;
      } else {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Server is taking too long. Please try again later.',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getVerification(String otp) async {
    await Future.delayed(const Duration(seconds: 3));
    try {
      const code = "123456"; // Simulated OTP for testing
      if (otp == code) {
        return {'success': true, 'message': 'OTP verified successfully.'};
      } else {
        return {'success': false, 'message': 'Invalid OTP. Please try again.'};
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Server is taking too long. Please try again later.',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
