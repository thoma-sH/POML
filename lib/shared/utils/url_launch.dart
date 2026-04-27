import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Opens the given URL in the default external browser. Shows a friendly
// snackbar on failure rather than throwing — settings rows should never
// crash the app just because the OS can't resolve a handler.
Future<void> launchExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    _toast(context, 'Invalid link.');
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    _toast(context, 'Could not open link.');
  }
}

// Opens the user's mail client to compose a new message to the given
// address. The subject is optional and rendered as a URL query parameter.
Future<void> launchMail(
  BuildContext context,
  String email, {
  String? subject,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: subject == null ? null : {'subject': subject},
  );
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    _toast(context, 'No mail app available — write to $email');
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
