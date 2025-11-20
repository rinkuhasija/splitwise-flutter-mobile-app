import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../services/auth_service.dart';

import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final user = dataProvider.currentUser;

    print('ProfileScreen: currentUser = $user');
    print('ProfileScreen: isLoading = ${dataProvider.isLoading}');

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
      appBar: AppBar(title: const Text('Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn().slideX(),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Settings'),
            _buildSettingItem(context, 'Scan code', FontAwesomeIcons.qrcode),
            _buildSettingItem(
              context,
              'Splitwise Pro',
              FontAwesomeIcons.crown,
              isPro: true,
            ),
            _buildSettingItem(
              context,
              'Email settings',
              FontAwesomeIcons.envelope,
            ),
            _buildSettingItem(
              context,
              'Device settings',
              FontAwesomeIcons.mobile,
            ),
            _buildSettingItem(context, 'Passcode', FontAwesomeIcons.lock),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Feedback'),
            _buildSettingItem(context, 'Rate Splitwise', FontAwesomeIcons.star),
            _buildSettingItem(context, 'Contact us', FontAwesomeIcons.headset),
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
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isPro ? Colors.amber : AppTheme.textSecondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: () {},
    );
  }
}
