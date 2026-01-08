import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/admin_home_page.dart';
import 'patient_profile_page.dart';

class MedicalColors {
  static const Color primary = Color(0xFF0066CC);
  static const Color primaryLight = Color(0xFF4D94FF);
  static const Color secondary = Color(0xFF00C853);
  static const Color accent = Color(0xFFFF6B35);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
}

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({Key? key}) : super(key: key);

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool isLoading = true;
  late TabController _tabController;

  String searchQuery = '';
  String filterCondition = 'All';
  String filterSeverity = 'All';
  String sortBy = 'Name';

  List<String> conditions = ['All'];
  List<String> severityLevels = ['All', 'Low', 'Medium', 'High'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPatients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchPatients() async {
    setState(() {
      isLoading = true;
    });

    try {
      final QuerySnapshot querySnapshot = await _firestore.collection('Appointments').get();
      Set<String> uniqueConditions = {'All'};

      List<Map<String, dynamic>> patientsList = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['condition'] != null && data['condition'].toString().isNotEmpty) {
          uniqueConditions.add(data['condition'].toString());
        }

        return {
          'id': doc.id,
          'name': data['fullName'] ?? 'Unknown',
          'phone': data['phone'] ?? 'N/A',
          'email': data['email'] ?? 'N/A',
          'location': data['country'] ?? 'N/A',
          'condition': data['condition'] ?? 'N/A',
          'specifyCondition': data['specifyCondition'] ?? 'N/A',
          'severity': data['severity'] ?? 'N/A',
          'patientAge': data['age'] ?? 'N/A',
          'gender': data['gender'] ?? 'N/A',
          'allergies': data['allergies'] ?? 'N/A',
          'chronicConditions': data['chronicConditions'] ?? 'N/A',
          'medications': data['medications'] ?? 'N/A',
          'currentTreatment': data['currentTreatment'] ?? false,
          'treatmentDetails': data['treatmentDetails'] ?? 'N/A',
          'previousDiagnosis': data['previousDiagnosis'] ?? false,
          'diagnosisDetails': data['diagnosisDetails'] ?? 'N/A',
          'previousSurgeries': data['previousSurgeries'] ?? false,
          'surgeriesDetails': data['surgeriesDetails'] ?? 'N/A',
          'worseningSymptoms': data['worseningSymptoms'] ?? false,
          'symptomsDescription': data['symptomsDescription'] ?? 'N/A',
          'otherDetails': data['otherDetails'] ?? 'N/A',
          'appointmentDate': data['appointmentDate'] ?? 'N/A',
          'appointmentTime': data['appointmentTime'] ?? 'N/A',
          'timeZone': data['timeZone'] ?? 'N/A',
          'timestamp': data['timestamp'] ?? null,
          'userId': data['userId'] ?? 'N/A',
          'doctorPreference': data['doctorPreference'] ?? false,
          'preferredDoctor': data['preferredDoctor'] ?? 'N/A',
          'preferredLanguage': data['preferredLanguage'] ?? 'N/A',
          'doctorName': data['doctorName'] ?? 'Not Assigned',
        };
      }).toList();

      setState(() {
        _patients = patientsList;
        _filteredPatients = patientsList;
        conditions = uniqueConditions.toList()..sort();
        isLoading = false;
      });

      _applyFiltersAndSort();
    } catch (e) {
      print('Error fetching patients: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load patient details'),
            backgroundColor: MedicalColors.error,
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    setState(() {
      _filteredPatients = _patients.where((patient) {
        bool matchesSearch = searchQuery.isEmpty ||
            (patient['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())) ||
            (patient['id'].toString().toLowerCase().contains(searchQuery.toLowerCase())) ||
            (patient['condition'].toString().toLowerCase().contains(searchQuery.toLowerCase()));

        bool matchesCondition = filterCondition == 'All' ||
            patient['condition'] == filterCondition;

        bool matchesSeverity = filterSeverity == 'All' ||
            patient['severity'] == filterSeverity;

        return matchesSearch && matchesCondition && matchesSeverity;
      }).toList();

      switch (sortBy) {
        case 'Name':
          _filteredPatients.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
          break;
        case 'Appointment Date':
          _filteredPatients.sort((a, b) => (a['appointmentDate'] ?? '').compareTo(b['appointmentDate'] ?? ''));
          break;
        case 'Severity (High to Low)':
          final Map<String, int> severityValues = {'High': 3, 'Medium': 2, 'Low': 1, 'N/A': 0};
          _filteredPatients.sort((a, b) =>
              (severityValues[b['severity']] ?? 0).compareTo(severityValues[a['severity']] ?? 0));
          break;
        case 'Age':
          _filteredPatients.sort((a, b) {
            int ageA = int.tryParse(a['patientAge']?.toString() ?? '0') ?? 0;
            int ageB = int.tryParse(b['patientAge']?.toString() ?? '0') ?? 0;
            return ageA.compareTo(ageB);
          });
          break;
      }
    });
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'High':
        return MedicalColors.error;
      case 'Medium':
        return MedicalColors.warning;
      case 'Low':
        return MedicalColors.secondary;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityBgColor(String? severity) {
    switch (severity) {
      case 'High':
        return Color(0xFFFFEBEE);
      case 'Medium':
        return Color(0xFFFFF3E0);
      case 'Low':
        return Color(0xFFE8F5E9);
      default:
        return Color(0xFFF5F5F5);
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Field
          Container(
            decoration: BoxDecoration(
              color: MedicalColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE0E0E0)),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: MedicalColors.primary, size: 22),
                hintText: 'Search by name, condition, or ID...',
                hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _applyFiltersAndSort();
                });
              },
            ),
          ),

          SizedBox(height: 12),

          // Filters Row
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Condition',
                  filterCondition,
                  conditions,
                      (value) => setState(() {
                    filterCondition = value!;
                    _applyFiltersAndSort();
                  }),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildFilterDropdown(
                  'Severity',
                  filterSeverity,
                  severityLevels,
                      (value) => setState(() {
                    filterSeverity = value!;
                    _applyFiltersAndSort();
                  }),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Sort and Reset Row
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Sort By',
                  sortBy,
                  ['Name', 'Appointment Date', 'Severity (High to Low)', 'Age'],
                      (value) => setState(() {
                    sortBy = value!;
                    _applyFiltersAndSort();
                  }),
                ),
              ),
              SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: MedicalColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: MedicalColors.secondary.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                        searchQuery = '';
                        filterCondition = 'All';
                        filterSeverity = 'All';
                        sortBy = 'Name';
                        _applyFiltersAndSort();
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: MedicalColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: MedicalColors.textSecondary),
          style: TextStyle(fontSize: 14, color: MedicalColors.textPrimary),
          hint: Text(label, style: TextStyle(fontSize: 14)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientProfilePage(patientData: patient),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [MedicalColors.primary, MedicalColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: MedicalColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ID: ${patient['id'].toString().substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 12,
                              color: MedicalColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getSeverityBgColor(patient['severity']),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            size: 14,
                            color: _getSeverityColor(patient['severity']),
                          ),
                          SizedBox(width: 4),
                          Text(
                            patient['severity'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getSeverityColor(patient['severity']),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),
                Divider(height: 1),
                SizedBox(height: 12),

                _buildInfoItem(Icons.medical_services_rounded, 'Condition', patient['condition'] ?? 'N/A'),
                SizedBox(height: 8),
                _buildInfoItem(Icons.calendar_today_rounded, 'Appointment', '${patient['appointmentDate'] ?? 'N/A'} at ${patient['appointmentTime'] ?? 'N/A'}'),
                SizedBox(height: 8),
                _buildInfoItem(Icons.person_outline_rounded, 'Doctor', patient['doctorName'] ?? 'Not Assigned'),

                SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildQuickInfo(Icons.cake_rounded, '${patient['patientAge'] ?? 'N/A'} yrs'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickInfo(Icons.wc_rounded, patient['gender'] ?? 'N/A'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickInfo(Icons.location_on_rounded, patient['location'] ?? 'N/A'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: MedicalColors.textSecondary),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: MedicalColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: MedicalColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfo(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: MedicalColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: MedicalColors.primary),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MedicalColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    int totalPatients = _patients.length;
    Map<String, int> patientsByCondition = {};
    Map<String, int> patientsBySeverity = {'High': 0, 'Medium': 0, 'Low': 0, 'N/A': 0};

    for (var patient in _patients) {
      String condition = patient['condition'] ?? 'Unknown';
      patientsByCondition[condition] = (patientsByCondition[condition] ?? 0) + 1;

      String severity = patient['severity'] ?? 'N/A';
      patientsBySeverity[severity] = (patientsBySeverity[severity] ?? 0) + 1;
    }

    List<MapEntry<String, int>> sortedConditions = patientsByCondition.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Stats
          _buildStatCard('Total Patients', totalPatients.toString(), Icons.people_rounded, MedicalColors.primary, Color(0xFFF0F9FF)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMiniStatCard('High', patientsBySeverity['High'].toString(), MedicalColors.error, Color(0xFFFFEBEE))),
              SizedBox(width: 12),
              Expanded(child: _buildMiniStatCard('Medium', patientsBySeverity['Medium'].toString(), MedicalColors.warning, Color(0xFFFFF3E0))),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMiniStatCard('Low', patientsBySeverity['Low'].toString(), MedicalColors.secondary, Color(0xFFE8F5E9))),
              SizedBox(width: 12),
              Expanded(child: _buildMiniStatCard('N/A', patientsBySeverity['N/A'].toString(), Colors.grey, Color(0xFFF5F5F5))),
            ],
          ),

          SizedBox(height: 24),

          // Top Conditions
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: MedicalColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Top Medical Conditions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MedicalColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFE8E8E8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: sortedConditions.take(5).map((entry) {
                double percentage = totalPatients > 0 ? entry.value / totalPatients * 100 : 0;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: MedicalColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: MedicalColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: MedicalColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(MedicalColors.primary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: MedicalColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: MedicalColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String value, Color color, Color bgColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_rounded, color: color, size: 24),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: MedicalColors.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: MedicalColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedicalColors.background,
      appBar: AppBar(
        title: Text(
          'Patient Management',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: MedicalColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _fetchPatients,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            Tab(text: 'Patients', icon: Icon(Icons.people_rounded, size: 20)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics_rounded, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Patients List
                isLoading
                    ? Center(child: CircularProgressIndicator(color: MedicalColors.primary))
                    : _filteredPatients.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        searchQuery.isEmpty && filterCondition == 'All' && filterSeverity == 'All'
                            ? 'No patients found'
                            : 'No patients match your filters',
                        style: TextStyle(fontSize: 16, color: MedicalColors.textSecondary),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _filteredPatients.length,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  itemBuilder: (context, index) => _buildPatientCard(_filteredPatients[index]),
                ),

                // Statistics
                _buildStatistics(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: MedicalColors.primary),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AdminHomePage()),
                    );
                  },
                  tooltip: 'Back to Home',
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: MedicalColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_rounded, size: 16, color: MedicalColors.primary),
                      SizedBox(width: 6),
                      Text(
                        '${_filteredPatients.length} Patients',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: MedicalColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: MedicalColors.secondary),
                  onPressed: _fetchPatients,
                  tooltip: 'Refresh Data',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}