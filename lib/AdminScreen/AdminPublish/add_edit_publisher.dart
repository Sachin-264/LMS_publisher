import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lms_publisher/Service/publisher_api_service.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/publish_model.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:lms_publisher/service/user_right_service.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';

class AddEditPublisherDialog extends StatefulWidget {
  final int? publisherRecNo;

  const AddEditPublisherDialog({super.key, this.publisherRecNo});

  @override
  State<AddEditPublisherDialog> createState() => _AddEditPublisherDialogState();
}

class _AddEditPublisherDialogState extends State<AddEditPublisherDialog>
    with SingleTickerProviderStateMixin {
  final _apiService = PublisherApiService();
  final _userRightsService = UserRightsService();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  bool _isSaving = false;
  bool get _isEditMode => widget.publisherRecNo != null;

  // UserID Verification State
  bool _isVerifyingUserID = false;
  bool? _userIdVerified;
  String? _userIdVerificationMessage;

  XFile? _selectedLogoFile;
  Uint8List? _selectedLogoBytes;
  String? _existingLogoFileName;

  // Dropdown selections
  String? _selectedPublisherType;
  int? _selectedYear;
  int? _selectedDistrictID;
  int? _selectedCityID;
  int? _selectedStateID;
  String? _selectedPaymentTerms;
  String? _selectedDistributionType;
  String? _selectedAreasCovered;

  // Dropdown data
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _states = [];
  bool _loadingLocations = false;

  // Constants
  final List<String> _publisherTypes = [
    'Book',
    'Journal',
    'Digital',
    'Magazine',
    'Others'
  ];

  final List<String> _paymentTerms = [
    'Prepaid',
    'Postpaid',
    '30 Days Credit',
    '60 Days Credit',
    '90 Days Credit'
  ];

  final List<String> _distributionTypes = [
    'Direct',
    'Through Distributor',
    'Both'
  ];

  final List<String> _areasCovered = ['National', 'International', 'Both'];

  final Map<String, TextEditingController> _controllers = {
    'publisherName': TextEditingController(),
    'contactPersonName': TextEditingController(),
    'contactPersonDesignation': TextEditingController(),
    'emailID': TextEditingController(),
    'phoneNumber': TextEditingController(),
    'alternatePhoneNumber': TextEditingController(),
    'faxNumber': TextEditingController(),
    'addressLine1': TextEditingController(),
    'addressLine2': TextEditingController(),
    'country': TextEditingController(text: 'India'),
    'pinZipCode': TextEditingController(),
    'website': TextEditingController(),
    'gstNumber': TextEditingController(),
    'panNumber': TextEditingController(),
    'bankAccountDetails': TextEditingController(),
    'languagesPublished': TextEditingController(),
    'numberOfTitles': TextEditingController(),
    'userID': TextEditingController(),
    'userPassword': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _loadData();

    // Add listeners to update completion status
    _controllers.forEach((key, controller) {
      controller.addListener(_updateCompletionStatus);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Calculate section completion status
  void _updateCompletionStatus() {
    setState(() {});
  }

  bool _isBasicInfoComplete() {
    return _controllers['publisherName']!.text.trim().isNotEmpty &&
        _selectedPublisherType != null &&
        _selectedYear != null;
  }

  bool _isContactInfoComplete() {
    return _controllers['contactPersonName']!.text.trim().isNotEmpty &&
        _controllers['emailID']!.text.trim().isNotEmpty &&
        _controllers['phoneNumber']!.text.trim().isNotEmpty;
  }

  bool _isAddressComplete() {
    return _controllers['addressLine1']!.text.trim().isNotEmpty &&
        _selectedStateID != null &&
        _selectedDistrictID != null &&
        _selectedCityID != null;
  }

  bool _isCredentialsComplete() {
    if (_isEditMode) return true;
    return _controllers['userID']!.text.trim().isNotEmpty &&
        _controllers['userPassword']!.text.trim().isNotEmpty &&
        _userIdVerified == false;
  }

  double _calculateOverallProgress() {
    int completedSections = 0;
    int totalSections = _isEditMode ? 3 : 4;

    if (_isBasicInfoComplete()) completedSections++;
    if (_isContactInfoComplete()) completedSections++;
    if (_isAddressComplete()) completedSections++;
    if (!_isEditMode && _isCredentialsComplete()) completedSections++;

    return completedSections / totalSections;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _loadLocationData();

      if (_isEditMode) {
        final details =
        await _apiService.getPublisherDetails(widget.publisherRecNo!);
        _populateForm(details);
      }

      _animationController.forward();
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Error loading data: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLocationData() async {
    setState(() => _loadingLocations = true);
    try {
      final statesData = await _apiService.getStates();
      final statesList = (statesData as List).map((state) {
        return {
          'StateID': int.parse(state['State_ID'].toString()),
          'StateName': state['State_Name'].toString(),
        };
      }).toList();
      setState(() {
        _states = statesList;
        _loadingLocations = false;
      });
    } catch (e) {
      setState(() => _loadingLocations = false);
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load location data');
      }
    }
  }

  Future<void> _loadDistrictsForState(int stateID) async {
    try {
      final districtsData = await _apiService.getDistricts(stateID);
      final districtsList = (districtsData as List).map((district) {
        return {
          'DistrictID': int.parse(district['District_ID'].toString()),
          'DistrictName': district['District_Name'].toString(),
          'StateID': int.parse(district['State_ID'].toString()),
        };
      }).toList();
      setState(() {
        _districts = districtsList;
      });
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load districts');
      }
    }
  }

  Future<void> _loadCitiesForDistrict(int districtID) async {
    try {
      final citiesData = await _apiService.getCities(districtID);
      final citiesList = (citiesData as List).map((city) {
        return {
          'CityID': int.parse(city['City_ID'].toString()),
          'CityName': city['City_Name'].toString(),
          'DistrictID': int.parse(city['District_ID'].toString()),
        };
      }).toList();
      setState(() {
        _cities = citiesList;
      });
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load cities');
      }
    }
  }

  Future<void> _verifyUserID() async {
    final userId = _controllers['userID']!.text.trim();
    if (userId.isEmpty) {
      CustomSnackbar.showWarning(context, 'Please enter a UserID first');
      return;
    }
    setState(() {
      _isVerifyingUserID = true;
      _userIdVerified = null;
      _userIdVerificationMessage = null;
    });

    try {
      final exists = await _userRightsService.checkUserIdExists(userId);
      setState(() {
        _userIdVerified = exists;
        if (exists) {
          _userIdVerificationMessage =
          'UserID already exists! Please choose another.';
          CustomSnackbar.showError(context, _userIdVerificationMessage!);
        } else {
          _userIdVerificationMessage = 'UserID is available!';
          CustomSnackbar.showSuccess(context, _userIdVerificationMessage!);
        }
      });
    } catch (e) {
      setState(() {
        _userIdVerified = null;
        _userIdVerificationMessage = 'Error checking UserID: $e';
      });
      CustomSnackbar.showError(context, _userIdVerificationMessage!);
    } finally {
      setState(() => _isVerifyingUserID = false);
    }
  }

  void _populateForm(PublisherDetail details) {
    _controllers['publisherName']!.text = details.publisherName;
    _selectedPublisherType = details.publisherType;
    _selectedYear = details.yearOfEstablishment;
    _controllers['contactPersonName']!.text = details.contactPersonName ?? '';
    _controllers['contactPersonDesignation']!.text =
        details.contactPersonDesignation ?? '';
    _controllers['emailID']!.text = details.emailID ?? '';
    _controllers['phoneNumber']!.text = details.phoneNumber ?? '';
    _controllers['alternatePhoneNumber']!.text =
        details.alternatePhoneNumber ?? '';
    _controllers['faxNumber']!.text = details.faxNumber ?? '';
    _controllers['addressLine1']!.text = details.addressLine1 ?? '';
    _controllers['addressLine2']!.text = details.addressLine2 ?? '';
    _controllers['country']!.text = details.country ?? 'India';
    _controllers['pinZipCode']!.text = details.pinZipCode ?? '';
    _controllers['website']!.text = details.website ?? '';
    _controllers['gstNumber']!.text = details.gstNumber ?? '';
    _controllers['panNumber']!.text = details.panNumber ?? '';
    _controllers['bankAccountDetails']!.text = details.bankAccountDetails ?? '';
    _controllers['languagesPublished']!.text = details.languagesPublished ?? '';
    _controllers['numberOfTitles']!.text =
        details.numberOfTitles?.toString() ?? '';
    _controllers['userID']!.text = details.userID ?? '';

    _selectedStateID = details.stateID;
    _selectedDistrictID = details.districtID;
    _selectedCityID = details.cityID;
    _selectedDistributionType = details.distributionType;
    _selectedAreasCovered = details.areasCovered;
    _existingLogoFileName = details.logoFileName;

    if (_selectedStateID != null) {
      _loadDistrictsForState(_selectedStateID!);
    }

    if (_selectedDistrictID != null) {
      _loadCitiesForDistrict(_selectedDistrictID!);
    }
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedLogoFile = image;
          _selectedLogoBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Error picking image: $e');
      }
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Check UserID verification for new publishers
    if (!_isEditMode) {
      if (_userIdVerified == null) {
        CustomSnackbar.showError(context, 'Please verify the UserID first');
        return;
      }
      if (_userIdVerified == true) {
        CustomSnackbar.showError(
            context, 'UserID already exists! Choose another UserID');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserCode = userProvider.userCode;

      if (currentUserCode == null) throw Exception('User not logged in');

      String? uploadedFileName = _existingLogoFileName;
      if (_selectedLogoFile != null) {
        uploadedFileName = await _apiService.uploadLogo(_selectedLogoFile!);
      }

      if (_isEditMode) {
        final data = {
          'RecNo': widget.publisherRecNo,
          'PublisherName': _controllers['publisherName']!.text.trim(),
          'PublisherType': _selectedPublisherType,
          'YearOfEstablishment': _selectedYear,
          'ContactPersonName': _controllers['contactPersonName']!.text.trim(),
          'ContactPersonDesignation':
          _controllers['contactPersonDesignation']!.text.trim(),
          'EmailID': _controllers['emailID']!.text.trim(),
          'PhoneNumber': _controllers['phoneNumber']!.text.trim(),
          'AlternatePhoneNumber':
          _controllers['alternatePhoneNumber']!.text.trim(),
          'FaxNumber': _controllers['faxNumber']!.text.trim(),
          'AddressLine1': _controllers['addressLine1']!.text.trim(),
          'AddressLine2': _controllers['addressLine2']!.text.trim(),
          'DistrictID': _selectedDistrictID,
          'CityID': _selectedCityID,
          'StateID': _selectedStateID,
          'Country': _controllers['country']!.text.trim(),
          'PinZipCode': _controllers['pinZipCode']!.text.trim(),
          'Website': _controllers['website']!.text.trim(),
          'GSTNumber': _controllers['gstNumber']!.text.trim(),
          'PANNumber': _controllers['panNumber']!.text.trim(),
          'BankAccountDetails': _controllers['bankAccountDetails']!.text.trim(),
          'PaymentID': _paymentTerms.indexOf(_selectedPaymentTerms ?? '') + 1,
          'DistributionType': _selectedDistributionType,
          'AreasCovered': _selectedAreasCovered,
          'LanguagesPublished': _controllers['languagesPublished']!.text.trim(),
          'NumberOfTitles':
          int.tryParse(_controllers['numberOfTitles']!.text.trim()),
          'Logo': uploadedFileName,
          'ModifiedBy': currentUserCode,
        };

        final success = await _apiService.updatePublisher(data);

        if (success && mounted) {
          Navigator.pop(context, true);
          CustomSnackbar.showSuccess(
              context, '✓ Publisher updated successfully');
        }
      } else {
        final userGroups = await _userRightsService.getUserGroups();
        UserGroup? publisherGroup;
        for (var group in userGroups) {
          if (group.userGroupName.toLowerCase().contains('publisher')) {
            publisherGroup = group;
            break;
          }
        }

        if (publisherGroup == null) {
          throw Exception('Publisher user group not found in the system.');
        }

        final userID = _controllers['userID']!.text.trim();
        final userPassword = _controllers['userPassword']!.text.trim();

        if (userID.isEmpty || userPassword.isEmpty) {
          throw Exception('UserID and Password required');
        }

        final data = {
          'PublisherName': _controllers['publisherName']!.text.trim(),
          'PublisherType': _selectedPublisherType,
          'YearOfEstablishment': _selectedYear,
          'ContactPersonName': _controllers['contactPersonName']!.text.trim(),
          'ContactPersonDesignation':
          _controllers['contactPersonDesignation']!.text.trim(),
          'EmailID': _controllers['emailID']!.text.trim(),
          'PhoneNumber': _controllers['phoneNumber']!.text.trim(),
          'AlternatePhoneNumber':
          _controllers['alternatePhoneNumber']!.text.trim(),
          'FaxNumber': _controllers['faxNumber']!.text.trim(),
          'AddressLine1': _controllers['addressLine1']!.text.trim(),
          'AddressLine2': _controllers['addressLine2']!.text.trim(),
          'DistrictID': _selectedDistrictID,
          'CityID': _selectedCityID,
          'StateID': _selectedStateID,
          'Country': _controllers['country']!.text.trim(),
          'PinZipCode': _controllers['pinZipCode']!.text.trim(),
          'Website': _controllers['website']!.text.trim(),
          'GSTNumber': _controllers['gstNumber']!.text.trim(),
          'PANNumber': _controllers['panNumber']!.text.trim(),
          'BankAccountDetails': _controllers['bankAccountDetails']!.text.trim(),
          'PaymentID': _paymentTerms.indexOf(_selectedPaymentTerms ?? '') + 1,
          'DistributionType': _selectedDistributionType,
          'AreasCovered': _selectedAreasCovered,
          'LanguagesPublished': _controllers['languagesPublished']!.text.trim(),
          'NumberOfTitles':
          int.tryParse(_controllers['numberOfTitles']!.text.trim()),
          'Logo': uploadedFileName,
          'AdminCode': currentUserCode,
          'UserID': userID,
          'UserPassword': userPassword,
          'UserGroupCode': publisherGroup.userGroupCode,
          'ModifiedBy': currentUserCode,
        };

        final result = await _apiService.addPublisher(data);

        if (result['success'] == true && mounted) {
          Navigator.pop(context, true);
          CustomSnackbar.showSuccess(
              context, '✓ Publisher created! Code: ${result['pubCode']}');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 1000,
          maxHeight: MediaQuery.of(context).size.height * 0.94,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSlimHeader(),
            Expanded(
              child: _isLoading
                  ? Center(
                child: BeautifulLoader(
                  type: LoaderType.spinner,
                  message: 'Loading publisher data...',
                  color: AppTheme.primaryGreen,
                  size: 60,
                ),
              )
                  : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Combined Basic Info & Logo
                          _buildBasicInfoWithLogo(),
                          const SizedBox(height: 20),

                          // Contact Info
                          _buildSection(
                            'Contact Information',
                            Iconsax.call,
                            Colors.green,
                            _isContactInfoComplete(),
                            [
                              _buildModernTextField('Contact Person',
                                  'contactPersonName', Iconsax.user),
                              _buildModernTextField(
                                  'Designation',
                                  'contactPersonDesignation',
                                  Iconsax.briefcase),
                              _buildModernTextField(
                                  'Email', 'emailID', Iconsax.sms),
                              _buildModernTextField(
                                  'Phone', 'phoneNumber', Iconsax.call),
                              _buildModernTextField('Alt. Phone',
                                  'alternatePhoneNumber', Iconsax.call),
                              _buildModernTextField(
                                  'Fax', 'faxNumber', Iconsax.printer),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Address
                          _buildSection(
                            'Address',
                            Iconsax.location,
                            Colors.purple,
                            _isAddressComplete(),
                            [
                              _buildModernTextField('Address Line 1',
                                  'addressLine1', Iconsax.location),
                              _buildModernTextField('Address Line 2',
                                  'addressLine2', Iconsax.location),
                              _buildModernDropdown<Map<String, dynamic>>(
                                label: 'State',
                                icon: Iconsax.map,
                                value: () {
                                  if (_states.isNotEmpty &&
                                      _selectedStateID != null) {
                                    try {
                                      return _states.firstWhere((s) =>
                                      s['StateID'] ==
                                          _selectedStateID);
                                    } catch (e) {
                                      return <String, Object>{};
                                    }
                                  }
                                  return null;
                                }(),
                                items: _states
                                    .where((s) => s.isNotEmpty)
                                    .toList(),
                                itemLabel: (state) =>
                                state['StateName'] ?? 'Unknown',
                                onChanged: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    setState(() {
                                      _selectedStateID = value['StateID'];
                                      _selectedDistrictID = null;
                                      _selectedCityID = null;
                                      _districts = [];
                                      _cities = [];
                                    });
                                    if (_selectedStateID != null) {
                                      _loadDistrictsForState(
                                          _selectedStateID!);
                                    }
                                  }
                                },
                              ),
                              _buildModernDropdown<Map<String, dynamic>>(
                                label: 'District',
                                icon: Iconsax.location,
                                value: () {
                                  if (_districts.isNotEmpty &&
                                      _selectedDistrictID != null) {
                                    try {
                                      return _districts.firstWhere((d) =>
                                      d['DistrictID'] ==
                                          _selectedDistrictID);
                                    } catch (e) {
                                      return <String, Object>{};
                                    }
                                  }
                                  return null;
                                }(),
                                items: _districts,
                                itemLabel: (district) =>
                                district['DistrictName'] ?? '',
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDistrictID =
                                    value?['DistrictID'];
                                    _selectedCityID = null;
                                    _cities = [];
                                  });
                                  if (_selectedDistrictID != null) {
                                    _loadCitiesForDistrict(
                                        _selectedDistrictID!);
                                  }
                                },
                              ),
                              _buildModernDropdown<Map<String, dynamic>>(
                                label: 'City',
                                icon: Iconsax.building_4,
                                value: () {
                                  if (_cities.isNotEmpty &&
                                      _selectedCityID != null) {
                                    try {
                                      return _cities.firstWhere((c) =>
                                      c['CityID'] == _selectedCityID);
                                    } catch (e) {
                                      return <String, Object>{};
                                    }
                                  }
                                  return null;
                                }(),
                                items: _cities,
                                itemLabel: (city) =>
                                city['CityName'] ?? '',
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCityID = value?['CityID'];
                                  });
                                },
                              ),
                              _buildModernTextField(
                                  'Country', 'country', Iconsax.global),
                              _buildModernTextField('PIN/ZIP Code',
                                  'pinZipCode', Iconsax.code),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Business Details
                          _buildSection(
                            'Business Details',
                            Iconsax.document,
                            Colors.orange,
                            false,
                            [
                              _buildModernTextField(
                                  'Website', 'website', Iconsax.link),
                              _buildModernTextField('GST Number',
                                  'gstNumber', Iconsax.card),
                              _buildModernTextField('PAN Number',
                                  'panNumber', Iconsax.card),
                              _buildModernTextField(
                                  'Bank Account Details',
                                  'bankAccountDetails',
                                  Iconsax.bank),
                              _buildModernDropdown(
                                label: 'Payment Terms',
                                icon: Iconsax.money,
                                value: _selectedPaymentTerms,
                                items: _paymentTerms,
                                itemLabel: (term) => term,
                                onChanged: (value) => setState(
                                        () => _selectedPaymentTerms = value),
                              ),
                              _buildModernDropdown(
                                label: 'Distribution Type',
                                icon: Iconsax.truck_fast,
                                value: _selectedDistributionType,
                                items: _distributionTypes,
                                itemLabel: (type) => type,
                                onChanged: (value) => setState(() =>
                                _selectedDistributionType = value),
                              ),
                              _buildModernDropdown(
                                label: 'Areas Covered',
                                icon: Iconsax.global,
                                value: _selectedAreasCovered,
                                items: _areasCovered,
                                itemLabel: (area) => area,
                                onChanged: (value) => setState(
                                        () => _selectedAreasCovered = value),
                              ),
                              _buildModernTextField('Languages Published',
                                  'languagesPublished',
                                  Iconsax.translate),
                              _buildModernTextField('Number of Titles',
                                  'numberOfTitles', Iconsax.book_1),
                            ],
                          ),

                          // Credentials Section (Last, only if not edit mode)
                          if (!_isEditMode) ...[
                            const SizedBox(height: 20),
                            _buildCredentialsSection(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildModernActionButtons(),
          ],
        ),
      ),
    );
  }

  // REFACTORED: Much slimmer header
  Widget _buildSlimHeader() {
    final progress = _calculateOverallProgress();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _isEditMode ? Iconsax.edit : Iconsax.add_circle,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isEditMode ? 'Edit Publisher' : 'New Publisher',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Slim progress bar integrated at bottom of header
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? Colors.amberAccent : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Combined Section (Basic Info Left + Logo Right)
  Widget _buildBasicInfoWithLogo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isBasicInfoComplete()
              ? Colors.blue.withOpacity(0.5)
              : Colors.blue.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.info_circle, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Text(
                'Basic Information',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Text Fields
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildModernTextField('Publisher Name', 'publisherName',
                        Iconsax.building,
                        isRequired: true),
                    _buildModernDropdown(
                      label: 'Publisher Type',
                      icon: Iconsax.category,
                      value: _selectedPublisherType,
                      items: _publisherTypes,
                      itemLabel: (type) => type,
                      onChanged: (value) =>
                          setState(() => _selectedPublisherType = value),
                      isRequired: true,
                    ),
                    _buildYearPicker(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right Side: Logo Picker
              Column(
                children: [
                  Text(
                    'Publisher Logo',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickLogo,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey[300]!, style: BorderStyle.solid),
                      ),
                      child: _selectedLogoBytes != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.memory(_selectedLogoBytes!,
                            fit: BoxFit.cover),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.gallery_add,
                              size: 32, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Upload',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return _buildSection(
      'Login Credentials',
      Iconsax.key,
      Colors.red,
      _isCredentialsComplete(),
      [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildModernTextField(
                'UserID',
                'userID',
                Iconsax.user,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              margin: const EdgeInsets.only(top: 0),
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isVerifyingUserID ? null : _verifyUserID,
                icon: _isVerifyingUserID
                    ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : Icon(
                  _userIdVerified == null
                      ? Iconsax.tick_circle
                      : _userIdVerified!
                      ? Iconsax.close_circle
                      : Iconsax.tick_circle,
                  size: 22,
                ),
                label: Text(
                  _isVerifyingUserID ? '...' : 'Verify',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userIdVerified == null
                      ? AppTheme.primaryGreen
                      : _userIdVerified!
                      ? Colors.red
                      : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        if (_userIdVerificationMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_userIdVerified == true ? Colors.red : Colors.green)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (_userIdVerified == true ? Colors.red : Colors.green)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _userIdVerified == true
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                  size: 18,
                  color: _userIdVerified == true ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _userIdVerificationMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color:
                      _userIdVerified == true ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _buildModernTextField(
          'Password',
          'userPassword',
          Iconsax.lock,
          isPassword: true,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildSection(
      String title,
      IconData icon,
      Color color,
      bool isComplete,
      List<Widget> children,
      ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? Colors.green.withOpacity(0.5) : color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (isComplete ? Colors.green : color).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              if (isComplete) ...[
                const Spacer(),
                Icon(Icons.check_circle, size: 18, color: Colors.green),
              ]
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernTextField(String label, String key, IconData icon,
      {bool isPassword = false, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: isPassword,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey[600],
          ),
          prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.primaryGreen, width: 1.5),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: isRequired
            ? (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        }
            : null,
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required Function(T?) onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: (value != null && items.contains(value)) ? value : null,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
          prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.primaryGreen, width: 1.5),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemLabel(item),
              style:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: isRequired
            ? (value) {
          if (value == null) return '$label is required';
          return null;
        }
            : null,
        dropdownColor: Colors.white,
        icon:
        Icon(Iconsax.arrow_down_1, size: 20, color: AppTheme.primaryGreen),
        isExpanded: true,
      ),
    );
  }

  Widget _buildYearPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(_selectedYear ?? DateTime.now().year),
            firstDate: DateTime(1800),
            lastDate: DateTime.now(),
            initialDatePickerMode: DatePickerMode.year,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppTheme.primaryGreen,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (picked != null) {
            setState(() => _selectedYear = picked.year);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Year of Establishment *',
            labelStyle:
            GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
            prefixIcon:
            Icon(Iconsax.calendar, size: 18, color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primaryGreen, width: 1.5),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          child: Text(
            _selectedYear?.toString() ?? 'Select Year',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _selectedYear != null ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              foregroundColor: Colors.grey[700],
            ),
            child: Text('Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveForm,
            icon: _isSaving
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
                : Icon(
              _isEditMode ? Iconsax.tick_circle : Iconsax.add_circle,
              size: 20,
            ),
            label: Text(
              _isSaving
                  ? 'Saving...'
                  : _isEditMode
                  ? 'Update Publisher'
                  : 'Create Publisher',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}