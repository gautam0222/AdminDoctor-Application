import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsPage extends StatefulWidget {
  final String patientId;

  const StatisticsPage({Key? key, required this.patientId}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> patientData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch patient appointment data from Appointments collection
      DocumentSnapshot appointmentDoc = await _firestore
          .collection('Appointments')
          .doc(widget.patientId)
          .get();

      if (appointmentDoc.exists) {
        setState(() {
          patientData = appointmentDoc.data() as Map<String, dynamic>;
          patientData['id'] = appointmentDoc.id;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient data not found')),
        );
      }
    } catch (e) {
      print('Error fetching patient data: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load patient data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Statistics'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchPatientData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientProfileHeader(),
              _buildPhysicalStats(),
              _buildMedicalStats(),
              _buildHealthHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientProfileHeader() {
    String patientName = patientData['fullName'] ?? 'Unknown';
    String patientInitial = patientName.isNotEmpty ? patientName[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade500, Colors.blue.shade700],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              patientInitial,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            patientName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'ID: ${patientData['id'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          // Contact info row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildContactItem(Icons.phone, patientData['phone'] ?? 'N/A'),
              const SizedBox(width: 16),
              _buildContactItem(Icons.email, patientData['email'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildPhysicalStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Physical Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Age',
                '${patientData['age'] ?? 'N/A'}',
                Icons.calendar_today,
                Colors.orange,
              ),
              _buildStatCard(
                'Weight',
                '68 kg', // Placeholder value
                Icons.monitor_weight_outlined,
                Colors.green,
              ),
              _buildStatCard(
                'Height',
                '175 cm', // Placeholder value
                Icons.height,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'BMI',
                '22.1', // Placeholder value
                Icons.insert_chart,
                Colors.blue,
              ),
              _buildStatCard(
                'Gender',
                patientData['gender'] ?? 'N/A',
                patientData['gender'] == 'Male' ? Icons.male : Icons.female,
                Colors.pink,
              ),
              _buildStatCard(
                'Blood Type',
                'A+', // Placeholder value
                Icons.bloodtype,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medical Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildMedicalStatRow(
            'Heart Rate',
            '78 bpm', // Placeholder value
            Icons.favorite,
            Colors.red,
            Colors.red.withOpacity(0.1),
          ),
          _buildMedicalStatRow(
            'Blood Pressure',
            '120/80 mmHg', // Placeholder value
            Icons.medical_services, // Changed from blood_pressure
            Colors.blue,
            Colors.blue.withOpacity(0.1),
          ),
          _buildMedicalStatRow(
            'Blood Sugar',
            '95 mg/dL', // Placeholder value
            Icons.water_drop_outlined,
            Colors.purple,
            Colors.purple.withOpacity(0.1),
          ),
          _buildMedicalStatRow(
            'Oxygen Saturation',
            '98%', // Placeholder value
            Icons.air,
            Colors.lightBlue,
            Colors.lightBlue.withOpacity(0.1),
          ),
          _buildMedicalStatRow(
            'Body Temperature',
            '36.6 °C', // Placeholder value
            Icons.thermostat,
            Colors.orange,
            Colors.orange.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthHistory() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildHealthCard(
            'Condition',
            patientData['condition'] ?? 'N/A',
            patientData['specifyCondition'] ?? 'No specific details',
            Icons.medical_information,
            Colors.red.shade400,
          ),
          _buildHealthCard(
            'Allergies',
            patientData['allergies'] ?? 'None reported',
            '', // No detailed description needed
            Icons.dangerous,
            Colors.orange.shade400,
          ),
          _buildHealthCard(
            'Chronic Conditions',
            patientData['chronicConditions'] ?? 'None reported',
            '', // No detailed description needed
            Icons.monitor_heart_outlined,
            Colors.purple.shade400,
          ),
          _buildHealthCard(
            'Medications',
            patientData['medications'] ?? 'None reported',
            '', // No detailed description needed
            Icons.medication,
            Colors.green.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalStatRow(String title, String value, IconData icon, Color iconColor, Color backgroundColor) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 36),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(String title, String value, String description, IconData icon, Color color) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: description.isNotEmpty
            ? [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(description),
          ),
        ]
            : [],
      ),
    );
  }
}