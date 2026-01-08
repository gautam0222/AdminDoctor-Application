import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../admin/patient_details_page.dart' hide MedicalColors; // Hide MedicalColors from this import
import '../ductur/dr_nav.dart'; // Use MedicalColors from this import

// Alternatively, you could create a custom colors class here
class AppColors {
  static const Color primary = Color(0xFF3F51B5);
  static const Color primaryLight = Color(0xFF757DE8);
  static const Color secondary = Color(0xFF00BCD4);
  static const Color secondaryLight = Color(0xFF62EFFF);
  static const Color accent = Color(0xFFFFC107);
}

class MedicalInsightsCard extends StatelessWidget {
  final String message;
  final String detail;
  final IconData icon;
  const MedicalInsightsCard({
    required this.message,
    required this.detail,
    this.icon = Icons.monitor_heart,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.primaryLight.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    detail,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  late TabController _tabController;

  // Patient statistics
  int totalPatients = 0;
  Map<String, int> patientsByCondition = {};
  Map<String, int> patientsByCountry = {};
  Map<String, int> patientsBySeverity = {'High': 0, 'Medium': 0, 'Low': 0, 'N/A': 0};

  // Doctor statistics
  int totalDoctors = 0;
  Map<String, int> doctorsBySpecialization = {};
  Map<String, int> doctorsByCountry = {};
  double averageDoctorRating = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch all necessary data
  Future<void> _fetchAllData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        _fetchPatientData(),
        _fetchDoctorData(),
      ]);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch and process patient data
  Future<void> _fetchPatientData() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore.collection('Appointments').get();

      Map<String, int> conditionMap = {};
      Map<String, int> countryMap = {};
      Map<String, int> severityMap = {'High': 0, 'Medium': 0, 'Low': 0, 'N/A': 0};

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Count conditions
        String condition = data['condition'] ?? 'Unknown';
        conditionMap[condition] = (conditionMap[condition] ?? 0) + 1;

        // Count countries
        String country = data['country'] ?? 'Unknown';
        countryMap[country] = (countryMap[country] ?? 0) + 1;

        // Count severities
        String severity = data['severity'] ?? 'N/A';
        severityMap[severity] = (severityMap[severity] ?? 0) + 1;
      }

      setState(() {
        totalPatients = querySnapshot.docs.length;
        patientsByCondition = conditionMap;
        patientsByCountry = countryMap;
        patientsBySeverity = severityMap;
      });
    } catch (e) {
      print('Error fetching patient data: $e');
      throw e;
    }
  }

  // Fetch and process doctor data
  Future<void> _fetchDoctorData() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('status', isEqualTo: 'Verified')
          .get();

      Map<String, int> specializationMap = {};
      Map<String, int> countryMap = {};
      double ratingSum = 0;

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Count specializations
        String specialization = data['drSpecialization'] ?? 'Unknown';
        specializationMap[specialization] = (specializationMap[specialization] ?? 0) + 1;

        // Count countries
        String country = data['country'] ?? 'Unknown';
        countryMap[country] = (countryMap[country] ?? 0) + 1;

        // Sum ratings
        double rating = (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0;
        ratingSum += rating;
      }

      setState(() {
        totalDoctors = querySnapshot.docs.length;
        doctorsBySpecialization = specializationMap;
        doctorsByCountry = countryMap;
        averageDoctorRating = totalDoctors > 0 ? ratingSum / totalDoctors : 0;
      });
    } catch (e) {
      print('Error fetching doctor data: $e');
      throw e;
    }
  }

  // Build overview statistics dashboard
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              _buildStatCard(
                'Total Patients',
                totalPatients.toString(),
                Icons.people,
                AppColors.primary,
              ),
              SizedBox(width: 12),
              _buildStatCard(
                'Total Doctors',
                totalDoctors.toString(),
                Icons.medical_services,
                AppColors.secondary,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'High Severity Cases',
                patientsBySeverity['High'].toString(),
                Icons.warning,
                Colors.red,
              ),
              SizedBox(width: 12),
              _buildStatCard(
                'Avg. Doctor Rating',
                averageDoctorRating.toStringAsFixed(1),
                Icons.star,
                Colors.amber,
              ),
            ],
          ),

          MedicalInsightsCard(
            message: 'Patient Load Warning',
            detail: 'Consider allocating more doctors to regions with high patient severity cases to optimize response time.',
          ),

          SizedBox(height: 24),

          // Patient-to-Doctor Ratio Chart
          Text(
            'Patient-to-Doctor Ratio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: totalDoctors > 0 && totalPatients > 0
                    ? PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: totalDoctors.toDouble(),
                        title: 'Doctors\n$totalDoctors',
                        color: AppColors.secondary,
                        radius: 80,
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      PieChartSectionData(
                        value: totalPatients.toDouble(),
                        title: 'Patients\n$totalPatients',
                        color: AppColors.primary,
                        radius: 80,
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
                    : Center(child: Text('No data available')),
              ),
            ),
          ),

          SizedBox(height: 24),

          // Patient Severity Distribution Chart
          Text(
            'Patient Severity Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxSeverityCount().toDouble(),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            String text = '';
                            switch(value.toInt()) {
                              case 0: text = 'High'; break;
                              case 1: text = 'Medium'; break;
                              case 2: text = 'Low'; break;
                              case 3: text = 'N/A'; break;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(value.toInt().toString(),
                                style: TextStyle(fontSize: 12));
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: patientsBySeverity['High']?.toDouble() ?? 0,
                            color: Colors.red,
                            width: 22,
                            borderRadius: BorderRadius.circular(2),
                          )
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: patientsBySeverity['Medium']?.toDouble() ?? 0,
                            color: Colors.orange,
                            width: 22,
                            borderRadius: BorderRadius.circular(2),
                          )
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: patientsBySeverity['Low']?.toDouble() ?? 0,
                            color: Colors.green,
                            width: 22,
                            borderRadius: BorderRadius.circular(2),
                          )
                        ],
                      ),
                      BarChartGroupData(
                        x: 3,
                        barRods: [
                          BarChartRodData(
                            toY: patientsBySeverity['N/A']?.toDouble() ?? 0,
                            color: Colors.grey,
                            width: 22,
                            borderRadius: BorderRadius.circular(2),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build patient statistics tab
  Widget _buildPatientTab() {
    // Sort conditions by count
    List<MapEntry<String, int>> sortedConditions = patientsByCondition.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Sort countries by count
    List<MapEntry<String, int>> sortedCountries = patientsByCountry.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Distribution by Medical Condition',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: sortedConditions.isEmpty
                  ? Center(child: Text('No condition data available'))
                  : Column(
                children: sortedConditions.take(5).map((entry) {
                  double percentage = totalPatients > 0 ? entry.value / totalPatients * 100 : 0;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(entry.key),
                        ),
                        Expanded(
                          flex: 7,
                          child: Stack(
                            children: [
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage / 100,
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          SizedBox(height: 24),

          Text(
            'Patient Geographic Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: sortedCountries.isEmpty
                  ? Center(child: Text('No country data available'))
                  : Column(
                children: sortedCountries.take(5).map((entry) {
                  double percentage = totalPatients > 0 ? entry.value / totalPatients * 100 : 0;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(entry.key),
                        ),
                        Expanded(
                          flex: 7,
                          child: Stack(
                            children: [
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage / 100,
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build doctor statistics tab
  Widget _buildDoctorTab() {
    // Sort specializations by count
    List<MapEntry<String, int>> sortedSpecializations = doctorsBySpecialization.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Sort countries by count
    List<MapEntry<String, int>> sortedCountries = doctorsByCountry.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doctor Distribution by Specialization',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: sortedSpecializations.isEmpty
                  ? Center(child: Text('No specialization data available'))
                  : Column(
                children: sortedSpecializations.take(5).map((entry) {
                  double percentage = totalDoctors > 0 ? entry.value / totalDoctors * 100 : 0;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(entry.key),
                        ),
                        Expanded(
                          flex: 7,
                          child: Stack(
                            children: [
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage / 100,
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          SizedBox(height: 24),

          Text(
            'Doctor Geographic Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: sortedCountries.isEmpty
                  ? Center(child: Text('No country data available'))
                  : Column(
                children: sortedCountries.take(5).map((entry) {
                  double percentage = totalDoctors > 0 ? entry.value / totalDoctors * 100 : 0;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(entry.key),
                        ),
                        Expanded(
                          flex: 7,
                          child: Stack(
                            children: [
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage / 100,
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getMaxSeverityCount() {
    int max = 0;
    patientsBySeverity.forEach((_, value) {
      if (value > max) max = value;
    });
    return max;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management Analytics'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAllData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Patients', icon: Icon(Icons.people)),
            Tab(text: 'Doctors', icon: Icon(Icons.medical_services)),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPatientTab(),
          _buildDoctorTab(),
        ],
      ),
    );
  }
}