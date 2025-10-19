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
    'country': TextEditingController(text: 'India'), // DEFAULT VALUE
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load location data first
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
      // Load states first
      final statesData = await _apiService.getStates();

      // Convert to proper format with correct field names
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

      // Convert to proper format
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

      print('[AddEditPublisher] Loaded ${_districts.length} districts for state $stateID');
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

      // Convert to proper format
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

      print('[AddEditPublisher] Loaded ${_cities.length} cities for district $districtID');
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load cities');
      }
      print('[AddEditPublisher] Error loading cities: $e');
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

    // Load dependent dropdowns
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
                          [
                            _buildModernTextField('Publisher Name',
                                'publisherName', Iconsax.building,
                                isRequired: true),
                            _buildModernDropdown<String>(
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
                          [
                            _buildModernTextField('Address Line 1',
                                'addressLine1', Iconsax.location),
                            _buildModernTextField('Address Line 2',
                                'addressLine2', Iconsax.location),
                            _buildModernDropdown<Map<String, dynamic>>(
                              label: 'State',
                              icon: Iconsax.map,
                              value: _states.isNotEmpty && _selectedStateID != null
                                  ? _states.firstWhere(
                                      (s) => s['StateID'] == _selectedStateID,
                                  orElse: () => <String, dynamic>{})
                                  : null,
                              items: _states.where((s) => s.isNotEmpty).toList(), // FILTER EMPTY MAPS
                              itemLabel: (state) => state['StateName'] ?? 'Unknown',
                              onChanged: (value) {
                                if (value != null && value.isNotEmpty) { // CHECK IF NOT EMPTY
                                  setState(() {
                                    _selectedStateID = value['StateID'];
                                    _selectedDistrictID = null;
                                    _selectedCityID = null;
                                    _districts = [];
                                    _cities = [];
                                  });
                                  if (_selectedStateID != null) {
                                    _loadDistrictsForState(_selectedStateID!);
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
                              icon: Iconsax.location,
                              value: _cities.isNotEmpty &&
                                  _selectedCityID != null
                                  ? _cities.firstWhere(
                                      (c) =>
                                  c['CityID'] == _selectedCityID,
                                  orElse: () => {})
                                  : null,
                              items: _cities,
                              itemLabel: (city) =>
                              city['CityName'] ?? '',
                              onChanged: (value) => setState(
                                      () => _selectedCityID = value?['CityID']),
                            ),
                            _buildModernTextField(
                                'Country', 'country', Iconsax.global),
                            _buildModernTextField(
                                'PIN/Zip', 'pinZipCode', Iconsax.map),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          'Business Information',
                          Iconsax.dollar_circle,
                          Colors.orange,
                          [
                            _buildModernTextField(
                                'Website', 'website', Iconsax.global),
                            _buildModernTextField('GST Number',
                                'gstNumber', Iconsax.document_text),
                            _buildModernTextField(
                                'PAN Number', 'panNumber', Iconsax.card),
                            _buildModernTextField('Bank Details',
                                'bankAccountDetails', Iconsax.bank),
                            _buildModernDropdown<String>(
                              label: 'Payment Terms',
                              icon: Iconsax.money,
                              value: _selectedPaymentTerms,
                              items: _paymentTerms,
                              itemLabel: (term) => term,
                              onChanged: (value) => setState(
                                      () => _selectedPaymentTerms = value),
                            ),
                            _buildModernDropdown<String>(
                              label: 'Distribution Type',
                              icon: Iconsax.box,
                              value: _selectedDistributionType,
                              items: _distributionTypes,
                              itemLabel: (type) => type,
                              onChanged: (value) => setState(() =>
                              _selectedDistributionType = value),
                            ),
                            _buildModernDropdown<String>(
                              label: 'Areas Covered',
                              icon: Iconsax.global,
                              value: _selectedAreasCovered,
                              items: _areasCovered,
                              itemLabel: (area) => area,
                              onChanged: (value) => setState(
                                      () => _selectedAreasCovered = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          'Publishing Details',
                          Iconsax.book,
                          Colors.teal,
                          [
                            _buildModernTextField(
                                'Languages',
                                'languagesPublished',
                                Iconsax.language_square),
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
            _buildModernFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border:
              Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Icon(_isEditMode ? Iconsax.edit : Iconsax.add,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode ? 'Edit Publisher' : 'Add New Publisher',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _isEditMode
                      ? 'Update publisher information'
                      : 'Create a new publisher profile',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFooter() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1.5)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveForm,
            icon: Icon(
                _isSaving
                    ? Icons.hourglass_empty
                    : (_isEditMode ? Iconsax.tick_circle : Iconsax.add_circle),
                size: 20),
            label: Text(
              _isSaving
                  ? 'Saving...'
                  : (_isEditMode ? 'Update Publisher' : 'Create Publisher'),
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: GestureDetector(
        onTap: _pickLogo,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.4), width: 3),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _selectedLogoBytes != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Image.memory(_selectedLogoBytes!, fit: BoxFit.cover),
          )
              : _existingLogoFileName != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Image.network(
              _apiService.getLogoUrl(_existingLogoFileName!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.gallery_add,
                      size: 40, color: AppTheme.primaryGreen),
                  const SizedBox(height: 8),
                  Text(
                    'Upload Logo',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.gallery_add,
                  size: 40, color: AppTheme.primaryGreen),
              const SizedBox(height: 8),
              Text(
                'Upload Logo',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withOpacity(0.08),
            AppTheme.accentGreen.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                const Icon(Iconsax.shield_tick, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'Login Credentials',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernTextField('User ID', 'userID', Iconsax.user,
              isRequired: true),
          _buildModernTextField('Password', 'userPassword', Iconsax.key,
              isPassword: true, isRequired: true),
        ],
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
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
        icon:
        Icon(Iconsax.arrow_down_1, size: 20, color: AppTheme.primaryGreen),
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
              color:
              _selectedYear != null ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
