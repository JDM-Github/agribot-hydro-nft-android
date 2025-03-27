import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NeedHelpSection extends StatelessWidget {
  const NeedHelpSection({super.key});

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Need Help?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _buildHelpLink("Our Email", "mailto:support@example.com"),
          _buildHelpLink("Documentation", "https://docs.example.com"),
          _buildHelpLink("Main Website", "https://www.example.com"),
        ],
      ),
    );
  }

  Widget _buildHelpLink(String title, String url) {
    return TextButton(
      onPressed: () => _launchUrl(url),
      style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, decoration: TextDecoration.underline),
      ),
    );
  }
}
