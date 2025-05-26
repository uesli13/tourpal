import 'package:flutter/material.dart';
import 'package:tourpal/features/settings/presentation/widgets/change_email_dialog.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/change_password_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ACCOUNT SECTION
            _buildSectionHeader('Account', Icons.person),
            const SizedBox(height: 12),
            
            _buildSettingsTile(
              title: 'Change Email',
              subtitle: 'Update your email address',
              icon: Icons.email_outlined,
              onTap: () => _showChangeEmailDialog(),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            
            const SizedBox(height: 8),
            
            _buildSettingsTile(
              title: 'Change Password',
              subtitle: 'Update your password',
              icon: Icons.lock_outline,
              onTap: () => _showChangePasswordDialog(),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            
            const SizedBox(height: 24),
            
            // PREFERENCES SECTION
            _buildSectionHeader('Preferences', Icons.tune),
            const SizedBox(height: 12),
            
            _buildSettingsTile(
              title: 'Push Notifications',
              subtitle: 'Get tour updates and reminders',
              icon: Icons.notifications_outlined,
              trailing: Switch.adaptive(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _showSnackBar(
                    value 
                        ? '🔔 Notifications enabled' 
                        : '🔕 Notifications disabled'
                  );
                },
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withOpacity(0.3),
              ),
            ),
            
            const SizedBox(height: 8),
            
            _buildSettingsTile(
              title: 'Location Services',
              subtitle: 'Better recommendations and navigation',
              icon: Icons.location_on_outlined,
              trailing: Switch.adaptive(
                value: _locationEnabled,
                onChanged: (value) {
                  setState(() {
                    _locationEnabled = value;
                  });
                  _showSnackBar(
                    value 
                        ? '📍 Location enabled' 
                        : '📍 Location disabled'
                  );
                },
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withOpacity(0.3),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // APP INFO
            _buildSectionHeader('App Info', Icons.info_outline),
            const SizedBox(height: 12),
            
            _buildSettingsTile(
              title: 'Version',
              subtitle: '1.0.0 - Latest',
              icon: Icons.info_outline,
              onTap: () => _showAboutDialog(),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            
            const SizedBox(height: 32),
            
            // DANGER ZONE
            _buildSectionHeader('Danger Zone', Icons.warning_outlined, color: Colors.red),
            const SizedBox(height: 12),
            
            _buildSettingsTile(
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              icon: Icons.delete_forever_outlined,
              onTap: () => _showDeleteAccountDialog(),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              textColor: Colors.red,
              iconColor: Colors.red,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          color: color ?? AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showChangeEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => const ChangeEmailDialog(),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('About TourPal'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TourPal - Your Personal Tour Guide',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Version: 1.0.0\nBuild: 001\n\nDiscover amazing places and create unforgettable tours with TourPal!',
              style: TextStyle(height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cool!'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure? This will permanently delete your account and all your tours. This cannot be undone!',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('❌ Account deletion cancelled');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}