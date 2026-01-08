import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AIPage extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const AIPage({Key? key, required this.patientData}) : super(key: key);

  @override
  _AIPageState createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  int _selectedFeatureIndex = 0;

  final List<Map<String, dynamic>> _aiFeatures = [
    {
      'title': 'Medical Image Analysis',
      'icon': Icons.image_search,
      'description': 'Analyze X-rays, MRIs, CT scans, and other medical images',
      'color': Colors.blue,
    },
    {
      'title': 'Symptom Checker',
      'icon': Icons.medical_services,
      'description': 'Describe symptoms and get possible diagnoses',
      'color': Colors.green,
    },
    {
      'title': 'Treatment Advisor',
      'icon': Icons.healing,
      'description': 'Get treatment recommendations and care plans',
      'color': Colors.orange,
    },
    {
      'title': 'Drug Interaction Checker',
      'icon': Icons.medication,
      'description': 'Check for potential drug interactions',
      'color': Colors.red,
    },
    {
      'title': 'Medical Report Summarizer',
      'icon': Icons.summarize,
      'description': 'Summarize lengthy medical reports',
      'color': Colors.purple,
    },
    {
      'title': 'Diagnosis Explainer',
      'icon': Icons.info_outline,
      'description': 'Explain medical diagnoses in simple terms',
      'color': Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Medical Assistant'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Row(
        children: [
          // Sidebar with AI features
          Container(
            width: 280,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade700,
                  child: Column(
                    children: [
                      Icon(Icons.psychology, size: 48, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        'AI Features',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient: ${widget.patientData['name'] ?? 'N/A'}',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _aiFeatures.length,
                    itemBuilder: (context, index) {
                      final feature = _aiFeatures[index];
                      final isSelected = _selectedFeatureIndex == index;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? feature['color'].withOpacity(0.1) : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: feature['color'], width: 2)
                              : null,
                        ),
                        child: ListTile(
                          leading: Icon(
                            feature['icon'],
                            color: isSelected ? feature['color'] : Colors.grey.shade600,
                          ),
                          title: Text(
                            feature['title'],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            feature['description'],
                            style: TextStyle(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedFeatureIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: _buildFeatureContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureContent() {
    switch (_selectedFeatureIndex) {
      case 0:
        return MedicalImageAnalyzer();
      case 1:
        return SymptomChecker();
      case 2:
        return TreatmentAdvisor();
      case 3:
        return DrugInteractionChecker();
      case 4:
        return MedicalReportSummarizer();
      case 5:
        return DiagnosisExplainer();
      default:
        return Center(child: Text('Feature not available'));
    }
  }
}

// 1. Medical Image Analysis Feature
class MedicalImageAnalyzer extends StatefulWidget {
  @override
  _MedicalImageAnalyzerState createState() => _MedicalImageAnalyzerState();
}

class _MedicalImageAnalyzerState extends State<MedicalImageAnalyzer> {
  File? _selectedImage;
  Uint8List? _webImage;
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _selectedImage = null;
          _result = null;
        });
      } else {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _webImage = null;
          _result = null;
        });
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null && _webImage == null) return;
    setState(() => _loading = true);

    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _result = {"error": "API key not found. Please check your .env file."};
        });
        setState(() => _loading = false);
        return;
      }

      debugPrint("API Key loaded: ${apiKey.substring(0, 10)}...");

      Uint8List bytes;
      if (kIsWeb) {
        bytes = _webImage!;
      } else {
        bytes = await _selectedImage!.readAsBytes();
      }

      final base64Image = base64Encode(bytes);
      final models = [
        "google/gemini-2.0-flash-exp:free"
      ];

      bool success = false;
      for (String modelId in models) {
        try {
          final payload = {
            "model": modelId,
            "messages": [
              {
                "role": "user",
                "content": [
                  {
                    "type": "text",
                    "text": """Analyze this medical image and provide:

1. **Image Type**: Identify the type of scan
2. **Primary Observations**: What you see in the image
3. **Possible Diagnoses** (2-3 options):
   - Most likely diagnosis with confidence
   - Alternative diagnoses
   - Reasoning for each
4. **Key Findings**: Abnormalities or areas of concern
5. **Recommendations**: Follow-up tests or consultations
6. **Disclaimer**: Note this is AI analysis requiring professional verification"""
                  },
                  {
                    "type": "image_url",
                    "image_url": {"url": "data:image/png;base64,$base64Image"}
                  }
                ]
              }
            ],
            "temperature": 0.3,
            "max_tokens": 1200
          };

          final response = await http.post(
            Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
            headers: {
              "Authorization": "Bearer $apiKey",
              "Content-Type": "application/json",
              "HTTP-Referer": "https://yourapp.com",
              "X-Title": "Medical AI Assistant",
            },
            body: jsonEncode(payload),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            setState(() {
              _result = {
                "analysis": data['choices'][0]['message']['content'],
                "model": modelId
              };
            });
            success = true;
            break;
          } else {
            debugPrint("Model $modelId failed with status: ${response.statusCode}");
            debugPrint("Response: ${response.body}");
          }
        } catch (e) {
          debugPrint("Model $modelId failed: $e");
        }
      }

      if (!success) {
        setState(() {
          _result = {"error": "Analysis failed. Please try again."};
        });
      }
    } catch (e) {
      setState(() {
        _result = {"error": e.toString()};
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medical Image Analysis',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload and analyze X-rays, MRIs, CT scans, and other medical images',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(width: 12),
              if (_selectedImage != null || _webImage != null)
                ElevatedButton.icon(
                  onPressed: _loading ? null : _analyzeImage,
                  icon: _loading
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.analytics),
                  label: Text(_loading ? 'Analyzing...' : 'Analyze Image'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_selectedImage != null || _webImage != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selected Image:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.memory(_webImage!, fit: BoxFit.contain)
                            : Image.file(_selectedImage!, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_information, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Analysis Results',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (_result!.containsKey('model'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Model: ${_result!['model']}',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    const Divider(),
                    if (_result!.containsKey('error'))
                      Text(_result!['error'],
                          style: TextStyle(color: Colors.red))
                    else
                      SelectableText(
                        _result!['analysis'],
                        style: TextStyle(fontSize: 14, height: 1.6),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 2. Symptom Checker Feature
class SymptomChecker extends StatefulWidget {
  @override
  _SymptomCheckerState createState() => _SymptomCheckerState();
}

class _SymptomCheckerState extends State<SymptomChecker> {
  final TextEditingController _symptomsController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _checkSymptoms() async {
    if (_symptomsController.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _result = {"error": "API key not found. Please check your .env file."};
        });
        setState(() => _loading = false);
        return;
      }

      debugPrint("Checking symptoms with API...");

      final payload = {
        "model": "google/gemini-2.0-flash-exp:free",
        "messages": [
          {
            "role": "user",
            "content": """Based on these symptoms: ${_symptomsController.text}

Provide a comprehensive analysis:
1. **Symptom Summary**: Brief overview
2. **Possible Conditions** (3-4 options ranked by likelihood)
3. **Severity Assessment**: Urgent, moderate, or mild
4. **Recommended Actions**: When to seek care
5. **Home Care Tips**: If applicable
6. **Warning Signs**: When to seek immediate help

IMPORTANT: Add disclaimer that this is not a diagnosis and professional medical consultation is required."""
          }
        ],
        "temperature": 0.4,
        "max_tokens": 1000
      };

      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "https://yourapp.com",
          "X-Title": "Medical AI Assistant",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = {"analysis": data['choices'][0]['message']['content']};
        });
      } else {
        debugPrint("API Error: ${response.statusCode}");
        debugPrint("Response: ${response.body}");
        setState(() => _result = {"error": "Failed to analyze symptoms. Status: ${response.statusCode}"});
      }
    } catch (e) {
      debugPrint("Exception in _checkSymptoms: $e");
      setState(() => _result = {"error": e.toString()});
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Symptom Checker',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Describe your symptoms in detail',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _symptomsController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText:
                      'Example: I have a persistent headache for 3 days, fever of 101°F, and body aches...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _checkSymptoms,
                      icon: _loading
                          ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.search),
                      label: Text(_loading ? 'Analyzing...' : 'Check Symptoms'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('Analysis Results',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    if (_result!.containsKey('error'))
                      Text(_result!['error'],
                          style: TextStyle(color: Colors.red))
                    else
                      SelectableText(_result!['analysis'],
                          style: TextStyle(fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 3. Treatment Advisor
class TreatmentAdvisor extends StatefulWidget {
  @override
  _TreatmentAdvisorState createState() => _TreatmentAdvisorState();
}

class _TreatmentAdvisorState extends State<TreatmentAdvisor> {
  final TextEditingController _conditionController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _getTreatmentAdvice() async {
    if (_conditionController.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _result = {"error": "API key not found. Please check your .env file."};
        });
        setState(() => _loading = false);
        return;
      }

      final payload = {
        "model": "google/gemini-2.0-flash-exp:free",
        "messages": [
          {
            "role": "user",
            "content": """Provide comprehensive treatment guidance for: ${_conditionController.text}

Include:
1. **Treatment Overview**: Standard approaches
2. **Medication Options**: Common prescriptions
3. **Lifestyle Modifications**: Diet, exercise, habits
4. **Alternative Therapies**: Complementary options
5. **Recovery Timeline**: Expected duration
6. **Follow-up Care**: Monitoring requirements
7. **Prevention Tips**: Avoiding recurrence

Add disclaimer about consulting healthcare providers."""
          }
        ],
        "temperature": 0.4,
        "max_tokens": 1200
      };

      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = {"analysis": data['choices'][0]['message']['content']};
        });
      } else {
        debugPrint("API Error: ${response.statusCode}");
        debugPrint("Response: ${response.body}");
        setState(() => _result = {"error": "Failed to get treatment advice. Status: ${response.statusCode}"});
      }
    } catch (e) {
      debugPrint("Exception in _getTreatmentAdvice: $e");
      setState(() => _result = {"error": e.toString()});
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Treatment Advisor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Get treatment recommendations for medical conditions',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _conditionController,
                    decoration: InputDecoration(
                      labelText: 'Enter condition or diagnosis',
                      hintText: 'Example: Type 2 Diabetes, Hypertension...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _getTreatmentAdvice,
                      icon: _loading
                          ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.healing),
                      label:
                      Text(_loading ? 'Processing...' : 'Get Treatment Plan'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.healing, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('Treatment Recommendations',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    if (_result!.containsKey('error'))
                      Text(_result!['error'],
                          style: TextStyle(color: Colors.red))
                    else
                      SelectableText(_result!['analysis'],
                          style: TextStyle(fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 4. Drug Interaction Checker
class DrugInteractionChecker extends StatefulWidget {
  @override
  _DrugInteractionCheckerState createState() =>
      _DrugInteractionCheckerState();
}

class _DrugInteractionCheckerState extends State<DrugInteractionChecker> {
  final TextEditingController _drugsController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _checkInteractions() async {
    if (_drugsController.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _result = {"error": "API key not found. Please check your .env file."};
        });
        setState(() => _loading = false);
        return;
      }

      final payload = {
        "model": "google/gemini-2.0-flash-exp:free",
        "messages": [
          {
            "role": "user",
            "content": """Analyze drug interactions for: ${_drugsController.text}

Provide:
1. **Interaction Summary**: Overview of concerns
2. **Major Interactions**: Serious combinations to avoid
3. **Moderate Interactions**: Caution required
4. **Minor Interactions**: Low-risk combinations
5. **Timing Recommendations**: When to take each medication
6. **Food Interactions**: Dietary considerations
7. **Side Effects**: Common adverse reactions
8. **Safety Tips**: How to minimize risks

Include disclaimer about consulting pharmacist/doctor."""
          }
        ],
        "temperature": 0.3,
        "max_tokens": 1100
      };

      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = {"analysis": data['choices'][0]['message']['content']};
        });
      } else {
        debugPrint("API Error: ${response.statusCode}");
        debugPrint("Response: ${response.body}");
        setState(() =>
        _result = {"error": "Failed to check drug interactions. Status: ${response.statusCode}"});
      }
    } catch (e) {
      debugPrint("Exception in _checkInteractions: $e");
      setState(() => _result = {"error": e.toString()});
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Drug Interaction Checker',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Check for potential drug interactions',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _drugsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Enter medications',
                      hintText:
                      'Example: Aspirin, Warfarin, Lisinopril\n(Separate with commas)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _checkInteractions,
                      icon: _loading
                          ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.warning),
                      label: Text(
                          _loading ? 'Checking...' : 'Check Interactions'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medication, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Interaction Analysis',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    if (_result!.containsKey('error'))
                      Text(_result!['error'],
                          style: TextStyle(color: Colors.red))
                    else
                      SelectableText(_result!['analysis'],
                          style: TextStyle(fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 5. Medical Report Summarizer
class MedicalReportSummarizer extends StatefulWidget {
  @override
  _MedicalReportSummarizerState createState() =>
      _MedicalReportSummarizerState();
}

class _MedicalReportSummarizerState extends State<MedicalReportSummarizer> {
  final TextEditingController _reportController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _summarizeReport() async {
    if (_reportController.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _result = {"error": "API key not found. Please check your .env file."};
        });
        setState(() => _loading = false);
        return;
      }

      final payload = {
        "model": "google/gemini-2.0-flash-exp:free",
        "messages": [
          {
            "role": "user",
            "content": """Summarize this medical report concisely:

${_reportController.text}

Provide:
1. **Key Findings**: Main results/observations
2. **Diagnosis**: Primary and secondary diagnoses
3. **Critical Values**: Abnormal test results
4. **Recommendations**: Suggested actions
5. **Follow-up**: Required next steps
6. **Plain Language Summary**: Explanation for patients"""
          }
        ],
        "temperature": 0.3,
        "max_tokens": 900
      };

      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = {"analysis": data['choices'][0]['message']['content']};
        });
      } else {
        debugPrint("API Error: ${response.statusCode}");
        debugPrint("Response: ${response.body}");
        setState(() => _result = {"error": "Failed to summarize report. Status: ${response.statusCode}"});
      }
    } catch (e) {
      debugPrint("Exception in _summarizeReport: $e");
      setState(() => _result = {"error": e.toString()});
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Medical Report Summarizer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Paste lengthy medical reports for quick summaries',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _reportController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: 'Paste medical report here',
                      hintText:
                      'Paste the full text of lab results, imaging reports, discharge summaries, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _summarizeReport,
                      icon: _loading
                          ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.summarize),
                      label: Text(_loading ? 'Summarizing...' : 'Summarize Report'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.summarize, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text('Report Summary',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    if (_result!.containsKey('error'))
                      Text(_result!['error'],
                          style: TextStyle(color: Colors.red))
                    else
                      SelectableText(_result!['analysis'],
                          style: TextStyle(fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 6. Diagnosis Explainer
class DiagnosisExplainer extends StatefulWidget {
  @override
  _DiagnosisExplainerState createState() => _DiagnosisExplainerState();
}

class _DiagnosisExplainerState extends State<DiagnosisExplainer> {
  final TextEditingController _diagnosisController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _explainDiagnosis() async {
    if (_diagnosisController.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _result = {"error": "API key not found. Please check your .env file."};
        });
        setState(() => _loading = false);
        return;
      }

      final payload = {
        "model": "google/gemini-2.0-flash-exp:free",
        "messages": [
          {
            "role": "user",
            "content": """Explain this medical diagnosis in simple, patient-friendly language: ${_diagnosisController.text}

Provide:
1. **What It Is**: Simple definition without jargon
2. **What Causes It**: Common causes and risk factors
3. **How It Affects You**: Impact on daily life
4. **Common Symptoms**: What patients typically experience
5. **Treatment Options**: Available therapies explained simply
6. **Prognosis**: What to expect long-term
7. **Living With It**: Practical lifestyle tips
8. **Questions to Ask Your Doctor**: Important topics to discuss

Use everyday language that anyone can understand."""
          }
        ],
        "temperature": 0.4,
        "max_tokens": 1100
      };

      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = {"analysis": data['choices'][0]['message']['content']};
        });
      } else {
        debugPrint("API Error: ${response.statusCode}");
        debugPrint("Response: ${response.body}");
        setState(() => _result = {"error": "Failed to explain diagnosis. Status: ${response.statusCode}"});
      }
    } catch (e) {
      debugPrint("Exception in _explainDiagnosis: $e");
      setState(() => _result = {"error": e.toString()});
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagnosis Explainer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Get simple explanations of medical diagnoses',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _diagnosisController,
                    decoration: InputDecoration(
                      labelText: 'Enter diagnosis or medical term',
                      hintText:
                      'Example: Atrial Fibrillation, Pneumonia, Osteoarthritis...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _explainDiagnosis,
                      icon: _loading
                          ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.info),
                      label: Text(_loading ? 'Explaining...' : 'Explain Diagnosis'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text('Diagnosis Explanation',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    if (_result!.containsKey('error'))
                      Text(_result!['error'],
                          style: TextStyle(color: Colors.red))
                    else
                      SelectableText(_result!['analysis'],
                          style: TextStyle(fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}