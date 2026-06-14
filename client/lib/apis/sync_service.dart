import 'dart:async';
import 'dart:convert';

import 'package:expense_tracker/config/app_config.dart';
import 'package:http/http.dart' as http;

class SyncService {
  static const baseUrl = "${AppConfig.baseUrl}/sync";

  static Future<Map<String, dynamic>> sync({
    required String token,
    required String lastSyncedAt,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "last_synced_at": lastSyncedAt,
              "changes": {"transactions": transactions},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // Return structured error so SyncProvider can surface feedback
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message':
              body['message'] ?? 'Sync failed (HTTP ${response.statusCode})',
        };
      } catch (_) {
        return {
          'success': false,
          'message': 'Sync failed (HTTP ${response.statusCode})',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Sync timed out. Please try again later.',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
