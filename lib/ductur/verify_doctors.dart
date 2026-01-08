import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VerifyDoctorsPage extends StatefulWidget {
  @override
  _VerifyDoctorsPageState createState() => _VerifyDoctorsPageState();
}

class _VerifyDoctorsPageState extends State<VerifyDoctorsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> unverifiedDoctors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUnverifiedDoctors();
  }

  Future<void> fetchUnverifiedDoctors() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .get();

      List<Map<String, dynamic>> doctors = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('drSpecialization') &&
            data['drSpecialization'] != null &&
            (!data.containsKey('status') || data['status'] == null)) {

          data['id'] = doc.id;
          doctors.add(data);
        }
      }

      setState(() {
        unverifiedDoctors = doctors;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Error fetching doctors: $e');
    }
  }

  Future<void> verifyDoctor(String docId) async {
    try {
      await _firestore.collection('users').doc(docId).update({
        'status': 'Verified',
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Doctor verified successfully');
      fetchUnverifiedDoctors();
    } catch (e) {
      _showErrorSnackBar('Error verifying doctor: $e');
    }
  }

  Future<void> rejectDoctor(String docId) async {
    try {
      await _firestore.collection('users').doc(docId).update({
        'status': 'Rejected',
      });

      _showSuccessSnackBar('Doctor rejected');
      fetchUnverifiedDoctors();
    } catch (e) {
      _showErrorSnackBar('Error rejecting doctor: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Verification'),
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchUnverifiedDoctors,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.9),
            ],
          ),
        ),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Loading doctor profiles...',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    if (unverifiedDoctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 16),
            Text(
              'No pending verifications',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'All doctor profiles have been reviewed',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              onPressed: fetchUnverifiedDoctors,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: unverifiedDoctors.length,
      itemBuilder: (context, index) {
        return _buildDoctorCard(unverifiedDoctors[index], theme);
      },
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor, ThemeData theme) {
    final String specialization = doctor['drSpecialization'] ?? 'Unknown Specialization';
    final String fullName = doctor['fullName'] ?? 'Unknown';
    final String? profileImageUrl = doctor['profileImage'];
    final Color cardColor = theme.colorScheme.surface;

    // Generate avatar background color based on name
    final int nameHash = fullName.hashCode;
    final List<Color> avatarColors = [
      Colors.blue.shade300,
      Colors.purple.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.pink.shade300,
      Colors.teal.shade300,
    ];
    final Color avatarColor = avatarColors[nameHash.abs() % avatarColors.length];

    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        backgroundColor: cardColor,
        collapsedBackgroundColor: cardColor,
        tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: EdgeInsets.all(0),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: avatarColor,
          backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
          child: profileImageUrl == null
              ? Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          )
              : null,
        ),
        title: Text(
          fullName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            specialization,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        children: [
          Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection('Personal Details', [
                  _infoRow('Email', doctor['email'], Icons.email_outlined, theme),
                  _infoRow('Phone', doctor['phoneNumber'], Icons.phone_outlined, theme),
                  _infoRow('Gender', doctor['gender'], Icons.person_outline, theme),
                  _infoRow('Date of Birth', doctor['dateOfBirth'] != null
                      ? formatDate(doctor['dateOfBirth'])
                      : 'N/A', Icons.cake_outlined, theme),
                ], theme),
                SizedBox(height: 16),
                _buildInfoSection('Professional Details', [
                  _infoRow('License No', doctor['medicalLicenseNo'],
                      Icons.badge_outlined, theme),
                  _infoRow('Address', doctor['address'], Icons.location_on_outlined, theme),
                  _infoRow('Country', doctor['country'], Icons.flag_outlined, theme),
                ], theme),
                SizedBox(height: 24),
                _buildActionButtons(doctor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _infoRow(String label, String? value, IconData icon, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.secondary.withOpacity(0.7),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> doctor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.check_circle_outline),
            label: Text('Verify'),
            onPressed: () => verifyDoctor(doctor['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(Icons.cancel_outlined),
            label: Text('Reject'),
            onPressed: () => rejectDoctor(doctor['id']),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade600),
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}