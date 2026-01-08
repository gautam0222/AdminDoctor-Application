import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/home_page.dart';

// Main application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables from .env file
    await dotenv.load(fileName: ".env");
    print('Environment variables loaded successfully');
  } catch (e) {
    print('Error loading environment variables: $e');
  }

  try {
    // Firebase initialization with error handling
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBzE0VmYZZkWhV7ypX2vovTuJmltctq3GQ",
        authDomain: "global-healthcure-56c92.firebaseapp.com",
        databaseURL: "https://global-healthcure-56c92-default-rtdb.firebaseio.com",
        projectId: "global-healthcure-56c92",
        storageBucket: "global-healthcure-56c92.appspot.com",
        messagingSenderId: "554600059294",
        appId: "1:554600059294:web:887b3f0d47d2b06f21068f",
        measurementId: "G-C4QXNSWY4B",
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

// HIPAA Compliance Helper
class HIPAACompliance {
  // Encrypt sensitive data - simplified version that doesn't require cloud functions
  static Map<String, dynamic> encryptData(Map<String, dynamic> data) {
    // Simple transformation (in real implementation, use proper encryption)
    final jsonData = json.encode(data);
    final bytes = utf8.encode(jsonData);
    final encrypted = base64Encode(bytes);

    return {'encryptedData': encrypted};
  }

  // Decrypt sensitive data
  static Map<String, dynamic> decryptData(String encryptedData) {
    try {
      // Simple transformation (in real implementation, use proper decryption)
      final decoded = base64Decode(encryptedData);
      final jsonString = utf8.decode(decoded);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error decrypting data: $e');
      return {};
    }
  }

  // Log access for audit trails (HIPAA requirement)
  static void logAccess(String dataId, String action, String userId) {
    // In a real implementation, this would send data to a secure logging service
    final logEntry = {
      'dataId': dataId,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
    };

    print('HIPAA Access Log: ${json.encode(logEntry)}');

    // In a real app, you would use Firebase Analytics or a similar service
    // FirebaseAnalytics.instance.logEvent(name: 'hipaa_data_access', parameters: logEntry);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HIPAA Compliant Patient Portal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(), // Use const constructor
      debugShowCheckedModeBanner: false,
    );
  }
}