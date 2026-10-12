import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';

/// Opens the device mail app with a pre-filled feedback email. Works on iOS
/// and Android (and web, which opens the default mail handler) via a mailto:
/// URL.
class FeedbackEmail {
  FeedbackEmail._();

  static const String address = 'BrainBuddies13@gmail.com';

  static Future<void> open(BuildContext context) async {
    final l = L10n.read(context).strings;
    final uri = Uri(
      scheme: 'mailto',
      path: address,
      query: _encodeQuery({
        'subject': l.feedbackSubject,
        'body': l.feedbackBody,
      }),
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);

    if (!launched && context.mounted) {
      // Fallback: show the address so the user can copy it manually.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.emailUsAt(address)),
          duration: const Duration(seconds: 4),
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
