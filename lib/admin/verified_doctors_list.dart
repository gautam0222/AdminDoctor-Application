import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VerifiedDoctorsList extends StatefulWidget {
  final String patientId;
  final Function(Map<String, dynamic>) onDoctorSelected;

  const VerifiedDoctorsList({
    Key? key,
    required this.patientId,
    required this.onDoctorSelected,
  }) : super(key: key);

  @override
  _VerifiedDoctorsListState createState() => _VerifiedDoctorsListState();
}

class _VerifiedDoctorsListState extends State<VerifiedDoctorsList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> verifiedDoctors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVerifiedDoctors();
  }

  Future<void> fetchVerifiedDoctors() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Query doctors where status is "Verified"
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('status', isEqualTo: 'Verified')
          .get();

      List<Map<String, dynamic>> doctors = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Store the document ID
        doctors.add(data);
      }

      setState(() {
        verifiedDoctors = doctors;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching verified doctors: $e')),
      );
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  Future<void> assignDoctor(Map<String, dynamic> doctor) async {
    try {
      // Prepare the doctor data in the format expected by the parent
      Map<String, dynamic> doctorData = {
        'id': doctor['id'],
        'name': doctor['fullName'] ?? 'Unknown',
        'specialisation': doctor['drSpecialization'] ?? 'General',
      };

      // Call the callback to assign doctor
      widget.onDoctorSelected(doctorData);

      // Close the screen
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning doctor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Doctor to Assign'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : verifiedDoctors.isEmpty
          ? Center(child: Text('No verified doctors found'))
          : ListView.builder(
        itemCount: verifiedDoctors.length,
        itemBuilder: (context, index) {
          final doctor = verifiedDoctors[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(doctor['fullName'] ?? 'Unknown'),
              subtitle: Text(doctor['drSpecialization'] ?? 'Unknown Specialization'),
              trailing: ElevatedButton(
                onPressed: () => assignDoctor(doctor),
                child: Text('Assign'),
              ),
              onTap: () {
                // Show dialog with more doctor details
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(doctor['fullName'] ?? 'Unknown'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _infoRow('Specialization', doctor['drSpecialization']),
                            _infoRow('Gender', doctor['gender']),
                            _infoRow('License No', doctor['medicalLicenseNo']),
                            _infoRow('Email', doctor['email']),
                            _infoRow('Phone', doctor['phoneNumber']),
                            _infoRow('Verified On', doctor['verifiedAt'] != null
                                ? formatDate(doctor['verifiedAt'])
                                : 'N/A'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            assignDoctor(doctor);
                          },
                          child: Text('Assign This Doctor'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchVerifiedDoctors,
        child: Icon(Icons.refresh),
        tooltip: 'Refresh',
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}