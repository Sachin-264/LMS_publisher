import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_model.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_service.dart';
import 'package:lms_publisher/Service/user_right_service.dart'; // ✅ ADD THIS
import '../../Theme/apptheme.dart';
import 'teacher_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../Util/custom_snackbar.dart'; // ✅ ADD THIS
import '../../Util/beautiful_loader.dart'; // ✅ ADD THIS

const int _kTotalTabs = 6;


class AddTeacherScreen extends StatefulWidget {
  final TeacherModel? teacher;
  final int schoolRecNo;

  const AddTeacherScreen({super.key, this.teacher, required this.schoolRecNo});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen>
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

  final Map<int, bool> _tabsCompleted = {
    0: false,
    1: false,
    2: false,
    3: false,
    4: false,
    5: false,
  };

  late TabController _tabController;
  final TeacherApiService apiService = TeacherApiService();
  final UserRightsService userRightsService = UserRightsService();

  bool get isEditMode => widget.teacher != null;

  bool _isVerifyingUserId = false;
  bool? _userIdVerified;

  // Photo Upload
  XFile? _selectedPhoto;
  bool _isUploadingPhoto = false;
  String? _uploadedPhotoPath;
  bool _isSameAsPermanent = false;



  // ✅ Hardcoded dropdown lists
  final List<String> _categoryList = ['General', 'OBC', 'SC', 'ST', 'EWS', 'Others'];
  final List<String> _employmentTypeList = ['Permanent', 'Contract', 'Visiting', 'Part-Time', 'Temporary'];
  final List<String> _employeeStatusList = ['Active', 'Inactive', 'On Leave', 'Retired', 'Terminated'];
  final List<String> _maritalStatusList = ['Single', 'Married', 'Divorced', 'Widowed'];
  // Dropdown lists for Nationality and Religion
  final List<String> _nationalityOptions = ['Indian', 'Nepali', 'Sri Lankan', 'Other'];
  final List<String> _religionOptions = ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 'Jain', 'Other'];

  String? _selectedNationality;
  String? _selectedReligion;


  // Controllers - Basic Information
  final _teacherCodeController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _religionController = TextEditingController();

  // Controllers - Contact Information
  final _mobileNumberController = TextEditingController();
  final _alternateContactController = TextEditingController();
  final _personalEmailController = TextEditingController();
  final _institutionalEmailController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final TextEditingController _permanentPinController = TextEditingController();
  final TextEditingController _currentPinController = TextEditingController();

  String? _selectedPermanentState;
  String? _selectedPermanentDistrict;
  String? _selectedPermanentCity;
  String _permanentCountry = "India";  // ✅ Default to India

// Current Address Dropdowns
  String? _selectedCurrentState;
  String? _selectedCurrentDistrict;
  String? _selectedCurrentCity;
  String _currentCountry = "India";  // ✅ Default to India

// Location Lists
  List<StateModel> _permanentStates = [];
  List<DistrictModel> _permanentDistricts = [];
  List<CityModel> _permanentCities = [];

  List<StateModel> _currentStates = [];
  List<DistrictModel> _currentDistricts = [];
  List<CityModel> _currentCities = [];

// Loading States
  bool _isLoadingPermanentStates = false;
  bool _isLoadingPermanentDistricts = false;
  bool _isLoadingPermanentCities = false;

  bool _isLoadingCurrentStates = false;
  bool _isLoadingCurrentDistricts = false;
  bool _isLoadingCurrentCities = false;

  // Controllers - Employment Details
  final _dateOfJoiningController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();
  final _subjectsTaughtController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceYearsController = TextEditingController();

  // Controllers - Identity & Documents
  final _aadhaarNumberController = TextEditingController();
  final _panNumberController = TextEditingController();
  final _passportNumberController = TextEditingController();
  final _photographController = TextEditingController();
  final _certificateFileController = TextEditingController();
  final _registrationNoController = TextEditingController();

  // Controllers - Payroll / Finance
  final _salaryIdController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _pfNumberController = TextEditingController();
  final _esiNumberController = TextEditingController();
  final _uanNumberController = TextEditingController();

  // Controllers - Other Information
  final _emergencyContactController = TextEditingController();
  final _specialSkillsController = TextEditingController();
  final _achievementsController = TextEditingController();
  final _extraResponsibilitiesController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();

  // ✅ Dropdown values
  String? _selectedGender;
  String? _selectedCategory;
  String? _selectedEmploymentType;
  String? _selectedEmployeeStatus;
  String? _selectedMaritalStatus;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kTotalTabs, vsync: this);

    // ✅ NEW: Listen to tab changes to update UI
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _loadPermanentStates();
    _loadCurrentStates();

    if (isEditMode) {
      _loadTeacherData();
      // ✅ Mark all tabs as completed in edit mode
      _tabsCompleted.forEach((key, value) {
        _tabsCompleted[key] = true;
      });
    }
  }

  // ✅ NEW: Verify UserID availability
  Future<void> _verifyUserId() async {
    final userId = _userNameController.text.trim();

    if (userId.isEmpty) {
      CustomSnackbar.showWarning(
        context,
        'Please enter a User ID first',
        title: 'Missing Input',
      );
      return;
    }

    setState(() {
      _isVerifyingUserId = true;
      _userIdVerified = null;
    });

    try {
      final exists = await userRightsService.checkUserIdExists(userId);

      setState(() {
        _userIdVerified = !exists; // true if available, false if taken
        _isVerifyingUserId = false;
      });

      if (!exists) {
        CustomSnackbar.showSuccess(
          context,
          'User ID "$userId" is available!',
          title: 'Available',
        );
      } else {
        CustomSnackbar.showError(
          context,
          'User ID "$userId" is already taken. Please choose another.',
          title: 'Not Available',
        );
      }
    } catch (e) {
      setState(() {
        _isVerifyingUserId = false;
        _userIdVerified = null;
      });
      CustomSnackbar.showError(
        context,
        'Failed to verify User ID: ${e.toString()}',
        title: 'Verification Failed',
      );
    }
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

      // ✅ Show BeautifulLoader
      OverlayLoader.show(
        context,
        message: 'Uploading photo...',
        type: LoaderType.spinner,
      );

      final photoPath = await apiService.uploadTeacherPhoto(image);

      // ✅ Hide loader
      OverlayLoader.hide();

      if (photoPath != null && photoPath.isNotEmpty) {
        setState(() {
          _uploadedPhotoPath = photoPath;
          _isUploadingPhoto = false;
        });

        if (mounted) {
          // ✅ Show success with CustomSnackbar
          CustomSnackbar.showSuccess(
            context,
            'Photo uploaded successfully!',
            title: 'Success',
          );
        }
      }
    } catch (e) {
      // ✅ Hide loader on error
      OverlayLoader.hide();

      setState(() {
        _isUploadingPhoto = false;
        _selectedPhoto = null;
      });

      if (mounted) {
        // ✅ Show error with CustomSnackbar
        CustomSnackbar.showError(
          context,
          'Failed to upload photo: $e',
          title: 'Upload Failed',
        );
      }
    }
  }



  // ✅ NEW: Load Permanent Address States
  Future<void> _loadPermanentStates() async {
    setState(() => _isLoadingPermanentStates = true);
    try {
      final states = await apiService.fetchStates();
      if (mounted) {
        setState(() {
          _permanentStates = states;
          _isLoadingPermanentStates = false;
        });
      }
    } catch (e) {
      print("❌ Error loading permanent states: $e");
      if (mounted) {
        setState(() => _isLoadingPermanentStates = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load states"), backgroundColor: Colors.red),
        );
      }
    }
  }

// ✅ NEW: Load Current Address States
  Future<void> _loadCurrentStates() async {
    setState(() => _isLoadingCurrentStates = true);
    try {
      final states = await apiService.fetchStates();
      if (mounted) {
        setState(() {
          _currentStates = states;
          _isLoadingCurrentStates = false;
        });
      }
    } catch (e) {
      print("❌ Error loading current states: $e");
      if (mounted) {
        setState(() => _isLoadingCurrentStates = false);
      }
    }
  }

// ✅ NEW: Load Permanent Districts
  Future<void> _loadPermanentDistricts(String stateId) async {
    setState(() {
      _isLoadingPermanentDistricts = true;
      _selectedPermanentDistrict = null;
      _selectedPermanentCity = null;
      _permanentDistricts = [];
      _permanentCities = [];
    });

    try {
      final districts = await apiService.fetchDistricts(stateId);
      if (mounted) {
        setState(() {
          _permanentDistricts = districts;
          _isLoadingPermanentDistricts = false;
        });
      }
    } catch (e) {
      print("❌ Error loading permanent districts: $e");
      if (mounted) {
        setState(() => _isLoadingPermanentDistricts = false);
      }
    }
  }

// ✅ NEW: Load Permanent Cities
  Future<void> _loadPermanentCities(String districtId) async {
    setState(() {
      _isLoadingPermanentCities = true;
      _selectedPermanentCity = null;
      _permanentCities = [];
    });

    try {
      final cities = await apiService.fetchCities(districtId);
      if (mounted) {
        setState(() {
          _permanentCities = cities;
          _isLoadingPermanentCities = false;
        });
      }
    } catch (e) {
      print("❌ Error loading permanent cities: $e");
      if (mounted) {
        setState(() => _isLoadingPermanentCities = false);
      }
    }
  }

// ✅ NEW: Load Current Districts
  Future<void> _loadCurrentDistricts(String stateId) async {
    setState(() {
      _isLoadingCurrentDistricts = true;
      _selectedCurrentDistrict = null;
      _selectedCurrentCity = null;
      _currentDistricts = [];
      _currentCities = [];
    });

    try {
      final districts = await apiService.fetchDistricts(stateId);
      if (mounted) {
        setState(() {
          _currentDistricts = districts;
          _isLoadingCurrentDistricts = false;
        });
      }
    } catch (e) {
      print("❌ Error loading current districts: $e");
      if (mounted) {
        setState(() => _isLoadingCurrentDistricts = false);
      }
    }
  }

// ✅ NEW: Load Current Cities
  Future<void> _loadCurrentCities(String districtId) async {
    setState(() {
      _isLoadingCurrentCities = true;
      _selectedCurrentCity = null;
      _currentCities = [];
    });

    try {
      final cities = await apiService.fetchCities(districtId);
      if (mounted) {
        setState(() {
          _currentCities = cities;
          _isLoadingCurrentCities = false;
        });
      }
    } catch (e) {
      print("❌ Error loading current cities: $e");
      if (mounted) {
        setState(() => _isLoadingCurrentCities = false);
      }
    }
  }

  // ✅ NEW: Validate current tab and mark as complete
  bool _validateAndMarkTab(int tabIndex) {
    final formKey = _formKeys[tabIndex];

    // Special check for photo requirement in Basic Info tab (tab 0)
    if (tabIndex == 0 && !isEditMode) {
      if (_uploadedPhotoPath == null && _selectedPhoto == null) {
        CustomSnackbar.showError(
          context,
          'Please upload a teacher photo before proceeding',
          title: 'Photo Required',
        );
        return false;
      }
    }

    // Validate form fields
    if (formKey?.currentState?.validate() ?? false) {
      setState(() {
        _tabsCompleted[tabIndex] = true;
      });
      return true;
    } else {
      CustomSnackbar.showWarning(
        context,
        'Please fill all required fields correctly in this section',
        title: 'Incomplete Form',
      );
      return false;
    }
  }

  // ✅ NEW: Calculate completion percentage





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
                'Teacher Photo',
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
                    TeacherApiService.getTeacherPhotoUrl(_uploadedPhotoPath),
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



  void _loadTeacherData() {
    final teacher = widget.teacher!;
    _uploadedPhotoPath = teacher.photograph;
    _teacherCodeController.text = teacher.teacherCode ?? '';
    _employeeCodeController.text = teacher.employeeCode ?? '';
    _firstNameController.text = teacher.firstName;
    _middleNameController.text = teacher.middleName ?? '';
    _lastNameController.text = teacher.lastName;
    _dateOfBirthController.text = teacher.dateOfBirth;
    _bloodGroupController.text = teacher.bloodGroup ?? '';
    _selectedNationality = teacher.nationality;  // ✅ ADD THIS
    _selectedReligion = teacher.religion;

    // ✅ Set dropdown values
    _selectedGender = teacher.gender;
    _selectedCategory = teacher.category;

    // Contact
    _mobileNumberController.text = teacher.mobileNumber ?? '';
    _alternateContactController.text = teacher.alternateContactNumber ?? '';
    _personalEmailController.text = teacher.personalEmail ?? '';
    _institutionalEmailController.text = teacher.institutionalEmail ?? '';
    _permanentAddressController.text = teacher.permanentAddress ?? '';
    _currentAddressController.text = teacher.currentAddress ?? '';

    // ✅ NEW: Populate Address Fields
    _permanentCountry = teacher.permanentCountry ?? "India";
    _currentCountry = teacher.currentCountry ?? "India";
    _permanentPinController.text = teacher.permanentPin ?? '';
    _currentPinController.text = teacher.currentPin ?? '';

    // ✅ Set dropdown values and load dependent data for Permanent Address
    if (teacher.permanentStateId != null) {
      _selectedPermanentState = teacher.permanentStateId.toString();
      _loadPermanentDistricts(_selectedPermanentState!);
    }
    if (teacher.permanentDistrictId != null) {
      _selectedPermanentDistrict = teacher.permanentDistrictId.toString();
      _loadPermanentCities(_selectedPermanentDistrict!);
    }
    if (teacher.permanentCityId != null) {
      _selectedPermanentCity = teacher.permanentCityId.toString();
    }

    // ✅ Set dropdown values and load dependent data for Current Address
    if (teacher.currentStateId != null) {
      _selectedCurrentState = teacher.currentStateId.toString();
      _loadCurrentDistricts(_selectedCurrentState!);
    }
    if (teacher.currentDistrictId != null) {
      _selectedCurrentDistrict = teacher.currentDistrictId.toString();
      _loadCurrentCities(_selectedCurrentDistrict!);
    }
    if (teacher.currentCityId != null) {
      _selectedCurrentCity = teacher.currentCityId.toString();
    }

    // Employment
    _dateOfJoiningController.text = teacher.dateOfJoining ?? '';
    _designationController.text = teacher.designation ?? '';
    _departmentController.text = teacher.department ?? '';
    _subjectsTaughtController.text = teacher.subjectsTaught ?? '';
    _qualificationController.text = teacher.qualification ?? '';
    _experienceYearsController.text = teacher.experienceYears?.toString() ?? '';
    _selectedEmploymentType = teacher.employmentType;
    _selectedEmployeeStatus = teacher.employeeStatus;

    // Documents
    _aadhaarNumberController.text = teacher.aadhaarNumber ?? '';
    _panNumberController.text = teacher.panNumber ?? '';
    _passportNumberController.text = teacher.passportNumber ?? '';
    _photographController.text = teacher.photograph ?? '';
    _certificateFileController.text = teacher.certificateFile ?? '';
    _registrationNoController.text = teacher.registrationNo ?? '';

    // Payroll
    _salaryIdController.text = teacher.salaryId?.toString() ?? '';
    _bankAccountNumberController.text = teacher.bankAccountNumber ?? '';
    _ifscCodeController.text = teacher.ifscCode ?? '';
    _bankNameController.text = teacher.bankName ?? '';
    _pfNumberController.text = teacher.pfNumber ?? '';
    _esiNumberController.text = teacher.esiNumber ?? '';
    _uanNumberController.text = teacher.uanNumber ?? '';

    // Other
    _selectedMaritalStatus = teacher.maritalStatus;
    _emergencyContactController.text = teacher.emergencyContact ?? '';
    _specialSkillsController.text = teacher.specialSkills ?? '';
    _achievementsController.text = teacher.achievements ?? '';
    _extraResponsibilitiesController.text = teacher.extraResponsibilities ?? '';
    _userNameController.text = teacher.userName ?? '';

    // ✅ Use placeholder if in edit mode and password exists
    _passwordController.text = (teacher.password != null && teacher.password!.isNotEmpty)
        ? '••••••••'
        : '';
    _isActive = teacher.isActive ?? true;
  }


  @override
  void dispose() {
    _tabController.dispose();
    // Dispose all controllers
    _teacherCodeController.dispose();
    _employeeCodeController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _bloodGroupController.dispose();
    _nationalityController.dispose();
    _religionController.dispose();
    _mobileNumberController.dispose();
    _alternateContactController.dispose();
    _personalEmailController.dispose();
    _institutionalEmailController.dispose();
    _permanentAddressController.dispose();
    _currentAddressController.dispose();
    _dateOfJoiningController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    _subjectsTaughtController.dispose();
    _qualificationController.dispose();
    _experienceYearsController.dispose();
    _aadhaarNumberController.dispose();
    _panNumberController.dispose();
    _passportNumberController.dispose();
    _photographController.dispose();
    _certificateFileController.dispose();
    _registrationNoController.dispose();
    _salaryIdController.dispose();
    _bankAccountNumberController.dispose();
    _ifscCodeController.dispose();
    _bankNameController.dispose();
    _pfNumberController.dispose();
    _esiNumberController.dispose();
    _uanNumberController.dispose();
    _emergencyContactController.dispose();
    _specialSkillsController.dispose();
    _achievementsController.dispose();
    _extraResponsibilitiesController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: _buildAppBar(),
      body: BlocListener<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is TeacherOperationSuccessState) {
            CustomSnackbar.showSuccess(
              context,
              state.message,
              title: isEditMode ? 'Updated' : 'Added',
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && Navigator.canPop(context)) {
                Navigator.of(context).pop(true);
              }
            });
          } else if (state is TeacherErrorState) {
            CustomSnackbar.showError(
              context,
              state.error,
              title: 'Error',
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
                  _buildEmploymentDetailsTab(),
                  _buildDocumentsTab(),
                  _buildPayrollFinanceTab(),
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
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left, color: AppTheme.darkText),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        isEditMode ? 'Edit Teacher Details' : 'Add New Teacher',
        style: GoogleFonts.poppins(
          color: AppTheme.darkText,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
      actions: [
        // ADD THIS PROGRESS INDICATOR
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: buildProgressIndicator(),
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primaryGreen,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.bodyText,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        tabs: [
          // ✅ Each tab now shows completion checkmark
          Tab(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.user, size: 18),
                if (_tabsCompleted[0] == true) ...[
                  const SizedBox(width: 4),
                  const Icon(Iconsax.tick_circle, size: 14, color: AppTheme.primaryGreen),
                ],
              ],
            ),
            text: 'Basic Info',
          ),
          Tab(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.call, size: 18),
                if (_tabsCompleted[1] == true) ...[
                  const SizedBox(width: 4),
                  const Icon(Iconsax.tick_circle, size: 14, color: AppTheme.primaryGreen),
                ],
              ],
            ),
            text: 'Contact',
          ),
          Tab(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.briefcase, size: 18),
                if (_tabsCompleted[2] == true) ...[
                  const SizedBox(width: 4),
                  const Icon(Iconsax.tick_circle, size: 14, color: AppTheme.primaryGreen),
                ],
              ],
            ),
            text: 'Employment',
          ),
          Tab(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.document_text_1, size: 18),
                if (_tabsCompleted[3] == true) ...[
                  const SizedBox(width: 4),
                  const Icon(Iconsax.tick_circle, size: 14, color: AppTheme.primaryGreen),
                ],
              ],
            ),
            text: 'Documents',
          ),
          Tab(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.wallet_money, size: 18),
                if (_tabsCompleted[4] == true) ...[
                  const SizedBox(width: 4),
                  const Icon(Iconsax.tick_circle, size: 14, color: AppTheme.primaryGreen),
                ],
              ],
            ),
            text: 'Finance',
          ),
          Tab(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.info_circle, size: 18),
                if (_tabsCompleted[5] == true) ...[
                  const SizedBox(width: 4),
                  const Icon(Iconsax.tick_circle, size: 14, color: AppTheme.primaryGreen),
                ],
              ],
            ),
            text: 'Other',
          ),
        ],
      ),
    );
  }

  // Progress indicator showing completion percentage
  Widget buildProgressIndicator() {
    final completedCount = _tabsCompleted.values.where((completed) => completed).length;
    final progress = completedCount / _kTotalTabs;
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



  // ==================== TAB 1: BASIC INFORMATION ====================
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[0],
        child: _buildInputCard(
          children: [
            _buildSectionHeader('Basic Identity Details', Iconsax.user_octagon),
            const SizedBox(height: 20),

            // Employee Code (Teacher Code commented out as auto-generated)
            _buildResponsiveRow([
              _buildTextField(
                'Employee Code',
                _employeeCodeController,
                'Enter employee code',
                isRequired: true,
              ),
            ]),

            // First Name & Middle Name
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

            // Last Name & Gender
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

            // Date of Birth & Blood Group
            _buildResponsiveRow([
              _buildDateField(
                'Date of Birth',
                _dateOfBirthController,
                isRequired: true,
              ),
              _buildTextField(
                'Blood Group',
                _bloodGroupController,
                'e.g., A+, O-, AB+',
              ),
            ]),

            // ✅ NATIONALITY & CATEGORY - Updated Nationality to Dropdown
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
                _categoryList,
                    (value) => setState(() => _selectedCategory = value),
                isRequired: true,
              ),
            ]),

            // ✅ RELIGION - Updated to Dropdown
            _buildResponsiveRow([
              _buildDropdown(
                'Religion',
                _selectedReligion,
                _religionOptions,
                    (value) => setState(() => _selectedReligion = value),
                isRequired: false,
              ),
            ]),

            const SizedBox(height: 20),
            _buildPhotoUploadWidget(),
          ],
        ),
      ),
    );
  }


  // ==================== TAB 2: CONTACT INFORMATION ====================
  Widget _buildContactInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[1],
        child: _buildInputCard(
          children: [
            _buildSectionHeader('Primary Contact', Iconsax.call_calling),
            const SizedBox(height: 20),
            _buildResponsiveRow([
              _buildTextField(
                'Mobile Number',
                _mobileNumberController,
                'Enter 10-digit mobile number',
                keyboardType: TextInputType.phone,
                isRequired: true,
              ),
              _buildTextField(
                'Alternate Contact Number',
                _alternateContactController,
                'Enter alternate contact (optional)',
                keyboardType: TextInputType.phone,
              ),
            ]),
            _buildResponsiveRow([
              _buildTextField(
                'Email ID (Personal)',
                _personalEmailController,
                'Enter personal email',
                keyboardType: TextInputType.emailAddress,
                isRequired: true,
              ),
              _buildTextField(
                'Institutional Email ID',
                _institutionalEmailController,
                'Enter institutional email',
                keyboardType: TextInputType.emailAddress,
              ),
            ]),
            const SizedBox(height: 12),
            _buildSectionHeader('Address Details', Iconsax.location),
            const SizedBox(height: 20),

            // ============ PERMANENT ADDRESS SECTION ============
            Text(
              'Permanent Address',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.bodyText,
              ),
            ),
            const SizedBox(height: 12),

            // Country (Read-only, default India)
            _buildTextField(
              'Country',
              TextEditingController(text: _permanentCountry),
              'Country',
              readOnly: true,
            ),

            // State Dropdown
            _buildDropdownField(
              label: 'State *',
              value: _selectedPermanentState,
              items: _permanentStates.map((state) => DropdownMenuItem(
                value: state.id,
                child: Text(state.name),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPermanentState = value;
                  _selectedPermanentDistrict = null;
                  _selectedPermanentCity = null;
                  _permanentDistricts = [];
                  _permanentCities = [];
                });
                if (value != null) {
                  _loadPermanentDistricts(value);
                }
              },
              icon: Iconsax.location,
              isLoading: _isLoadingPermanentStates,
            ),

            // District Dropdown
            _buildDropdownField(
              label: 'District *',
              value: _selectedPermanentDistrict,
              items: _permanentDistricts.map((district) => DropdownMenuItem(
                value: district.id,
                child: Text(district.name),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPermanentDistrict = value;
                  _selectedPermanentCity = null;
                  _permanentCities = [];
                });
                if (value != null) {
                  _loadPermanentCities(value);
                }
              },
              icon: Iconsax.map,
              isLoading: _isLoadingPermanentDistricts,
            ),

            // City Dropdown
            _buildDropdownField(
              label: 'City *',
              value: _selectedPermanentCity,
              items: _permanentCities.map((city) => DropdownMenuItem(
                value: city.id,
                child: Text(city.name),
              )).toList(),
              onChanged: (value) {
                setState(() => _selectedPermanentCity = value);
              },
              icon: Iconsax.building,
              isLoading: _isLoadingPermanentCities,
            ),

            // PIN Code
            _buildTextField(
              'PIN Code',
              _permanentPinController,
              'Enter PIN code',
              keyboardType: TextInputType.number,
            ),

            // Full Address
            _buildTextField(
              'Full Address',
              _permanentAddressController,
              'Enter complete address',
              maxLines: 3,
            ),

            // ============ CURRENT ADDRESS SECTION ============
            const SizedBox(height: 24),
            Text(
              'Current Address',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.bodyText,
              ),
            ),
            const SizedBox(height: 12),

// ✅ NEW: Same as Permanent Address Checkbox
            Container(
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: CheckboxListTile(
                title: Text(
                  'Same as Permanent Address',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                value: _isSameAsPermanent,
                activeColor: AppTheme.accentGreen,
                onChanged: (bool? value) {
                  setState(() {
                    _isSameAsPermanent = value ?? false;
                    if (_isSameAsPermanent) {
                      _copyPermanentToCurrent();
                    } else {
                      _clearCurrentAddress();
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            const SizedBox(height: 12),

            // Country (Read-only, default India)
            _buildTextField(
              'Country',
              TextEditingController(text: _currentCountry),
              'Country',
              readOnly: true,
            ),

            // State Dropdown
            _buildDropdownField(
              label: 'State *',
              value: _selectedCurrentState,
              items: _currentStates.map((state) => DropdownMenuItem(
                value: state.id,
                child: Text(state.name),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrentState = value;
                  _selectedCurrentDistrict = null;
                  _selectedCurrentCity = null;
                  _currentDistricts = [];
                  _currentCities = [];
                });
                if (value != null) {
                  _loadCurrentDistricts(value);
                }
              },
              icon: Iconsax.location,
              isLoading: _isLoadingCurrentStates,
            ),

            // District Dropdown
            _buildDropdownField(
              label: 'District *',
              value: _selectedCurrentDistrict,
              items: _currentDistricts.map((district) => DropdownMenuItem(
                value: district.id,
                child: Text(district.name),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrentDistrict = value;
                  _selectedCurrentCity = null;
                  _currentCities = [];
                });
                if (value != null) {
                  _loadCurrentCities(value);
                }
              },
              icon: Iconsax.map,
              isLoading: _isLoadingCurrentDistricts,
            ),

            // City Dropdown
            _buildDropdownField(
              label: 'City *',
              value: _selectedCurrentCity,
              items: _currentCities.map((city) => DropdownMenuItem(
                value: city.id,
                child: Text(city.name),
              )).toList(),
              onChanged: (value) {
                setState(() => _selectedCurrentCity = value);
              },
              icon: Iconsax.building,
              isLoading: _isLoadingCurrentCities,
            ),

            // PIN Code
            _buildTextField(
              'PIN Code',
              _currentPinController,
              'Enter PIN code',
              keyboardType: TextInputType.number,
            ),

            // Full Address
            _buildTextField(
              'Current Address',
              _currentAddressController,
              'Enter complete address',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required IconData icon,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with asterisk
          RichText(
            text: TextSpan(
              text: label.replaceAll(' *', ''),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
              children: [
                if (label.contains('*'))
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Dropdown
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderGrey),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: AppTheme.accentGreen, size: 20),
                suffixIcon: isLoading
                    ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                    ),
                  ),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: items,
              onChanged: isLoading ? null : onChanged,
              isExpanded: true,
              hint: Text(
                'Select ${label.replaceAll(' *', '')}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.bodyText,
                ),
              ),
              dropdownColor: Colors.white,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.darkText,
                fontWeight: FontWeight.w500,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.accentGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ==================== TAB 3: EMPLOYMENT DETAILS ====================
  Widget _buildEmploymentDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[2],
        child: _buildInputCard(
          children: [
            _buildSectionHeader('Employment / Job Details', Iconsax.briefcase),
            const SizedBox(height: 20),
            _buildResponsiveRow([
              _buildDateField(
                'Date of Joining',
                _dateOfJoiningController,
                isRequired: true,
              ),
              _buildTextField(
                'Designation',
                _designationController,
                'e.g., Principal, Teacher',
                isRequired: true,
              ),
            ]),
            _buildResponsiveRow([
              _buildTextField(
                'Department',
                _departmentController,
                'e.g., Science, Mathematics',
                isRequired: true,
              ),
              _buildTextField(
                'Qualification',
                _qualificationController,
                'e.g., B.Ed, M.Ed',
                isRequired: true,
              ),
            ]),
            _buildResponsiveRow([
              _buildTextField(
                'Experience (Years)',
                _experienceYearsController,
                'Total years of experience',
                keyboardType: TextInputType.number,
              ),
              _buildDropdown(
                'Employment Type',
                _selectedEmploymentType,
                _employmentTypeList,
                    (value) => setState(() => _selectedEmploymentType = value),
                isRequired: true,
              ),
            ]),
            _buildResponsiveRow([
              _buildDropdown(
                'Employee Status',
                _selectedEmployeeStatus,
                _employeeStatusList,
                    (value) => setState(() => _selectedEmployeeStatus = value),
                isRequired: true,
              ),
            ]),
            _buildTextField(
              'Subject(s) Taught',
              _subjectsTaughtController,
              'e.g., Physics, Chemistry',
              maxLines: 2,
              isResponsive: false,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 4: IDENTITY & DOCUMENTS ====================
  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[3],
        child: _buildInputCard(
          children: [
            _buildSectionHeader('Identity & Documents', Iconsax.document_text_1),
            const SizedBox(height: 20),
            _buildResponsiveRow([
              _buildTextField(
                'Aadhaar Number',
                _aadhaarNumberController,
                'Enter 12-digit Aadhaar number',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                'PAN Number',
                _panNumberController,
                'Enter PAN card number',
              ),
            ]),
            _buildResponsiveRow([
              _buildTextField(
                'Passport Number',
                _passportNumberController,
                'Enter passport number',
              ),
              _buildTextField(
                'Registration No.',
                _registrationNoController,
                'Enter registration number',
              ),
            ]),
            _buildResponsiveRow([
              // _buildTextField(
              //   'Photograph URL/Path',
              //   _photographController,
              //   'Upload or enter photo URL',
              // ),
              _buildTextField(
                'Certificates',
                _certificateFileController,
                'Upload certificates file path',
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 5: PAYROLL / FINANCE ====================
  Widget _buildPayrollFinanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKeys[4],
        child: _buildInputCard(
          children: [
            _buildSectionHeader('Payroll / Finance Details', Iconsax.wallet_money),
            const SizedBox(height: 20),
            _buildResponsiveRow([
              _buildTextField(
                'Salary ID',
                _salaryIdController,
                'Enter salary ID',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                'Bank Account Number',
                _bankAccountNumberController,
                'Enter bank account number',
                keyboardType: TextInputType.number,
              ),
            ]),
            _buildResponsiveRow([
              _buildTextField(
                'IFSC Code',
                _ifscCodeController,
                'Enter bank IFSC code',
              ),
              _buildTextField(
                'Bank Name',
                _bankNameController,
                'Enter bank name',
              ),
            ]),
            _buildResponsiveRow([
              _buildTextField(
                'PF Number',
                _pfNumberController,
                'Enter Provident Fund number',
              ),
              _buildTextField(
                'ESI Number',
                _esiNumberController,
                'Enter ESI number',
              ),
            ]),
            _buildTextField(
              'UAN Number',
              _uanNumberController,
              'Enter Universal Account Number',
              isResponsive: false,
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
        key: _formKeys[5], // ✅ Form key for tab 5
        child: Column(
          children: [
            _buildInputCard(
              children: [
                _buildSectionHeader('General Information', Iconsax.info_circle),
                const SizedBox(height: 20),
                _buildResponsiveRow([
                  _buildDropdown(
                    'Marital Status',
                    _selectedMaritalStatus,
                    _maritalStatusList,
                        (value) => setState(() => _selectedMaritalStatus = value),
                  ),
                  _buildTextField(
                    'Emergency Contact',
                    _emergencyContactController,
                    'Name and contact number',
                    isRequired: true,
                  ),
                ]),
                _buildTextField(
                  'Special Skills',
                  _specialSkillsController,
                  'Any special skills or expertise',
                  maxLines: 2,
                  isResponsive: false,
                ),
                _buildTextField(
                  'Achievements',
                  _achievementsController,
                  'Notable achievements or awards',
                  maxLines: 2,
                  isResponsive: false,
                ),
                _buildTextField(
                  'Extra-Curricular Responsibilities',
                  _extraResponsibilitiesController,
                  'Any additional responsibilities',
                  maxLines: 2,
                  isResponsive: false,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ✅ Login Details Card with UserID Verification
            _buildInputCard(
              children: [
                _buildSectionHeader('Login Details & Status', Iconsax.lock),
                const SizedBox(height: 20),

                // ✅ UserID field with Verify button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'User ID',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText,
                        ),
                        children: [
                          if (!isEditMode)
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _userNameController,
                            readOnly: isEditMode,
                            style: GoogleFonts.inter(
                              color: AppTheme.darkText,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter username for login',
                              hintStyle: GoogleFonts.inter(
                                color: AppTheme.bodyText.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: isEditMode ? AppTheme.lightGrey : Colors.white,
                              suffixIcon: _userIdVerified != null
                                  ? Icon(
                                _userIdVerified!
                                    ? Iconsax.tick_circle
                                    : Iconsax.close_circle,
                                color: _userIdVerified!
                                    ? AppTheme.primaryGreen
                                    : Colors.red,
                              )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.borderGrey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _userIdVerified == false
                                      ? Colors.red
                                      : AppTheme.borderGrey,
                                  width: _userIdVerified == false ? 2 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryGreen,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (_) {
                              // Reset verification when user types
                              if (_userIdVerified != null) {
                                setState(() => _userIdVerified = null);
                              }
                            },
                            validator: (value) {
                              if (!isEditMode && (value == null || value.isEmpty)) {
                                return 'This field is required';
                              }
                              return null;
                            },
                          ),
                        ),

                        // ✅ Verify Button (only in add mode)
                        if (!isEditMode) ...[
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isVerifyingUserId ? null : _verifyUserId,
                            icon: _isVerifyingUserId
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                                : const Icon(Iconsax.shield_tick, size: 18),
                            label: Text(
                              'Verify',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // ✅ Verification Status Messages
                    if (_userIdVerified == false) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.close_circle,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'This User ID is already taken. Please choose another.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_userIdVerified == true) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.tick_circle,
                            size: 16,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'This User ID is available!',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Password field
                _buildTextField(
                  'Password',
                  _passwordController,
                  isEditMode ? 'Leave blank to keep current' : 'Enter password',
                  obscureText: true,
                  isRequired: !isEditMode,
                  readOnly: isEditMode,
                ),

                const SizedBox(height: 12),
                _buildStatusSwitchListTile(),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // ==================== HELPER WIDGETS ====================
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
          return Column(
            children: children
                .map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            ))
                .toList(),
          );
        }
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
        bool isResponsive = true,
        Function(String)? onChanged,
        String? Function(String?)? validator,
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
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator ??
                  (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  return 'This field is required';
                }
                if (keyboardType == TextInputType.emailAddress && value!.isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                }
                return null;
              },
        ),
      ],
    );
    if (!isResponsive) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: textField,
      );
    }
    return textField;
  }

  // ✅ FIXED: Dropdown with proper null handling
  Widget _buildDropdown(
      String label,
      String? value,
      List<String> items,
      Function(String?) onChanged, {
        bool isRequired = false,
        bool readOnly = false,
      }) {
    // ✅ Ensure value is either null or exists in items list
    final String? effectiveValue = (value != null && items.contains(value)) ? value : null;

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
          value: effectiveValue, // ✅ Use sanitized value
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
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: items
              .map((item) => DropdownMenuItem<String>(
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
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildStatusSwitchListTile() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: SwitchListTile(
        title: Text(
          'Active Status',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        subtitle: Text(
          _isActive ? 'This teacher account is active' : 'This teacher account is inactive',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.bodyText,
          ),
        ),
        value: _isActive,
        onChanged: (value) {
          setState(() {
            _isActive = value;
          });
        },
        activeColor: AppTheme.primaryGreen,
        secondary: Icon(
          _isActive ? Iconsax.tick_circle : Iconsax.close_circle,
          color: _isActive ? AppTheme.primaryGreen : Colors.red,
        ),
      ),
    );
  }


  // ==================== BOTTOM BAR ====================
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: const Border(
          top: BorderSide(color: AppTheme.borderGrey),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Back button (only show if not on first tab)
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              return Visibility(
                visible: _tabController.index > 0,
                child: OutlinedButton(
                  onPressed: () {
                    _tabController.animateTo(_tabController.index - 1);
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    foregroundColor: AppTheme.darkText,
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

          // Next/Submit button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleNextOrSubmit,
              icon: Icon(
                _tabController.index == _kTotalTabs - 1
                    ? (isEditMode ? Iconsax.save_2 : Iconsax.add_square)
                    : Iconsax.arrow_right_3,
                size: 18,
              ),
              label: Text(
                _tabController.index == _kTotalTabs - 1
                    ? (isEditMode ? 'Update Teacher' : 'Save Teacher')
                    : 'Next Step',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ==================== SUBMIT LOGIC ====================
// ✅ UPDATED: Handle Next/Submit with validation
  void _handleNextOrSubmit() {
    final currentIndex = _tabController.index;

    // ✅ Validate current tab before proceeding
    if (!_validateAndMarkTab(currentIndex)) {
      return; // Don't proceed if validation fails
    }

    // If last tab, submit; otherwise move to next
    if (currentIndex < _kTotalTabs - 1) {
      _tabController.animateTo(currentIndex + 1);
      setState(() {});
    } else {
      // ✅ Final validation before submit
      if (!isEditMode && _userIdVerified != true) {
        CustomSnackbar.showWarning(
          context,
          'Please verify the User ID before submitting',
          title: 'Verification Required',
        );
        return;
      }

      _showConfirmationDialog();
    }
  }



// ✅ FIXED: Copy Permanent Address to Current Address
  void _copyPermanentToCurrent() async {
    setState(() {
      _currentCountry = _permanentCountry;
      _selectedCurrentState = _selectedPermanentState;
      _currentPinController.text = _permanentPinController.text;
      _currentAddressController.text = _permanentAddressController.text;

      // Copy the states list
      _currentStates = _permanentStates;
    });

    // ✅ Load districts first, then cities
    if (_selectedPermanentState != null) {
      await _loadCurrentDistricts(_selectedPermanentState!);

      // After districts are loaded, set the selected district
      setState(() {
        _selectedCurrentDistrict = _selectedPermanentDistrict;
      });

      // Then load cities if district is selected
      if (_selectedPermanentDistrict != null) {
        await _loadCurrentCities(_selectedPermanentDistrict!);

        // After cities are loaded, set the selected city
        setState(() {
          _selectedCurrentCity = _selectedPermanentCity;
        });
      }
    }
  }


// ✅ NEW: Clear Current Address fields
  void _clearCurrentAddress() {
    setState(() {
      _selectedCurrentState = null;
      _selectedCurrentDistrict = null;
      _selectedCurrentCity = null;
      _currentPinController.clear();
      _currentAddressController.clear();
      _currentDistricts = [];
      _currentCities = [];
    });
  }


  void _showConfirmationDialog() {
    final action = isEditMode ? 'Update' : 'Add';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Confirm $action Teacher',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to $action this teacher? Please verify all information is correct.',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppTheme.bodyText),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _submitForm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm $action',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }


  // ✅ Hash password function
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

// ✅ UPDATED: Submit form with INSERT_USER mechanism and hashed password
  void _submitForm() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        },
      );

      String? userCodeForTeacher;

      // ✅ STEP 1: For ADD mode, first create user account with HASHED password
      if (!isEditMode) {
        if (_userNameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
          // ✅ Hash password using API
          final hashResult = await apiService.hashPassword(_passwordController.text);
          final hashedPassword = hashResult['hashedPassword'];
          final salt = hashResult['salt'];

          final userResponse = await apiService.insertUser(
            userName: '${_firstNameController.text} ${_lastNameController.text}',
            userGroupCode: 4, // Teacher group code
            userID: _userNameController.text,
            hashedPassword: hashedPassword,
            salt: salt,
          );

          // ✅ Get UserCode from response
          if (userResponse['status'] == 'success' && userResponse['data'] != null) {
            userCodeForTeacher = userResponse['data']['UserCode']?.toString();
          }
        }
      }

      // ✅ STEP 2: Prepare teacher data (Password = NULL for INSERT)
      final teacherData = {
        'Photograph': _uploadedPhotoPath,
        'TeacherCode': userCodeForTeacher ?? _teacherCodeController.text,
        'EmployeeCode': _employeeCodeController.text.isNotEmpty ? _employeeCodeController.text : null,
        'FirstName': _firstNameController.text,
        'MiddleName': _middleNameController.text.isNotEmpty ? _middleNameController.text : null,
        'LastName': _lastNameController.text,
        'Gender': _selectedGender,
        'DateOfBirth': _dateOfBirthController.text,
        'BloodGroup': _bloodGroupController.text.isNotEmpty ? _bloodGroupController.text : null,
        'Nationality': _nationalityController.text.isNotEmpty ? _nationalityController.text : null,
        'Category': _selectedCategory,
        'Religion': _religionController.text.isNotEmpty ? _religionController.text : null,
        'MobileNumber': _mobileNumberController.text.isNotEmpty ? _mobileNumberController.text : null,
        'AlternateContactNumber': _alternateContactController.text.isNotEmpty ? _alternateContactController.text : null,
        'PersonalEmail': _personalEmailController.text.isNotEmpty ? _personalEmailController.text : null,
        'InstitutionalEmail': _institutionalEmailController.text.isNotEmpty ? _institutionalEmailController.text : null,
        'PermanentAddress': _permanentAddressController.text.isNotEmpty ? _permanentAddressController.text : null,
        'CurrentAddress': _currentAddressController.text.isNotEmpty ? _currentAddressController.text : null,

        // ✅ NEW: Permanent Address Fields
        'Permanent_State_ID': _selectedPermanentState != null ? int.parse(_selectedPermanentState!) : null,
        'Permanent_District_ID': _selectedPermanentDistrict != null ? int.parse(_selectedPermanentDistrict!) : null,
        'Permanent_City_ID': _selectedPermanentCity != null ? int.parse(_selectedPermanentCity!) : null,
        'Permanent_Country': _permanentCountry,
        'Permanent_PIN': _permanentPinController.text.isNotEmpty ? _permanentPinController.text : null,

        // ✅ NEW: Current Address Fields
        'Current_State_ID': _selectedCurrentState != null ? int.parse(_selectedCurrentState!) : null,
        'Current_District_ID': _selectedCurrentDistrict != null ? int.parse(_selectedCurrentDistrict!) : null,
        'Current_City_ID': _selectedCurrentCity != null ? int.parse(_selectedCurrentCity!) : null,
        'Current_Country': _currentCountry,
        'Current_PIN': _currentPinController.text.isNotEmpty ? _currentPinController.text : null,

        'DateOfJoining': _dateOfJoiningController.text.isNotEmpty ? _dateOfJoiningController.text : null,
        'Designation': _designationController.text.isNotEmpty ? _designationController.text : null,
        'Department': _departmentController.text.isNotEmpty ? _departmentController.text : null,
        'SubjectsTaught': _subjectsTaughtController.text.isNotEmpty ? _subjectsTaughtController.text : null,
        'Qualification': _qualificationController.text.isNotEmpty ? _qualificationController.text : null,
        'ExperienceYears': _experienceYearsController.text.isNotEmpty ? int.tryParse(_experienceYearsController.text) : null,
        'EmploymentType': _selectedEmploymentType,
        'EmployeeStatus': _selectedEmployeeStatus,
        'AadhaarNumber': _aadhaarNumberController.text.isNotEmpty ? _aadhaarNumberController.text : null,
        'PANNumber': _panNumberController.text.isNotEmpty ? _panNumberController.text : null,
        'PassportNumber': _passportNumberController.text.isNotEmpty ? _passportNumberController.text : null,
        'CertificateFile': _certificateFileController.text.isNotEmpty ? _certificateFileController.text : null,
        'RegistrationNo': _registrationNoController.text.isNotEmpty ? _registrationNoController.text : null,
        'SalaryID': _salaryIdController.text.isNotEmpty ? int.tryParse(_salaryIdController.text) : null,
        'BankAccountNumber': _bankAccountNumberController.text.isNotEmpty ? _bankAccountNumberController.text : null,
        'IFSCCode': _ifscCodeController.text.isNotEmpty ? _ifscCodeController.text : null,
        'BankName': _bankNameController.text.isNotEmpty ? _bankNameController.text : null,
        'PFNumber': _pfNumberController.text.isNotEmpty ? _pfNumberController.text : null,
        'ESINumber': _esiNumberController.text.isNotEmpty ? _esiNumberController.text : null,
        'UANNumber': _uanNumberController.text.isNotEmpty ? _uanNumberController.text : null,
        'MaritalStatus': _selectedMaritalStatus,
        'EmergencyContact': _emergencyContactController.text.isNotEmpty ? _emergencyContactController.text : null,
        'SpecialSkills': _specialSkillsController.text.isNotEmpty ? _specialSkillsController.text : null,
        'Achievements': _achievementsController.text.isNotEmpty ? _achievementsController.text : null,
        'ExtraResponsibilities': _extraResponsibilitiesController.text.isNotEmpty ? _extraResponsibilitiesController.text : null,
        'UserName': _userNameController.text.isNotEmpty ? _userNameController.text : null,
        'Password': null,
        'IsActive': _isActive ? 1 : 0,
        'ModifiedBy': 'Admin',
      };


      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // ✅ STEP 3: Submit teacher data
      if (isEditMode) {
        context.read<TeacherBloc>().add(
          UpdateTeacherEvent(
            recNo: widget.teacher!.recNo!,
            teacherData: teacherData,
            schoolRecNo: widget.schoolRecNo,
          ),
        );
      } else {
        context.read<TeacherBloc>().add(
          AddTeacherEvent(
            teacherData: teacherData,
            schoolRecNo: widget.schoolRecNo,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

}
