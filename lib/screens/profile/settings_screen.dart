import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Appearance'),
          _buildSwitchTile(
            'Dark Mode',
            'Enable dark theme',
            themeProvider.isDarkMode,
            (value) => themeProvider.toggleTheme(value),
          ),
          const Divider(),
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            'Push Notifications',
            'Receive push notifications',
            true,
            (value) {},
          ),
          _buildSwitchTile(
            'Email Notifications',
            'Receive email updates',
            true,
            (value) {},
          ),
          const Divider(),
          _buildSectionHeader('Privacy'),
          _buildSwitchTile(
            'Show Profile',
            'Allow others to see your profile',
            true,
            (value) {},
          ),
          const Divider(),
          _buildSectionHeader('Data'),
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text(
              'Download your data',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.download),
            onTap: () {
              // TODO: Implement export data
            },
          ),
          ListTile(
            title: const Text('Clear Cache'),
            subtitle: const Text(
              'Free up storage space',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.delete_outline),
            onTap: () {
              // TODO: Implement clear cache
            },
          ),
          const Divider(),
          _buildSectionHeader('About'),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text(
              '1.0.0',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Open terms of service
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primary,
    );
  }
}
