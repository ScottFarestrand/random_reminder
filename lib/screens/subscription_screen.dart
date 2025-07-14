import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; // For making HTTP calls to Cloud Functions
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart'; // <--- ADD THIS IMPORT
import 'package:random_reminder/utilities/message_box.dart';

class SubscriptionScreen extends StatefulWidget {
  final String userId;
  final String? userEmail;
  final Function(String, MessageType) showMessage;

  const SubscriptionScreen({
    super.key,
    required this.userId,
    this.userEmail,
    required this.showMessage,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;

  // IMPORTANT: Replace with your actual deployed Cloud Function URL for createSquareSubscription
  // Example: 'https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/createSquareSubscription'
  final String _createSubscriptionCloudFunctionUrl =
      'https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/createSquareSubscription';

  Future<void> _handleSubscribe() async {
    setState(() {
      _isLoading = true;
    });

    // --- Placeholder for Square In-App Payments SDK integration ---
    // In a real app, you would integrate Square's In-App Payments SDK here
    // to collect card details securely and get a payment token (nonce).
    // Example (conceptual, requires native SDK setup):
    /*
    try {
      final String nonce = await SquareInAppPayments.startCardEntry();
      if (nonce.isNotEmpty) {
        // Send nonce to your Cloud Function
        final response = await http.post(
          Uri.parse(_createSubscriptionCloudFunctionUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'data': { // Callable functions require data in a 'data' field
              'nonce': nonce,
              'userId': widget.userId,
              'userEmail': widget.userEmail,
            }
          }),
        );

        final responseData = json.decode(response.body);
        final data = responseData['data']; // Callable functions return data in a 'data' field

        if (response.statusCode == 200 && data['success'] == true) {
          widget.showMessage('Subscription successful!', MessageType.success);
          // The main.dart StreamBuilder will automatically detect the subscription status change
          // and navigate to HomeScreen.
        } else {
          widget.showMessage('Subscription failed: ${data['error'] ?? 'Unknown error'}', MessageType.error);
        }
      } else {
        widget.showMessage('Payment cancelled or failed.', MessageType.error);
      }
    } catch (e) {
      widget.showMessage('An error occurred during payment: $e', MessageType.error);
      print('Square SDK integration error: $e');
    }
    */

    // --- TEMPORARY MOCK FOR TESTING WITHOUT ACTUAL SQUARE SDK ---
    // REMOVE THIS MOCK WHEN INTEGRATING REAL SQUARE SDK
    // This mock will simulate a successful subscription after a delay.
    // In a real app, you'd call your Cloud Function with the actual nonce.
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        // Simulate sending a request to your Cloud Function
        final response = await http.post(
          Uri.parse(_createSubscriptionCloudFunctionUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'data': {
              'nonce':
                  'mock_nonce_for_testing', // This would be the actual nonce from Square SDK
              'userId': widget.userId,
              'userEmail': widget.userEmail ?? 'test@example.com',
            },
          }),
        );

        final responseData = json.decode(response.body);
        final data = responseData['data'];

        if (response.statusCode == 200 && data['success'] == true) {
          widget.showMessage(
            'Subscription successful! (Mock)',
            MessageType.success,
          );
          // The main.dart StreamBuilder will automatically detect the subscription status change
          // and navigate to HomeScreen.
        } else {
          widget.showMessage(
            'Subscription failed: ${data['error'] ?? 'Unknown error'} (Mock)',
            MessageType.error,
          );
        }
      } catch (e) {
        widget.showMessage(
          'An error occurred during mock payment: $e',
          MessageType.error,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    });
    // --- END TEMPORARY MOCK ---
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFE1BEE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 24.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 8.0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Subscribe to Random Reminders',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Get unlimited reminders for just \$10/year!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Placeholder for Square Card Entry Form
                    Container(
                      height: 150, // Approximate height for card form
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.grey.shade100,
                      ),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Square Payment Form Placeholder',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            'Requires Square In-App Payments SDK integration.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _handleSubscribe,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'Subscribe Now',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        widget.showMessage('Signed out.', MessageType.info);
                      },
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
