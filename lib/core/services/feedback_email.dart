import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the device mail app with a pre-filled feedback email. Works on iOS
/// and Android (and web, which opens the default mail handler) via a mailto:
/// URL.
class FeedbackEmail {
  FeedbackEmail._();

  static const String address = 'BrainBuddies13@gmail.com';

  static Future<void> open(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: address,
      query: _encodeQuery({
        'subject': 'BrainBuddies Feedback',
        'body': 'Hi BrainBuddies team,\n\n',
      }),
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);

    if (!launched && context.mounted) {
      // Fallback: show the address so the user can copy it manually.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email us at $address'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // Uri's query encoding uses '+' for spaces, which some mail clients show
  // literally; encode manually with %20 instead.
  static String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
