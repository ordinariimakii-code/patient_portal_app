import 'package:flutter/material.dart';
import 'package:patient_portal/services/api_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String? _selectedType;
  String? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _isLoadingDoctors = false;
  List<Map<String, dynamic>> _filteredDoctors = [];
  List<String> _availableTimeSlots = [];

  // Appointment types with their corresponding category IDs
  final List<Map<String, dynamic>> _appointmentTypes = [
    {
      'label': 'General Checkup',
      'categoryId': 1,
      'icon': Icons.medical_services,
      'color': const Color(0xFF4A6CF7),
    },
    {
      'label': 'Consultation',
      'categoryId': 2,
      'icon': Icons.chat_bubble_outline,
      'color': const Color(0xFF6C63FF),
    },
  ];

  bool get _isFormValid {
    return _selectedType != null &&
        _selectedDoctor != null &&
        _selectedDate != null &&
        _selectedTime != null;
  }

  int _getDayOfWeek(DateTime date) {
    return date.weekday;
  }

  Future<void> _fetchDoctors() async {
    if (_selectedType == null || _selectedDate == null) return;
    
    final categoryId = _appointmentTypes.firstWhere(
      (type) => type['label'] == _selectedType,
    )['categoryId'];
    
    final dayOfWeek = _getDayOfWeek(_selectedDate!);
    
    setState(() {
      _isLoadingDoctors = true;
      _selectedDoctor = null;
      _selectedTime = null;
      _filteredDoctors = [];
      _availableTimeSlots = [];
    });

    try {
      final result = await ApiService.getDoctorsWithSchedule(categoryId, dayOfWeek: dayOfWeek);
      
      if (result['success']) {
        setState(() {
          _filteredDoctors = List<Map<String, dynamic>>.from(result['doctors']);
          _isLoadingDoctors = false;
          if (_filteredDoctors.length == 1) {
            _selectedDoctor = _filteredDoctors[0]['DoctorID']?.toString();
            _updateTimeSlots();
          }
        });
      } else {
        setState(() {
          _filteredDoctors = [];
          _isLoadingDoctors = false;
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to load doctors'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _filteredDoctors = [];
        _isLoadingDoctors = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading doctors: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _updateTimeSlots() {
    if (_selectedDoctor == null || _selectedDate == null) {
      setState(() {
        _availableTimeSlots = [];
        _selectedTime = null;
      });
      return;
    }

    final doctor = _filteredDoctors.firstWhere(
      (d) => d['DoctorID']?.toString() == _selectedDoctor,
      orElse: () => {},
    );

    if (doctor.isNotEmpty && doctor['schedule'] != null) {
      final dayOfWeek = _getDayOfWeek(_selectedDate!);
      final daySchedule = (doctor['schedule'] as List).firstWhere(
        (s) => s['day'] == dayOfWeek,
        orElse: () => {},
      );

      if (daySchedule.isNotEmpty && daySchedule['timeSlots'] != null) {
        setState(() {
          _availableTimeSlots = List<String>.from(daySchedule['timeSlots']);
          _selectedTime = null;
        });
      } else {
        setState(() {
          _availableTimeSlots = [];
          _selectedTime = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/patient_portal_background69.png'),
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
              _buildCustomAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProgressIndicator(),
                      const SizedBox(height: 20),
                      _buildFormCard(),
                      const SizedBox(height: 20),
                      _buildBookButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D47A1),  // Deep Healthcare Blue
            Color(0xFF1976D2),  // Healthcare Blue
            Color(0xFF42A5F5),  // Light Healthcare Blue
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Book Appointment',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Schedule your visit with a specialist',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Type', 'Date', 'Doctor', 'Time'];
    int currentStep = 0;
    if (_selectedType != null) currentStep = 1;
    if (_selectedDate != null) currentStep = 2;
    if (_selectedDoctor != null) currentStep = 3;
    if (_selectedTime != null) currentStep = 4;

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index < currentStep;
        final isCurrent = index == currentStep;
        return Expanded(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive 
                      ? const Color(0xFF1976D2) 
                      : isCurrent 
                          ? const Color(0xFF1976D2).withValues(alpha: 0.4) 
                          : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                steps[index],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: isActive || isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isActive || isCurrent ? const Color(0xFF1976D2) : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Appointment Type
            _buildSectionHeader(
              icon: Icons.medical_information,
              title: 'Appointment Type',
              subtitle: 'Choose the type of appointment you need',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _appointmentTypes.map((type) {
                final isSelected = _selectedType == type['label'];
                final color = type['color'] as Color? ?? const Color(0xFF1976D2);
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'] as IconData? ?? Icons.medical_services,
                        size: 18,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type['label'],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = selected ? type['label'] : null;
                      _selectedDoctor = null;
                      _selectedTime = null;
                      _filteredDoctors = [];
                      _availableTimeSlots = [];
                    });
                    if (selected && _selectedDate != null) {
                      _fetchDoctors();
                    }
                  },
                  selectedColor: color,
                  backgroundColor: color.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  elevation: 0,
                  pressElevation: 2,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 24),

            // 2. Select Date
            _buildSectionHeader(
              icon: Icons.calendar_today,
              title: 'Select Date',
              subtitle: 'Choose your preferred appointment date',
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedDate != null ? const Color(0xFF1976D2) : Colors.grey.shade200,
                  width: _selectedDate != null ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: _selectedDate != null ? const Color(0xFF1976D2) : Colors.grey.shade400,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? _formatDate(_selectedDate!)
                              : 'Choose a date',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.w400,
                            color: _selectedDate != null
                                ? const Color(0xFF1A1A2E)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      if (_selectedDate != null)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _selectedDate = null;
                                _selectedTime = null;
                                _availableTimeSlots = [];
                                _filteredDoctors = [];
                                _selectedDoctor = null;
                              });
                            },
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Select Doctor
            if (_selectedType != null && _selectedDate != null) ...[
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 24),
              _buildSectionHeader(
                icon: Icons.local_hospital,
                title: 'Select Doctor',
                subtitle: _filteredDoctors.isNotEmpty 
                    ? '${_filteredDoctors.length} doctor(s) available'
                    : 'No doctors available for this day',
              ),
              const SizedBox(height: 14),
              if (_isLoadingDoctors)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF1976D2),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Loading doctors...',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredDoctors.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedDoctor != null ? const Color(0xFF1976D2) : Colors.grey.shade200,
                      width: _selectedDoctor != null ? 2 : 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDoctor,
                      isExpanded: true,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Search doctor...',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      items: _filteredDoctors.map((doctor) {
                        final doctorName = doctor['Lastname'] != null && doctor['Firstname'] != null
                            ? '${doctor['Lastname']}, ${doctor['Firstname']}'
                            : doctor['FullName'] ?? doctor['name'] ?? 'Unknown Doctor';
                        
                        final specialtyId = doctor['SpecialtyID'];
                        final hasSpecialty = specialtyId != null && specialtyId.toString() != '0' && specialtyId.toString().isNotEmpty;
                        final specialty = hasSpecialty ? ' ($specialtyId)' : '';
                        
                        final doctorId = doctor['DoctorID']?.toString() ?? '';
                        
                        return DropdownMenuItem<String>(
                          value: doctorId,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF1976D2),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        doctorName,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (hasSpecialty)
                                        Text(
                                          specialty,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDoctor = value;
                          _updateTimeSlots();
                        });
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF1976D2),
                          size: 28,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        color: Colors.grey.shade400,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No doctors available for this day',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // 4. Time Slots
            if (_selectedDoctor != null && _selectedDate != null) ...[
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 24),
              _buildSectionHeader(
                icon: Icons.access_time,
                title: 'Available Times',
                subtitle: _availableTimeSlots.isNotEmpty 
                    ? '${_availableTimeSlots.length} time slot(s) available'
                    : 'No time slots available',
              ),
              const SizedBox(height: 14),
              if (_availableTimeSlots.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableTimeSlots.map((time) {
                    final isSelected = _selectedTime == time;
                    return FilterChip(
                      label: Text(
                        time,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTime = selected ? time : null;
                        });
                      },
                      selectedColor: const Color(0xFF1976D2),
                      backgroundColor: Colors.grey.shade50,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected 
                              ? const Color(0xFF1976D2) 
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      elevation: 0,
                      pressElevation: 2,
                      showCheckmark: false,
                    );
                  }).toList(),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        color: Colors.grey.shade400,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No available time slots for this doctor on this day',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF1976D2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFormValid
            ? [
                BoxShadow(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: _isFormValid ? _bookAppointment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isFormValid) ...[
              const Icon(Icons.check_circle, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              _isFormValid ? 'Book Appointment' : 'Complete All Fields',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A2E),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1976D2),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _availableTimeSlots = [];
        _selectedDoctor = null;
        _filteredDoctors = [];
      });
      if (_selectedType != null) {
        await _fetchDoctors();
      }
    }
  }

  String _formatDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getDayLabel(int dayOfWeek) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek - 1];
  }

  void _bookAppointment() {
    final doctor = _filteredDoctors.firstWhere(
      (d) => d['DoctorID']?.toString() == _selectedDoctor,
      orElse: () => {},
    );
    
    final doctorName = doctor.isNotEmpty 
        ? '${doctor['Lastname']}, ${doctor['Firstname']}'
        : _selectedDoctor ?? '';
    
    final dayLabel = _selectedDate != null 
        ? _getDayLabel(_getDayOfWeek(_selectedDate!))
        : '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Appointment Booked!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your appointment has been confirmed',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildConfirmationRow('Type', _selectedType!),
                    _buildConfirmationRow('Doctor', doctorName),
                    _buildConfirmationRow('Date', _formatDate(_selectedDate!)),
                    _buildConfirmationRow('Day', dayLabel),
                    _buildConfirmationRow('Time', _selectedTime!),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}