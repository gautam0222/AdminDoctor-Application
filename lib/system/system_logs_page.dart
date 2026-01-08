import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SystemLogsPage extends StatefulWidget {
  @override
  _SystemLogsPageState createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends State<SystemLogsPage> {
  List<LogEntry> _logs = [];
  bool _isLoading = true;
  Timer? _logUpdateTimer;

  // App usage statistics
  String _firstLaunchTime = 'Unknown';
  String _lastSessionDuration = 'Unknown';
  String _avgSessionDuration = 'Unknown';
  int _totalSessions = 0;
  int _currentSessionStart = 0;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _startSessionTracking();

    // Update logs every 5 seconds to show real-time data
    _logUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _updateCurrentSessionTime();
    });
  }

  @override
  void dispose() {
    _logUpdateTimer?.cancel();
    _endSessionTracking();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load app usage statistics
      _firstLaunchTime = prefs.getString('first_launch_time') ?? 'Not recorded';
      _lastSessionDuration = prefs.getString('last_session_duration') ?? '0 minutes';
      _avgSessionDuration = prefs.getString('avg_session_duration') ?? '0 minutes';
      _totalSessions = prefs.getInt('total_sessions') ?? 0;

      // Load system logs
      final logsList = prefs.getStringList('system_logs') ?? [];
      _logs = logsList.map((logStr) {
        final parts = logStr.split('|');
        if (parts.length >= 3) {
          return LogEntry(
            timestamp: DateTime.parse(parts[0]),
            type: _getLogTypeFromString(parts[1]),
            message: parts[2],
          );
        }
        return LogEntry(
          timestamp: DateTime.now(),
          type: LogType.info,
          message: logStr,
        );
      }).toList();

      // Add current session log
      _logs.add(LogEntry(
        timestamp: DateTime.now(),
        type: LogType.info,
        message: 'System logs page opened',
      ));

      // Save updated logs
      _saveLogs();
    } catch (e) {
      _logs.add(LogEntry(
        timestamp: DateTime.now(),
        type: LogType.error,
        message: 'Error loading logs: $e',
      ));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsList = _logs.map((log) =>
    '${log.timestamp.toIso8601String()}|${log.type.toString().split('.').last}|${log.message}'
    ).toList();

    await prefs.setStringList('system_logs', logsList);
  }

  void _startSessionTracking() async {
    final prefs = await SharedPreferences.getInstance();
    _currentSessionStart = DateTime.now().millisecondsSinceEpoch;

    // Record first launch if not already set
    if (prefs.getString('first_launch_time') == null) {
      await prefs.setString('first_launch_time', DateTime.now().toString());
    }

    // Increment total sessions
    final totalSessions = prefs.getInt('total_sessions') ?? 0;
    await prefs.setInt('total_sessions', totalSessions + 1);
  }

  void _endSessionTracking() async {
    if (_currentSessionStart > 0) {
      final sessionDuration = DateTime.now().millisecondsSinceEpoch - _currentSessionStart;
      final durationInMinutes = sessionDuration / 60000; // Convert to minutes

      final prefs = await SharedPreferences.getInstance();

      // Save last session duration
      await prefs.setString('last_session_duration', '${durationInMinutes.toStringAsFixed(1)} minutes');

      // Update average session duration
      final totalSessions = prefs.getInt('total_sessions') ?? 1;
      final prevAvgStr = prefs.getString('avg_session_duration') ?? '0 minutes';
      final prevAvg = double.parse(prevAvgStr.split(' ')[0]);

      final newAvg = ((prevAvg * (totalSessions - 1)) + durationInMinutes) / totalSessions;
      await prefs.setString('avg_session_duration', '${newAvg.toStringAsFixed(1)} minutes');

      // Add session end log
      _logs.add(LogEntry(
        timestamp: DateTime.now(),
        type: LogType.info,
        message: 'System logs page closed - Duration: ${durationInMinutes.toStringAsFixed(1)} minutes',
      ));

      _saveLogs();
    }
  }

  void _updateCurrentSessionTime() {
    if (_currentSessionStart > 0) {
      setState(() {
        // Just trigger a rebuild to update current session time
      });
    }
  }

  String _getCurrentSessionTime() {
    if (_currentSessionStart > 0) {
      final sessionDuration = DateTime.now().millisecondsSinceEpoch - _currentSessionStart;
      final minutes = (sessionDuration / 60000).floor();
      final seconds = ((sessionDuration % 60000) / 1000).floor();
      return '$minutes min $seconds sec';
    }
    return '0 min 0 sec';
  }

  LogType _getLogTypeFromString(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'error':
        return LogType.error;
      case 'warning':
        return LogType.warning;
      case 'debug':
        return LogType.debug;
      default:
        return LogType.info;
    }
  }

  void _clearLogs() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Logs'),
        content: Text('Are you sure you want to clear all system logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('system_logs');

              setState(() {
                _logs = [
                  LogEntry(
                    timestamp: DateTime.now(),
                    type: LogType.warning,
                    message: 'All logs cleared by user',
                  )
                ];
              });

              _saveLogs();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('System logs cleared'))
              );
            },
            child: Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('System Logs'),
        centerTitle: true,
        backgroundColor: Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUsageStatisticsCard(),
            SizedBox(height: 16),
            Text(
              'Activity Logs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: _logs.isEmpty
                  ? Center(
                child: Text(
                  'No logs available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  // Display logs in reverse chronological order
                  final log = _logs[_logs.length - 1 - index];
                  return _buildLogItem(log);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatisticsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Usage Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            SizedBox(height: 16),
            _buildStatRow(
              icon: Icons.access_time,
              title: 'Current Session',
              value: _getCurrentSessionTime(),
            ),
            Divider(),
            _buildStatRow(
              icon: Icons.calendar_today,
              title: 'First Launch',
              value: _firstLaunchTime,
            ),
            Divider(),
            _buildStatRow(
              icon: Icons.timelapse,
              title: 'Avg. Session Duration',
              value: _avgSessionDuration,
            ),
            Divider(),
            _buildStatRow(
              icon: Icons.history,
              title: 'Last Session Duration',
              value: _lastSessionDuration,
            ),
            Divider(),
            _buildStatRow(
              icon: Icons.repeat,
              title: 'Total Sessions',
              value: _totalSessions.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF0D47A1), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(LogEntry log) {
    Color getLogColor() {
      switch (log.type) {
        case LogType.error:
          return Colors.red;
        case LogType.warning:
          return Colors.orange;
        case LogType.debug:
          return Colors.purple;
        default:
          return Colors.green;
      }
    }

    IconData getLogIcon() {
      switch (log.type) {
        case LogType.error:
          return Icons.error_outline;
        case LogType.warning:
          return Icons.warning_amber_outlined;
        case LogType.debug:
          return Icons.code;
        default:
          return Icons.info_outline;
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: getLogColor().withOpacity(0.2),
          child: Icon(getLogIcon(), color: getLogColor(), size: 20),
        ),
        title: Text(
          log.message,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          '${_formatTimestamp(log.timestamp)} • ${log.type.toString().split('.').last}',
          style: TextStyle(fontSize: 12),
        ),
        dense: true,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

enum LogType {
  info,
  warning,
  error,
  debug,
}

class LogEntry {
  final DateTime timestamp;
  final LogType type;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.type,
    required this.message,
  });
}