import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/data_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'pro_screen.dart';
import 'qr_code_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final user = dataProvider.currentUser;

    if (dataProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: const Center(child: Text('No user data available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              onTap: () => _showEditProfileDialog(context, user.name, user.id),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: user.avatarUrl == null
                          ? Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                color: AppTheme.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideX(),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Settings'),
            _buildSettingItem(
              context,
              'Scan code',
              FontAwesomeIcons.qrcode,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRCodeScreen(user: user),
                ),
              ),
            ),
            _buildSettingItem(
              context,
              'Splitwise Pro',
              FontAwesomeIcons.crown,
              isPro: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProScreen()),
              ),
            ),
            _buildSettingItem(
              context,
              'Email settings',
              FontAwesomeIcons.envelope,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              ),
            ),
            _buildSettingItem(
              context,
              'Device settings',
              FontAwesomeIcons.mobile,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),
            _buildSettingItem(
              context,
              'Passcode',
              FontAwesomeIcons.lock,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Feedback'),
            _buildSettingItem(
              context,
              'Rate Splitwise',
              FontAwesomeIcons.star,
              onTap: () {
                // Placeholder for app store rating
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening App Store...')),
                );
              },
            ),
            _buildSettingItem(
              context,
              'Contact us',
              FontAwesomeIcons.headset,
              onTap: () => _contactSupport(context),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () async {
                await AuthService().signOut();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Log out'),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    IconData icon, {
    bool isPro = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isPro ? Colors.amber : AppTheme.textSecondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    String currentName,
    String userId,
  ) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await FirestoreService().updateUser(userId, name: newName);
                  // Force refresh user data
                  if (context.mounted) {
                    // DataProvider listens to auth state, but we might need to trigger a reload
                    // Actually, since we updated Firestore, if we were listening to a stream of the user doc, it would update.
                    // But DataProvider fetches once. We should reload.
                    // For now, let's just update the local state if possible or rely on full reload.
                    // A better way is to expose a reload method in DataProvider.
                    // Or just let the user know.
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully'),
                      ),
                    );
                    // Trigger a reload in DataProvider
                    Provider.of<DataProvider>(
                      context,
                      listen: false,
                    ).reloadCurrentUser();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating profile: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@splitwiseclone.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'Support Request: Splitwise Clone',
      }),
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client')),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
