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
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
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
        _userIdVerified == false; // UserID must be verified as NOT existing
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
      print('[AddEditPublisher] Loaded ${_states.length} states');
    } catch (e) {
      setState(() => _loadingLocations = false);
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load location data');
      }
      print('[AddEditPublisher] Error loading locations: $e');
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
      print(
          '[AddEditPublisher] Loaded ${_districts.length} districts for state $stateID');
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load districts');
      }
      print('[AddEditPublisher] Error loading districts: $e');
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
      print(
          '[AddEditPublisher] Loaded ${_cities.length} cities for district $districtID');
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load cities');
      }
      print('[AddEditPublisher] Error loading cities: $e');
    }
  }

  // Verify UserID existence
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
          _userIdVerificationMessage = 'UserID already exists! Please choose another.';
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
    _controllers['bankAccountDetails']!.text =
        details.bankAccountDetails ?? '';
    _controllers['languagesPublished']!.text =
        details.languagesPublished ?? '';
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
      final XFile? image =
      await _picker.pickImage(source: ImageSource.gallery);
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
        CustomSnackbar.showError(context, 'UserID already exists! Choose another UserID');
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
          'BankAccountDetails':
          _controllers['bankAccountDetails']!.text.trim(),
          'PaymentID': _paymentTerms.indexOf(_selectedPaymentTerms ?? '') + 1,
          'DistributionType': _selectedDistributionType,
          'AreasCovered': _selectedAreasCovered,
          'LanguagesPublished':
          _controllers['languagesPublished']!.text.trim(),
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
        final publisherGroup = userGroups.firstWhere(
              (group) => group.userGroupName.toLowerCase().contains('publisher'),
          orElse: () => throw Exception('Publisher user group not found'),
        );

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
          'BankAccountDetails':
          _controllers['bankAccountDetails']!.text.trim(),
          'PaymentID': _paymentTerms.indexOf(_selectedPaymentTerms ?? '') + 1,
          'DistributionType': _selectedDistributionType,
          'AreasCovered': _selectedAreasCovered,
          'LanguagesPublished':
          _controllers['languagesPublished']!.text.trim(),
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
          maxWidth: 950,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 50,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildModernHeader(),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogoSection(),
                        const SizedBox(height: 24),
                        if (!_isEditMode) ...[
                          _buildCredentialsSection(),
                          const SizedBox(height: 24),
                        ],
                        _buildSection(
                          'Basic Information',
                          Iconsax.info_circle,
                          Colors.blue,
                          _isBasicInfoComplete(),
                          [
                            _buildModernTextField('Publisher Name',
                                'publisherName', Iconsax.building,
                                isRequired: true),
                            _buildModernDropdown(
                              label: 'Publisher Type',
                              icon: Iconsax.category,
                              value: _selectedPublisherType,
                              items: _publisherTypes,
                              itemLabel: (type) => type,
                              onChanged: (value) => setState(
                                      () => _selectedPublisherType = value),
                              isRequired: true,
                            ),
                            _buildYearPicker(),
                          ],
                        ),
                        const SizedBox(height: 24),
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
                        const SizedBox(height: 24),
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
                              value: _states.isNotEmpty &&
                                  _selectedStateID != null
                                  ? _states.firstWhere(
                                      (s) =>
                                  s['StateID'] == _selectedStateID,
                                  orElse: () => {})
                                  : null,
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
                              value: _districts.isNotEmpty &&
                                  _selectedDistrictID != null
                                  ? _districts.firstWhere(
                                      (d) =>
                                  d['DistrictID'] ==
                                      _selectedDistrictID,
                                  orElse: () => {})
                                  : null,
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
                              value: _cities.isNotEmpty &&
                                  _selectedCityID != null
                                  ? _cities.firstWhere(
                                      (c) => c['CityID'] == _selectedCityID,
                                  orElse: () => {})
                                  : null,
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
                        const SizedBox(height: 24),
                        _buildSection(
                          'Business Details',
                          Iconsax.document,
                          Colors.orange,
                          false,
                          [
                            _buildModernTextField(
                                'Website', 'website', Iconsax.link),
                            _buildModernTextField(
                                'GST Number', 'gstNumber', Iconsax.card),
                            _buildModernTextField(
                                'PAN Number', 'panNumber', Iconsax.card),
                            _buildModernTextField('Bank Account Details',
                                'bankAccountDetails', Iconsax.bank),
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
                                'languagesPublished', Iconsax.translate),
                            _buildModernTextField('Number of Titles',
                                'numberOfTitles', Iconsax.book_1),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    final progress = _calculateOverallProgress();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isEditMode ? Iconsax.edit : Iconsax.add_circle,
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
                      _isEditMode ? 'Edit Publisher' : 'Add New Publisher',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditMode
                          ? 'Update publisher information'
                          : 'Fill in the details below',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                iconSize: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completion Progress',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Publisher Logo',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickLogo,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen, width: 2),
              ),
              child: _selectedLogoBytes != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(_selectedLogoBytes!, fit: BoxFit.cover),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.gallery_add,
                      size: 48, color: AppTheme.primaryGreen),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
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
          children: [
            Expanded(
              child: _buildModernTextField(
                'UserID',
                'userID',
                Iconsax.user,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isVerifyingUserID ? null : _verifyUserID,
                icon: _isVerifyingUserID
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(
                  _userIdVerified == null
                      ? Iconsax.tick_circle
                      : _userIdVerified!
                      ? Iconsax.close_circle
                      : Iconsax.tick_circle,
                  size: 20,
                ),
                label: Text(_isVerifyingUserID ? 'Checking...' : 'Verify'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userIdVerified == null
                      ? AppTheme.primaryGreen
                      : _userIdVerified!
                      ? Colors.red
                      : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ],
        ),
        if (_userIdVerificationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(
                  _userIdVerified == true
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                  size: 16,
                  color: _userIdVerified == true ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _userIdVerificationMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _userIdVerified == true ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete ? Colors.green.withOpacity(0.5) : color.withOpacity(0.2),
          width: isComplete ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isComplete
                      ? Colors.green.withOpacity(0.15)
                      : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isComplete ? Colors.green : color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              if (isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        'Complete',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernTextField(String label, String key, IconData icon,
      {bool isPassword = false, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryGreen),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        value: (value != null && items.contains(value)) ? value : null,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryGreen),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemLabel(item),
              style: GoogleFonts.inter(fontSize: 14),
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
        icon: Icon(Iconsax.arrow_down_1, size: 20, color: AppTheme.primaryGreen),
        isExpanded: true,
      ),
    );
  }

  Widget _buildYearPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
            labelText: 'Year of Establishment',
            prefixIcon:
            Icon(Iconsax.calendar, size: 20, color: AppTheme.primaryGreen),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          child: Text(
            _selectedYear?.toString() ?? 'Select Year',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _selectedYear != null ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppTheme.primaryGreen),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppTheme.primaryGreen,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: _isSaving
                  ? const ButtonLoader()
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isEditMode ? Iconsax.tick_circle : Iconsax.add_circle,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode ? 'Update Publisher' : 'Create Publisher',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
