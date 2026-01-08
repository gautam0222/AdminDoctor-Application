// registration_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for fields that patient_details_page.dart expects
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController conditionController = TextEditingController();
  final TextEditingController specifyConditionController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedSeverity = 'Medium';

  // Function to save form data to Firebase Firestore
  void _saveToFirebase() async {
    if (_formKey.currentState!.validate()) {
      try {
        // **FIX 1: Saving to 'Appointments' collection**
        // **FIX 2: Saving the correct data fields**
        await FirebaseFirestore.instance.collection('Appointments').add({
          // Personal Details
          'fullName': fullNameController.text,
          'age': ageController.text,
          'gender': _selectedGender,
          'phone': phoneController.text,
          'email': emailController.text,
          'country': countryController.text,

          // Medical Details
          'condition': conditionController.text,
          'specifyCondition': specifyConditionController.text,
          'severity': _selectedSeverity,

          // Default/Empty fields that the system expects
          'allergies': 'N/A',
          'medications': 'N/A',
          'chronicConditions': 'N/A',
          'doctorName': 'Not Assigned',
          'doctorId': null,

          // Appointment/System Details
          'appointmentDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'appointmentTime': DateFormat('HH:mm').format(DateTime.now()),
          'timeZone': 'N/A',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': 'admin_registered', // Or logic to get current user ID
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient Registered Successfully in "Appointments"')),
        );

        // Clear all form fields after submission
        _formKey.currentState?.reset();
        fullNameController.clear();
        ageController.clear();
        phoneController.clear();
        emailController.clear();
        countryController.clear();
        conditionController.clear();
        specifyConditionController.clear();

        // Navigate back to home page after submission
        Navigator.pop(context);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register patient: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Registration'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Register New Patient',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              // Form fields
              buildTextField('Full Name', fullNameController, Icons.person),
              buildTextField('Age', ageController, Icons.calendar_today),
              buildDropdown('Gender', _selectedGender, ['Male', 'Female', 'Other'], (val) {
                setState(() => _selectedGender = val ?? 'Male');
              }),
              buildTextField('Phone Number', phoneController, Icons.phone),
              buildTextField('Email', emailController, Icons.email),
              buildTextField('Country / Location', countryController, Icons.location_on),
              buildTextField('Condition', conditionController, Icons.health_and_safety),
              buildTextField('Specify Condition', specifyConditionController, Icons.note),
              buildDropdown('Severity', _selectedSeverity, ['Low', 'Medium', 'High'], (val) {
                setState(() => _selectedSeverity = val ?? 'Medium');
              }),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveToFirebase,
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build form fields
  Widget buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          prefixIcon: Icon(label == 'Gender' ? Icons.wc : Icons.warning_amber_rounded),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}