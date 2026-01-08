import 'package:flutter/material.dart';
import '../system/user_management.dart';
import './notification_setting_page.dart';
import './database_backup_page.dart';  // Changed from '../database_backup_page.dart'
import './security_settings_page.dart'; // Changed from '../security_settings_page.dart'
import './system_logs_page.dart';
class SystemPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('System Administration'),
        centerTitle: true,
        backgroundColor: Color(0xFF0D47A1),  // Using MedicalColors.primary
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildSettingTile(
                    icon: Icons.people,
                    title: 'User Management',
                    subtitle: 'View analytics and manage system users',
                    onTap: () {
                      // Navigate to user management
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserManagementPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    icon: Icons.backup,
                    title: 'Database Backup',
                    subtitle: 'Configure backup settings and restore points',
                    onTap: () {
                      // Navigate to backup settings
                    },
                  ),
                  _buildSettingTile(
                    icon: Icons.notifications,
                    title: 'Notification Settings',
                    subtitle: 'Configure system notifications',
                    onTap: () {
                      // Navigate to notification settings
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationSettingsPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    icon: Icons.security,
                    title: 'Security Settings',
                    subtitle: 'Configure password policies and security options',
                    onTap: () {
                      // Navigate to security settings
                    },
                  ),
                  _buildSettingTile(
                    icon: Icons.history,
                    title: 'System Logs',
                    subtitle: 'View system activity and error logs',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SystemLogsPage(),
                        ),
                      );
                      // Navigate to system logs
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF0D47A1).withOpacity(0.1),
          child: Icon(icon, color: Color(0xFF0D47A1)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}