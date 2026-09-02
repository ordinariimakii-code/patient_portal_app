import 'package:flutter/material.dart';
import 'package:patient_portal/services/api_service.dart';

class LatestResultsScreen extends StatefulWidget {
  const LatestResultsScreen({super.key});

  @override
  State<LatestResultsScreen> createState() => _LatestResultsScreenState();
}

class _LatestResultsScreenState extends State<LatestResultsScreen> {
  Map<String, dynamic>? _resultsData;
  bool _isLoading = true;
  String? _error;
  String? _hospNum;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await ApiService.getUserData();
      
      if (userData == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final hospNum = userData['hospNum'];
      if (hospNum == null || hospNum.toString().isEmpty) {
        setState(() {
          _error = 'No hospital number associated with this user';
          _isLoading = false;
        });
        return;
      }

      _hospNum = hospNum.toString();
      final result = await ApiService.getLatestResults(_hospNum!);
      
      if (result['success']) {
        final data = result['data'];
        
        setState(() {
          _resultsData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to load results';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading results: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/patient_portal_background68.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(alpha: 0.92),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2ECC71),
                        ),
                      )
                    : _error != null
                        ? _buildErrorView()
                        : _resultsData != null
                            ? _buildResultsContent()
                            : _buildEmptyState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Latest Results',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your latest laboratory results will appear here',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent() {
    final labResults = _resultsData!['labResults'] ?? [];
    final xrayResults = _resultsData!['xrayResults'] ?? [];
    final ultrasoundResults = _resultsData!['ultrasoundResults'] ?? [];
    final ctResults = _resultsData!['ctResults'] ?? [];
    
    final hasResults = labResults.isNotEmpty || 
                       xrayResults.isNotEmpty || 
                       ultrasoundResults.isNotEmpty || 
                       ctResults.isNotEmpty;

    if (!hasResults) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lab Results Section
          if (labResults.isNotEmpty) ...[
            _buildSectionHeader('Laboratory Results', Icons.science, const Color(0xFF2ECC71)),
            const SizedBox(height: 12),
            ...labResults.map((result) => _buildLabResultCard(result)),
            const SizedBox(height: 20),
          ],
          
          // X-Ray Results Section
          if (xrayResults.isNotEmpty) ...[
            _buildSectionHeader('X-Ray Results', Icons.medical_information, const Color(0xFF4A6CF7)),
            const SizedBox(height: 12),
            ...xrayResults.map((result) => _buildRadiologyResultCard(result, 'X-Ray')),
            const SizedBox(height: 20),
          ],
          
          // Ultrasound Results Section
          if (ultrasoundResults.isNotEmpty) ...[
            _buildSectionHeader('Ultrasound Results', Icons.medical_services, const Color(0xFFE74C3C)),
            const SizedBox(height: 12),
            ...ultrasoundResults.map((result) => _buildRadiologyResultCard(result, 'Ultrasound')),
            const SizedBox(height: 20),
          ],
          
          // CT Scan Results Section
          if (ctResults.isNotEmpty) ...[
            _buildSectionHeader('CT Scan Results', Icons.radar, const Color(0xFFF39C12)),
            const SizedBox(height: 12),
            ...ctResults.map((result) => _buildRadiologyResultCard(result, 'CT Scan')),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const Spacer(),
        Text(
          'Latest',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLabResultCard(dynamic result) {
    final testName = result['LabExam']?.toString() ?? 'Unknown Test';
    final section = result['SectionName']?.toString() ?? 'General';
    final date = _formatDate(result['TransDate']);
    final refNum = result['RefNum']?.toString() ?? 'N/A';
    final requestNum = result['RequestNum']?.toString() ?? '';
    final accessionNum = result['AccessionNum']?.toString() ?? '';
    final doctor = result['Doctor']?.toString() ?? 'N/A';
    final testDetails = result['TestDetails'] ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            section,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        date,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    if (refNum.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tag, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'Ref: $refNum',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    if (requestNum.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'Req: $requestNum',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    if (accessionNum.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.numbers, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'Accession: $accessionNum',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          doctor,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Test Details (if available)
          if (testDetails.isNotEmpty) ...[
            const Divider(height: 1, thickness: 1),
            // Header row for the table
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Test',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Result',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Unit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Normal Range',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: testDetails.map<Widget>((detail) {
                  final testName = detail['TestName']?.toString() ?? 'Unknown';
                  final result = detail['Result']?.toString() ?? '';
                  final unit = detail['Unit']?.toString() ?? '';
                  final normalValues = detail['NormalValues']?.toString() ?? '';
                  final minValue = detail['MinValue']?.toString() ?? '';
                  final maxValue = detail['MaxValue']?.toString() ?? '';
                  
                  // Check if result is abnormal
                  bool isAbnormal = false;
                  if (result.isNotEmpty && minValue.isNotEmpty && maxValue.isNotEmpty) {
                    try {
                      final resultNum = double.parse(result);
                      final minNum = double.parse(minValue);
                      final maxNum = double.parse(maxValue);
                      isAbnormal = resultNum < minNum || resultNum > maxNum;
                    } catch (e) {
                      // Ignore parsing errors
                    }
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            testName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            result.isNotEmpty ? result : '-',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isAbnormal ? Colors.red.shade700 : const Color(0xFF1A1A2E),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            unit,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            normalValues.isNotEmpty ? normalValues : '${minValue.isNotEmpty ? minValue : ''} - ${maxValue.isNotEmpty ? maxValue : ''}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

Widget _buildRadiologyResultCard(dynamic result, String type) {
  final examDescription = result['ExamDescription']?.toString() ?? '$type Exam';
  final date = _formatDate(result['DateVerified'] ?? result['ExamDate']);
  final requestNum = result['RequestNum']?.toString() ?? 'N/A';
  final radiologist = result['Radiologist']?.toString() ?? 'N/A';
  final interpretation = result['Interpretation']?.toString();
  final transNo = result['TransNo']?.toString() ?? '';
  
  Color color;
  switch (type) {
    case 'X-Ray':
      color = const Color(0xFF4A6CF7);
      break;
    case 'Ultrasound':
      color = const Color(0xFFE74C3C);
      break;
    case 'CT Scan':
      color = const Color(0xFFF39C12);
      break;
    default:
      color = const Color(0xFF2ECC71);
  }
  
  // Parse interpretation to extract sections
  String? cleanInterpretation;
  String? impression;
  
  if (interpretation != null && interpretation.isNotEmpty) {
    // Split by common section markers
    final sections = _parseRadiologyReport(interpretation);
    cleanInterpretation = sections['interpretation'];
    impression = sections['impression'];
  }
  
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    examDescription,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    type,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                date,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            if (transNo.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.confirmation_number, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Trans #: $transNo',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'Req: $requestNum',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  radiologist,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (interpretation != null && interpretation.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Interpretation Section
                if (cleanInterpretation != null && cleanInterpretation.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.article, size: 16, color: color),
                      const SizedBox(width: 8),
                      Text(
                        'Interpretation:',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cleanInterpretation,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      height: 1.6,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
                
                // Impression Section (if available) - Same style as Interpretation
                if (impression != null && impression.isNotEmpty) ...[
                  if (cleanInterpretation != null && cleanInterpretation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(Icons.health_and_safety, size: 16, color: color),
                      const SizedBox(width: 8),
                      Text(
                        'Impression:',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    impression,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      height: 1.6,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
                
                // Fallback: If parsing failed, show the full text
                if (cleanInterpretation == null || cleanInterpretation.isEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.article, size: 16, color: color),
                      const SizedBox(width: 8),
                      Text(
                        'Report:',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    interpretation,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      height: 1.6,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

// Helper method to parse radiology report
Map<String, String> _parseRadiologyReport(String text) {
  String interpretation = '';
  String impression = '';
  
  // Try to find IMPRESSION section
  final impressionPattern = RegExp(r'IMPRESSION\s*[:：]\s*(.*?)(?=$|(?=\n\s*\n)|(?=\n\s*[A-Z]))', caseSensitive: false);
  final impressionMatch = impressionPattern.firstMatch(text);
  
  if (impressionMatch != null) {
    impression = impressionMatch.group(1)?.trim() ?? '';
    // Remove impression from interpretation text
    interpretation = text.replaceAll(impressionPattern, '').trim();
  } else {
    // Try alternative: "Impression:" with lowercase
    final altPattern = RegExp(r'Impression\s*[:：]\s*(.*?)(?=$|(?=\n\s*\n)|(?=\n\s*[A-Z]))', caseSensitive: false);
    final altMatch = altPattern.firstMatch(text);
    if (altMatch != null) {
      impression = altMatch.group(1)?.trim() ?? '';
      interpretation = text.replaceAll(altPattern, '').trim();
    } else {
      // No impression found, use entire text as interpretation
      interpretation = text;
    }
  }
  
  // Clean up interpretation
  interpretation = interpretation
      .replaceAll(RegExp(r'^\s*INTERPRETATION\s*[:：]\s*', caseSensitive: false), '')
      .trim();
  
  // If interpretation starts with "CXR" or similar, keep it
  if (interpretation.isEmpty && impression.isNotEmpty) {
    // If we only have impression, use it as interpretation
    interpretation = impression;
    impression = '';
  }
  
  return {
    'interpretation': interpretation,
    'impression': impression,
  };
}
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    
    try {
      DateTime date;
      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return dateValue.toString();
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateValue.toString();
    }
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1976D2),
            Color(0xFF42A5F5),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 8),
            const Text(
              'Latest Results',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadResults,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}