import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'statistics_page.dart';
import 'all_reports_page.dart';
import 'payments_page.dart';
import 'history_page.dart';
import 'verified_doctors_list.dart';
import 'ai.dart'; // Import AI page

class PatientProfilePage extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const PatientProfilePage({Key? key, required this.patientData}) : super(key: key);

  @override
  _PatientProfilePageState createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _summaryController = TextEditingController();
  String? selectedDoctor;
  String? selectedDoctorId;
  bool hasJoinedCall = false;

  @override
  void initState() {
    super.initState();
    _summaryController.text = widget.patientData['summary'] ?? '';
    selectedDoctor = widget.patientData['doctorName'] ?? 'Not Assigned';
    selectedDoctorId = widget.patientData['doctorId'];
  }

  Future<List<Map<String, dynamic>>> fetchVerifiedDoctors() async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('status', isEqualTo: 'Verified')
          .get();

      List<Map<String, dynamic>> doctors = [];

      for (var doc in query.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        doctors.add({
          'id': doc.id,
          'name': data['fullName'] ?? 'Unknown',
          'specialisation': data['drSpecialization'] ?? 'General',
        });
      }

      return doctors;
    } catch (e) {
      debugPrint("Error fetching verified doctors: $e");
      return [];
    }
  }

  Future<void> assignDoctor(Map<String, dynamic> doctor) async {
    try {
      String patientId = widget.patientData['id'].toString();

      Map<String, dynamic> patientDetails = {
        'name': widget.patientData['name'] ?? 'Unknown',
        'patientAge': widget.patientData['patientAge'] ?? 'N/A',
        'condition': widget.patientData['condition'] ?? 'N/A',
        'gender': widget.patientData['gender'] ?? 'N/A',
        'severity': widget.patientData['severity'] ?? 'Medium',
        'specifyCondition': widget.patientData['specifyCondition'] ?? 'N/A',
        'appointmentDate': widget.patientData['appointmentDate'] ?? 'N/A',
        'phone': widget.patientData['phone'] ?? 'N/A',
        'email': widget.patientData['email'] ?? 'N/A',
        'medications': widget.patientData['medications'] ?? 'None',
        'allergies': widget.patientData['allergies'] ?? 'None',
      };

      await _firestore.collection('Appointments').doc(patientId).update({
        'doctorName': doctor['name'],
        'doctorId': doctor['id'],
      });

      if (selectedDoctorId != null && selectedDoctorId != doctor['id']) {
        DocumentSnapshot prevDoctorDoc = await _firestore.collection('users').doc(selectedDoctorId).get();
        if (prevDoctorDoc.exists) {
          Map<String, dynamic> prevDoctorData = prevDoctorDoc.data() as Map<String, dynamic>;
          List<dynamic> prevPatients = prevDoctorData['patientsAssigned'] ?? [];

          if (prevPatients.contains(patientId)) {
            prevPatients.remove(patientId);
            await _firestore.collection('users').doc(selectedDoctorId).update({
              'patientsAssigned': prevPatients,
            });
          }
        }
      }

      DocumentSnapshot doctorDoc = await _firestore.collection('users').doc(doctor['id']).get();

      if (doctorDoc.exists) {
        Map<String, dynamic> doctorData = doctorDoc.data() as Map<String, dynamic>;
        List<dynamic> patientsAssigned = doctorData['patientsAssigned'] ?? [];

        if (!patientsAssigned.contains(patientId)) {
          patientsAssigned.add(patientId);

          await _firestore.collection('users').doc(doctor['id']).update({
            'patientsAssigned': patientsAssigned,
          });
        }
      }

      await _firestore.collection('doctorPatientDetails').doc(patientId).set({
        'patientId': patientId,
        'doctorId': doctor['id'],
        'patientDetails': patientDetails,
        'assignedDate': FieldValue.serverTimestamp(),
      });

      setState(() {
        selectedDoctor = doctor['name'];
        selectedDoctorId = doctor['id'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Doctor Successfully Assigned"),
        ),
      );
    } catch (e) {
      debugPrint("Error assigning doctor: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to Assign Doctor"),
        ),
      );
    }
  }

  void showDoctorSelectionDialog() async {
    List<Map<String, dynamic>> doctors = await fetchVerifiedDoctors();

    if (doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No verified doctors available"))
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Doctor'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(doctors[index]['name']),
                subtitle: Text(doctors[index]['specialisation']),
                onTap: () {
                  Navigator.pop(context);
                  assignDoctor(doctors[index]);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void updateSummary() async {
    try {
      await _firestore.collection('Appointments').doc(widget.patientData['id'].toString()).update({
        'patientSummary': _summaryController.text,
      });

      if (selectedDoctorId != null) {
        await _firestore.collection('doctorPatientDetails').doc(widget.patientData['id'].toString()).update({
          'patientDetails.summary': _summaryController.text,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Summary Updated"),
        ),
      );
    } catch (e) {
      debugPrint("Error updating summary: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to Update Summary"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {/* Print functionality */},
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {/* Share functionality */},
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Side navigation
          Container(
            width: 200,
            color: Colors.grey[200],
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: Text(
                          widget.patientData['name']?.toString().substring(0, 1).toUpperCase() ?? 'P',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.patientData['name']?.toString() ?? 'Patient Name',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.patientData['email']?.toString() ?? 'No Email',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  selected: true,
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Overview'),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Statistics'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) =>
                      StatisticsPage(patientId: widget.patientData['id']?.toString() ?? ''))),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Reports'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) =>
                      AllReportsPage(patientId: widget.patientData['id']?.toString() ?? ''))),
                ),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Payments'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) =>
                      PaymentsPage(patientId: widget.patientData['id']?.toString() ?? ''))),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('History'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) =>
                      HistoryPage(patientId: widget.patientData['id']?.toString() ?? ''))),
                ),
                const Divider(),
                // AI Assistant Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AIPage(patientData: widget.patientData),
                        ),
                      );
                    },
                    icon: const Icon(Icons.psychology),
                    label: const Text('AI Assistant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        hasJoinedCall = !hasJoinedCall;
                      });
                    },
                    child: Text(hasJoinedCall ? 'End Call' : 'Join Call'),
                  ),
                ),
              ],
            ),
          ),

          // Main content section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status cards
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Patient Status', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: Text('ID: ${widget.patientData['id']?.toString() ?? 'N/A'}')),
                              Expanded(child: Text('Next Appt: ${widget.patientData['appointmentDate']?.toString() ?? 'N/A'}')),
                              Expanded(child: Text('Doctor: ${selectedDoctor ?? 'Not Assigned'}')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Personal info
                  const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow('Age', widget.patientData['patientAge']?.toString() ?? 'N/A'),
                          _buildInfoRow('Gender', widget.patientData['gender']?.toString() ?? 'N/A'),
                          _buildInfoRow('Phone', widget.patientData['phone']?.toString() ?? 'N/A'),
                          _buildInfoRow('Location', widget.patientData['location']?.toString() ?? 'N/A'),
                          _buildInfoRow('User ID', widget.patientData['userId']?.toString() ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Appointment details
                  const Text('Appointment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow('Date', widget.patientData['appointmentDate']?.toString() ?? 'N/A'),
                          _buildInfoRow('Time', widget.patientData['appointmentTime']?.toString() ?? 'N/A'),
                          _buildInfoRow('Time Zone', widget.patientData['timeZone']?.toString() ?? 'N/A'),
                          _buildInfoRow('Preferred Doctor', widget.patientData['preferredDoctor']?.toString() ?? 'N/A'),
                          _buildInfoRow('Preferred Language', widget.patientData['preferredLanguage']?.toString() ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Medical info
                  const Text('Medical Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Condition', style: TextStyle(fontWeight: FontWeight.bold)),
                          _buildInfoRow('Condition', widget.patientData['condition']?.toString() ?? 'N/A'),
                          _buildInfoRow('Details', widget.patientData['specifyCondition']?.toString() ?? 'N/A'),
                          _buildInfoRow('Severity', widget.patientData['severity']?.toString() ?? 'Medium'),

                          const Divider(),
                          const Text('Treatment History', style: TextStyle(fontWeight: FontWeight.bold)),
                          _buildInfoRow('Current Treatment', widget.patientData['currentTreatment'] == true ? 'Yes' : 'No'),
                          _buildInfoRow('Details', widget.patientData['treatmentDetails']?.toString() ?? 'N/A'),
                          _buildInfoRow('Previous Diagnosis', widget.patientData['previousDiagnosis'] == true ? 'Yes' : 'No'),
                          _buildInfoRow('Details', widget.patientData['diagnosisDetails']?.toString() ?? 'N/A'),
                          _buildInfoRow('Previous Surgeries', widget.patientData['previousSurgeries'] == true ? 'Yes' : 'No'),
                          _buildInfoRow('Details', widget.patientData['surgeriesDetails']?.toString() ?? 'N/A'),

                          const Divider(),
                          const Text('Symptoms & Allergies', style: TextStyle(fontWeight: FontWeight.bold)),
                          _buildInfoRow('Worsening Symptoms', widget.patientData['worseningSymptoms'] == true ? 'Yes' : 'No'),
                          _buildInfoRow('Description', widget.patientData['symptomsDescription']?.toString() ?? 'N/A'),
                          _buildInfoRow('Allergies', widget.patientData['allergies']?.toString() ?? 'None reported'),
                          _buildInfoRow('Medications', widget.patientData['medications']?.toString() ?? 'None reported'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Patient summary
                  const Text('Patient Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _summaryController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: 'Enter detailed notes about the patient...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _summaryController.clear();
                                },
                                child: const Text('Clear'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: updateSummary,
                                child: const Text('Save Summary'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Doctor assignment
                  const Text('Assign Doctor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Current Doctor: ${selectedDoctor ?? 'Not Assigned'}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: showDoctorSelectionDialog,
                                child: const Text('Assign Doctor'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}