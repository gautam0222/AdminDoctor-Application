import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  final String? patientId;

  const HistoryPage({Key? key, this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          patientId != null ? 'Medical History for Patient $patientId' : 'Medical History',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        foregroundColor: Colors.blueGrey[800],
        centerTitle: true,
      ),
      body: const MedicalHistoryContent(),
    );
  }
}

class MedicalHistoryContent extends StatelessWidget {
  const MedicalHistoryContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'View and manage all medical documents',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 24),

            // X-Ray Section
            MedicalCategoryCard(
              title: 'X-Rays',
              icon: Icons.burst_mode,
              color: const Color(0xFF3498DB),
              count: 2,
              onTap: () => _navigateToCategory(context, 'X-Rays'),
            ),
            const SizedBox(height: 20),

            // CT Scans Section
            MedicalCategoryCard(
              title: 'CT Scans',
              icon: Icons.view_in_ar,
              color: const Color(0xFF9B59B6),
              count: 2,
              onTap: () => _navigateToCategory(context, 'CT Scans'),
            ),
            const SizedBox(height: 20),

            // Lab Reports Section
            MedicalCategoryCard(
              title: 'Lab Reports',
              icon: Icons.science,
              color: const Color(0xFF2ECC71),
              count: 2,
              onTap: () => _navigateToCategory(context, 'Lab Reports'),
            ),
            const SizedBox(height: 20),

            // MRI Scans Section
            MedicalCategoryCard(
              title: 'MRI Scans',
              icon: Icons.panorama_horizontal,
              color: const Color(0xFFE74C3C),
              count: 2,
              onTap: () => _navigateToCategory(context, 'MRI Scans'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCategory(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailPage(category: category),
      ),
    );
  }
}

class MedicalCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const MedicalCategoryCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Category header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count Files',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Preview info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Last updated: ${_getLastUpdatedDate(title)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // View all button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View All Files',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLastUpdatedDate(String category) {
    // In a real app, this would come from your data source
    switch (category) {
      case 'X-Rays':
        return 'Mar 5, 2023';
      case 'CT Scans':
        return 'Feb 18, 2023';
      case 'Lab Reports':
        return 'Jan 15, 2023';
      case 'MRI Scans':
        return 'Jan 30, 2023';
      default:
        return 'Jan 1, 2023';
    }
  }
}

class CategoryDetailPage extends StatelessWidget {
  final String category;

  const CategoryDetailPage({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        foregroundColor: Colors.blueGrey[800],
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey[50],
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _getMedicalRecords().length,
          itemBuilder: (context, index) {
            final record = _getMedicalRecords()[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RecordCard(
                record: record,
                color: _getCategoryColor(),
                onTap: () => _navigateToFileViewer(context, record),
              ),
            );
          },
        ),
      ),
    );
  }

  List<MedicalRecord> _getMedicalRecords() {
    // Return records based on category
    switch (category) {
      case 'X-Rays':
        return const [
          MedicalRecord(
            title: 'Chest X-Ray',
            date: '2023-03-05',
            doctor: 'Dr. Wilson',
            fileType: 'DICOM',
            fileSize: '15 MB',
          ),
          MedicalRecord(
            title: 'Wrist X-Ray',
            date: '2022-08-23',
            doctor: 'Dr. Smith',
            fileType: 'DICOM',
            fileSize: '10 MB',
          ),
        ];
      case 'CT Scans':
        return const [
          MedicalRecord(
            title: 'Brain CT Scan',
            date: '2023-02-18',
            doctor: 'Dr. Reynolds',
            fileType: 'DICOM',
            fileSize: '45 MB',
          ),
          MedicalRecord(
            title: 'Abdominal CT Scan',
            date: '2022-10-05',
            doctor: 'Dr. Harrison',
            fileType: 'DICOM',
            fileSize: '52 MB',
          ),
        ];
      case 'Lab Reports':
        return const [
          MedicalRecord(
            title: 'Complete Blood Count',
            date: '2023-01-15',
            doctor: 'Dr. Miller',
            fileType: 'PDF',
            fileSize: '2 MB',
          ),
          MedicalRecord(
            title: 'Lipid Profile',
            date: '2022-12-20',
            doctor: 'Dr. Adams',
            fileType: 'PDF',
            fileSize: '1.5 MB',
          ),
        ];
      case 'MRI Scans':
        return const [
          MedicalRecord(
            title: 'Knee MRI',
            date: '2023-01-30',
            doctor: 'Dr. Campbell',
            fileType: 'DICOM',
            fileSize: '60 MB',
          ),
          MedicalRecord(
            title: 'Brain MRI',
            date: '2022-09-12',
            doctor: 'Dr. Reynolds',
            fileType: 'DICOM',
            fileSize: '72 MB',
          ),
        ];
      default:
        return [];
    }
  }

  Color _getCategoryColor() {
    switch (category) {
      case 'X-Rays':
        return const Color(0xFF3498DB);
      case 'CT Scans':
        return const Color(0xFF9B59B6);
      case 'Lab Reports':
        return const Color(0xFF2ECC71);
      case 'MRI Scans':
        return const Color(0xFFE74C3C);
      default:
        return Colors.blueGrey;
    }
  }

  void _navigateToFileViewer(BuildContext context, MedicalRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileViewerPage(record: record, color: _getCategoryColor()),
      ),
    );
  }
}

class RecordCard extends StatelessWidget {
  final MedicalRecord record;
  final Color color;
  final VoidCallback onTap;

  const RecordCard({
    Key? key,
    required this.record,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                _getFileIcon(record.fileType),
                color: color,
                size: 24,
              ),
            ),
          ),
          title: Text(
            record.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${_formatDate(record.date)} • ${record.doctor}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${record.fileType} • ${record.fileSize}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DICOM':
        return Icons.image;
      case 'JPEG':
        return Icons.photo;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length != 3) return date;

      final year = parts[0];
      final month = _getMonthAbbreviation(int.parse(parts[1]));
      final day = int.parse(parts[2]);

      return '$month $day, $year';
    } catch (e) {
      return date;
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}

class FileViewerPage extends StatelessWidget {
  final MedicalRecord record;
  final Color color;

  const FileViewerPage({
    Key? key,
    required this.record,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          record.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        foregroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // File info header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getFileIcon(record.fileType),
                      color: color,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(record.date)} • ${record.doctor}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${record.fileType} • ${record.fileSize}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // File content area
          Expanded(
            child: _buildFileContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent(BuildContext context) {
    if (record.fileType == 'DICOM' || record.fileType == 'JPEG') {
      return _buildImageViewer();
    } else if (record.fileType == 'PDF') {
      return _buildPDFViewer();
    } else {
      return const Center(
        child: Text('Unsupported file type'),
      );
    }
  }

  Widget _buildImageViewer() {
    return Container(
      color: Colors.black87,
      child: Column(
        children: [
          // Image viewer toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _toolbarButton(Icons.zoom_out, 'Zoom Out'),
                _toolbarButton(Icons.zoom_in, 'Zoom In'),
                _toolbarButton(Icons.rotate_left, 'Rotate'),
                _toolbarButton(Icons.tune, 'Adjust'),
                _toolbarButton(Icons.compare, 'Compare'),
              ],
            ),
          ),

          // Image placeholder
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                color: Colors.grey[850],
                child: Stack(
                  children: [
                    // This would be a real image in a complete app
                    Center(
                      child: Icon(
                        Icons.image,
                        size: 120,
                        color: Colors.grey[700],
                      ),
                    ),
                    Center(
                      child: Text(
                        '${record.title} Image',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Image navigation bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Series 1/1',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.navigate_before, color: Colors.grey[400]),
                      onPressed: () {},
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Image 1/1',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.navigate_next, color: Colors.grey[400]),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFViewer() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description,
                size: 72,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'PDF Document Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This is where PDF content would be displayed',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white70,
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DICOM':
        return Icons.image;
      case 'JPEG':
        return Icons.photo;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length != 3) return date;

      final year = parts[0];
      final month = _getMonthAbbreviation(int.parse(parts[1]));
      final day = int.parse(parts[2]);

      return '$month $day, $year';
    } catch (e) {
      return date;
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}

class MedicalRecord {
  final String title;
  final String date;
  final String doctor;
  final String fileType;
  final String fileSize;

  const MedicalRecord({
    required this.title,
    required this.date,
    required this.doctor,
    required this.fileType,
    required this.fileSize,
  });
}