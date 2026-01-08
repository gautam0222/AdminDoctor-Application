import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AllReportsPage extends StatefulWidget {
  final String? patientId;

  const AllReportsPage({Key? key, this.patientId}) : super(key: key);

  @override
  State<AllReportsPage> createState() => _AllReportsPageState();
}

class _AllReportsPageState extends State<AllReportsPage> {
  List<Map<String, dynamic>> reports = List.generate(
    5,
        (index) => {
      'name': 'Lab Report #$index',
      'description': 'Description of the report goes here. E.g., blood test, X-ray, etc.',
      'isUploaded': false,
    },
  );

  @override
  void initState() {
    super.initState();
    _loadSavedReports();
  }

  Future<void> _loadSavedReports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/reports');

      if (await reportsDir.exists()) {
        final files = await reportsDir.list().where((entity) =>
        entity is File && path.extension(entity.path).toLowerCase() == '.pdf'
        ).toList();

        if (files.isNotEmpty) {
          setState(() {
            for (var fileEntity in files) {
              final file = fileEntity as File;
              final fileName = path.basename(file.path);
              reports.add({
                'name': fileName,
                'description': 'Previously uploaded PDF',
                'isUploaded': true,
                'file': file,
                'filePath': file.path,
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved reports: $e');
    }
  }

  Future<String> _saveFile(File sourceFile, String fileName) async {
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create reports directory if it doesn't exist
      final reportsDir = Directory('${directory.path}/reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      // Create destination path and copy the file
      final destinationPath = '${reportsDir.path}/$fileName';
      final File newFile = await sourceFile.copy(destinationPath);

      return newFile.path;
    } catch (e) {
      debugPrint('Error saving file: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reports'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildUploadButton(context),
            const SizedBox(height: 16),
            Expanded(
              child: reports.isEmpty
                  ? const Center(child: Text('No reports available'))
                  : ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) => _buildReportCard(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.upload_file),
      label: const Text('Upload PDF Report'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () async {
        try {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecting file...')),
          );

          // Use file_picker to select PDF files
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );

          if (result != null && result.files.single.path != null) {
            // Show saving indicator
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saving file...')),
            );

            File sourceFile = File(result.files.single.path!);
            final fileName = result.files.single.name;

            // Save the file to app's documents directory
            final savedFilePath = await _saveFile(sourceFile, fileName);

            // Add the new file to our reports list
            setState(() {
              reports.add({
                'name': fileName,
                'description': 'Uploaded on ${DateTime.now().toString().substring(0, 16)}',
                'isUploaded': true,
                'file': File(savedFilePath),
                'filePath': savedFilePath,
              });
            });

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF uploaded successfully')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading file: $e')),
          );
        }
      },
    );
  }

  Widget _buildReportCard(BuildContext context, int index) {
    final report = reports[index];
    final bool isUploaded = report['isUploaded'] ?? false;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${report['name']} ${widget.patientId != null ? "for Patient ${widget.patientId}" : ""}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report['description'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (isUploaded && report['filePath'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Saved at: ${report['filePath']}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            if (isUploaded)
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.red),
                tooltip: 'Delete',
                onPressed: () {
                  _showDeleteConfirmation(context, index);
                },
              ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              tooltip: 'Download',
              onPressed: () {
                if (isUploaded && report['filePath'] != null) {
                  // Open the file
                  _openFile(report['filePath']);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening report...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openFile(String filePath) async {
    try {
      // For production code, use a plugin like open_file or url_launcher
      // to properly open the PDF file on different platforms
      debugPrint('Opening file: $filePath');
      // This is just a placeholder. In a real app, you'd implement platform-specific file opening
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final report = reports[index];
                // Delete the file if it exists
                if (report['filePath'] != null) {
                  final file = File(report['filePath']);
                  if (await file.exists()) {
                    await file.delete();
                  }
                }

                setState(() {
                  reports.removeAt(index);
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report deleted')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting report: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}