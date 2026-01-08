import 'package:flutter/material.dart';

class AllReportsPage extends StatelessWidget {
  final List<Map<String, dynamic>> reports = [
    {"patient": "John Doe", "operation": "Knee Replacement", "date": "2025-02-10", "status": "Successful"},
    {"patient": "Mary Smith", "operation": "Gallbladder Removal", "date": "2025-02-15", "status": "Successful"},
    {"patient": "Alex Johnson", "operation": "Fracture Surgery", "date": "2025-03-01", "status": "Successful"},
    {"patient": "Emma Brown", "operation": "Heart Bypass", "date": "2025-01-25", "status": "Successful"},
    {"patient": "Michael Davis", "operation": "Liver Transplant", "date": "2025-01-20", "status": "Ongoing Recovery"},
    {"patient": "Sophia Wilson", "operation": "Appendectomy", "date": "2025-02-28", "status": "Successful"},
    {"patient": "James Anderson", "operation": "Brain Surgery", "date": "2025-03-05", "status": "Ongoing Recovery"},
    {"patient": "Isabella Martinez", "operation": "Spinal Fusion", "date": "2025-01-10", "status": "Successful"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Final Reports")),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          var report = reports[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text("Patient: ${report["patient"]}", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Operation: ${report['operation']}\nDate: ${report['date']}"),
              trailing: Text(report["status"], style: TextStyle(color: report["status"] == "Successful" ? Colors.green : Colors.orange)),
            ),
          );
        },
      ),
    );
  }
}
