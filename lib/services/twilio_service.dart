import 'package:cloud_functions/cloud_functions.dart';

class TwilioService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Calls the Cloud Function to send an SMS reminder via Twilio.
  /// [to]: The recipient's phone number (e.g., "+1234567890").
  /// [message]: The message body.
  /// [fromSmsNumber]: Your Twilio phone number (e.g., "+1987654321").
  Future<Map<String, dynamic>> sendSmsReminder(
    String to,
    String message,
    String fromSmsNumber,
  ) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'sendReminderViaTwilio',
      );
      final HttpsCallableResult result = await callable.call({
        'to': to,
        'message': message,
        'type': 'sms',
        'fromSmsNumber': fromSmsNumber,
      });
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Failed to send SMS: ${e.message} (Code: ${e.code})');
    } catch (e) {
      throw Exception('An unexpected error occurred while sending SMS: $e');
    }
  }

  /// Calls the Cloud Function to send an Email reminder via Twilio (SendGrid).
  /// [to]: The recipient's email address.
  /// [message]: The email body.
  /// [fromEmail]: Your verified Twilio SendGrid sender email.
  Future<Map<String, dynamic>> sendEmailReminder(
    String to,
    String message,
    String fromEmail,
  ) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'sendReminderViaTwilio',
      );
      final HttpsCallableResult result = await callable.call({
        'to': to,
        'message': message,
        'type': 'email',
        'fromEmail': fromEmail,
      });
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Failed to send email: ${e.message} (Code: ${e.code})');
    } catch (e) {
      throw Exception('An unexpected error occurred while sending email: $e');
    }
  }
}
