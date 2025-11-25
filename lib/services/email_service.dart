import 'package:cloud_functions/cloud_functions.dart';

class EmailService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Sends an invitation email to a new friend
  ///
  /// Parameters:
  /// - [recipientEmail]: Email address of the person being invited
  /// - [recipientName]: Name of the person being invited
  /// - [senderName]: Name of the person sending the invitation
  ///
  /// Returns: true if email was sent successfully, false otherwise
  Future<bool> sendInviteEmail({
    required String recipientEmail,
    required String recipientName,
    required String senderName,
  }) async {
    try {
      // Call the Firebase Cloud Function
      final callable = _functions.httpsCallable('sendInviteEmail');

      final result = await callable.call({
        'recipientEmail': recipientEmail,
        'recipientName': recipientName,
        'senderName': senderName,
        'appDownloadLink':
            'https://play.google.com/store/apps/details?id=com.splitwise.clone', // Update with actual link
      });

      return result.data['success'] == true;
    } catch (e) {
      print('Error sending invite email: $e');
      return false;
    }
  }

  /// Validates email format using regex
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
