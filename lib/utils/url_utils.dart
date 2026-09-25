import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the device's default browser (or a handling app, e.g. a
/// deep link) as a full handoff out of the app. Shows a snackbar instead of
/// crashing or failing silently if the URL is malformed or can't launch.
Future<void> launchTicketUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !await canLaunchUrl(uri)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this ticket link.')),
      );
    }
    return;
  }
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this ticket link.')),
      );
    }
  }
}
