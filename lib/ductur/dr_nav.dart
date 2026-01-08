import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'verify_doctors.dart';
import 'dr_profile.dart';
import '../admin/patient_profile_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class DrNavPage extends StatefulWidget {
  @override
  _DrNavPageState createState() => _DrNavPageState();
}

class _DrNavPageState extends State<DrNavPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> verifiedDoctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];
  Map<String, List<Map<String, dynamic>>> doctorPatients = {};

  bool isLoading = true;
  String searchQuery = '';
  String filterSpecialization = 'All';
  String filterCountry = 'All';
  String sortBy = 'Name';

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // For dropdown filters
  List<String> specializations = ['All'];
  List<String> countries = ['All'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchVerifiedDoctors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
      Map<String, List<Map<String, dynamic>>> tempDoctorPatients = {};
      Set<String> tempSpecializations = {'All'};
      Set<String> tempCountries = {'All'};

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String doctorId = doc.id;
        data['id'] = doctorId; // Store the document ID

        // Add default values if missing
        data['rating'] = data['rating'] ?? 0.0;
        data['country'] = data['country'] ?? 'Unknown';
        data['drSpecialization'] = data['drSpecialization'] ?? 'General';

        // Collect unique specializations and countries for filters
        if (data['drSpecialization'] != null) {
          tempSpecializations.add(data['drSpecialization']);
        }
        if (data['country'] != null) {
          tempCountries.add(data['country']);
        }

        // Fetch assigned patients for each doctor
        List<dynamic> patientIds = data['patientsAssigned'] ?? [];
        List<Map<String, dynamic>> patientsList = [];

        if (patientIds.isNotEmpty) {
          for (String patientId in List<String>.from(patientIds)) {
            try {
              // Fetch from doctorPatientDetails for complete information
              DocumentSnapshot patientDetailDoc = await _firestore
                  .collection('doctorPatientDetails')
                  .doc(patientId)
                  .get();

              if (patientDetailDoc.exists) {
                Map<String, dynamic> patientData = patientDetailDoc.data() as Map<String, dynamic>;

                // Extract patient details
                Map<String, dynamic> patientDetails = patientData['patientDetails'] ?? {};
                patientDetails['id'] = patientId; // Add the patient ID
                patientDetails['assignedDate'] = patientData['assignedDate'];

                patientsList.add(patientDetails);
              } else {
                // Fallback to Appointments collection if not found
                DocumentSnapshot appointmentDoc = await _firestore
                    .collection('Appointments')
                    .doc(patientId)
                    .get();

                if (appointmentDoc.exists) {
                  Map<String, dynamic> appointmentData = appointmentDoc.data() as Map<String, dynamic>;
                  appointmentData['id'] = patientId;
                  patientsList.add(appointmentData);
                }
              }
            } catch (e) {
              debugPrint("Error fetching patient $patientId: $e");
            }
          }
        }

        tempDoctorPatients[doctorId] = patientsList;
        doctors.add(data);
      }

      setState(() {
        verifiedDoctors = doctors;
        filteredDoctors = doctors;
        doctorPatients = tempDoctorPatients;
        specializations = tempSpecializations.toList()..sort();
        countries = tempCountries.toList()..sort();
        isLoading = false;
      });

      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching verified doctors: $e')),
      );
    }
  }

  void _applyFiltersAndSort() {
    setState(() {
      filteredDoctors = verifiedDoctors.where((doctor) {
        // Apply text search
        bool matchesSearch = searchQuery.isEmpty ||
            (doctor['fullName']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (doctor['drSpecialization']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (doctor['doctorId']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

        // Apply specialization filter
        bool matchesSpecialization = filterSpecialization == 'All' ||
            doctor['drSpecialization'] == filterSpecialization;

        // Apply country filter
        bool matchesCountry = filterCountry == 'All' ||
            doctor['country'] == filterCountry;

        return matchesSearch && matchesSpecialization && matchesCountry;
      }).toList();

      // Apply sorting
      switch (sortBy) {
        case 'Name':
          filteredDoctors.sort((a, b) => (a['fullName'] ?? '').compareTo(b['fullName'] ?? ''));
          break;
        case 'Rating (High to Low)':
          filteredDoctors.sort((a, b) => (b['rating'] ?? 0.0).compareTo(a['rating'] ?? 0.0));
          break;
        case 'Patients (High to Low)':
          filteredDoctors.sort((a, b) {
            int patientsA = doctorPatients[a['id']]?.length ?? 0;
            int patientsB = doctorPatients[b['id']]?.length ?? 0;
            return patientsB.compareTo(patientsA);
          });
          break;
        case 'Most Recent First':
          filteredDoctors.sort((a, b) {
            Timestamp? timestampA = a['verifiedAt'];
            Timestamp? timestampB = b['verifiedAt'];
            if (timestampA == null && timestampB == null) return 0;
            if (timestampA == null) return 1;
            if (timestampB == null) return -1;
            return timestampB.compareTo(timestampA);
          });
          break;
      }
    });
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  void _openDoctorProfile(String doctorId) {
    // Pass the doctor's patients to the profile page
    List<Map<String, dynamic>> patients = doctorPatients[doctorId] ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrProfilePage(
          doctorId: doctorId,
          assignedPatients: patients,
        ),
      ),
    ).then((_) => fetchVerifiedDoctors()); // Refresh when returning
  }

  void _viewPatientProfile(Map<String, dynamic> patientData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientProfilePage(patientData: patientData),
      ),
    ).then((_) => fetchVerifiedDoctors()); // Refresh when returning
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Text Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search doctors by name, specialization, ID...',
              prefixIcon: Icon(Icons.search, color: MedicalColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: MedicalColors.primary.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: MedicalColors.primary),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
                _applyFiltersAndSort();
              });
            },
          ),
          SizedBox(height: 12),

          // Filter and Sort Row
          Row(
            children: [
              // Specialization Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Specialization',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: filterSpecialization,
                  items: specializations.map((spec) {
                    return DropdownMenuItem(
                      value: spec,
                      child: Text(spec, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      filterSpecialization = value!;
                      _applyFiltersAndSort();
                    });
                  },
                ),
              ),
              SizedBox(width: 8),

              // Country Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Country',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: filterCountry,
                  items: countries.map((country) {
                    return DropdownMenuItem(
                      value: country,
                      child: Text(country, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      filterCountry = value!;
                      _applyFiltersAndSort();
                    });
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Sort Row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: sortBy,
                  items: [
                    'Name',
                    'Rating (High to Low)',
                    'Patients (High to Low)',
                    'Most Recent First',
                  ].map((sort) {
                    return DropdownMenuItem(
                      value: sort,
                      child: Text(sort),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      sortBy = value!;
                      _applyFiltersAndSort();
                    });
                  },
                ),
              ),

              SizedBox(width: 8),

              // Reset button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedicalColors.secondary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    searchQuery = '';
                    filterSpecialization = 'All';
                    filterCountry = 'All';
                    sortBy = 'Name';
                    _applyFiltersAndSort();
                  });
                },
                icon: Icon(Icons.refresh, size: 16),
                label: Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final String doctorId = doctor['id'];
    final List<Map<String, dynamic>> patients = doctorPatients[doctorId] ?? [];
    final double rating = (doctor['rating'] is double)
        ? doctor['rating']
        : ((doctor['rating'] is int) ? doctor['rating'].toDouble() : 0.0);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: MedicalColors.primaryLight,
          child: Icon(Icons.person, color: Colors.white),
          radius: 24,
        ),
        title: Text(
          doctor['fullName'] ?? 'Unknown',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, size: 14, color: MedicalColors.primary),
                SizedBox(width: 4),
                Expanded(
                  child: Text(doctor['drSpecialization'] ?? 'Unknown Specialization',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(doctor['country'] ?? 'Unknown', style: TextStyle(fontSize: 12)),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                RatingBarIndicator(
                  rating: rating,
                  itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 14.0,
                ),
                SizedBox(width: 4),
                Text(
                  '(${rating.toStringAsFixed(1)})',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Verified: ${doctor['verifiedAt'] != null ? formatDate(doctor['verifiedAt']) : 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.people, size: 12, color: MedicalColors.secondary),
                    SizedBox(width: 4),
                    Text(
                      '${patients.length} patients',
                      style: TextStyle(fontSize: 12, color: MedicalColors.secondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.visibility, color: MedicalColors.primary),
          onPressed: () => _openDoctorProfile(doctorId),
          tooltip: 'View Doctor Details',
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Divider(),
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Assigned Patients',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: MedicalColors.primary,
              ),
            ),
          ),
          patients.isEmpty
              ? Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: Text(
                'No patients assigned to this doctor.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: patients.length > 3 ? 3 : patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: MedicalColors.secondaryLight,
                  child: Text(
                    (patient['name'] ?? 'UN')[0],
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(patient['name'] ?? 'Unknown Patient'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Age: ${patient['patientAge'] ?? 'N/A'} | ${patient['gender'] ?? 'N/A'}'),
                    Text(
                      'Condition: ${patient['condition'] ?? 'N/A'} (${patient['severity'] ?? 'N/A'})',
                      style: TextStyle(
                        color: patient['severity'] == 'High'
                            ? Colors.red
                            : patient['severity'] == 'Medium'
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () => _viewPatientProfile(patient),
                ),
                dense: true,
              );
            },
          ),
          if (patients.length > 3)
            TextButton(
              child: Text(
                'View all ${patients.length} patients',
                style: TextStyle(color: MedicalColors.secondary),
              ),
              onPressed: () => _openDoctorProfile(doctorId),
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorList() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: MedicalColors.primary),
            SizedBox(height: 16),
            Text('Loading doctors...'),
          ],
        ),
      );
    }

    if (filteredDoctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              searchQuery.isEmpty && filterSpecialization == 'All' && filterCountry == 'All'
                  ? 'No verified doctors found'
                  : 'No doctors match your search criteria',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredDoctors.length,
      padding: EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        return _buildDoctorCard(filteredDoctors[index]);
      },
    );
  }

  Widget _buildStatistics() {
    // Calculate statistics
    int totalDoctors = verifiedDoctors.length;
    Map<String, int> doctorsBySpecialization = {};
    Map<String, int> doctorsByCountry = {};
    int totalPatients = 0;
    double averageRating = 0;

    for (var doctor in verifiedDoctors) {
      // Count by specialization
      String spec = doctor['drSpecialization'] ?? 'Unknown';
      doctorsBySpecialization[spec] = (doctorsBySpecialization[spec] ?? 0) + 1;

      // Count by country
      String country = doctor['country'] ?? 'Unknown';
      doctorsByCountry[country] = (doctorsByCountry[country] ?? 0) + 1;

      // Sum patients
      String doctorId = doctor['id'];
      totalPatients += doctorPatients[doctorId]?.length ?? 0;

      // Sum ratings
      averageRating += (doctor['rating'] is num) ? doctor['rating'] : 0;
    }

    // Calculate average rating
    averageRating = totalDoctors > 0 ? averageRating / totalDoctors : 0;

    // Sort specializations and countries by count
    List<MapEntry<String, int>> sortedSpecs = doctorsBySpecialization.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<MapEntry<String, int>> sortedCountries = doctorsByCountry.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              _buildStatCard(
                'Total Doctors',
                totalDoctors.toString(),
                Icons.person,
                MedicalColors.primary,
              ),
              SizedBox(width: 12),
              _buildStatCard(
                'Total Patients',
                totalPatients.toString(),
                Icons.people,
                MedicalColors.secondary,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'Average Rating',
                averageRating.toStringAsFixed(1),
                Icons.star,
                Colors.amber,
              ),
              SizedBox(width: 12),
              _buildStatCard(
                'Avg Patients/Doctor',
                totalDoctors > 0 ? (totalPatients / totalDoctors).toStringAsFixed(1) : '0',
                Icons.pie_chart,
                Colors.purple,
              ),
            ],
          ),

          SizedBox(height: 24),

          // Top Specializations
          Text(
            'Top Specializations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MedicalColors.primary,
            ),
          ),
          SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: sortedSpecs.take(5).map((entry) {
                  double percentage = totalDoctors > 0 ? entry.value / totalDoctors * 100 : 0;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(entry.key),
                        ),
                        Expanded(
                          flex: 7,
                          child: Stack(
                            children: [
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage / 100,
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: MedicalColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          SizedBox(height: 24),

          // Top Countries
          Text(
            'Doctors by Country',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MedicalColors.primary,
            ),
          ),
          SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: sortedCountries.take(5).map((entry) {
                  double percentage = totalDoctors > 0 ? entry.value / totalDoctors * 100 : 0;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(entry.key),
                        ),
                        Expanded(
                          flex: 7,
                          child: Stack(
                            children: [
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage / 100,
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: MedicalColors.secondaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Management'),
        backgroundColor: MedicalColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchVerifiedDoctors,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Doctors List', icon: Icon(Icons.people)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: MedicalColors.primary.withOpacity(0.05),
            padding: EdgeInsets.all(16),
            child: _buildSearchBar(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDoctorList(),
                _buildStatistics(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MedicalColors.secondary,
        child: Icon(Icons.verified_user),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyDoctorsPage(),
            ),
          ).then((_) {
            // Refresh doctor list when returning from VerifyDoctorsPage
            fetchVerifiedDoctors();
          });
        },
        tooltip: 'Verify Doctors',
      ),
    );
  }
}
class MedicalColors {
  static const Color primary = Color(0xFF0D47A1);      // Dark Blue
  static const Color primaryLight = Color(0xFF5472D3);
  static const Color secondary = Color(0xFF00796B);    // Teal
  static const Color secondaryLight = Color(0xFF48A999);
  static const Color accent = Color(0xFFEC407A);       // Pink
  static const Color background = Color(0xFFF5F5F5);   // Light Grey
  static const Color surface = Color(0xFFFFFFFF);      // White
  static const Color error = Color(0xFFB71C1C);        // Dark Red
  static const Color success = Color(0xFF43A047);      // Green
  static const Color warning = Color(0xFFFFA000);      // Amber
}