import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatelessWidget {
  final String patientId;

  const HistoryPage({Key? key, required this.patientId}) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchPatientHistory() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .collection('history')
          .get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching history: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Treatment History")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPatientHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No history found."));
          }

          List<Map<String, dynamic>> patientHistory = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: patientHistory.length,
            itemBuilder: (context, index) {
              var patient = patientHistory[index];
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(patient["name"], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Age: ${patient['age']}, Condition: ${patient['disease']}"),
                  trailing: Text(patient["status"], style: TextStyle(color: Colors.blue)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
