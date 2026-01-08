import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalColors {
  static const Color primary = Color(0xFF0D47A1);      // Dark Blue
  static const Color primaryLight = Color(0xFF5472D3);
  static const Color secondary = Color(0xFF00796B);    // Teal
  static const Color secondaryLight = Color(0xFF48A999);
  static const Color accent = Color(0xFFEC407A);       // Pink
  static const Color background = Color(0xFFF5F5F5);   // Light Grey
  static const Color surface = Color(0xFFFFFFFF);      // White
  static const Color error = Color(0xFFB71C1C);        // Dark Red
  static const Color success = Color(0xFF43A047);      // Green
  static const Color warning = Color(0xFFFFA000);      // Amber
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  late TabController _tabController;

  // Notification settings
  bool _patientAppointmentNotifications = true;
  bool _doctorAvailabilityNotifications = true;
  bool _emergencyNotifications = true;
  bool _systemUpdateNotifications = true;
  bool _securityAlertNotifications = true;

  // Channel settings
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;

  // Timing settings
  String _notificationDeliveryTime = 'Immediate';
  String _digestFrequency = 'Daily';

  // Statistics
  Map<String, dynamic> _notificationStats = {
    'totalSent': 0,
    'deliveryRate': 0,
    'readRate': 0,
    'mostCommonType': 'None',
  };

  List<Map<String, dynamic>> _recentNotifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchNotificationSettings();
    _fetchNotificationStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch notification settings from Firestore
  Future<void> _fetchNotificationSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      // In a real app, you would fetch from your settings collection
      DocumentSnapshot settingsSnapshot = await _firestore
          .collection('systemSettings')
          .doc('notifications')
          .get();

      if (settingsSnapshot.exists) {
        Map<String, dynamic> data = settingsSnapshot.data() as Map<String, dynamic>;

        setState(() {
          // Notification types
          _patientAppointmentNotifications = data['patientAppointmentNotifications'] ?? true;
          _doctorAvailabilityNotifications = data['doctorAvailabilityNotifications'] ?? true;
          _emergencyNotifications = data['emergencyNotifications'] ?? true;
          _systemUpdateNotifications = data['systemUpdateNotifications'] ?? true;
          _securityAlertNotifications = data['securityAlertNotifications'] ?? true;

          // Channels
          _emailNotifications = data['emailNotifications'] ?? true;
          _pushNotifications = data['pushNotifications'] ?? true;
          _smsNotifications = data['smsNotifications'] ?? false;

          // Timing
          _notificationDeliveryTime = data['notificationDeliveryTime'] ?? 'Immediate';
          _digestFrequency = data['digestFrequency'] ?? 'Daily';
        });
      }

      isLoading = false;
    } catch (e) {
      print('Error fetching notification settings: $e');
      _showSnackBar('Failed to load notification settings');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch notification statistics
  Future<void> _fetchNotificationStatistics() async {
    try {
      // In a real app, you would fetch actual stats
      DocumentSnapshot statsSnapshot = await _firestore
          .collection('analytics')
          .doc('notificationStats')
          .get();

      if (statsSnapshot.exists) {
        Map<String, dynamic> stats = statsSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _notificationStats = stats;
        });
      }

      // Fetch recent notifications
      QuerySnapshot recentNotificationsSnapshot = await _firestore
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      setState(() {
        _recentNotifications = recentNotificationsSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error fetching notification statistics: $e');
    }
  }

  // Save notification settings to Firestore
  Future<void> _saveNotificationSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _firestore.collection('systemSettings').doc('notifications').set({
        // Notification types
        'patientAppointmentNotifications': _patientAppointmentNotifications,
        'doctorAvailabilityNotifications': _doctorAvailabilityNotifications,
        'emergencyNotifications': _emergencyNotifications,
        'systemUpdateNotifications': _systemUpdateNotifications,
        'securityAlertNotifications': _securityAlertNotifications,

        // Channels
        'emailNotifications': _emailNotifications,
        'pushNotifications': _pushNotifications,
        'smsNotifications': _smsNotifications,

        // Timing
        'notificationDeliveryTime': _notificationDeliveryTime,
        'digestFrequency': _digestFrequency,

        // Metadata
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Notification settings saved successfully');
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error saving notification settings: $e');
      _showSnackBar('Failed to save notification settings');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings'),
        centerTitle: true,
        backgroundColor: MedicalColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveNotificationSettings,
            tooltip: 'Save Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Settings', icon: Icon(Icons.settings_applications)),
            Tab(text: 'Channels', icon: Icon(Icons.send)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: MedicalColors.primary))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationSettingsTab(),
          _buildChannelSettingsTab(),
          _buildNotificationAnalyticsTab(),
        ],
      ),
    );
  }

  // Tab 1: Notification Settings
  Widget _buildNotificationSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Notification Types'),
          SizedBox(height: 8),

          _buildNotificationToggle(
            'Patient Appointment Notifications',
            'New appointments, cancellations, and reminders',
            _patientAppointmentNotifications,
                (value) {
              setState(() {
                _patientAppointmentNotifications = value;
              });
            },
            Icons.calendar_today,
          ),

          _buildNotificationToggle(
            'Doctor Availability Updates',
            'Changes to doctor schedules and availability',
            _doctorAvailabilityNotifications,
                (value) {
              setState(() {
                _doctorAvailabilityNotifications = value;
              });
            },
            Icons.people,
          ),

          _buildNotificationToggle(
            'Emergency Alerts',
            'Urgent medical situations and critical updates',
            _emergencyNotifications,
                (value) {
              setState(() {
                _emergencyNotifications = value;
              });
            },
            Icons.warning,
            isHighPriority: true,
          ),

          _buildNotificationToggle(
            'System Updates',
            'Platform maintenance and feature updates',
            _systemUpdateNotifications,
                (value) {
              setState(() {
                _systemUpdateNotifications = value;
              });
            },
            Icons.system_update,
          ),

          _buildNotificationToggle(
            'Security Alerts',
            'Login attempts and security-related events',
            _securityAlertNotifications,
                (value) {
              setState(() {
                _securityAlertNotifications = value;
              });
            },
            Icons.security,
          ),

          SizedBox(height: 24),
          _buildSectionHeader('Delivery Preferences'),
          SizedBox(height: 8),

          _buildDropdownSetting(
            'Notification Delivery',
            'When non-critical notifications are delivered',
            _notificationDeliveryTime,
            ['Immediate', 'Hourly Digest', 'Daily Digest', 'Weekly Digest'],
                (value) {
              setState(() {
                _notificationDeliveryTime = value!;
              });
            },
          ),

          _buildDropdownSetting(
            'Digest Frequency',
            'How often you receive notification summaries',
            _digestFrequency,
            ['Daily', 'Weekly', 'Monthly'],
                (value) {
              setState(() {
                _digestFrequency = value!;
              });
            },
          ),

          SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Save Settings'),
              onPressed: _saveNotificationSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: MedicalColors.secondary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 2: Channel Settings
  Widget _buildChannelSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Notification Channels'),
          SizedBox(height: 16),

          _buildChannelCard(
            'Email Notifications',
            'Receive notifications via email',
            Icons.email,
            _emailNotifications,
                (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),

          _buildChannelCard(
            'Push Notifications',
            'Receive notifications on your device',
            Icons.notifications_active,
            _pushNotifications,
                (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),

          _buildChannelCard(
            'SMS Notifications',
            'Receive important alerts via SMS',
            Icons.message,
            _smsNotifications,
                (value) {
              setState(() {
                _smsNotifications = value;
              });
            },
          ),

          SizedBox(height: 24),
          _buildSectionHeader('Channel Settings'),
          SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priority Channel Order',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Notifications will attempt delivery in this order:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  SizedBox(height: 16),

                  _buildReorderableItem(1, 'Push Notifications', Icons.notifications_active),
                  _buildReorderableItem(2, 'Email', Icons.email),
                  _buildReorderableItem(3, 'SMS (Emergency Only)', Icons.message),

                  SizedBox(height: 16),
                  Text(
                    'Note: Emergency notifications may be sent through all enabled channels simultaneously.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Save Channel Settings'),
              onPressed: _saveNotificationSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: MedicalColors.secondary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 3: Notification Analytics
  Widget _buildNotificationAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Notification Statistics'),
          SizedBox(height: 16),

          Row(
            children: [
              _buildStatCard(
                'Total Sent',
                _notificationStats['totalSent'].toString(),
                Icons.send,
                MedicalColors.primary,
              ),
              SizedBox(width: 12),
              _buildStatCard(
                'Delivery Rate',
                '${_notificationStats['deliveryRate']}%',
                Icons.done_all,
                MedicalColors.success,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'Read Rate',
                '${_notificationStats['readRate']}%',
                Icons.visibility,
                MedicalColors.secondary,
              ),
              SizedBox(width: 12),
              _buildStatCard(
                'Common Type',
                _notificationStats['mostCommonType'],
                Icons.category,
                MedicalColors.accent,
              ),
            ],
          ),

          SizedBox(height: 24),
          _buildSectionHeader('Recent Notifications'),
          SizedBox(height: 16),

          _recentNotifications.isEmpty
              ? _buildEmptyState('No recent notifications to display', Icons.notifications_off)
              : Column(
            children: _recentNotifications.map((notification) =>
                _buildNotificationItem(notification)
            ).toList(),
          ),

          SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Volume',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 16),

                  // Placeholder for a chart - in a real app, you'd use a chart library
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('Notification Volume Chart'),
                    ),
                  ),

                  SizedBox(height: 12),
                  Text(
                    'Displaying notification volume over the past 30 days',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              icon: Icon(Icons.download),
              label: Text('Export Notification Report'),
              onPressed: () {
                _showSnackBar('Notification report download started');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: MedicalColors.primary,
                side: BorderSide(color: MedicalColors.primary),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MedicalColors.primary,
          ),
        ),
        Expanded(
          child: Divider(
            indent: 12,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle(
      String title,
      String subtitle,
      bool value,
      Function(bool) onChanged,
      IconData icon, {
        bool isHighPriority = false,
      }) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: isHighPriority
                  ? MedicalColors.error.withOpacity(0.1)
                  : MedicalColors.primary.withOpacity(0.1),
              child: Icon(
                icon,
                color: isHighPriority ? MedicalColors.error : MedicalColors.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeColor: isHighPriority ? MedicalColors.error : MedicalColors.primary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildDropdownSetting(
      String title,
      String subtitle,
      String value,
      List<String> options,
      Function(String?) onChanged,
      ) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              value: value,
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard(
      String title,
      String subtitle,
      IconData icon,
      bool isEnabled,
      Function(bool) onChanged,
      ) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? MedicalColors.primary.withOpacity(0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isEnabled ? MedicalColors.primary : Colors.grey,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: onChanged,
              activeColor: MedicalColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableItem(int position, String channel, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: MedicalColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 12),
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 8),
          Text(
            channel,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Spacer(),
          Icon(Icons.drag_handle, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final DateTime timestamp = notification['timestamp']?.toDate() ?? DateTime.now();
    final String timeAgo = _getTimeAgo(timestamp);
    final IconData typeIcon = _getNotificationTypeIcon(notification['type'] ?? 'system');
    final Color typeColor = _getNotificationTypeColor(notification['type'] ?? 'system');

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: typeColor.withOpacity(0.1),
          child: Icon(typeIcon, color: typeColor, size: 20),
        ),
        title: Text(notification['title'] ?? 'Notification'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['body'] ?? 'No content'),
            Text(
              timeAgo,
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Icon(
          notification['read'] == true ? Icons.check_circle : Icons.circle_outlined,
          color: notification['read'] == true ? Colors.green : Colors.grey,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
        return Icons.calendar_today;
      case 'doctor':
        return Icons.people;
      case 'emergency':
        return Icons.warning;
      case 'system':
        return Icons.system_update;
      case 'security':
        return Icons.security;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
        return MedicalColors.primary;
      case 'doctor':
        return MedicalColors.secondary;
      case 'emergency':
        return MedicalColors.error;
      case 'system':
        return MedicalColors.accent;
      case 'security':
        return MedicalColors.warning;
      default:
        return Colors.blue;
    }
  }
}