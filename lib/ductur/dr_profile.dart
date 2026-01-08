import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../admin/patient_profile_page.dart';

class DrProfilePage extends StatefulWidget {
  final String doctorId;
  final List<Map<String, dynamic>> assignedPatients;
  final bool isAdmin;

  const DrProfilePage({
    Key? key,
    required this.doctorId,
    this.assignedPatients = const [],
    this.isAdmin = false,
  }) : super(key: key);

  @override
  _DrProfilePageState createState() => _DrProfilePageState();
}

class _DrProfilePageState extends State<DrProfilePage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  Map<String, dynamic> doctorData = {};
  late TabController _tabController;
  bool _isEditing = false;
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _languagesController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isActive = true;
  String _adminNote = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isAdmin ? 3 : 2, vsync: this);
    fetchDoctorDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    _languagesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> fetchDoctorDetails() async {
    setState(() => isLoading = true);
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(widget.doctorId).get();
      if (doc.exists) {
        setState(() {
          doctorData = doc.data() as Map<String, dynamic>;
          isLoading = false;
          _experienceController.text = doctorData['experience']?.toString() ?? '';
          _phoneController.text = doctorData['phoneNumber'] ?? '';
          _languagesController.text = doctorData['languages'] ?? '';
          _isActive = doctorData['isActive'] ?? true;
          _adminNote = doctorData['adminNote'] ?? '';
          _noteController.text = _adminNote;
        });
      } else {
        _showSnackBar('Doctor not found');
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateDoctorStatus(bool isActive) async {
    try {
      await _firestore.collection('users').doc(widget.doctorId).update({'isActive': isActive});
      setState(() => _isActive = isActive);
      _showSnackBar('Status updated');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> saveAdminNote() async {
    try {
      await _firestore.collection('users').doc(widget.doctorId).update({'adminNote': _noteController.text});
      setState(() => _adminNote = _noteController.text);
      _showSnackBar('Note saved');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> updateDoctorInfo() async {
    try {
      await _firestore.collection('users').doc(widget.doctorId).update({
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'phoneNumber': _phoneController.text,
        'languages': _languagesController.text,
      });
      setState(() {
        doctorData['experience'] = int.tryParse(_experienceController.text) ?? 0;
        doctorData['phoneNumber'] = _phoneController.text;
        doctorData['languages'] = _languagesController.text;
        _isEditing = false;
      });
      _showSnackBar('Info updated');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).primaryColor,
    ));
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  void _viewPatientProfile(Map<String, dynamic> patientData) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PatientProfilePage(patientData: patientData)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (widget.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Switch(
                value: _isActive,
                onChanged: updateDoctorStatus,
                activeColor: Colors.green,
                activeTrackColor: Colors.green.withOpacity(0.4),
              ),
            ),
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                updateDoctorInfo();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(icon: Icon(Icons.person), text: "Profile"),
            Tab(icon: Icon(Icons.people), text: "Patients"),
            if (widget.isAdmin) Tab(icon: Icon(Icons.admin_panel_settings), text: "Admin"),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildPatientsTab(),
          if (widget.isAdmin) _buildAdminTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final ThemeData theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: primaryColor.withOpacity(0.05),
            child: Column(
              children: [
                _buildDoctorHeader(),
                _buildStatCards(),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(12),
          sliver: SliverToBoxAdapter(child: _buildInfoCard()),
        ),
      ],
    );
  }

  Widget _buildDoctorHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Hero(
                tag: 'doctor-${widget.doctorId}',
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (doctorData['fullName'] ?? 'Dr').substring(0, 1).toUpperCase(),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                  ),
                ),
              ),
              if (_isActive)
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 14),
                ),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorData['fullName'] ?? 'Unknown',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    doctorData['drSpecialization'] ?? 'Specialty not specified',
                    style: TextStyle(fontSize: 14, color: Colors.blue.shade800),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.mail_outline, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctorData['email'] ?? 'N/A',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Patients', '${widget.assignedPatients.length}', Icons.people, Colors.blue)),
          Expanded(child: _buildStatCard('Experience', '${doctorData['experience'] ?? '0'} yrs', Icons.star, Colors.amber)),
          Expanded(child: _buildStatCard('Rating', '${doctorData['rating'] ?? '4.5'}', Icons.thumbs_up_down, Colors.green)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Doctor Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                )
            ),
            Divider(height: 24),
            _buildInfoItem('Email', doctorData['email'] ?? 'N/A', Icons.email, _isEditing, null),
            _buildInfoItem('Phone', doctorData['phoneNumber'] ?? 'N/A', Icons.phone, _isEditing, _phoneController),
            _buildInfoItem(
                'Experience', '${doctorData['experience'] ?? 'N/A'} years', Icons.work, _isEditing, _experienceController),
            _buildInfoItem(
                'Languages', doctorData['languages'] ?? 'N/A', Icons.language, _isEditing, _languagesController),
            _buildInfoItem('Verified On', formatDate(doctorData['verifiedAt']), Icons.verified, false, null),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, bool isEditing, TextEditingController? controller) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    label,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)
                ),
                SizedBox(height: 4),
                isEditing && controller != null
                    ? TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                )
                    : Text(
                    value,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Icon(Icons.people, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  'Assigned Patients (${widget.assignedPatients.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
        widget.assignedPatients.isEmpty
            ? SliverFillRemaining(
          child: _buildEmptyState("No patients assigned", Icons.people),
        )
            : SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPatientCard(widget.assignedPatients[index]),
              childCount: widget.assignedPatients.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final severityColor = _getSeverityColor(patient['severity'] ?? 'Medium');

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewPatientProfile(patient),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.05),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: severityColor.withOpacity(0.2),
                  child: Text(
                    (patient['name'] ?? 'P').substring(0, 1).toUpperCase(),
                    style: TextStyle(fontSize: 20, color: severityColor.withOpacity(0.8), fontWeight: FontWeight.bold),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        patient['name'] ?? 'Unknown Patient',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: severityColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        patient['severity'] ?? 'Medium',
                        style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPatientInfoChip(Icons.person, '${patient['patientAge'] ?? 'N/A'} yrs'),
                        SizedBox(width: 8),
                        _buildPatientInfoChip(Icons.wc, patient['gender'] ?? 'N/A'),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.medical_services, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Condition: ${patient['condition'] ?? 'N/A'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16),
              title: Text('View Details', style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor)),
              collapsedIconColor: Theme.of(context).primaryColor,
              iconColor: Theme.of(context).primaryColor,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (patient['medications'] != null && patient['medications'].toString().isNotEmpty)
                        _buildDetailItem('Medications', patient['medications'], Icons.medication),
                      if (patient['allergies'] != null && patient['allergies'].toString().isNotEmpty)
                        _buildDetailItem('Allergies', patient['allergies'], Icons.warning),
                      if (patient['notes'] != null && patient['notes'].toString().isNotEmpty)
                        _buildDetailItem('Notes', patient['notes'], Icons.note),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text('View Full Profile'),
                        onPressed: () => _viewPatientProfile(patient),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)
                ),
                SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red.shade700;
      case 'medium':
        return Colors.orange.shade700;
      case 'low':
        return Colors.green.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  Widget _buildAdminTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Theme.of(context).primaryColor),
                        SizedBox(width: 8),
                        Text(
                            'Administrative Controls',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    Divider(height: 24),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Doctor Status', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        _isActive ? 'Active - Currently seeing patients' : 'Inactive - Not seeing patients',
                        style: TextStyle(color: _isActive ? Colors.green : Colors.red),
                      ),
                      value: _isActive,
                      onChanged: updateDoctorStatus,
                      activeColor: Colors.green,
                      secondary: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_isActive ? Colors.green : Colors.red).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isActive ? Icons.check_circle : Icons.cancel,
                          color: _isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    Divider(height: 24),
                    Text('Admin Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add notes here...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        ),
                        fillColor: Colors.grey.withOpacity(0.05),
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.save, size: 18),
                      label: Text('Save Notes'),
                      onPressed: saveAdminNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: Theme.of(context).primaryColor),
                        SizedBox(width: 8),
                        Text(
                            'Activity History',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    Divider(height: 24),
                    _buildLogItem('System', 'Doctor verified', formatDate(doctorData['verifiedAt'])),
                    _buildLogItem('Admin', 'Status change', formatDate(doctorData['statusUpdatedAt'] ?? null)),
                    _buildLogItem('System', 'Account created', formatDate(doctorData['createdAt'] ?? null)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(String actor, String action, String timestamp) {
    final bool isSystem = actor == 'System';
    final Color actorColor = isSystem ? Colors.blue : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: actorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSystem ? Icons.computer : Icons.admin_panel_settings,
              color: actorColor,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                SizedBox(height: 2),
                Text(
                    "By: $actor • $timestamp",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, size: 40, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}