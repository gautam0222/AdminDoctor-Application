import 'package:flutter/material.dart';

class PaymentsPage extends StatelessWidget {
  final String? patientId;

  const PaymentsPage({Key? key, this.patientId}) : super(key: key);

  final List<Map<String, dynamic>> paymentHistory = const [
    {
      'date': '2023-03-15',
      'amount': 150.00,
      'description': 'Consultation Fee',
      'status': 'Paid'
    },
    {
      'date': '2023-02-28',
      'amount': 300.50,
      'description': 'Laboratory Tests',
      'status': 'Paid'
    },
    {
      'date': '2023-02-10',
      'amount': 75.00,
      'description': 'Medication',
      'status': 'Paid'
    },
    {
      'date': '2023-01-20',
      'amount': 200.00,
      'description': 'Follow-up Appointment',
      'status': 'Paid'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patientId != null ? 'Payment History for Patient $patientId' : 'Payment History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildPaymentSummary(),
          Expanded(
            child: ListView.builder(
              itemCount: paymentHistory.length,
              itemBuilder: (context, index) {
                final payment = paymentHistory[index];
                return _buildPaymentCard(payment);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    // Calculate total amount paid
    double totalPaid = paymentHistory.fold(
        0, (sum, payment) => sum + (payment['amount'] as double));

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Amount Paid:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '₹${totalPaid.toStringAsFixed(2)}', // Changed to INR symbol
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.attach_money, color: Colors.white),
        ),
        title: Text('${payment['description']}'),
        subtitle: Text('Date: ${payment['date']}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${payment['amount'].toStringAsFixed(2)}',  // Changed to INR symbol
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              '${payment['status']}',
              style: TextStyle(
                color: payment['status'] == 'Paid' ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}