import 'package:flutter/material.dart';
import 'package:patient_portal/services/api_service.dart';

class ClinicalSummaryScreen extends StatefulWidget {
  const ClinicalSummaryScreen({super.key});

  @override
  State<ClinicalSummaryScreen> createState() => _ClinicalSummaryScreenState();
}

class _ClinicalSummaryScreenState extends State<ClinicalSummaryScreen> {
  Map<String, dynamic>? _clinicalData;
  bool _isLoading = true;
  String? _error;
  String? _hospNum;

  @override
  void initState() {
    super.initState();
    _loadClinicalSummary();
  }

  Future<void> _loadClinicalSummary() async {
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
      final result = await ApiService.getClinicalSummary(_hospNum!);
      
      if (result['success']) {
        setState(() {
          _clinicalData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading clinical summary: $e';
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
                        color: Color(0xFF1976D2),
                      ),
                    )
                  : _error != null
                    ? _buildErrorView()
                    : _clinicalData != null
                      ? _buildClinicalSummaryContent()
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
              onPressed: _loadClinicalSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
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
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Clinical Summary',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your clinical summary will appear here',
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

  Widget _buildClinicalSummaryContent() {
    final clinicalSummary = _clinicalData!['clinicalSummary'] ?? {};
    
    // Extract full name
    final fullName = '${clinicalSummary['FirstName'] ?? ''} ${clinicalSummary['MiddleName'] ?? ''} ${clinicalSummary['LastName'] ?? ''}'.trim();
    
    // Format admission and discharge dates
    final admissionDate = _formatDateString(clinicalSummary['AdmissionDate']);
    final dischargeDate = clinicalSummary['DischargeDate'] != null 
        ? _formatDateString(clinicalSummary['DischargeDate']) 
        : 'Not discharged yet';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Patient Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF1976D2),
                  Color(0xFF42A5F5),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isNotEmpty ? fullName : 'Patient',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _buildPatientBadge('Age: ${clinicalSummary['Age']?.toString() ?? 'N/A'}', Icons.calendar_today),
                              _buildPatientBadge(clinicalSummary['Sex'] ?? 'N/A', Icons.person_outline),
                              _buildPatientBadge(clinicalSummary['CivilStatus'] ?? 'N/A', Icons.family_restroom),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Admission Card
          _buildInfoCard(
            title: 'Admission Details',
            icon: Icons.local_hospital,
            children: [
              _buildInfoRow(Icons.confirmation_number, 'Admission No:', clinicalSummary['AdmissionNumber'] ?? 'N/A'),
              _buildInfoRow(Icons.badge, 'Hospital No:', clinicalSummary['HospitalNumber'] ?? 'N/A'),
              _buildInfoRow(Icons.meeting_room, 'Room:', clinicalSummary['Room'] ?? 'N/A'),
              _buildInfoRow(Icons.calendar_today, 'Admission Date:', admissionDate),
              _buildInfoRow(Icons.calendar_today, 'Discharge Date:', dischargeDate),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Doctors Card
          _buildInfoCard(
            title: 'Medical Team',
            icon: Icons.medical_services,
            children: [
              _buildInfoRow(Icons.person, 'Attending Doctor:', clinicalSummary['AttendingDoctor']?.toString() ?? 'N/A'),
              _buildInfoRow(Icons.person_outline, 'Admitting Doctor:', clinicalSummary['AdmittingDoctor']?.toString() ?? 'N/A'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Diagnoses Card
          if (clinicalSummary['AdmittingDiagnosis'] != null && 
              clinicalSummary['AdmittingDiagnosis'].toString().isNotEmpty) 
            _buildInfoCard(
              title: 'Diagnoses',
              icon: Icons.assignment,
              children: [
                _buildInfoRow(Icons.note, 'Admitting Diagnosis:', clinicalSummary['AdmittingDiagnosis']),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Chief Complaints Card
          if (clinicalSummary['ChiefComplaints'] != null && 
              clinicalSummary['ChiefComplaints'].toString().isNotEmpty) 
            _buildInfoCard(
              title: 'Chief Complaints',
              icon: Icons.sick,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1976D2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          clinicalSummary['ChiefComplaints'],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Final Diagnosis Card
          if (clinicalSummary['FinalDiagnosis'] != null && 
              clinicalSummary['FinalDiagnosis'].toString().isNotEmpty) 
            _buildInfoCard(
              title: 'Final Diagnosis',
              icon: Icons.health_and_safety,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      clinicalSummary['FinalDiagnosis'],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Vital Signs Card
          if (_hasVitalSigns(clinicalSummary)) 
            _buildInfoCard(
              title: 'Vital Signs',
              icon: Icons.monitor_heart,
              children: [
                Row(
                  children: [
                    if (clinicalSummary['BloodPressure'] != null && 
                        clinicalSummary['BloodPressure'].toString().isNotEmpty)
                      Expanded(
                        child: _buildVitalSignTile(
                          Icons.bloodtype,
                          'Blood Pressure',
                          clinicalSummary['BloodPressure'],
                          Colors.blue,
                        ),
                      ),
                    if (clinicalSummary['Temperature'] != null && 
                        clinicalSummary['Temperature'].toString().isNotEmpty)
                      Expanded(
                        child: _buildVitalSignTile(
                          Icons.thermostat,
                          'Temperature',
                          '${clinicalSummary['Temperature']}°C',
                          Colors.orange,
                        ),
                      ),
                    if (clinicalSummary['Weight'] != null && 
                        clinicalSummary['Weight'] != 0)
                      Expanded(
                        child: _buildVitalSignTile(
                          Icons.monitor_weight,
                          'Weight',
                          '${clinicalSummary['Weight']} kg',
                          Colors.green,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Address Card
          if (clinicalSummary['Address'] != null && 
              clinicalSummary['Address'].toString().isNotEmpty) 
            _buildInfoCard(
              title: 'Address',
              icon: Icons.location_on,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.location_pin, color: Color(0xFF1976D2), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          clinicalSummary['Address'],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPatientBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF1976D2), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2B4A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1976D2), size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A2B4A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignTile(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _hasVitalSigns(Map<String, dynamic> data) {
    return (data['BloodPressure'] != null && data['BloodPressure'].toString().isNotEmpty) ||
           (data['Temperature'] != null && data['Temperature'].toString().isNotEmpty) ||
           (data['Weight'] != null && data['Weight'] != 0);
  }

  String _formatDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
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
              'Clinical Summary',
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
              onPressed: _loadClinicalSummary,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}