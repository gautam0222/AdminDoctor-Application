import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VerifiedDoctorsPage extends StatefulWidget {
  @override
  _VerifiedDoctorsPageState createState() => _VerifiedDoctorsPageState();
}

class _VerifiedDoctorsPageState extends State<VerifiedDoctorsPage> {
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

  String formatDate(Timestamp timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verified Doctors'),
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
            child: ExpansionTile(
              title: Text(doctor['fullName'] ?? 'Unknown'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor['drSpecialization'] ?? 'Unknown Specialization'),
                  Text(
                    'Verified on: ${doctor['verifiedAt'] != null ? formatDate(doctor['verifiedAt']) : 'N/A'}',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Email', doctor['email']),
                      _infoRow('Phone', doctor['phoneNumber']),
                      _infoRow('Gender', doctor['gender']),
                      _infoRow('License No', doctor['medicalLicenseNo']),
                      _infoRow('DOB', doctor['dateOfBirth'] != null
                          ? formatDate(doctor['dateOfBirth'])
                          : 'N/A'),
                      _infoRow('Address', doctor['address']),
                      _infoRow('Country', doctor['country']),
                    ],
                  ),
                ),
              ],
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