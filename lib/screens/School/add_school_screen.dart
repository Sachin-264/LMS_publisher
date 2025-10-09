import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

// --- Make sure these paths are correct for your project structure ---
import 'package:lms_publisher/Theme/apptheme.dart';
import 'school_model.dart';
import 'package:lms_publisher/screens/School/add_school_bloc.dart';
import 'package:lms_publisher/service/school_service.dart';


class AddSchoolScreen extends StatefulWidget {
  final String? schoolId;

  const AddSchoolScreen({super.key, this.schoolId});

  @override
  State<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final SchoolApiService _apiService = SchoolApiService();
  final ImagePicker _picker = ImagePicker();



  bool get _isEditMode => widget.schoolId != null;
  final String _logoBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";
  String? _originalCreatedBy;

  // --- Data Lists & Models ---
  List<SubscriptionPlan> _subscriptionPlans = [];
  List<StateModel> _states = [];
  List<DistrictModel> _districts = [];
  List<CityModel> _cities = [];
  List<Map<String, String>> _schoolTypes = [];
  List<Map<String, String>> _boardAffiliations = [];
  List<Map<String, String>> _mediumInstructions = [];
  List<Map<String, String>> _managementTypes = [];
  List<FeeStructure> _feeStructures = [];

  // --- Loading State Flags ---
  bool _isLoading = true;
  bool _isLoadingDistricts = false;
  bool _isLoadingCities = false;
  bool _isSaving = false;
  bool _isLoadingFees = false;

  // --- Selected Values ---
  SubscriptionPlan? _selectedSubscription;
  StateModel? _selectedState;
  DistrictModel? _selectedDistrict;
  CityModel? _selectedCity;
  Map<String, String>? _selectedSchoolType;
  Map<String, String>? _selectedBoardAffiliation;
  Map<String, String>? _selectedMediumInstruction;
  Map<String, String>? _selectedManagementType;
  FeeStructure? _selectedFeeStructure;
  XFile? _logoFile;
  String? _existingLogoPath;

  // --- Form Data & Controllers ---
  DateTime _startDate = DateTime.now();
  bool _scholarshipsGrants = false;

  bool _isAutoRenewal = true;
  final TextEditingController _paymentRefController = TextEditingController();

  final Map<String, TextEditingController> _controllers = {
    'schoolName': TextEditingController(),
    'schoolCode': TextEditingController(),
    'schoolShortName': TextEditingController(),
    'affiliationNo': TextEditingController(),
    'establishmentDate': TextEditingController(),
    'addressLine1': TextEditingController(),
    'addressLine2': TextEditingController(),
    'pinCode': TextEditingController(),
    'phoneNo': TextEditingController(),
    'mobileNo': TextEditingController(),
    'email': TextEditingController(),
    'website': TextEditingController(),
    'principalName': TextEditingController(),
    'principalContact': TextEditingController(),
    'chairmanName': TextEditingController(),
    'branchCount': TextEditingController(),
    'parentOrganization': TextEditingController(),
    'classesOffered': TextEditingController(),
    'sectionsPerClass': TextEditingController(),
    'studentCapacity': TextEditingController(),
    'currentEnrollment': TextEditingController(),
    'teacherStrength': TextEditingController(),
    'panNumber': TextEditingController(),
    'gstNumber': TextEditingController(),
    'bankAccountDetails': TextEditingController(),
  };

  final Map<String, bool> _facilitySwitches = {
    'isHostel': false,
    'isTransport': false,
    'isLibrary': false,
    'isComputerLab': false,
    'isPlayground': false,
    'isAuditorium': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _controllers['establishmentDate']!.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    _fetchAllInitialData().then((_) {
      if (_isEditMode) {
        _fetchAndPopulateSchoolDetails();
      } else {
        setState(() => _isLoading = false);
        _paymentRefController.text = "PAY-${DateTime.now().millisecondsSinceEpoch}";
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controllers.forEach((_, controller) => controller.dispose());
    _paymentRefController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.fetchSubscriptions(),
        _apiService.fetchStates(),
        _apiService.fetchSchoolTypes(),
        _apiService.fetchBoardAffiliations(),
        _apiService.fetchMediumInstructions(),
        _apiService.fetchManagementTypes(),
        _apiService.fetchFeeStructures(),
      ]);
      if (mounted) {
        setState(() {
          _subscriptionPlans = results[0] as List<SubscriptionPlan>;
          _states = results[1] as List<StateModel>;
          _schoolTypes = results[2] as List<Map<String, String>>;
          _boardAffiliations = results[3] as List<Map<String, String>>;
          _mediumInstructions = results[4] as List<Map<String, String>>;
          _managementTypes = results[5] as List<Map<String, String>>;
          _feeStructures = results[6] as List<FeeStructure>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load initial data: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchAndPopulateSchoolDetails() async {
    try {
      final school = await _apiService.fetchSchoolDetails(schoolId: widget.schoolId!);

      if (mounted) {
        // --- Populate Text Controllers ---
        _originalCreatedBy = school.createdBy;
        _controllers['schoolName']!.text = school.name;
        _controllers['schoolCode']!.text = school.code ?? '';
        _controllers['schoolShortName']!.text = school.shortName ?? '';
        _controllers['affiliationNo']!.text = school.affiliationNo ?? '';
        _controllers['establishmentDate']!.text = school.establishmentDate ?? '';
        _controllers['addressLine1']!.text = school.address1 ?? '';
        _controllers['addressLine2']!.text = school.address2 ?? '';
        _controllers['pinCode']!.text = school.pincode ?? '';
        _controllers['phoneNo']!.text = school.phone ?? '';
        _controllers['mobileNo']!.text = school.mobile ?? '';
        _controllers['email']!.text = school.email ?? '';
        _controllers['website']!.text = school.website ?? '';
        _controllers['principalName']!.text = school.principalName ?? '';
        _controllers['principalContact']!.text = school.principalContact ?? '';
        _controllers['chairmanName']!.text = school.chairmanName ?? '';
        _controllers['branchCount']!.text = school.branchCount ?? '1';
        _controllers['parentOrganization']!.text = school.parentOrganization ?? '';
        _controllers['classesOffered']!.text = school.classesOffered ?? '';
        _controllers['sectionsPerClass']!.text = school.sectionsPerClass ?? '0';
        _controllers['studentCapacity']!.text = school.studentCapacity ?? '0';
        _controllers['currentEnrollment']!.text = school.currentEnrollment ?? '0';
        _controllers['teacherStrength']!.text = school.teacherStrength ?? '0';
        _controllers['panNumber']!.text = school.pan ?? '';
        _controllers['gstNumber']!.text = school.gst ?? '';
        _controllers['bankAccountDetails']!.text = school.bankAccountDetails ?? '';
        _existingLogoPath = school.logoPath;
        _originalCreatedBy = school.createdBy;
        // --- Populate Facility Switches ---
        _facilitySwitches['isHostel'] = school.isHostel ?? false;
        _facilitySwitches['isTransport'] = school.isTransport ?? false;
        _facilitySwitches['isLibrary'] = school.isLibrary ?? false;
        _facilitySwitches['isComputerLab'] = school.isComputerLab ?? false;
        _facilitySwitches['isPlayground'] = school.isPlayground ?? false;
        _facilitySwitches['isAuditorium'] = school.isAuditorium ?? false;
        _scholarshipsGrants = school.scholarshipsGrants?.toLowerCase() == 'yes';

        // --- Populate Dropdowns (SAFE METHOD) ---
        try { _selectedBoardAffiliation = _boardAffiliations.firstWhere((b) => b['id'] == school.board); } catch (e) { _selectedBoardAffiliation = null; }
        try { _selectedSchoolType = _schoolTypes.firstWhere((st) => st['id'] == school.schoolType); } catch (e) { _selectedSchoolType = null; }
        try { _selectedMediumInstruction = _mediumInstructions.firstWhere((m) => m['id'] == school.medium); } catch (e) { _selectedMediumInstruction = null; }
        try { _selectedManagementType = _managementTypes.firstWhere((m) => m['id'] == school.managementType); } catch (e) { _selectedManagementType = null; }
        if (school.feeStructureRef != null) {
          try { _selectedFeeStructure = _feeStructures.firstWhere((fs) => fs.id == school.feeStructureRef); } catch (e) { _selectedFeeStructure = null; }
        }

        // --- Handle Location Dropdowns (SAFE METHOD) ---
        if (school.stateId != null) {
          try { _selectedState = _states.firstWhere((s) => s.id == school.stateId); } catch (e) { _selectedState = null; }
          if (_selectedState != null) {
            await _fetchDistricts(_selectedState!.id);
            if (school.districtId != null) {
              try { _selectedDistrict = _districts.firstWhere((d) => d.id == school.districtId); } catch (e) { _selectedDistrict = null; }
              if (_selectedDistrict != null) {
                await _fetchCities(_selectedDistrict!.id);
                if (school.cityId != null) {
                  try { _selectedCity = _cities.firstWhere((c) => c.id == school.cityId); } catch (e) { _selectedCity = null; }
                }
              }
            }
          }
        }

        // --- Populate Subscription Info (SAFE METHOD) ---
        _paymentRefController.text = school.paymentRefId ?? '';
        _isAutoRenewal = school.isAutoRenewal ?? true;
        if(school.startDate != null) _startDate = school.startDate!;
        if(school.subscription != null) {
          try { _selectedSubscription = _subscriptionPlans.firstWhere((p) => p.name == school.subscription); } catch (e) { _selectedSubscription = null; }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load school details: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _refreshFeeStructures() async {
    setState(() => _isLoadingFees = true);
    try {
      final feeStructures = await _apiService.fetchFeeStructures();
      if (mounted) {
        setState(() => _feeStructures = feeStructures);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingFees = false);
    }
  }

  Future<void> _fetchDistricts(String stateId) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _selectedDistrict = null;
      _cities = [];
      _selectedCity = null;
    });
    try {
      final districts = await _apiService.fetchDistricts(stateId);
      if (mounted) setState(() => _districts = districts);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _fetchCities(String districtId) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _selectedCity = null;
    });
    try {
      final cities = await _apiService.fetchCities(districtId);
      if (mounted) setState(() => _cities = cities);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _logoFile = image);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final schoolMasterData = {
        "School_Code": _controllers['schoolCode']!.text,
        "School_Name": _controllers['schoolName']!.text,
        "School_Short_Name": _controllers['schoolShortName']!.text,
        "SchoolType_ID": _selectedSchoolType?['id'],
        "Medium_ID": _selectedMediumInstruction?['id'],
        "BoardAffliation_ID": _selectedBoardAffiliation?['id'],
        "Affiliation_No": _controllers['affiliationNo']!.text,
        "Date_of_Establishment": _controllers['establishmentDate']!.text,
        "Address_Line1": _controllers['addressLine1']!.text,
        "Address_Line2": _controllers['addressLine2']!.text,
        "Country": "India",
        "State_ID": _selectedState?.id,
        "District_ID": _selectedDistrict?.id,
        "City_ID": _selectedCity?.id,
        "Pin_Code": _controllers['pinCode']!.text,
        "Phone_No": _controllers['phoneNo']!.text,
        "Mobile_No": _controllers['mobileNo']!.text,
        "Email": _controllers['email']!.text,
        "Website": _controllers['website']!.text,
        "Principal_Name": _controllers['principalName']!.text,
        "Principal_Contact": _controllers['principalContact']!.text,
        "Chairman_Name": _controllers['chairmanName']!.text,
        "Management_ID": _selectedManagementType?['id'],
        "Branch_Count": int.tryParse(_controllers['branchCount']!.text) ?? 1,
        "Parent_Organization": _controllers['parentOrganization']!.text,
        "Classes_Offered": _controllers['classesOffered']!.text,
        "Sections_Per_Class": int.tryParse(_controllers['sectionsPerClass']!.text) ?? 0,
        "Student_Capacity": int.tryParse(_controllers['studentCapacity']!.text) ?? 0,
        "Current_Enrollment": int.tryParse(_controllers['currentEnrollment']!.text) ?? 0,
        "Teacher_Strength": int.tryParse(_controllers['teacherStrength']!.text) ?? 0,
        "IsHostel": _facilitySwitches['isHostel'],
        "IsTransport": _facilitySwitches['isTransport'],
        "IsLibrary": _facilitySwitches['isLibrary'],
        "IsComputer_Lab": _facilitySwitches['isComputerLab'],
        "IsPlayground": _facilitySwitches['isPlayground'],
        "IsAuditorium": _facilitySwitches['isAuditorium'],
        "PAN_Number": _controllers['panNumber']!.text,
        "GST_Number": _controllers['gstNumber']!.text,
        "Bank_Account_Details": _controllers['bankAccountDetails']!.text,
        "Fee_Structure_Ref": _selectedFeeStructure?.id,
        "Scholarships_Grants": _scholarshipsGrants ? 'Yes' : 'No',
        "Status": true
      };

      if (_logoFile == null && _isEditMode) {
        schoolMasterData['Logo_Path'] = _existingLogoPath;
      }

      DateTime endDate;
      switch (_selectedSubscription?.planType) {
        case 'Weekly':
          endDate = _startDate.add(const Duration(days: 7));
          break;
        case 'Monthly':
          endDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
          break;
        case 'Yearly':
          endDate = DateTime(_startDate.year + 1, _startDate.month, _startDate.day);
          break;
        default:
          endDate = _startDate;
      }

      final subscriptionData = {
        "Subscription_ID": _selectedSubscription?.id,
        "Purchase_Date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "Start_Date": DateFormat('yyyy-MM-dd').format(_startDate),
        "End_Date": DateFormat('yyyy-MM-dd').format(endDate),
        "Payment_Ref_ID": _paymentRefController.text,
        "Is_Auto_Renewal": _isAutoRenewal,
        "Subscription_Status": "Active",
      };

      if (_isEditMode) {
        // --- FIX: Corrected the BLoC event call ---
        context.read<AddEditSchoolBloc>().add(UpdateSchool(
            schoolId: widget.schoolId!,
            schoolMasterData: schoolMasterData,
            subscriptionData: subscriptionData,
            logoFile: _logoFile));
      } else {
        context.read<AddEditSchoolBloc>().add(AddSchool(
          schoolMasterData: schoolMasterData,
          subscriptionData: subscriptionData,
          logoFile: _logoFile,
          createdBy: "Admin",
        ));
      }
    }
  }

  void _nextPage() {
    if (_tabController.index < _tabController.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
    } else {
      _submitForm();
    }
  }

  void _previousPage() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  // --- NEW: Method to show the AddFeeStructureDialog ---
  Future<void> _showAddFeeDialog() async {
    final newFeeId = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddFeeStructureDialog(apiService: _apiService),
    );

    if (newFeeId != null && newFeeId.isNotEmpty) {
      await _refreshFeeStructures(); // Refresh the list from the API
      try {
        // Find the newly added fee structure from the refreshed list
        final newFee = _feeStructures.firstWhere((fee) => fee.id == newFeeId);
        setState(() {
          _selectedFeeStructure = newFee; // Auto-select the new fee
        });
      } catch (e) {
        // This might happen if the new fee isn't in the list immediately
        print("Could not auto-select the newly created fee structure: $e");
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<AddEditSchoolBloc, AddEditSchoolState>(
      listener: (context, state) {
        if (state is AddEditSchoolSuccess) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode ? 'School updated successfully!' : 'School added successfully! ID: ${state.successResponse['School_ID']}'),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is AddEditSchoolFailure) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode ? 'Failed to update school: ${state.error}' : 'Failed to add school: ${state.error}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is AddEditSchoolLoading) {
          setState(() => _isSaving = true);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left_2, color: AppTheme.darkText),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(_isEditMode ? 'Edit School Details' : 'Register New School',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                  fontSize: 22)),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: AppTheme.primaryGreen,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.bodyText,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.inter(),
            tabs: const [
              Tab(icon: Icon(Iconsax.buildings), text: 'Basic Info'),
              Tab(icon: Icon(Iconsax.location), text: 'Location'),
              Tab(icon: Icon(Iconsax.book), text: 'Details'),
              Tab(icon: Icon(Iconsax.crown), text: 'Subscription'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSchoolInformationSection(),
              _buildLocationAndContactSection(),
              _buildAcademicAndFacilitiesSection(),
              _buildSubscriptionSection(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
        border: const Border(
            top: BorderSide(color: AppTheme.borderGrey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                return Visibility(
                  visible: _tabController.index > 0,
                  child: OutlinedButton(
                    onPressed: _previousPage,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      foregroundColor: AppTheme.darkText,
                      side: const BorderSide(color: AppTheme.borderGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                );
              }),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _nextPage,
            icon: _isSaving
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  return Icon(
                      _tabController.index == 3
                          ? Iconsax.save_2
                          : Iconsax.arrow_right_3,
                      size: 20);
                }),
            label: AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  final isLastTab = _tabController.index == 3;
                  if (isLastTab) {
                    return Text(_isEditMode ? 'Update School' : 'Save School');
                  }
                  return const Text('Next Step');
                }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderGrey, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 16),
            ...children
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolInformationSection() {
    return _buildSection(children: [
      _buildCard(
        title: 'Basic Information',
        children: [
          _buildResponsiveRow(children: [
            _buildTextField(
                label: 'School Name',
                controller: _controllers['schoolName']!,
                icon: Iconsax.building_4),
            _buildTextField(
                label: 'School Code',
                controller: _controllers['schoolCode']!,
                icon: Iconsax.code),
          ]),
          const SizedBox(height: 16),
          _buildResponsiveRow(children: [
            _buildTextField(
                label: 'School Short Name',
                controller: _controllers['schoolShortName']!,
                icon: Iconsax.text),
            _buildDropdown<Map<String, String>>(
              label: 'School Type',
              value: _selectedSchoolType,
              items: _schoolTypes,
              onChanged: (value) => setState(() => _selectedSchoolType = value),
              itemToString: (item) => item['name']!,
              isLoading: _isLoading,
              icon: Iconsax.category,
            ),
          ]),
        ],
      ),
      _buildCard(
        title: 'Affiliation & Establishment',
        children: [
          _buildResponsiveRow(children: [
            _buildDropdown<Map<String, String>>(
              label: 'Board Affiliation',
              value: _selectedBoardAffiliation,
              items: _boardAffiliations,
              onChanged: (value) =>
                  setState(() => _selectedBoardAffiliation = value),
              itemToString: (item) => item['name']!,
              isLoading: _isLoading,
              icon: Iconsax.verify,
            ),
            _buildTextField(
                label: 'Affiliation No.',
                controller: _controllers['affiliationNo']!,
                icon: Iconsax.barcode),
          ]),
          const SizedBox(height: 16),
          _buildResponsiveRow(children: [
            _buildDropdown<Map<String, String>>(
              label: 'Medium of Instruction',
              value: _selectedMediumInstruction,
              items: _mediumInstructions,
              onChanged: (value) =>
                  setState(() => _selectedMediumInstruction = value),
              itemToString: (item) => item['name']!,
              isLoading: _isLoading,
              icon: Iconsax.language_circle,
            ),
            _buildDatePicker(
              label: 'Date of Establishment',
              controller: _controllers['establishmentDate']!,
              icon: Iconsax.calendar_1,
              onDateSelected: (date) {
                setState(() => _controllers['establishmentDate']!.text =
                    DateFormat('yyyy-MM-dd').format(date));
              },
            ),
          ]),
        ],
      ),
      _buildCard(
        title: 'Management Details',
        children: [
          _buildResponsiveRow(children: [
            _buildTextField(
                label: 'Principal Name',
                controller: _controllers['principalName']!,
                icon: Iconsax.user),
            _buildTextField(
                label: 'Principal Contact',
                controller: _controllers['principalContact']!,
                icon: Iconsax.call,
                isNumeric: true),
          ]),
          const SizedBox(height: 16),
          _buildResponsiveRow(children: [
            _buildTextField(
                label: 'Chairman Name',
                controller: _controllers['chairmanName']!,
                icon: Iconsax.user_octagon),
            _buildDropdown<Map<String, String>>(
              label: 'Management Type',
              value: _selectedManagementType,
              items: _managementTypes,
              onChanged: (value) =>
                  setState(() => _selectedManagementType = value),
              itemToString: (item) => item['name']!,
              isLoading: _isLoading,
              icon: Iconsax.briefcase,
            ),
          ]),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Parent Organization',
            controller: _controllers['parentOrganization']!,
            icon: Iconsax.building,
            required: false,
          ),
        ],
      ),
      _buildCard(
        title: 'Financial Information',
        children: [
          _buildResponsiveRow(children: [
            _buildTextField(
                label: 'PAN Number',
                controller: _controllers['panNumber']!,
                icon: Iconsax.card),
            _buildTextField(
                label: 'GST Number',
                controller: _controllers['gstNumber']!,
                icon: Iconsax.receipt_2),
          ]),
          const SizedBox(height: 16),
          _buildTextField(
              label: 'Bank Account Details',
              controller: _controllers['bankAccountDetails']!,
              icon: Iconsax.bank,
              maxLines: 2),
        ],
      ),
    ]);
  }

  Widget _buildLocationAndContactSection() {
    return _buildSection(children: [
      _buildCard(
        title: 'School Address',
        children: [
          _buildTextField(
              label: 'Address Line 1',
              controller: _controllers['addressLine1']!,
              icon: Iconsax.location),
          const SizedBox(height: 16),
          _buildTextField(
              label: 'Address Line 2',
              controller: _controllers['addressLine2']!,
              icon: Iconsax.location_add,
              required: false),
          const SizedBox(height: 16),
          _buildResponsiveRow(children: [
            _buildDropdown<StateModel>(
              label: 'State',
              value: _selectedState,
              items: _states,
              onChanged: (value) {
                setState(() => _selectedState = value);
                if (value != null) _fetchDistricts(value.id);
              },
              itemToString: (state) => state.name,
              isLoading: _isLoading,
            ),
            _buildDropdown<DistrictModel>(
              label: 'District',
              value: _selectedDistrict,
              items: _districts,
              onChanged: (value) {
                setState(() => _selectedDistrict = value);
                if (value != null) _fetchCities(value.id);
              },
              itemToString: (district) => district.name,
              isLoading: _isLoadingDistricts,
              disabled: _selectedState == null,
            ),
          ]),
          const SizedBox(height: 16),
          _buildResponsiveRow(children: [
            _buildDropdown<CityModel>(
              label: 'City',
              value: _selectedCity,
              items: _cities,
              onChanged: (value) => setState(() => _selectedCity = value),
              itemToString: (city) => city.name,
              isLoading: _isLoadingCities,
              disabled: _selectedDistrict == null,
            ),
            _buildTextField(
                label: 'Pin Code',
                controller: _controllers['pinCode']!,
                icon: Iconsax.map_1,
                isNumeric: true),
          ]),
        ],
      ),
      _buildCard(
        title: 'Contact Information',
        children: [
          _buildResponsiveRow(children: [
            _buildTextField(
                label: 'Contact Email',
                controller: _controllers['email']!,
                icon: Iconsax.direct_right,
                isEmail: true),
            _buildTextField(
                label: 'Mobile Number',
                controller: _controllers['mobileNo']!,
                icon: Iconsax.call,
                isNumeric: true),
          ]),
          const SizedBox(height: 16),
          _buildResponsiveRow(children: [
            _buildTextField(
                label: 'Phone Number',
                controller: _controllers['phoneNo']!,
                icon: Iconsax.call_calling,
                isNumeric: true,
                required: false),
            _buildTextField(
                label: 'Website',
                controller: _controllers['website']!,
                icon: Iconsax.global,
                required: false),
          ]),
        ],
      ),
    ]);
  }

  Widget _buildAcademicAndFacilitiesSection() {
    return _buildSection(children: [
      _buildCard(
        title: 'Academic Details',
        children: [
          _buildResponsiveRow(children: [
            _buildTextField(
                label: 'Classes Offered (e.g., 1-12)',
                controller: _controllers['classesOffered']!,
                icon: Iconsax.book_1),
            _buildTextField(
                label: 'Sections Per Class',
                controller: _controllers['sectionsPerClass']!,
                icon: Iconsax.row_vertical,
                isNumeric: true),
          ]),
          const SizedBox(height: 16),
          _buildResponsiveRow(children: [
            _buildTextField(
                label: 'Total Student Capacity',
                controller: _controllers['studentCapacity']!,
                icon: Iconsax.people,
                isNumeric: true),
            _buildTextField(
                label: 'Current Enrollment',
                controller: _controllers['currentEnrollment']!,
                icon: Iconsax.profile_2user,
                isNumeric: true),
          ]),
          const SizedBox(height: 16),
          _buildTextField(
              label: 'Total Teacher Strength',
              controller: _controllers['teacherStrength']!,
              icon: Iconsax.teacher,
              isNumeric: true),
        ],
      ),
      _buildCard(
        title: 'Fees & Miscellaneous',
        children: [
          // --- CHANGE: Added a Row to hold the dropdown and the add button ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDropdown<FeeStructure>(
                  label: 'Fee Structure',
                  value: _selectedFeeStructure,
                  items: _feeStructures,
                  onChanged: (value) =>
                      setState(() => _selectedFeeStructure = value),
                  itemToString: (fee) => fee.name,
                  isLoading: _isLoadingFees,
                  icon: Iconsax.wallet_money,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: IconButton(
                  icon: const Icon(Iconsax.add_square, size: 28),
                  onPressed: _showAddFeeDialog,
                  tooltip: 'Add New Fee Structure',
                  color: AppTheme.primaryGreen,
                  splashRadius: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSwitchChip(
            label: 'Scholarships & Grants Offered',
            icon: Iconsax.award,
            value: _scholarshipsGrants,
            onChanged: (value) => setState(() => _scholarshipsGrants = value),
          ),
          const SizedBox(height: 16),
          _buildLogoPicker(),
        ],
      ),
      _buildCard(
        title: 'Facilities',
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _facilitySwitches.keys.map((key) {
              String label = key.replaceAll('is', '');
              label = label[0].toUpperCase() + label.substring(1);
              return _buildSwitchChip(
                label: label,
                icon: _getFacilityIcon(key),
                value: _facilitySwitches[key]!,
                onChanged: (value) =>
                    setState(() => _facilitySwitches[key] = value),
              );
            }).toList(),
          ),
        ],
      ),
    ]);
  }

  Widget _buildSubscriptionSection() {
    DateTime endDate;
    if (_selectedSubscription == null) {
      endDate = _startDate;
    } else {
      switch (_selectedSubscription!.planType) {
        case 'Weekly':
          endDate = _startDate.add(const Duration(days: 7));
          break;
        case 'Monthly':
          endDate =
              DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
          break;
        case 'Yearly':
          endDate =
              DateTime(_startDate.year + 1, _startDate.month, _startDate.day);
          break;
        default:
          endDate = _startDate;
      }
    }

    return _buildSection(children: [
      _buildCard(
        title: 'Choose a Plan',
        children: [
          _buildDropdown<SubscriptionPlan>(
              label: 'Subscription Plan',
              value: _selectedSubscription,
              items: _subscriptionPlans,
              onChanged: (value) {
                setState(() {
                  _selectedSubscription = value;
                  _startDate = DateTime.now();
                });
              },
              itemToString: (plan) => '${plan.name} (${plan.planType})',
              isLoading: _isLoading,
              icon: Iconsax.crown
          ),
          if (_selectedSubscription != null) ...[
            const SizedBox(height: 16),
            _buildDatePicker(
              label: 'Subscription Start Date',
              controller: TextEditingController(
                  text: DateFormat('yyyy-MM-dd').format(_startDate)),
              icon: Iconsax.calendar_add,
              onDateSelected: (date) {
                setState(() {
                  _startDate = date;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
                label: 'Payment Reference ID',
                controller: _paymentRefController,
                icon: Iconsax.receipt_edit,
                required: true
            ),
            const SizedBox(height: 16),
            _buildSwitchListTile(
              title: 'Enable Auto-Renewal',
              value: _isAutoRenewal,
              onChanged: (value) {
                setState(() {
                  _isAutoRenewal = value;
                });
              },
            ),
          ]
        ],
      ),
      if (_selectedSubscription != null)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.5))),
          color: AppTheme.primaryGreen.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Subscription Summary",
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen)),
                const SizedBox(height: 12),
                _buildSummaryRow(Iconsax.crown, 'Selected Plan',
                    _selectedSubscription!.name),
                _buildSummaryRow(Iconsax.calendar_1, 'Start Date',
                    DateFormat.yMMMd().format(_startDate)),
                _buildSummaryRow(Iconsax.calendar_tick, 'End Date',
                    DateFormat.yMMMd().format(endDate)),
                _buildSummaryRow(Iconsax.refresh, 'Auto-Renews',
                    _isAutoRenewal ? 'Yes' : 'No'),
              ],
            ),
          ),
        ),
    ]);
  }

  Widget _buildSwitchListTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged
  }) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderGrey.withOpacity(0.7))
      ),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.inter(color: AppTheme.darkText, fontWeight: FontWeight.w500)),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGreen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  IconData _getFacilityIcon(String key) {
    switch (key) {
      case 'isHostel':
        return Iconsax.building;
      case 'isTransport':
        return Iconsax.bus;
      case 'isLibrary':
        return Iconsax.book_1;
      case 'isComputerLab':
        return Iconsax.monitor;
      case 'isPlayground':
        return Iconsax.dribbble;
      case 'isAuditorium':
        return Iconsax.presention_chart;
      default:
        return Iconsax.check;
    }
  }

  Widget _buildResponsiveRow({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
              children: children
                  .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: c,
              ))
                  .toList());
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i < children.length - 1) const SizedBox(width: 20),
              ],
            ],
          );
        }
      },
    );
  }

  // --- CHANGE: Updated to handle numeric-only input ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool required = true,
    bool isNumeric = false,
    bool isEmail = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumeric
          ? TextInputType.number
          : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.digitsOnly] // Only allows numbers
          : [],
      decoration: _buildInputDecoration(label, icon),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        if (isEmail &&
            value!.isNotEmpty &&
            !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: _buildInputDecoration(label, icon),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primaryGreen,
                  onPrimary: Colors.white,
                ),
                dialogBackgroundColor: Colors.white,
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          onDateSelected(pickedDate);
          controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        }
      },
      validator: (value) =>
      (value == null || value.isEmpty) ? '$label is required' : null,
    );
  }

  Widget _buildSwitchChip(
      {required String label,
        required IconData icon,
        required bool value,
        required ValueChanged<bool> onChanged}) {
    return FilterChip(
      label: Text(label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: value ? AppTheme.primaryGreen : AppTheme.bodyText,
          )),
      avatar: Icon(icon,
          size: 20, color: value ? AppTheme.primaryGreen : AppTheme.bodyText),
      selected: value,
      onSelected: onChanged,
      showCheckmark: false,
      selectedColor: AppTheme.primaryGreen.withOpacity(0.1),
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: value ? AppTheme.primaryGreen.withOpacity(0.7) : AppTheme.borderGrey.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemToString,
    bool isLoading = false,
    bool disabled = false,
    IconData? icon,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: _buildInputDecoration(
        label,
        icon ?? Iconsax.arrow_down_1,
        suffixIcon: isLoading
            ? const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5)),
        )
            : null,
      ),
      dropdownColor: Colors.white,
      focusColor: AppTheme.primaryGreen.withOpacity(0.1),
      items: disabled
          ? []
          : items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemToString(item),
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter()),
        );
      }).toList(),
      onChanged: disabled ? null : onChanged,
      validator: (val) {
        if (val == null) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppTheme.bodyText),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.bodyText),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      hoverColor: AppTheme.primaryGreen.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderGrey.withOpacity(0.7))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderGrey.withOpacity(0.7))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: AppTheme.primaryGreen, width: 1.5)),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Text(label,
              style:
              GoogleFonts.inter(color: AppTheme.darkText, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLogoPicker() {
    final hasNewFile = _logoFile != null;
    final hasExistingImage = _existingLogoPath != null && _existingLogoPath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("School Logo", style: GoogleFonts.inter(color: AppTheme.bodyText, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickLogo,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderGrey.withOpacity(0.7)),
            ),
            child: hasNewFile
                ? (kIsWeb ? Image.network(_logoFile!.path, fit: BoxFit.contain) : Image.file(File(_logoFile!.path), fit: BoxFit.contain))
                : hasExistingImage
                ? Image.network('$_logoBaseUrl$_existingLogoPath', fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.gallery_slash, color: Colors.redAccent, size: 40),
                    SizedBox(height: 8),
                    Text("Could not load image", style: TextStyle(color: Colors.redAccent)),
                  ],
                ))
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.gallery_add,
                    color: AppTheme.bodyText, size: 40),
                SizedBox(height: 8),
                Text("Tap to select a logo"),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// --- Add Fee Structure Dialog ---

class AddFeeStructureDialog extends StatefulWidget {
  final SchoolApiService apiService;
  const AddFeeStructureDialog({super.key, required this.apiService});

  @override
  _AddFeeStructureDialogState createState() => _AddFeeStructureDialogState();
}

class _AddFeeStructureDialogState extends State<AddFeeStructureDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _feeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fromClassController = TextEditingController();
  final _toClassController = TextEditingController();

  String? _selectedFrequency = 'Yearly';
  final List<Map<String, TextEditingController>> _feeDetails = [];

  @override
  void initState() {
    super.initState();
    _addFeeDetailRow();
  }

  @override
  void dispose() {
    _feeNameController.dispose();
    _descriptionController.dispose();
    _fromClassController.dispose();
    _toClassController.dispose();
    for (var detail in _feeDetails) {
      detail['class']!.dispose();
      detail['amount']!.dispose();
      detail['dueDate']!.dispose();
    }
    super.dispose();
  }

  void _addFeeDetailRow() {
    setState(() {
      _feeDetails.add({
        'class': TextEditingController(),
        'amount': TextEditingController(),
        'dueDate':
        TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now())),
      });
    });
  }

  void _removeFeeDetailRow(int index) {
    if (_feeDetails.length > 1) {
      setState(() {
        _feeDetails[index]['class']!.dispose();
        _feeDetails[index]['amount']!.dispose();
        _feeDetails[index]['dueDate']!.dispose();
        _feeDetails.removeAt(index);
      });
    }
  }

  Future<void> _saveFeeStructure() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final feeDetailsPayload = _feeDetails.map((detail) => {
        "ClassID": int.tryParse(detail['class']!.text) ?? 0,
        "Amount": double.tryParse(detail['amount']!.text) ?? 0.0,
        "DueDate": detail['dueDate']!.text,
      }).toList();

      final payload = {
        "FeeName": _feeNameController.text,
        "Description": _descriptionController.text,
        "Frequency": _selectedFrequency,
        "FromClassID": int.tryParse(_fromClassController.text) ?? 0,
        "ToClassID": int.tryParse(_toClassController.text) ?? 0,
        "CreatedBy": "flutter_app",
        "FeeDetails": feeDetailsPayload,
      };

      try {
        final newFeeId = await widget.apiService.addFeeStructure(feeData: payload);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Fee structure created successfully!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop(newFeeId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to save: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: AppTheme.background,
      title: Text(
        "Create New Fee Structure",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: AppTheme.darkText,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  label: 'Fee Name',
                  controller: _feeNameController,
                  icon: Iconsax.money_send,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  icon: Iconsax.text,
                ),
                const SizedBox(height: 16),
                _buildDropdown<String>(
                  label: 'Frequency',
                  value: _selectedFrequency,
                  items: ['Yearly', 'Monthly', 'Quarterly', 'One-Time'],
                  onChanged: (value) =>
                      setState(() => _selectedFrequency = value),
                  itemToString: (item) => item,
                  icon: Iconsax.calendar_1,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'From Class ID',
                        controller: _fromClassController,
                        icon: Iconsax.book,
                        isNumeric: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'To Class ID',
                        controller: _toClassController,
                        icon: Iconsax.book,
                        isNumeric: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Fee Details",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _feeDetails.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              label: 'Class ID',
                              controller: _feeDetails[index]['class']!,
                              icon: Iconsax.hashtag,
                              isNumeric: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              label: 'Amount',
                              controller: _feeDetails[index]['amount']!,
                              icon: Iconsax.wallet_money,
                              isNumeric: true,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.trash, color: Colors.redAccent),
                            onPressed: () => _removeFeeDetailRow(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Iconsax.add_circle),
                    label: const Text("Add Row"),
                    onPressed: _addFeeDetailRow,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.darkText,
            side: const BorderSide(color: AppTheme.borderGrey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveFeeStructure,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ))
              : const Text("Save"),
        ),
      ],
    );
  }

  // --- CHANGE: Updated to handle numeric-only input ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool required = true,
    bool isNumeric = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.digitsOnly] // Only allows numbers
          : [],
      decoration: _buildInputDecoration(label, icon),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemToString,
    IconData? icon,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: _buildInputDecoration(label, icon ?? Iconsax.arrow_down_1),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemToString(item), style: GoogleFonts.inter()),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? '$label is required' : null,
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppTheme.bodyText),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.bodyText),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
    );
  }
}