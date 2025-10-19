import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lms_publisher/School_Panel/student_module/student_model.dart';
import 'package:lms_publisher/School_Panel/student_module/student_service.dart';
import 'package:provider/provider.dart'; // ✅ ADD THIS
import '../../Theme/apptheme.dart';
import 'student_bloc.dart';
import '../../Util/custom_snackbar.dart';
import '../../Util/beautiful_loader.dart';
import '../../Provider/ConnectivityProvider.dart'; // ✅ ADD THIS
import '../../Service/user_right_service.dart';



// Total number of tabs in the form
const int _kTotalTabs = 6;

class AddStudentScreen extends StatefulWidget {
  final StudentModel? student;
  final int schoolRecNo;

  const AddStudentScreen({super.key, this.student, required this.schoolRecNo});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen>
    with SingleTickerProviderStateMixin {
  // Use a map to store keys for each tab's form, allowing isolated validation
  final Map<int, GlobalKey<FormState>> _formKeys = {
    0: GlobalKey<FormState>(),
    1: GlobalKey<FormState>(),
    2: GlobalKey<FormState>(),
    3: GlobalKey<FormState>(),
    4: GlobalKey<FormState>(),
    5: GlobalKey<FormState>(),
  };

  late TabController _tabController;
  final StudentApiService apiService = StudentApiService();

  bool get isEditMode => widget.student != null;


  // Photo Upload
  XFile? _selectedPhoto;
  bool _isUploadingPhoto = false;
  String? _uploadedPhotoPath;


  List<Map<String, dynamic>> classList = [];
  bool isLoadingClasses = false;

  List<String> get academicYears {
    final currentYear = DateTime.now().year;
    final List<String> years = [];
    for (int i = -5; i <= 5; i++) {
      final year = currentYear + i;
      years.add('$year-${(year + 1).toString().substring(2)}');
    }
    return years;
  }



  // Controllers - Basic Information
  final _studentIdController = TextEditingController();
  final _admissionNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _religionController = TextEditingController();

  // Controllers - Contact Information
  final _mobileNumberController = TextEditingController();
  final _alternateMobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _permanentAddressStreetController = TextEditingController();
  final _permanentAddressCityController = TextEditingController();
  // _permanentAddressStateController and _permanentAddressCountryController are no longer used for text input
  final _permanentAddressPINController = TextEditingController();
  final _currentAddressStreetController = TextEditingController();
  final _currentAddressCityController = TextEditingController();
  // _currentAddressStateController and _currentAddressCountryController are no longer used for text input
  final _currentAddressPINController = TextEditingController();

  // Controllers - Parent/Guardian Information
  final _fatherNameController = TextEditingController();
  final _fatherOccupationController = TextEditingController();
  final _fatherMobileController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherOccupationController = TextEditingController();
  final _motherMobileController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianMobileController = TextEditingController();
  final academicYearController = TextEditingController();

  // Controllers - Academic Information
  final _admissionDateController = TextEditingController();
  final _admissionClassController = TextEditingController();
  final _currentClassController = TextEditingController();
  final _sectionController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _previousSchoolController = TextEditingController();
  final _previousBoardController = TextEditingController();
  final _mediumController = TextEditingController();

  // Controllers - Documents
  final _aadhaarController = TextEditingController();
  final _passportController = TextEditingController();
  final _transferCertController = TextEditingController();
  final _migrationCertController = TextEditingController();
  final _birthCertController = TextEditingController();

  // Controllers - Other Information
  final _busRouteController = TextEditingController();
  final _scholarshipDetailsController = TextEditingController();
  final _specialNeedsController = TextEditingController();
  final _extraCurricularController = TextEditingController();

  // Controllers - Login Info
  final _studentUsernameController = TextEditingController();
  final _studentPasswordController = TextEditingController();
  final _parentUsernameController = TextEditingController();
  final _parentPasswordController = TextEditingController();

  // Dropdown values
  String? _selectedGender;
  String? _selectedCategory;
  bool _medicalFitness = false;
  bool _hostelFacility = false;
  bool _transportFacility = false;
  bool _scholarshipAid = false;
  bool _isActive = true;
  bool _sameAsPermanent = false;
  String? selectedAcademicYear;


  String? _selectedCurrentCountry;
  String? _selectedCurrentState;

  int? _selectedSchoolRecNo;
  int? _selectedClassRecNo;

  String? _selectedNationality;
  String? _selectedReligion;
  final List<String> _religionOptions = [
    'Hindu',
    'Muslim',
    'Christian',
    'Sikh',
    'Buddhist',
    'Jain',
    'Parsi',
    'Other'
  ];

  // Same as Permanent Address checkbox
  bool _isSameAsPermanent = false;

// ✅ UPDATED: Nationality and Religion Dropdowns
  final List<String> _nationalityOptions = [
    'Indian',
    'Nepali',
    'Sri Lankan',
    'Bangladeshi',
    'Other'
  ];
  bool _isLoadingPermanentStates = false;
  bool _isLoadingPermanentDistricts = false;
  bool _isLoadingPermanentCities = false;

// Current Address - Hierarchical
  List<StateModel> _currentStates = [];
  List<DistrictModel> _currentDistricts = [];
  List<CityModel> _currentCities = [];

  String? _selectedCurrentStateId;
  String? _selectedCurrentDistrictId;
  String? _selectedCurrentCityId;

  bool _isLoadingCurrentStates = false;
  bool _isLoadingCurrentDistricts = false;
  bool _isLoadingCurrentCities = false;
  String _permanentCountry = 'India'; // Always India
  String _currentCountry = 'India'; // Always India

// Permanent Address - Hierarchical
  List<StateModel> _permanentStates = [];
  List<DistrictModel> _permanentDistricts = [];
  List<CityModel> _permanentCities = [];

  String? _selectedPermanentStateId;
  String? _selectedPermanentDistrictId;
  String? _selectedPermanentCityId;
  // Add this with your other dropdown lists (around line 200)
  String? _selectedMedium;

  final List<String> _mediumOptions = [
    'English',
    'Hindi',
    'Marathi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Bengali',
    'Gujarati',
    'Malayalam',
    'Punjabi',
    'Urdu',
    'Other',
  ];

  // ==================== NEW STATE VARIABLES FOR ENHANCEMENTS ====================

// Tab completion tracking
  final Set<int> _completedTabs = {};

// UserID verification states
  bool _isStudentUserIdVerified = false;
  bool _isParentUserIdVerified = false;
  bool _isVerifyingStudentUserId = false;
  bool _isVerifyingParentUserId = false;





  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kTotalTabs, vsync: this);

    // ✅ ADD THIS: Listen to tab changes
    _tabController.addListener(_onTabChanged);

    fetchClasses();

    if (isEditMode) {
      _initializeEditMode();
      // ✅ ADD THIS: Mark user IDs as verified in edit mode
      _isStudentUserIdVerified = true;
      _isParentUserIdVerified = true;
    } else {
      loadPermanentStates();
      loadCurrentStates();
    }
  }

  // ✅ NEW METHOD: Track tab changes
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }



// ✅ NEW: Initialize edit mode properly
  Future<void> _initializeEditMode() async {
    // Load states first
    await Future.wait([
      loadPermanentStates(),
      loadCurrentStates(),
    ]);

    // Then load student data (which will trigger district/city loading)
    _loadStudentData();
  }

  // ==================== USERID VERIFICATION METHODS ====================

  /// Verify if Student UserID is available
  Future<void> _verifyStudentUserId() async {
    final connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);

    if (_studentUsernameController.text.trim().isEmpty) {
      CustomSnackbar.showError(
        context,
        'Please enter a Student User ID first',
        title: 'Validation Error',
      );
      return;
    }

    if (!connectivityProvider.isOnline) {
      CustomSnackbar.showError(
        context,
        'Cannot verify User ID while offline. Please connect to internet.',
        title: 'No Internet Connection',
      );
      return;
    }

    setState(() {
      _isVerifyingStudentUserId = true;
    });

    try {
      final userRightsService = UserRightsService();
      final exists = await userRightsService.checkUserIdExists(
        _studentUsernameController.text.trim(),
      );

      setState(() {
        _isVerifyingStudentUserId = false;
      });

      if (exists) {
        CustomSnackbar.showError(
          context,
          'This Student User ID is already taken. Please choose a different one.',
          title: '⚠️ User ID Unavailable',
        );
        setState(() {
          _isStudentUserIdVerified = false;
        });
      } else {
        CustomSnackbar.showSuccess(
          context,
          'Great! This Student User ID is available and can be used.',
          title: '✅ User ID Available',
        );
        setState(() {
          _isStudentUserIdVerified = true;
        });
      }
    } catch (e) {
      setState(() {
        _isVerifyingStudentUserId = false;
      });

      CustomSnackbar.showError(
        context,
        'Failed to verify User ID. Please try again.',
        title: 'Verification Failed',
      );
    }
  }

  /// Verify if Parent UserID is available
  Future<void> _verifyParentUserId() async {
    final connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);

    if (_parentUsernameController.text.trim().isEmpty) {
      CustomSnackbar.showError(
        context,
        'Please enter a Parent User ID first',
        title: 'Validation Error',
      );
      return;
    }

    if (!connectivityProvider.isOnline) {
      CustomSnackbar.showError(
        context,
        'Cannot verify User ID while offline. Please connect to internet.',
        title: 'No Internet Connection',
      );
      return;
    }

    setState(() {
      _isVerifyingParentUserId = true;
    });

    try {
      final userRightsService = UserRightsService();
      final exists = await userRightsService.checkUserIdExists(
        _parentUsernameController.text.trim(),
      );

      setState(() {
        _isVerifyingParentUserId = false;
      });

      if (exists) {
        CustomSnackbar.showError(
          context,
          'This Parent User ID is already taken. Please choose a different one.',
          title: '⚠️ User ID Unavailable',
        );
        setState(() {
          _isParentUserIdVerified = false;
        });
      } else {
        CustomSnackbar.showSuccess(
          context,
          'Great! This Parent User ID is available and can be used.',
          title: '✅ User ID Available',
        );
        setState(() {
          _isParentUserIdVerified = true;
        });
      }
    } catch (e) {
      setState(() {
        _isVerifyingParentUserId = false;
      });

      CustomSnackbar.showError(
        context,
        'Failed to verify User ID. Please try again.',
        title: 'Verification Failed',
      );
    }
  }



  // ==================== FETCH LOCATION DATA METHODS ====================

// ✅ Load Permanent States
  Future<void> loadPermanentStates() async {
    setState(() {
      _isLoadingPermanentStates = true;
      _permanentStates = [];
      _permanentDistricts = [];
      _permanentCities = [];
      _selectedPermanentStateId = null;
      _selectedPermanentDistrictId = null;
      _selectedPermanentCityId = null;
    });

    try {
      final states = await apiService.fetchStates();
      setState(() {
        _permanentStates = states;
        _isLoadingPermanentStates = false;
      });
    } catch (e) {
      setState(() => _isLoadingPermanentStates = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load states: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> loadCurrentStates() async {
    setState(() {
      _isLoadingCurrentStates = true;
      _currentStates = [];
      _currentDistricts = [];
      _currentCities = [];
      _selectedCurrentStateId = null;
      _selectedCurrentDistrictId = null;
      _selectedCurrentCityId = null;
    });

    try {
      final states = await apiService.fetchStates();
      setState(() {
        _currentStates = states;
        _isLoadingCurrentStates = false;
      });
    } catch (e) {
      setState(() => _isLoadingCurrentStates = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load states: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// ✅ FIXED: Load Permanent Districts (preserve selected value)
  Future<void> _loadPermanentDistricts(String stateId) async {
    // ✅ Store current selections BEFORE clearing
    final currentDistrictId = _selectedPermanentDistrictId;
    final currentCityId = _selectedPermanentCityId;

    setState(() {
      _isLoadingPermanentDistricts = true;
      _permanentDistricts = [];
      // DON'T clear selected values yet
    });

    try {
      final districts = await apiService.fetchDistricts(stateId);
      setState(() {
        _permanentDistricts = districts;
        _isLoadingPermanentDistricts = false;

        // ✅ Restore selection if it exists in the loaded list
        if (currentDistrictId != null) {
          final exists = districts.any((d) => d.id == currentDistrictId);
          if (exists) {
            _selectedPermanentDistrictId = currentDistrictId;
            // ✅ Also reload cities to restore city selection
            if (currentCityId != null) {
              _loadPermanentCities(currentDistrictId);
            }
          } else {
            _selectedPermanentDistrictId = null;
            _selectedPermanentCityId = null;
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingPermanentDistricts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load districts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// ✅ FIXED: Load Permanent Cities (preserve selected value)
  Future<void> _loadPermanentCities(String districtId) async {
    // ✅ Store current selection BEFORE clearing
    final currentCityId = _selectedPermanentCityId;

    setState(() {
      _isLoadingPermanentCities = true;
      _permanentCities = [];
      // DON'T clear selected value yet
    });

    try {
      final cities = await apiService.fetchCities(districtId);
      setState(() {
        _permanentCities = cities;
        _isLoadingPermanentCities = false;

        // ✅ Restore selection if it exists in the loaded list
        if (currentCityId != null) {
          final exists = cities.any((c) => c.id == currentCityId);
          _selectedPermanentCityId = exists ? currentCityId : null;
        }
      });
    } catch (e) {
      setState(() => _isLoadingPermanentCities = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// ✅ FIXED: Load Current Districts (preserve selected value)
  Future<void> _loadCurrentDistricts(String stateId) async {
    // ✅ Store current selections BEFORE clearing
    final currentDistrictId = _selectedCurrentDistrictId;
    final currentCityId = _selectedCurrentCityId;

    setState(() {
      _isLoadingCurrentDistricts = true;
      _currentDistricts = [];
      // DON'T clear selected values yet
    });

    try {
      final districts = await apiService.fetchDistricts(stateId);
      setState(() {
        _currentDistricts = districts;
        _isLoadingCurrentDistricts = false;

        // ✅ Restore selection if it exists in the loaded list
        if (currentDistrictId != null) {
          final exists = districts.any((d) => d.id == currentDistrictId);
          if (exists) {
            _selectedCurrentDistrictId = currentDistrictId;
            // ✅ Also reload cities to restore city selection
            if (currentCityId != null) {
              _loadCurrentCities(currentDistrictId);
            }
          } else {
            _selectedCurrentDistrictId = null;
            _selectedCurrentCityId = null;
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingCurrentDistricts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load districts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// ✅ FIXED: Load Current Cities (preserve selected value)
  Future<void> _loadCurrentCities(String districtId) async {
    // ✅ Store current selection BEFORE clearing
    final currentCityId = _selectedCurrentCityId;

    setState(() {
      _isLoadingCurrentCities = true;
      _currentCities = [];
      // DON'T clear selected value yet
    });

    try {
      final cities = await apiService.fetchCities(districtId);
      setState(() {
        _currentCities = cities;
        _isLoadingCurrentCities = false;

        // ✅ Restore selection if it exists in the loaded list
        if (currentCityId != null) {
          final exists = cities.any((c) => c.id == currentCityId);
          _selectedCurrentCityId = exists ? currentCityId : null;
        }
      });
    } catch (e) {
      setState(() => _isLoadingCurrentCities = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  Future<void> fetchClasses() async {
    setState(() {
      isLoadingClasses = true;
    });

    try {
      final classes = await apiService.fetchClassesBySchool(
        schoolRecNo: widget.schoolRecNo,
      );
      setState(() {
        classList = classes;
        isLoadingClasses = false;
      });
    } catch (e) {
      setState(() {
        isLoadingClasses = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load classes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadStudentData() {
    final student = widget.student!;

    // Load existing photo
    _uploadedPhotoPath = student.studentPhotoPath;

    // Basic Info
    _studentIdController.text = student.studentId ?? '';
    _admissionNumberController.text = student.admissionNumber ?? '';
    _firstNameController.text = student.firstName;
    _middleNameController.text = student.middleName ?? '';
    _lastNameController.text = student.lastName;
    _dateOfBirthController.text = student.dateOfBirth;
    _bloodGroupController.text = student.bloodGroup ?? '';

    // ✅ UPDATED: Use dropdown values
    _selectedNationality = student.nationality;
    _selectedReligion = student.religion;
    _selectedGender = student.gender;
    _selectedCategory = student.category;
    selectedAcademicYear = student.academicYear;

    // Contact
    _mobileNumberController.text = student.mobileNumber ?? '';
    _alternateMobileController.text = student.alternateContactNumber ?? '';
    _emailController.text = student.emailId ?? '';

    // ✅ UPDATED: Permanent Address - NEW STRUCTURE
    _permanentAddressStreetController.text = student.permanentAddress ?? '';
    _selectedPermanentStateId = student.permanentStateId?.toString();
    _selectedPermanentDistrictId = student.permanentDistrictId?.toString();
    _selectedPermanentCityId = student.permanentCityId?.toString();
    _permanentCountry = student.permanentCountry ?? 'India';
    _permanentAddressPINController.text = student.permanentPIN ?? '';

    // ✅ FIXED: Load cascading dropdowns with setState
    if (_selectedPermanentStateId != null && _selectedPermanentStateId!.isNotEmpty) {
      _loadPermanentDistricts(_selectedPermanentStateId!).then((_) {
        // After districts load, load cities if needed
        if (_selectedPermanentDistrictId != null && _selectedPermanentDistrictId!.isNotEmpty) {
          _loadPermanentCities(_selectedPermanentDistrictId!);
        }
      });
    }

    // ✅ UPDATED: Current Address - NEW STRUCTURE
    _currentAddressStreetController.text = student.currentAddress ?? '';
    _selectedCurrentStateId = student.currentStateId?.toString();
    _selectedCurrentDistrictId = student.currentDistrictId?.toString();
    _selectedCurrentCityId = student.currentCityId?.toString();
    _currentCountry = student.currentCountry ?? 'India';
    _currentAddressPINController.text = student.currentPIN ?? '';

    // ✅ FIXED: Load cascading dropdowns with setState
    if (_selectedCurrentStateId != null && _selectedCurrentStateId!.isNotEmpty) {
      _loadCurrentDistricts(_selectedCurrentStateId!).then((_) {
        // After districts load, load cities if needed
        if (_selectedCurrentDistrictId != null && _selectedCurrentDistrictId!.isNotEmpty) {
          _loadCurrentCities(_selectedCurrentDistrictId!);
        }
      });
    }

    // Parents
    _fatherNameController.text = student.fatherName ?? '';
    _fatherOccupationController.text = student.fatherOccupation ?? '';
    _fatherMobileController.text = student.fatherMobileNumber ?? '';
    _motherNameController.text = student.motherName ?? '';
    _motherOccupationController.text = student.motherOccupation ?? '';
    _motherMobileController.text = student.motherMobileNumber ?? '';
    _guardianNameController.text = student.guardianName ?? '';
    _guardianMobileController.text = student.guardianContactNumber ?? '';

    // Academic
    _admissionDateController.text = student.admissionDate ?? '';
    _admissionClassController.text = student.admissionClass ?? '';
    _currentClassController.text = student.currentClass ?? '';
    _sectionController.text = student.sectionDivision ?? '';
    _rollNumberController.text = student.rollNumber ?? '';
    _previousSchoolController.text = student.previousSchoolName ?? '';
    _previousBoardController.text = student.previousBoardUniversity ?? '';

    // ✅ UPDATED: Set medium dropdown
    _mediumController.text = student.mediumOfInstruction ?? '';
    _selectedMedium = student.mediumOfInstruction;

    // Documents
    _aadhaarController.text = student.aadhaarNumber ?? '';
    _passportController.text = student.passportNumber ?? '';
    _transferCertController.text = student.transferCertificateNo ?? '';
    _migrationCertController.text = student.migrationCertificateNo ?? '';
    _birthCertController.text = student.birthCertificateNo ?? '';
    _medicalFitness = student.medicalFitnessCertificate ?? false;

    // Other
    _hostelFacility = student.hostelFacility ?? false;
    _transportFacility = student.transportFacility ?? false;
    _busRouteController.text = student.busRouteNo ?? '';
    _scholarshipAid = student.scholarshipFinancialAid ?? false;
    _scholarshipDetailsController.text = student.scholarshipDetails ?? '';
    _specialNeedsController.text = student.specialNeedsDisability ?? '';
    _extraCurricularController.text = student.extraCurricularInterests ?? '';

    // Login
    _studentUsernameController.text = student.studentUsername ?? '';
    _studentPasswordController.text = (student.studentUsername != null && student.studentUsername!.isNotEmpty) ? '********' : '';
    _parentUsernameController.text = student.parentUsername ?? '';
    _parentPasswordController.text = (student.parentUsername != null && student.parentUsername!.isNotEmpty) ? '********' : '';

    _selectedSchoolRecNo = student.schoolRecNo;
    _selectedClassRecNo = student.classRecNo;
    _isActive = student.isActive ?? true;

    // ✅ Force UI update after all data is loaded
    setState(() {});
  }


  Future<void> _pickAndUploadPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedPhoto = image;
        _isUploadingPhoto = true;
      });

      // Upload photo
      final photoPath = await apiService.uploadStudentPhoto(image);

      if (photoPath != null && photoPath.isNotEmpty) {
        setState(() {
          _uploadedPhotoPath = photoPath;
          _isUploadingPhoto = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Photo uploaded successfully!'),
              backgroundColor: AppTheme.accentGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingPhoto = false;
        _selectedPhoto = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to upload photo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  @override
  void dispose() {
    // ✅ Remove tab listener
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();

    // Dispose all text controllers - EXACT NAMES FROM YOUR FILE
    _studentIdController.dispose();
    _admissionNumberController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _bloodGroupController.dispose();
    _nationalityController.dispose();
    _religionController.dispose();
    _mobileNumberController.dispose();
    _alternateMobileController.dispose();
    _emailController.dispose();
    _permanentAddressStreetController.dispose();
    _permanentAddressCityController.dispose();
    _permanentAddressPINController.dispose();
    _currentAddressStreetController.dispose();
    _currentAddressCityController.dispose();
    _currentAddressPINController.dispose();
    _fatherNameController.dispose();
    _fatherOccupationController.dispose();
    _fatherMobileController.dispose();
    _motherNameController.dispose();
    _motherOccupationController.dispose();
    _motherMobileController.dispose();
    _guardianNameController.dispose();
    _guardianMobileController.dispose();
    academicYearController.dispose();
    _admissionDateController.dispose();
    _admissionClassController.dispose();
    _currentClassController.dispose();
    _sectionController.dispose();
    _rollNumberController.dispose();
    _previousSchoolController.dispose();
    _previousBoardController.dispose();
    _mediumController.dispose();
    _aadhaarController.dispose();
    _passportController.dispose();
    _transferCertController.dispose();
    _migrationCertController.dispose();
    _birthCertController.dispose();
    _busRouteController.dispose();
    _scholarshipDetailsController.dispose();
    _specialNeedsController.dispose();
    _extraCurricularController.dispose();
    _studentUsernameController.dispose();
    _studentPasswordController.dispose();
    _parentUsernameController.dispose();
    _parentPasswordController.dispose();

    super.dispose();
  }



  Widget _buildPhotoUploadWidget() {
    final hasPhoto = _uploadedPhotoPath != null || _selectedPhoto != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPhoto ? AppTheme.borderGrey : Colors.orange.withOpacity(0.5),
          width: hasPhoto ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Student Photo',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Required field - Please upload a photo',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Photo Preview
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: _isUploadingPhoto
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                )
                    : hasPhoto
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _selectedPhoto != null
                      ? (kIsWeb
                      ? Image.network(_selectedPhoto!.path, fit: BoxFit.cover)
                      : Image.file(File(_selectedPhoto!.path), fit: BoxFit.cover))
                      : Image.network(
                    StudentApiService.getStudentPhotoUrl(_uploadedPhotoPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Iconsax.user, size: 40, color: AppTheme.bodyText);
                    },
                  ),
                )
                    : const Icon(Iconsax.user, size: 40, color: AppTheme.bodyText),
              ),
              const SizedBox(width: 16),
              // Upload Button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                      icon: const Icon(Iconsax.camera, size: 18),
                      label: Text(
                        hasPhoto ? 'Change Photo' : 'Upload Photo',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Max size: 5MB • JPG, PNG',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.bodyText,
                      ),
                    ),
                    if (!hasPhoto) ...[
                      const SizedBox(height: 4),
                      Text(
                        '⚠️ Photo is mandatory',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: _buildAppBar(),
      body: BlocListener<StudentBloc, StudentState>(
        listener: (context, state) {
          if (state is StudentOperationSuccessState) {
            // Show success message
            CustomSnackbar.showSuccess(
              context,
              state.message,
              title: isEditMode ? 'Update Successful' : 'Student Enrolled',
            );

            // Pop the screen after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && Navigator.canPop(context)) {
                Navigator.of(context).pop(true); // Return true to refresh list
              }
            });
          } else if (state is StudentErrorState) {
            CustomSnackbar.showError(
              context,
              state.error,
              title: 'Operation Failed',
            );
          }
        },
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoTab(),
                  _buildContactInfoTab(),
                  _buildParentInfoTab(),
                  _buildAcademicInfoTab(),
                  _buildDocumentsTab(),
                  _buildOtherInfoTab(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }




  PreferredSizeWidget _buildAppBar() {
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);

    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left, color: AppTheme.darkText),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditMode ? 'Edit Student Details' : 'Enroll New Student',
            style: GoogleFonts.poppins(
              color: AppTheme.darkText,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          // ✅ NEW: Network Status Indicator
          if (!connectivityProvider.isOnline)
            Row(
              children: [
                const Icon(Icons.wifi_off, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  'Offline Mode',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        // ✅ NEW: Progress Indicator
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: _buildProgressIndicator(),
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorColor: AppTheme.primaryGreen,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.bodyText,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        tabs: [
          _buildTabWithCheckmark(0, Iconsax.user, 'Basic'),
          _buildTabWithCheckmark(1, Iconsax.call, 'Contact'),
          _buildTabWithCheckmark(2, Iconsax.user_tag, 'Parents'),
          _buildTabWithCheckmark(3, Iconsax.book_1, 'Academic'),
          _buildTabWithCheckmark(4, Iconsax.document_text_1, 'Docs'),
          _buildTabWithCheckmark(5, Iconsax.info_circle, 'Other'),
        ],
        onTap: (index) {
          setState(() {});
        },
      ),
    );
  }


  // ✅ NEW METHOD: Build tab with completion checkmark
  Widget _buildTabWithCheckmark(int tabIndex, IconData icon, String label) {
    final isCompleted = _completedTabs.contains(tabIndex);

    return Tab(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
          // ✅ Animated checkmark when tab is completed
          if (isCompleted)
            Positioned(
              top: -4,
              right: -4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

// ✅ NEW METHOD: Build progress indicator showing completion percentage
  Widget _buildProgressIndicator() {
    final progress = _completedTabs.length / _kTotalTabs;
    final percentage = (progress * 100).toInt();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 100,
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.lightGrey,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percentage%',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }


  // --- Tab Content Widgets ---

  // ==================== TAB 1: BASIC INFORMATION ====================
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[0],
        child: _buildInputCard(
          children: [
            _buildSectionHeader('Basic Identity Details', Iconsax.user),
            const SizedBox(height: 20),
            _buildResponsiveRow([
              // _buildTextField(
              //   'Student ID',
              //   _studentIdController,
              //   'Enter student ID (e.g., STD1001)',
              //   isRequired: true,
              // ),
              _buildTextField(
                'Admission Number',
                _admissionNumberController,
                'Enter admission number',
                isRequired: true,
              ),
            ]),
            _buildResponsiveRow([
              _buildTextField(
                'First Name',
                _firstNameController,
                'Enter first name',
                isRequired: true,
              ),
              _buildTextField(
                'Middle Name',
                _middleNameController,
                'Enter middle name (optional)',
              ),
            ]),
            _buildResponsiveRow([
              _buildTextField(
                'Last Name',
                _lastNameController,
                'Enter last name',
                isRequired: true,
              ),
              _buildDropdown(
                'Gender',
                _selectedGender,
                ['Male', 'Female', 'Other'],
                    (value) => setState(() => _selectedGender = value),
                isRequired: true,
              ),
            ]),
            _buildResponsiveRow([
              _buildDateField(
                'Date of Birth',
                _dateOfBirthController,
                isRequired: true,
              ),
              _buildTextField(
                'Blood Group',
                _bloodGroupController,
                'e.g., A+, B+, O-',
              ),
            ]),
            _buildResponsiveRow([
              _buildDropdown(
                'Nationality',
                _selectedNationality,
                _nationalityOptions,
                    (value) => setState(() => _selectedNationality = value),
                isRequired: true,
              ),
              _buildDropdown(
                'Category',
                _selectedCategory,
                ['General', 'OBC', 'SC', 'ST', 'Others'],
                    (value) => setState(() => _selectedCategory = value),
              ),
            ]),
            _buildDropdown(
              'Religion',
              _selectedReligion,
              _religionOptions,
                  (value) => setState(() => _selectedReligion = value),
            ),
            const SizedBox(height: 20),
            _buildPhotoUploadWidget(),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 2: CONTACT INFORMATION ====================
// ==================== TAB 2: CONTACT INFORMATION - COMPLETE REPLACEMENT ====================
  Widget _buildContactInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[1],
        child: _buildInputCard(
          children: [
            _buildSectionHeader('Primary Contact', Iconsax.call),
            const SizedBox(height: 20),

            _buildResponsiveRow([
              _buildTextField(
                'Mobile Number',
                _mobileNumberController,
                'Enter mobile number',
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                'Alternate Mobile',
                _alternateMobileController,
                'Enter alternate number',
                keyboardType: TextInputType.phone,
              ),
            ]),

            _buildTextField(
              'Email ID',
              _emailController,
              'Enter email address',
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Permanent Address', Iconsax.location),
            const SizedBox(height: 16),

            // ✅ Street Address
            _buildTextField(
              'Street Address',
              _permanentAddressStreetController,
              'Enter street address',
            ),

            // ✅ Country (Read-only, always India)
            _buildTextField(
              'Country',
              TextEditingController(text: _permanentCountry),
              'India',
              readOnly: true,
            ),

            // ✅ State Dropdown (Hierarchical)
            _buildResponsiveRow([
              _isLoadingPermanentStates
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLocationDropdown(
                'State',
                _selectedPermanentStateId,
                _permanentStates.map((s) => {'id': s.id, 'name': s.name}).toList(),
                    (value) {
                  setState(() {
                    _selectedPermanentStateId = value;
                    if (value != null) {
                      _loadPermanentDistricts(value);
                    }
                  });
                },
                isRequired: true,
              ),

              // ✅ District Dropdown
              _isLoadingPermanentDistricts
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLocationDropdown(
                'District',
                _selectedPermanentDistrictId,
                _permanentDistricts.map((d) => {'id': d.id, 'name': d.name}).toList(),
                    (value) {
                  setState(() {
                    _selectedPermanentDistrictId = value;
                    if (value != null) {
                      _loadPermanentCities(value);
                    }
                  });
                },
                isRequired: true,
              ),
            ]),

            _buildResponsiveRow([
              // ✅ City Dropdown
              _isLoadingPermanentCities
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLocationDropdown(
                'City',
                _selectedPermanentCityId,
                _permanentCities.map((c) => {'id': c.id, 'name': c.name}).toList(),
                    (value) {
                  setState(() => _selectedPermanentCityId = value);
                },
                isRequired: true,
              ),

              _buildTextField(
                'PIN Code',
                _permanentAddressPINController,
                'Enter PIN code',
                keyboardType: TextInputType.number,
              ),
            ]),

            const SizedBox(height: 24),

            // ✅ Current Address Section with "Same as Permanent" Checkbox
            Row(
              children: [
                _buildSectionHeader('Current Address', Iconsax.home),
                const Spacer(),
                Checkbox(
                  value: _isSameAsPermanent,
                  onChanged: (value) {
                    setState(() {
                      _isSameAsPermanent = value ?? false;
                      if (_isSameAsPermanent) {
                        _copySameAsPermanent();
                      }
                    });
                  },
                ),
                Text(
                  'Same as Permanent',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildTextField(
              'Street Address',
              _currentAddressStreetController,
              'Enter street address',
              readOnly: _isSameAsPermanent,
            ),

            // ✅ Country (Read-only, always India)
            _buildTextField(
              'Country',
              TextEditingController(text: _currentCountry),
              'India',
              readOnly: true,
            ),

            // ✅ State Dropdown
            _buildResponsiveRow([
              _isLoadingCurrentStates
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLocationDropdown(
                'State',
                _selectedCurrentStateId,
                _currentStates.map((s) => {'id': s.id, 'name': s.name}).toList(),
                    (value) {
                  if (!_isSameAsPermanent) {
                    setState(() {
                      _selectedCurrentStateId = value;
                      if (value != null) {
                        _loadCurrentDistricts(value);
                      }
                    });
                  }
                },
                isRequired: true,
                readOnly: _isSameAsPermanent,
              ),

              // ✅ District Dropdown
              _isLoadingCurrentDistricts
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLocationDropdown(
                'District',
                _selectedCurrentDistrictId,
                _currentDistricts.map((d) => {'id': d.id, 'name': d.name}).toList(),
                    (value) {
                  if (!_isSameAsPermanent) {
                    setState(() {
                      _selectedCurrentDistrictId = value;
                      if (value != null) {
                        _loadCurrentCities(value);
                      }
                    });
                  }
                },
                isRequired: true,
                readOnly: _isSameAsPermanent,
              ),
            ]),

            _buildResponsiveRow([
              // ✅ City Dropdown
              _isLoadingCurrentCities
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLocationDropdown(
                'City',
                _selectedCurrentCityId,
                _currentCities.map((c) => {'id': c.id, 'name': c.name}).toList(),
                    (value) {
                  if (!_isSameAsPermanent) {
                    setState(() => _selectedCurrentCityId = value);
                  }
                },
                isRequired: true,
                readOnly: _isSameAsPermanent,
              ),

              _buildTextField(
                'PIN Code',
                _currentAddressPINController,
                'Enter PIN code',
                keyboardType: TextInputType.number,
                readOnly: _isSameAsPermanent,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Location Dropdown Builder (State/District/City)
  Widget _buildLocationDropdown(
      String label,
      String? value,
      List<Map<String, String>> items,
      Function(String?) onChanged, {
        bool isRequired = false,
        bool readOnly = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: Colors.white,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? AppTheme.lightGrey : Colors.white,
            hintText: 'Select $label',
            hintStyle: GoogleFonts.inter(
              color: AppTheme.bodyText.withOpacity(0.6),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: items.isEmpty
              ? null
              : items.map((item) {
            return DropdownMenuItem<String>(
              value: item['id'],
              child: Text(
                item['name'] ?? '',
                style: GoogleFonts.inter(),
              ),
            );
          }).toList(),
          onChanged: readOnly ? null : onChanged,
          validator: isRequired
              ? (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          }
              : null,
        ),
      ],
    );
  }


// ✅ Helper Method: Copy Permanent to Current
  void _copySameAsPermanent() {
    setState(() {
      _currentAddressStreetController.text = _permanentAddressStreetController.text;
      _currentAddressPINController.text = _permanentAddressPINController.text;

      _selectedCurrentStateId = _selectedPermanentStateId;
      _selectedCurrentDistrictId = _selectedPermanentDistrictId;
      _selectedCurrentCityId = _selectedPermanentCityId;

      // Copy lists
      _currentStates = List.from(_permanentStates);
      _currentDistricts = List.from(_permanentDistricts);
      _currentCities = List.from(_permanentCities);
    });
  }



  // ==================== TAB 3: PARENT/GUARDIAN INFORMATION ====================
  Widget _buildParentInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[2],
        child: _buildInputCard(
          children: [
            _buildSectionHeader('Father Information', Iconsax.user_tag),
            const SizedBox(height: 20),
            _buildTextField(
              'Father Name',
              _fatherNameController,
              'Enter father name',
            ),
            _buildResponsiveRow([
              _buildTextField(
                'Occupation',
                _fatherOccupationController,
                'Enter occupation',
              ),
              _buildTextField(
                'Mobile Number',
                _fatherMobileController,
                'Enter mobile number',
                keyboardType: TextInputType.phone,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Mother Information', Iconsax.user_tag),
            const SizedBox(height: 20),
            _buildTextField(
              'Mother Name',
              _motherNameController,
              'Enter mother name',
            ),
            _buildResponsiveRow([
              _buildTextField(
                'Occupation',
                _motherOccupationController,
                'Enter occupation',
              ),
              _buildTextField(
                'Mobile Number',
                _motherMobileController,
                'Enter mobile number',
                keyboardType: TextInputType.phone,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader(
                'Guardian Information (if applicable)', Iconsax.shield_tick),
            const SizedBox(height: 20),
            _buildTextField(
              'Guardian Name',
              _guardianNameController,
              'Enter guardian name',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Guardian Mobile Number',
              _guardianMobileController,
              'Enter mobile number',
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 4: ACADEMIC INFORMATION ====================
  // TAB 4: ACADEMIC INFORMATION
// ==================== TAB 4: ACADEMIC INFORMATION - UPDATED ====================
  Widget _buildAcademicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[3],
        child: _buildInputCard(
          children: [
            _buildSectionHeader('Enrollment Details', Iconsax.book_1),
            const SizedBox(height: 20),

            // ✅ Class Dropdown - Shows "Class 1 - A" format
            _buildResponsiveRow([
              isLoadingClasses
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              )
                  : _buildClassDropdown(
                'Class',
                _selectedClassRecNo,
                classList,
                    (value) {
                  setState(() {
                    _selectedClassRecNo = value;

                    // ✅ Auto-fill Section/Division when class is selected
                    if (value != null) {
                      final selectedClass = classList.firstWhere(
                            (classData) => classData['ClassRecNo'] == value,
                        orElse: () => {},
                      );

                      // Auto-fill section from "Class 1 - A" format
                      if (selectedClass.isNotEmpty) {
                        final sectionName = selectedClass['Section_Name']?.toString() ?? '';
                        _sectionController.text = sectionName;

                        // ✅ Also auto-fill Current Class for consistency
                        final className = selectedClass['Class_Name']?.toString() ?? '';
                        _currentClassController.text = className;
                      }
                    } else {
                      // Clear section if no class selected
                     _sectionController.clear();
                      _currentClassController.clear();
                    }
                  });
                },
                isRequired: true,
              ),

              // Academic Year Dropdown
              _buildDropdown(
                'Academic Year',
                selectedAcademicYear,
                academicYears,
                    (value) {
                  setState(() {
                    selectedAcademicYear = value;
                    academicYearController.text = value ?? '';
                  });
                },
                isRequired: true,
              ),
            ]),

            _buildResponsiveRow([
              // ✅ Admission Date
              _buildDateField(
                'Admission Date',
                _admissionDateController,
                isRequired: true,
              ),

              // ✅ Admission Class - NOW USES CLASS DROPDOWN
              isLoadingClasses
                  ? const Center(child: CircularProgressIndicator())
                  : _buildClassDropdownForAdmission(
                'Admission Class',
                classList,
              _admissionClassController,
              ),
            ]),

            _buildResponsiveRow([
              // ✅ Section/Division - Auto-filled, but still editable
              _buildTextField(
                'Section/Division',
                _sectionController,
                'e.g., A, B, C',
                readOnly: false, // Allow manual edit if needed
              ),

              _buildTextField(
                'Roll Number',
                _rollNumberController,
                'Enter roll number',
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader('Previous Education', Iconsax.building_3),
            const SizedBox(height: 20),

            _buildTextField(
              'Previous School Name',
              _previousSchoolController,
              'Enter previous school name',
            ),

            _buildResponsiveRow([
              _buildTextField(
                'Previous Board/University',
                _previousBoardController,
                'Enter board name',
              ),
              _buildDropdown(
                'Medium of Instruction',
                _selectedMedium,
                _mediumOptions,
                    (value) {
                  setState(() {
                    _selectedMedium = value;
                    _mediumController.text = value ?? ''; // Also update controller
                  });
                },
                isRequired: true,
              ),
            ]),
          ],
        ),
      ),
    );
  }

// ✅ NEW: Class Dropdown for Current Class (with Section auto-fill)
  Widget _buildClassDropdown(
      String label,
      int? value,
      List<Map<String, dynamic>> classes,
      Function(int?) onChanged, {
        bool isRequired = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: value,
          dropdownColor: Colors.white,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Select Class',
            hintStyle: GoogleFonts.inter(
              color: AppTheme.bodyText.withOpacity(0.6),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: classes.map((classData) {
            return DropdownMenuItem<int>(
              value: classData['ClassRecNo'],
              child: Text(
                '${classData['Class_Name']} - ${classData['Section_Name']}',
                style: GoogleFonts.inter(),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: isRequired
              ? (value) {
            if (value == null) {
              return 'This field is required';
            }
            return null;
          }
              : null,
        ),
      ],
    );
  }

// ✅ NEW: Admission Class Dropdown (updates text controller)
  // ✅ FIXED: Admission Class Dropdown (uses ClassRecNo as value, not Class_Name)
  Widget _buildClassDropdownForAdmission(
      String label,
      List<Map<String, dynamic>> classes,
      TextEditingController controller,
      ) {
    // ✅ FIX: Find current ClassRecNo from controller text (Class_Name)
    int? currentClassRecNo;

    if (controller.text.isNotEmpty) {
      try {
        // Try to find matching class by Class_Name
        final matchingClass = classes.firstWhere(
              (classData) => classData['Class_Name']?.toString() == controller.text,
          orElse: () => {},
        );

        if (matchingClass.isNotEmpty) {
          currentClassRecNo = matchingClass['ClassRecNo'] as int?;
        }
      } catch (e) {
        currentClassRecNo = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: currentClassRecNo,
          dropdownColor: Colors.white,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Select Admission Class',
            hintStyle: GoogleFonts.inter(
              color: AppTheme.bodyText.withOpacity(0.6),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: classes.map((classData) {
            final className = classData['Class_Name']?.toString() ?? '';
            final sectionName = classData['Section_Name']?.toString() ?? '';
            final classRecNo = classData['ClassRecNo'] as int;
            final displayText = '$className - $sectionName';

            return DropdownMenuItem<int>(
              value: classRecNo, // ✅ Use ClassRecNo as unique value
              child: Text(
                displayText, // Display "Class 1 - A"
                style: GoogleFonts.inter(),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              // Find the selected class and store its Class_Name
              if (value != null) {
                final selectedClass = classes.firstWhere(
                      (classData) => classData['ClassRecNo'] == value,
                  orElse: () => {},
                );

                if (selectedClass.isNotEmpty) {
                  controller.text = selectedClass['Class_Name']?.toString() ?? '';
                }
              } else {
                controller.text = '';
              }
            });
          },
        ),
      ],
    );
  }



  // ==================== TAB 5: DOCUMENTS ====================
  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[4],
        child: _buildInputCard(
          children: [
            _buildSectionHeader('Identity and Certificates', Iconsax.document_text_1),
            const SizedBox(height: 20),
            _buildResponsiveRow([
              _buildTextField(
                'Aadhaar Number',
                _aadhaarController,
                'Enter 12-digit Aadhaar number',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                'Passport Number',
                _passportController,
                'Enter passport number (optional)',
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Certificates/Records', Iconsax.archive_book),
            const SizedBox(height: 20),
            _buildTextField(
              'Transfer Certificate No.',
              _transferCertController,
              'Enter TC number',
            ),
            _buildTextField(
              'Migration Certificate No.',
              _migrationCertController,
              'Enter migration cert number',
            ),
            _buildTextField(
              'Birth Certificate No.',
              _birthCertController,
              'Enter birth cert number',
            ),
            const SizedBox(height: 20),
            _buildCheckboxListTile(
              title: 'Medical Fitness Certificate Available',
              value: _medicalFitness,
              onChanged: (value) {
                setState(() => _medicalFitness = value ?? false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 6: OTHER INFORMATION ====================
  Widget _buildOtherInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[5],
        child: _buildInputCard(
          children: [
            _buildSectionHeader('Facilities & Aid', Iconsax.building_4),
            const SizedBox(height: 20),
            _buildCheckboxListTile(
              title: 'Hostel Facility Required',
              value: _hostelFacility,
              onChanged: (value) {
                setState(() => _hostelFacility = value ?? false);
              },
            ),
            _buildCheckboxListTile(
              title: 'Transport Facility Required',
              value: _transportFacility,
              onChanged: (value) {
                setState(() => _transportFacility = value ?? false);
              },
            ),
            if (_transportFacility)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildTextField(
                  'Bus Route Number',
                  _busRouteController,
                  'Enter assigned bus route number',
                  isResponsive: false, // Ensure full width inside card
                ),
              ),
            const SizedBox(height: 20),
            _buildCheckboxListTile(
              title: 'Scholarship/Financial Aid Required',
              value: _scholarshipAid,
              onChanged: (value) {
                setState(() => _scholarshipAid = value ?? false);
              },
            ),
            if (_scholarshipAid)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildTextField(
                  'Scholarship Details',
                  _scholarshipDetailsController,
                  'Enter scholarship/aid details (e.g., Govt. Scheme XYZ)',
                  maxLines: 3,
                  isResponsive: false,
                ),
              ),
            const SizedBox(height: 24),
            _buildSectionHeader(
                'Special Needs & Interests', Iconsax.info_circle),
            const SizedBox(height: 20),
            _buildTextField(
              'Special Needs/Disability',
              _specialNeedsController,
              'Specify any special needs or disabilities',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Extra-Curricular Interests',
              _extraCurricularController,
              'List interests (sports, arts, clubs, etc.)',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
// Find this part in your _buildOtherInfoTab method (around line 2800+)
// Replace ONLY the login credentials section (from "Login Credentials & Status" to the end)

            _buildSectionHeader('Login Credentials & Status', Iconsax.lock),
            const SizedBox(height: 20),

// ============ STUDENT LOGIN SECTION ============
            Text(
              'Student Login',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 12),

// ✅ NEW: Student Username with Verify Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    'Username',
                    _studentUsernameController,
                    'Enter student username',
                    readOnly: isEditMode,
                    onChanged: (_) {
                      setState(() {
                        _isStudentUserIdVerified = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: _isVerifyingStudentUserId
                      ? SizedBox(
                    width: 100,
                    height: 48,
                    child: Center(
                      child: BeautifulLoader(
                        type: LoaderType.dots,
                        size: 30,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  )
                      : ElevatedButton.icon(
                    onPressed: isEditMode ? null : _verifyStudentUserId,
                    icon: Icon(
                      _isStudentUserIdVerified
                          ? Icons.check_circle
                          : Icons.verified_user_outlined,
                      size: 18,
                    ),
                    label: Text(_isStudentUserIdVerified ? 'Verified' : 'Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isStudentUserIdVerified
                          ? AppTheme.primaryGreen
                          : AppTheme.primaryGreen.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

// ✅ Student Password (disabled until verified)
            _buildTextField(
              'Password',
              _studentPasswordController,
              _isStudentUserIdVerified ? 'Set password' : 'Verify User ID first',
              obscureText: true,
              readOnly: isEditMode || !_isStudentUserIdVerified,
            ),

// ✅ NEW: Warning message when not verified
            if (!_isStudentUserIdVerified && !isEditMode)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please verify the User ID before setting a password',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

// ============ PARENT LOGIN SECTION ============
            Text(
              'Parent Login',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 12),

// ✅ NEW: Parent Username with Verify Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    'Username',
                    _parentUsernameController,
                    'Enter parent username',
                    readOnly: isEditMode,
                    onChanged: (_) {
                      setState(() {
                        _isParentUserIdVerified = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: _isVerifyingParentUserId
                      ? SizedBox(
                    width: 100,
                    height: 48,
                    child: Center(
                      child: BeautifulLoader(
                        type: LoaderType.dots,
                        size: 30,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  )
                      : ElevatedButton.icon(
                    onPressed: isEditMode ? null : _verifyParentUserId,
                    icon: Icon(
                      _isParentUserIdVerified
                          ? Icons.check_circle
                          : Icons.verified_user_outlined,
                      size: 18,
                    ),
                    label: Text(_isParentUserIdVerified ? 'Verified' : 'Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isParentUserIdVerified
                          ? AppTheme.primaryGreen
                          : AppTheme.primaryGreen.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

// ✅ Parent Password (disabled until verified)
            _buildTextField(
              'Password',
              _parentPasswordController,
              _isParentUserIdVerified ? 'Set password' : 'Verify User ID first',
              obscureText: true,
              readOnly: isEditMode || !_isParentUserIdVerified,
            ),

// ✅ NEW: Warning message when not verified
            if (!_isParentUserIdVerified && !isEditMode)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please verify the User ID before setting a password',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
            _buildCheckboxListTile(
              title: 'Active Status',
              subtitle: 'Student is currently active in the system.',
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value ?? true);
              },
            ),

          ],
        ),
      ),
    );
  }

  // --- Utility/Helper Widgets ---



  Widget _buildInputCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          // Mobile/Half Screen: Stack children vertically
          return Column(
            children: children
                .map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            ))
                .toList(),
          );
        }
        // Desktop: Place children side-by-side with appropriate spacing
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children
              .map((child) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: child,
            ),
          ))
              .toList(),
        );
      },
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      String hint, {
        bool isRequired = false,
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        bool obscureText = false,
        bool readOnly = false,
        bool isResponsive = true, // Control padding for full width inside card
        Function(String)? onChanged,
      }) {
    final textField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
          readOnly: readOnly,
          onChanged: onChanged,
          style: GoogleFonts.inter(color: AppTheme.darkText, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppTheme.bodyText.withOpacity(0.6),
              fontSize: 14,
            ),
            filled: true,
            fillColor: readOnly ? AppTheme.lightGrey : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: isRequired
              ? (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          }
              : null,
        ),
      ],
    );
    // If not responsive, wrap in padding equivalent to the responsive row's margin/spacing
    if (!isResponsive) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: textField,
      );
    }
    return textField;
  }

  Widget _buildDropdown(
      String label,
      String? value,
      List<String> items,
      Function(String?) onChanged, {
        bool isRequired = false,
        bool readOnly = false,
      }) {
    // If readOnly is true, we disable the dropdown and use the current value.
    final List<String> effectiveItems = readOnly && value != null && !items.contains(value)
        ? [value!]
        : items;
    final String? effectiveValue = readOnly && value != null && !effectiveItems.contains(value)
        ? value // If readOnly and value not in list, use it as the only effective item/value
        : (value != null && items.contains(value) ? value : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: effectiveValue,
          dropdownColor: Colors.white,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? AppTheme.lightGrey : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: effectiveItems
              .map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, style: GoogleFonts.inter()),
          ))
              .toList(),
          onChanged: readOnly ? null : onChanged,
          validator: isRequired
              ? (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          }
              : null,
        ),
      ],
    );
  }

  Widget _buildDateField(
      String label,
      TextEditingController controller, {
        bool isRequired = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: GoogleFonts.inter(color: AppTheme.darkText, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Select date',
            hintStyle: GoogleFonts.inter(
              color: AppTheme.bodyText.withOpacity(0.6),
              fontSize: 14,
            ),
            suffixIcon: const Icon(Iconsax.calendar, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: controller.text.isNotEmpty
                  ? DateTime.tryParse(controller.text) ?? DateTime.now()
                  : DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppTheme.primaryGreen,
                      onPrimary: Colors.white,
                      onSurface: AppTheme.darkText,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                controller.text = DateFormat('yyyy-MM-dd').format(picked);
              });
            }
          },
          validator: isRequired
              ? (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          }
              : null,
        ),
      ],
    );
  }

  Widget _buildCheckboxListTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.bodyText),
        )
            : null,
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.primaryGreen,
        checkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  // ==================== BOTTOM BAR (Navigation Logic) ====================
  Widget _buildBottomBar() {
    return BlocBuilder<StudentBloc, StudentState>(
      builder: (context, state) {
        final isLoading = state is StudentOperationInProgressState;
        final isLastTab = _tabController.index == _kTotalTabs - 1;

        String buttonText = 'Next Step'; // Changed to 'Next Step' for consistency
        if (isLastTab) {
          buttonText = isEditMode ? 'Update Student' : 'Save Student'; // Changed to 'Save Student' for consistency
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.background, // Use AppTheme.background for consistency
            border: Border(
              top: BorderSide(color: AppTheme.borderGrey),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Previous Button (Visible after the first tab)
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  return Visibility(
                    visible: _tabController.index > 0,
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                        _tabController.animateTo(_tabController.index - 1);
                        setState(() {}); // Force UI update for button text/state
                      },
                      style: OutlinedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        foregroundColor: AppTheme.darkText, // Set foreground color
                        side: const BorderSide(color: AppTheme.borderGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
              if (_tabController.index > 0) const SizedBox(width: 12),
              // Main Action Button (Next or Submit)
              ElevatedButton.icon(
                onPressed: isLoading ? null : _handleNextOrSubmit,
                icon: isLastTab
                    ? Icon(isEditMode ? Iconsax.save_2 : Iconsax.add_square)
                    : const Icon(Iconsax.arrow_right_3),
                label: Text(
                  buttonText,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== NAVIGATION & SUBMISSION ====================

  void _handleNextOrSubmit() {
    final connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);

    // Validate current tab
    final currentKey = _formKeys[_tabController.index];
    if (currentKey == null || !currentKey.currentState!.validate()) {
      CustomSnackbar.showError(
        context,
        'Please complete all required fields on the current step before proceeding.',
        title: 'Validation Failed',
      );
      return;
    }

    // ✅ Mark current tab as completed
    setState(() {
      _completedTabs.add(_tabController.index);
    });

    // Check if this is the last tab
    if (_tabController.index < _kTotalTabs - 1) {
      // Move to next tab
      _tabController.animateTo(_tabController.index + 1);

      // ✅ Show success snackbar
      CustomSnackbar.showSuccess(
        context,
        'Section completed! Moving to next step.',
        title: '✅ Progress Saved',
      );

      setState(() {}); // Force UI update
    } else {
      // Last tab - check network before submission
      if (!connectivityProvider.isOnline) {
        CustomSnackbar.showError(
          context,
          'Cannot submit while offline. Please connect to internet first.',
          title: 'No Internet Connection',
        );
        return;
      }

      // Show confirmation dialog
      _showConfirmationDialog();
    }
  }




  // ==================== CONFIRMATION DIALOG ====================
  void _showConfirmationDialog() {
    final action = isEditMode ? 'Update' : 'Enroll';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Confirm $action Student', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text(
            'Are you sure you want to $action this student? Please verify all details before confirming.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.bodyText)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close confirmation dialog
                _handleSubmit(); // Proceed to final submission
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text('Confirm $action', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _handleSubmit() async {
    // Show loading indicator - RESPONSIVE VERSION
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  minWidth: 280,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isEditMode ? 'Updating Student...' : 'Creating Account...',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait, this may take a moment',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.bodyText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      String? userCodeForStudent;
      String? userCodeForParent;

      // STEP 1: Create Student User Account (if credentials provided)
      if (!isEditMode &&
          _studentUsernameController.text.isNotEmpty &&
          _studentPasswordController.text.isNotEmpty) {

        // Hash the student password
        final studentHashedData = await apiService.hashPassword(
          password: _studentPasswordController.text,
        );

        // Create student user master entry
        final studentUserResult = await apiService.insertUserMaster(
          userName: '${_firstNameController.text} ${_lastNameController.text}',
          userGroupCode: 5, // Student user group
          userId: _studentUsernameController.text,
          userPassword: null, // SEND NULL as requested
          salt: studentHashedData['salt'],
          encryptPassword: studentHashedData['hashedPassword'],
          isBlocked: 0,
          addUser: 'admin', // Replace with actual logged-in user
        );

        // Get the UserCode from response
        userCodeForStudent = studentUserResult['UserCode']?.toString();
      }

      // STEP 2: Create Parent User Account (if credentials provided)
      if (!isEditMode &&
          _parentUsernameController.text.isNotEmpty &&
          _parentPasswordController.text.isNotEmpty) {

        // Hash the parent password
        final parentHashedData = await apiService.hashPassword(
          password: _parentPasswordController.text,
        );

        // Create parent user master entry
        final parentUserResult = await apiService.insertUserMaster(
          userName: '${_fatherNameController.text.isNotEmpty ? _fatherNameController.text : _motherNameController.text} (Parent)',
          userGroupCode: 6, // Parent user group
          userId: _parentUsernameController.text,
          userPassword: null, // SEND NULL as requested
          salt: parentHashedData['salt'],
          encryptPassword: parentHashedData['hashedPassword'],
          isBlocked: 0,
          addUser: 'admin', // Replace with actual logged-in user
        );

        // Get the UserCode from response
        userCodeForParent = parentUserResult['UserCode']?.toString();
      }

      // STEP 3: Hash passwords for storing in student table (encrypted)
      String? studentEncryptedPassword;
      String? studentSalt;
      String? parentEncryptedPassword;
      String? parentSalt;

      if (_studentPasswordController.text.isNotEmpty) {
        final studentHashedData = await apiService.hashPassword(
          password: _studentPasswordController.text,
        );
        studentEncryptedPassword = studentHashedData['hashedPassword'];
        studentSalt = studentHashedData['salt'];
      }

      if (_parentPasswordController.text.isNotEmpty) {
        final parentHashedData = await apiService.hashPassword(
          password: _parentPasswordController.text,
        );
        parentEncryptedPassword = parentHashedData['hashedPassword'];
        parentSalt = parentHashedData['salt'];
      }

      // STEP 4: Prepare student data with UserCode in Student_ID field
      final studentData = {
        // ✅ ClassRecNo
        if (_selectedClassRecNo != null) 'ClassRecNo': _selectedClassRecNo,

        // ✅ Student_ID - Use UserCode or generate temp ID
        'Student_ID': isEditMode
            ? _studentIdController.text
            : (userCodeForStudent ?? 'STD${DateTime.now().millisecondsSinceEpoch}'),

        // ✅ Basic Info
        'Admission_Number': _admissionNumberController.text,
        'First_Name': _firstNameController.text,
        if (_middleNameController.text.isNotEmpty) 'Middle_Name': _middleNameController.text,
        'Last_Name': _lastNameController.text,
        'Gender': _selectedGender,
        'Date_of_Birth': _dateOfBirthController.text,
        if (_bloodGroupController.text.isNotEmpty) 'Blood_Group': _bloodGroupController.text,

        // ✅ UPDATED: Use dropdown values for Nationality and Religion
        if (_selectedNationality != null) 'Nationality': _selectedNationality,
        if (_selectedReligion != null) 'Religion': _selectedReligion,
        if (_selectedCategory != null) 'Category': _selectedCategory,

        if (_uploadedPhotoPath != null && _uploadedPhotoPath!.isNotEmpty)
          'Student_Photo_Path': _uploadedPhotoPath,

        // ✅ UPDATED: Permanent Address - NEW HIERARCHICAL STRUCTURE (State/District/City IDs)
        if (_permanentAddressStreetController.text.isNotEmpty)
          'Permanent_Address': _permanentAddressStreetController.text,
        if (_selectedPermanentCityId != null)
          'Permanent_City_ID': int.tryParse(_selectedPermanentCityId!),
        if (_selectedPermanentDistrictId != null)
          'Permanent_District_ID': int.tryParse(_selectedPermanentDistrictId!),
        if (_selectedPermanentStateId != null)
          'Permanent_State_ID': int.tryParse(_selectedPermanentStateId!),
        'Permanent_Country': _permanentCountry, // Always "India"
        if (_permanentAddressPINController.text.isNotEmpty)
          'Permanent_PIN': _permanentAddressPINController.text,

        // ✅ UPDATED: Current Address - NEW HIERARCHICAL STRUCTURE (State/District/City IDs)
        if (_currentAddressStreetController.text.isNotEmpty)
          'Current_Address': _currentAddressStreetController.text,
        if (_selectedCurrentCityId != null)
          'Current_City_ID': int.tryParse(_selectedCurrentCityId!),
        if (_selectedCurrentDistrictId != null)
          'Current_District_ID': int.tryParse(_selectedCurrentDistrictId!),
        if (_selectedCurrentStateId != null)
          'Current_State_ID': int.tryParse(_selectedCurrentStateId!),
        'Current_Country': _currentCountry, // Always "India"
        if (_currentAddressPINController.text.isNotEmpty)
          'Current_PIN': _currentAddressPINController.text,

        // ✅ Contact Info
        if (_mobileNumberController.text.isNotEmpty)
          'Mobile_Number': _mobileNumberController.text,
        if (_alternateMobileController.text.isNotEmpty)
          'Alternate_Contact_Number': _alternateMobileController.text,
        if (_emailController.text.isNotEmpty)
          'Email_ID': _emailController.text,

        // ✅ Parent Info
        if (_fatherNameController.text.isNotEmpty)
          'Father_Name': _fatherNameController.text,
        if (_fatherOccupationController.text.isNotEmpty)
          'Father_Occupation': _fatherOccupationController.text,
        if (_fatherMobileController.text.isNotEmpty)
          'Father_Mobile_Number': _fatherMobileController.text,
        if (_motherNameController.text.isNotEmpty)
          'Mother_Name': _motherNameController.text,
        if (_motherOccupationController.text.isNotEmpty)
          'Mother_Occupation': _motherOccupationController.text,
        if (_motherMobileController.text.isNotEmpty)
          'Mother_Mobile_Number': _motherMobileController.text,
        if (_guardianNameController.text.isNotEmpty)
          'Guardian_Name': _guardianNameController.text,
        if (_guardianMobileController.text.isNotEmpty)
          'Guardian_Contact_Number': _guardianMobileController.text,

        // ✅ Academic Info
        if (_admissionDateController.text.isNotEmpty)
          'Admission_Date': _admissionDateController.text,
        if (_admissionClassController.text.isNotEmpty)
          'Admission_Class': _admissionClassController.text,
        if (_currentClassController.text.isNotEmpty)
          'Current_Class': _currentClassController.text,
        if (_sectionController.text.isNotEmpty)
          'Section_Division': _sectionController.text,
        if (_rollNumberController.text.isNotEmpty)
          'Roll_Number': _rollNumberController.text,
        if (_previousSchoolController.text.isNotEmpty)
          'Previous_School_Name': _previousSchoolController.text,
        if (_previousBoardController.text.isNotEmpty)
          'Previous_Board_University': _previousBoardController.text,
        if (_mediumController.text.isNotEmpty)
          'Medium_of_Instruction': _mediumController.text,
        if (selectedAcademicYear != null)
          'Academic_Year': selectedAcademicYear,

        // ✅ Documents
        if (_aadhaarController.text.isNotEmpty)
          'Aadhaar_Number': _aadhaarController.text,
        if (_passportController.text.isNotEmpty)
          'Passport_Number': _passportController.text,
        if (_transferCertController.text.isNotEmpty)
          'Transfer_Certificate_No': _transferCertController.text,
        if (_migrationCertController.text.isNotEmpty)
          'Migration_Certificate_No': _migrationCertController.text,
        if (_birthCertController.text.isNotEmpty)
          'Birth_Certificate_No': _birthCertController.text,
        'Medical_Fitness_Certificate': _medicalFitness ? 1 : 0,

        // ✅ Other Info
        'Hostel_Facility': _hostelFacility ? 1 : 0,
        'Transport_Facility': _transportFacility ? 1 : 0,
        if (_busRouteController.text.isNotEmpty)
          'Bus_Route_No': _busRouteController.text,
        'Scholarship_Financial_Aid': _scholarshipAid ? 1 : 0,
        if (_scholarshipDetailsController.text.isNotEmpty)
          'Scholarship_Details': _scholarshipDetailsController.text,
        if (_specialNeedsController.text.isNotEmpty)
          'Special_Needs_Disability': _specialNeedsController.text,
        if (_extraCurricularController.text.isNotEmpty)
          'Extra_Curricular_Interests': _extraCurricularController.text,

        // ✅ Login Credentials - SEND ENCRYPTED PASSWORDS
        if (_studentUsernameController.text.isNotEmpty)
          'Student_Username': _studentUsernameController.text,
        if (studentEncryptedPassword != null)
          'Student_Password': studentEncryptedPassword, // ENCRYPTED
        if (_parentUsernameController.text.isNotEmpty)
          'Parent_Username': _parentUsernameController.text,
        if (parentEncryptedPassword != null)
          'Parent_Password': parentEncryptedPassword, // ENCRYPTED

        'IsActive': _isActive ? 1 : 0,
        'Operation_By': 'admin', // Replace with actual user
      };

      // STEP 5: Submit student data to database
      if (isEditMode) {
        context.read<StudentBloc>().add(
          UpdateStudentEvent(
            recNo: widget.student!.recNo!,
            studentData: studentData,
            schoolRecNo: widget.schoolRecNo,
          ),
        );
      } else {
        context.read<StudentBloc>().add(
          AddStudentEvent(
            studentData: studentData,
            schoolRecNo: widget.schoolRecNo,
          ),
        );
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // ✅ UPDATED: Enhanced Error Handling
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        // ✅ Check for specific duplicate errors
        if (errorMessage.contains('UserID already exists') ||
            errorMessage.contains('Student_ID already exists') ||
            errorMessage.contains('Student ID already exists') ||
            errorMessage.contains('Username already exists') ||
            errorMessage.contains('Admission Number already exists')) {

          // Show detailed error dialog with suggestions
          _showErrorDialog(
            '⚠️ Duplicate Entry Detected',
            errorMessage,
            [
              '• Try a different Student ID',
              '• Use a unique Username',
              '• Check if student already exists',
              '• Verify Admission Number is unique',
            ],
          );
        } else {
          // Show generic error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    }
  }

// ✅ NEW: Enhanced Error Dialog Method
  void _showErrorDialog(String title, String message, List<String> suggestions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 18,
                            color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Suggestions:',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...suggestions.map((suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 26),
                      child: Text(
                        suggestion,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.bodyText,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: AppTheme.bodyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Got it',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }



}