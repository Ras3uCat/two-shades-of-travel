import 'package:flutter/material.dart';

const _bgColor = Color(0xFF000612);
const _cyanColor = Color(0xFF58E3EF);
const _bodyColor = Color(0xFFCFD8DC);
const _mutedColor = Color(0xFF607D8B);
const _dividerColor = Color(0xFF1A2540);

class BingeQuestLegalScreen extends StatelessWidget {
  const BingeQuestLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'BingeQuest — Legal',
          style: TextStyle(color: _cyanColor, fontSize: 16, letterSpacing: 1.2),
        ),
        iconTheme: const IconThemeData(color: _cyanColor),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BingeQuest — Legal',
                  style: TextStyle(
                    color: _cyanColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Last updated: January 2026',
                  style: TextStyle(color: _mutedColor, fontSize: 13),
                ),
                const SizedBox(height: 40),
                _section('Privacy Policy', _privacyPolicySections),
                const _Divider(),
                _section('Terms of Service', _termsSections),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<_LegalEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _cyanColor,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        ...entries.map(_entry),
      ],
    );
  }

  Widget _entry(_LegalEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.heading,
            style: const TextStyle(
              color: _bodyColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            entry.body,
            style: const TextStyle(
              color: _mutedColor,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Divider(color: _dividerColor, thickness: 1),
    );
  }
}

class _LegalEntry {
  const _LegalEntry(this.heading, this.body);
  final String heading;
  final String body;
}

const _privacyPolicySections = [
  _LegalEntry(
    'Introduction',
    'BingeQuest ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
  ),
  _LegalEntry(
    'Information We Collect',
    'We collect information you provide directly to us:\n'
    '• Account information (email, name) when you sign in with Google or Apple\n'
    '• Watchlist data including movies and TV shows you add\n'
    '• Watch progress and completion data\n'
    '• Badge and achievement data\n'
    '• Device token for push notifications',
  ),
  _LegalEntry(
    'How We Use Your Information',
    'We use the information we collect to:\n'
    '• Provide and maintain the app\n'
    '• Sync your watchlist across devices\n'
    '• Generate personalized recommendations\n'
    '• Track your achievements and badges\n'
    '• Send push notifications for new episodes and streaming changes\n'
    '• Improve our services',
  ),
  _LegalEntry(
    'Data Storage',
    'Your data is securely stored using Supabase, a trusted cloud platform. We implement industry-standard security measures to protect your information.',
  ),
  _LegalEntry(
    'Third-Party Services',
    'We use the following third-party services:\n'
    '• TMDB (The Movie Database) for movie and TV show information\n'
    '• Google Sign-In for authentication\n'
    '• Apple Sign-In for authentication\n'
    '• Supabase for data storage\n'
    '• Firebase for push notifications and analytics',
  ),
  _LegalEntry(
    'Data Deletion',
    'You can delete your account and all associated data at any time through the Settings screen. This action is permanent and cannot be undone.',
  ),
  _LegalEntry(
    'Children\'s Privacy',
    'Our app is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
  ),
  _LegalEntry(
    'Changes to This Policy',
    'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the app.',
  ),
  _LegalEntry(
    'Contact',
    'If you have questions about this Privacy Policy, please contact us at: meow@raspucat.com',
  ),
];

const _termsSections = [
  _LegalEntry(
    'Agreement to Terms',
    'By using BingeQuest, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our app.',
  ),
  _LegalEntry(
    'Description of Service',
    'BingeQuest is a watchlist tracking application that helps users manage their movie and TV show backlog. We provide tools to track progress, receive recommendations, and earn achievements.',
  ),
  _LegalEntry(
    'User Accounts',
    'You must create an account using Google or Apple Sign-In to use the app. You are responsible for maintaining the security of your account and all activities that occur under your account.',
  ),
  _LegalEntry(
    'Acceptable Use',
    'You agree not to:\n'
    '• Use the app for any unlawful purpose\n'
    '• Attempt to gain unauthorized access to our systems\n'
    '• Interfere with or disrupt the app\'s functionality\n'
    '• Share your account credentials with others\n'
    '• Use automated systems to access the app',
  ),
  _LegalEntry(
    'Content',
    'Movie and TV show data is provided by TMDB (The Movie Database). This product uses the TMDB API but is not endorsed or certified by TMDB. We do not host or provide any streaming content.',
  ),
  _LegalEntry(
    'Intellectual Property',
    'The BingeQuest app, including its design, features, and content, is owned by us and protected by intellectual property laws. You may not copy, modify, or distribute our app without permission.',
  ),
  _LegalEntry(
    'Disclaimer of Warranties',
    'The app is provided "as is" without warranties of any kind. We do not guarantee that the app will be error-free or uninterrupted.',
  ),
  _LegalEntry(
    'Limitation of Liability',
    'To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the app.',
  ),
  _LegalEntry(
    'Account Termination',
    'You may delete your account at any time through the Settings screen. We reserve the right to suspend or terminate accounts that violate these terms.',
  ),
  _LegalEntry(
    'Changes to Terms',
    'We may modify these terms at any time. Continued use of the app after changes constitutes acceptance of the new terms.',
  ),
  _LegalEntry(
    'Contact',
    'For questions about these Terms of Service, contact us at: meow@raspucat.com',
  ),
];
