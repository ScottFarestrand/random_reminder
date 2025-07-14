import 'dart:convert';
import 'package:http/http.dart' as http;

class SquareService {
  // IMPORTANT: Replace with your actual deployed Cloud Function URLs
  // You can find these in your Firebase Console -> Functions -> Dashboard
  final String _createSubscriptionUrl =
      'https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/createSquareSubscription';
  final String _cancelSubscriptionUrl =
      'https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/cancelSquareSubscription';

  /// Calls the Cloud Function to create a Square subscription.
  /// [nonce]: The payment token (nonce) obtained from Square's SDK.
  /// [userId]: The Firebase user ID.
  /// [userEmail]: The user's email address.
  Future<Map<String, dynamic>> createSubscription(
    String nonce,
    String userId,
    String? userEmail,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_createSubscriptionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'data': {
            // Callable functions require data in a 'data' field
            'nonce': nonce,
            'userId': userId,
            'userEmail': userEmail,
          },
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseData['data']
            as Map<String, dynamic>; // Extract actual data from 'data' field
      } else {
        throw Exception(
          responseData['error'] ?? 'Failed to create subscription on server.',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to subscription service: $e');
    }
  }

  /// Calls the Cloud Function to cancel a Square subscription.
  /// [userId]: The Firebase user ID.
  Future<Map<String, dynamic>> cancelSubscription(String userId) async {
    try {
      final response = await http.post(
        Uri.parse(_cancelSubscriptionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'data': {
            // Callable functions require data in a 'data' field
            'userId': userId,
          },
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseData['data']
            as Map<String, dynamic>; // Extract actual data from 'data' field
      } else {
        throw Exception(
          responseData['error'] ?? 'Failed to cancel subscription on server.',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to cancellation service: $e');
    }
  }
}
