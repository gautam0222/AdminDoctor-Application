import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DrRegistrationPage extends StatefulWidget {
  @override
  _DrRegistrationPageState createState() => _DrRegistrationPageState();
}

class _DrRegistrationPageState extends State<DrRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController govtIdController = TextEditingController();

  void registerDoctor() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('doctors').add({
          'name': nameController.text,
          'specialization': specializationController.text,
          'hospital': hospitalController.text,
          'experience': int.tryParse(experienceController.text) ?? 0, // Convert to int
          'status': 'Pending', // Default status
          'patientsAssigned': [], // Empty list initially
          'revenueEarned': 0, // Default revenue
          'country': countryController.text,
          'govtId': govtIdController.text,
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Doctor registered successfully!")),
        );

        // Clear fields
        nameController.clear();
        specializationController.clear();
        hospitalController.clear();
        experienceController.clear();
        countryController.clear();
        govtIdController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctor Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Doctor Name'),
                validator: (value) => value!.isEmpty ? 'Enter Name' : null,
              ),
              TextFormField(
                controller: specializationController,
                decoration: InputDecoration(labelText: 'Specialization'),
                validator: (value) => value!.isEmpty ? 'Enter Specialization' : null,
              ),
              TextFormField(
                controller: hospitalController,
                decoration: InputDecoration(labelText: 'Hospital Name'),
                validator: (value) => value!.isEmpty ? 'Enter Hospital' : null,
              ),
              TextFormField(
                controller: experienceController,
                decoration: InputDecoration(labelText: 'Experience (Years)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter Experience' : null,
              ),
              TextFormField(
                controller: countryController,
                decoration: InputDecoration(labelText: 'Country'),
                validator: (value) => value!.isEmpty ? 'Enter Country' : null,
              ),
              TextFormField(
                controller: govtIdController,
                decoration: InputDecoration(labelText: 'Government ID'),
                validator: (value) => value!.isEmpty ? 'Enter Govt ID' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerDoctor,
                child: Text('Register Doctor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
