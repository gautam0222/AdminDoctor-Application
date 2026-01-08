import 'package:flutter/material.dart';

class PaymentsPage extends StatelessWidget {
  final List<Map<String, dynamic>> paymentHistory = [
    {"date": "2025-03-20", "amount": 1500, "patient": "John Doe"},
    {"date": "2025-03-18", "amount": 2000, "patient": "Mary Smith"},
    {"date": "2025-03-15", "amount": 1800, "patient": "Alex Johnson"},
    {"date": "2025-03-10", "amount": 2500, "patient": "Emma Brown"},
    {"date": "2025-03-08", "amount": 3000, "patient": "Michael Davis"},
    {"date": "2025-03-05", "amount": 1600, "patient": "Sophia Wilson"},
    {"date": "2025-03-02", "amount": 1400, "patient": "James Anderson"},
    {"date": "2025-02-28", "amount": 1900, "patient": "Isabella Martinez"},
  ];

  @override
  Widget build(BuildContext context) {
    int totalEarnings = paymentHistory.fold(0, (sum, item) => sum + (item['amount'] as int));

    return Scaffold(
      appBar: AppBar(title: Text("Payments Received")),
      body: Column(
        children: [
          // Total Payments Summary
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Text(
              "Total Earnings: ₹$totalEarnings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: paymentHistory.length,
              itemBuilder: (context, index) {
                var payment = paymentHistory[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text("Patient: ${payment["patient"]}", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Date: ${payment['date']}"),
                    trailing: Text("₹${payment['amount']}", style: TextStyle(color: Colors.green, fontSize: 16)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
