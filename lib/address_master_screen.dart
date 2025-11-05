import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:lms_publisher/service/address_master_service.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';

// ==================== MAIN SCREEN ====================
class AddressMasterScreen extends StatelessWidget {
  const AddressMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if screen is phone-sized
    final isPhone = MediaQuery.of(context).size.width < 600;

    if (isPhone) {
      // For phone screens, show only Direct Entry without tabs
      return MainLayout(
        activeScreen: AppScreen.addressMaster,
        child: AddressMasterView(isPhoneMode: true),
      );
    } else {
      // For larger screens, show tabs as before
      return DefaultTabController(
        length: 2,
        child: MainLayout(
          activeScreen: AppScreen.addressMaster,
          child: AddressMasterView(isPhoneMode: false),
        ),
      );
    }
  }
}

// ==================== VIEW WIDGET ====================
class AddressMasterView extends StatefulWidget {
  final bool isPhoneMode;

  const AddressMasterView({super.key, required this.isPhoneMode});

  @override
  State<AddressMasterView> createState() => _AddressMasterViewState();
}

class _AddressMasterViewState extends State<AddressMasterView> {
  final AddressMasterService _service = AddressMasterService();

  // Loading states
  bool isLoadingStates = true;
  bool isLoadingDistricts = false;
  bool isLoadingCities = false;

  // Data lists
  List<StateModel> states = [];
  List<DistrictModel> districts = [];
  List<CityModel> cities = [];

  // Selected items
  StateModel? selectedState;
  DistrictModel? selectedDistrict;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ==================== DATA LOADING ====================
  Future<void> _loadStates() async {
    if (!mounted) return;
    setState(() => isLoadingStates = true);
    try {
      final statesList = await _service.getStates();
      if (mounted) {
        setState(() {
          states = statesList;
          isLoadingStates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingStates = false);
        _showError('Failed to load states: $e');
      }
    }
  }

  Future<void> _loadDistricts(int stateId) async {
    if (!mounted) return;
    setState(() => isLoadingDistricts = true);
    try {
      final districtsList = await _service.getDistricts(stateId: stateId);
      if (mounted) {
        setState(() {
          districts = districtsList;
          isLoadingDistricts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingDistricts = false);
        _showError('Failed to load districts: $e');
      }
    }
  }

  Future<void> _loadCities(int districtId) async {
    if (!mounted) return;
    setState(() => isLoadingCities = true);
    try {
      final citiesList = await _service.getCities(districtId: districtId);
      if (mounted) {
        setState(() {
          cities = citiesList;
          isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingCities = false);
        _showError('Failed to load cities: $e');
      }
    }
  }

  // ==================== DIALOGS ====================
  Future<void> _showAddStateDialog() async {
    if (!mounted) return;
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Add New State',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: _buildInputDecoration(
                  'State Name',
                  Iconsax.location,
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'State name is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.bodyText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _service.insertState(nameController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    _showSuccess('State added successfully');
                    _loadStates();
                  }
                } catch (e) {
                  if (mounted) {
                    _showError('Failed to add state: $e');
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditStateDialog(StateModel state) async {
    if (!mounted) return;
    final nameController = TextEditingController(text: state.stateName);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Edit State',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: _buildInputDecoration('State Name', Iconsax.location),
            validator: (value) =>
            value?.isEmpty ?? true ? 'State name is required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.bodyText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _service.updateState(state.stateId, nameController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    _showSuccess('State updated successfully');
                    _loadStates();
                  }
                } catch (e) {
                  if (mounted) {
                    _showError('Failed to update state: $e');
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDistrictDialog() async {
    if (!mounted || selectedState == null) {
      _showError('Please select a state first');
      return;
    }

    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Add District to ${selectedState!.stateName}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: _buildInputDecoration('District Name', Iconsax.map),
            validator: (value) =>
            value?.isEmpty ?? true ? 'District name is required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.bodyText)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _service.insertDistrict(
                    nameController.text,
                    selectedState!.stateId,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _showSuccess('District added successfully');
                    _loadDistricts(selectedState!.stateId);
                  }
                } catch (e) {
                  if (mounted) {
                    _showError('Failed to add district: $e');
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCityDialog() async {
    if (!mounted || selectedDistrict == null) {
      _showError('Please select a district first');
      return;
    }

    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Add City to ${selectedDistrict!.districtName}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: _buildInputDecoration('City Name', Iconsax.buildings),
            validator: (value) =>
            value?.isEmpty ?? true ? 'City name is required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.bodyText)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _service.insertCity(
                    nameController.text,
                    selectedDistrict!.districtId,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _showSuccess('City added successfully');
                    _loadCities(selectedDistrict!.districtId);
                  }
                } catch (e) {
                  if (mounted) {
                    _showError('Failed to add city: $e');
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        color: AppTheme.bodyText,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryGreen),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.borderGrey.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.borderGrey.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If phone mode, show only Direct Entry
    if (widget.isPhoneMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.location,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Address Master',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      Text(
                        'Quick Entry',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Direct Entry Form
          Expanded(
            child: _buildDirectEntryView(),
          ),
        ],
      );
    }

    // Original tablet/desktop view with tabs
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.location,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address Master',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage States, Districts & Cities',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            indicatorColor: AppTheme.primaryGreen,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.bodyText,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            tabs: const [
              Tab(
                icon: Icon(Iconsax.hierarchy, size: 20),
                text: 'Hierarchical View',
              ),
              Tab(
                icon: Icon(Iconsax.additem, size: 20),
                text: 'Direct Entry',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Tab Content
        Expanded(
          child: TabBarView(
            children: [
              _buildHierarchicalView(),
              _buildDirectEntryView(),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== HIERARCHICAL VIEW ====================
  Widget _buildHierarchicalView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // States Column
        Expanded(
          child: _buildCard(
            title: 'States',
            count: states.length,
            icon: Iconsax.location,
            onAdd: _showAddStateDialog,
            child: isLoadingStates
                ? const Center(
              child: BeautifulLoader(
                type: LoaderType.spinner,
                color: AppTheme.primaryGreen, // ✅ AppTheme color
                size: 40,
              ),
            )
                : states.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.location,
                    size: 64,
                    color: AppTheme.borderGrey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No states added yet',
                    style: GoogleFonts.inter(
                      color: AppTheme.bodyText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: states.length,
              itemBuilder: (context, index) {
                final state = states[index];
                final isSelected =
                    selectedState?.stateId == state.stateId;
                return _buildListTile(
                  title: state.stateName,
                  isSelected: isSelected,
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        selectedState = state;
                        selectedDistrict = null;
                        districts = [];
                        cities = [];
                      });
                      _loadDistricts(state.stateId);
                    }
                  },
                  onEdit: () => _showEditStateDialog(state),
                  onDelete: () async {
                    try {
                      await _service.deleteState(state.stateId);
                      if (mounted) {
                        _showSuccess('State deleted successfully');
                        _loadStates();
                      }
                    } catch (e) {
                      if (mounted) {
                        _showError('Failed to delete: $e');
                      }
                    }
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Districts Column
        Expanded(
          child: _buildCard(
            title: 'Districts',
            count: districts.length,
            icon: Iconsax.map,
            onAdd: selectedState != null ? _showAddDistrictDialog : null,
            child: selectedState == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.map,
                    size: 64,
                    color: AppTheme.borderGrey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select a state to view districts',
                    style: GoogleFonts.inter(
                      color: AppTheme.bodyText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : isLoadingDistricts
                ? const Center(
              child: BeautifulLoader(
                type: LoaderType.spinner,
                color: AppTheme.primaryGreen, // ✅ AppTheme color
                size: 40,
              ),
            )
                : districts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.map,
                    size: 64,
                    color: AppTheme.borderGrey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No districts in this state',
                    style: GoogleFonts.inter(
                      color: AppTheme.bodyText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: districts.length,
              itemBuilder: (context, index) {
                final district = districts[index];
                final isSelected = selectedDistrict?.districtId ==
                    district.districtId;
                return _buildListTile(
                  title: district.districtName,
                  isSelected: isSelected,
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        selectedDistrict = district;
                        cities = [];
                      });
                      _loadCities(district.districtId);
                    }
                  },
                  onDelete: () async {
                    try {
                      await _service
                          .deleteDistrict(district.districtId);
                      if (mounted) {
                        _showSuccess(
                            'District deleted successfully');
                        _loadDistricts(selectedState!.stateId);
                      }
                    } catch (e) {
                      if (mounted) {
                        _showError('Failed to delete: $e');
                      }
                    }
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Cities Column
        Expanded(
          child: _buildCard(
            title: 'Cities',
            count: cities.length,
            icon: Iconsax.buildings,
            onAdd: selectedDistrict != null ? _showAddCityDialog : null,
            child: selectedDistrict == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.buildings,
                    size: 64,
                    color: AppTheme.borderGrey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select a district to view cities',
                    style: GoogleFonts.inter(
                      color: AppTheme.bodyText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : isLoadingCities
                ? const Center(
              child: BeautifulLoader(
                type: LoaderType.spinner,
                color: AppTheme.primaryGreen, // ✅ AppTheme color
                size: 40,
              ),
            )
                : cities.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.buildings,
                    size: 64,
                    color: AppTheme.borderGrey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cities in this district',
                    style: GoogleFonts.inter(
                      color: AppTheme.bodyText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: cities.length,
              itemBuilder: (context, index) {
                final city = cities[index];
                return _buildListTile(
                  title: city.cityName,
                  onDelete: () async {
                    try {
                      await _service.deleteCity(city.cityId);
                      if (mounted) {
                        _showSuccess('City deleted successfully');
                        _loadCities(
                            selectedDistrict!.districtId);
                      }
                    } catch (e) {
                      if (mounted) {
                        _showError('Failed to delete: $e');
                      }
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==================== DIRECT ENTRY VIEW ====================
  Widget _buildDirectEntryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _DirectEntryForm(
        states: states,
        districts: districts,
        service: _service,
        onSuccess: () {
          _loadStates();
        },
        onError: _showError,
        onLoadDistricts: _loadDistricts,
        isPhoneMode: widget.isPhoneMode,
      ),
    );
  }

  // ==================== WIDGETS ====================
  Widget _buildCard({
    required String title,
    required int count,
    required IconData icon,
    required Widget child,
    VoidCallback? onAdd,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText,
                        ),
                      ),
                      Text(
                        '$count ${count == 1 ? 'item' : 'items'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onAdd != null)
                  Material(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Iconsax.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderGrey.withOpacity(0.3)),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    bool isSelected = false,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryGreen.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.darkText,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Iconsax.edit, size: 18),
                    onPressed: onEdit,
                    color: AppTheme.bodyText,
                    tooltip: 'Edit',
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Iconsax.trash, size: 18),
                    onPressed: onDelete,
                    color: Colors.red.shade400,
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== DIRECT ENTRY FORM ====================
class _DirectEntryForm extends StatefulWidget {
  final List<StateModel> states;
  final List<DistrictModel> districts;
  final AddressMasterService service;
  final VoidCallback onSuccess;
  final Function(String) onError;
  final Function(int) onLoadDistricts;
  final bool isPhoneMode;

  const _DirectEntryForm({
    required this.states,
    required this.districts,
    required this.service,
    required this.onSuccess,
    required this.onError,
    required this.onLoadDistricts,
    required this.isPhoneMode,
  });

  @override
  State<_DirectEntryForm> createState() => _DirectEntryFormState();
}

class _DirectEntryFormState extends State<_DirectEntryForm> {
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  StateModel? _selectedStateForDistrict;
  StateModel? _selectedStateForCity;
  DistrictModel? _selectedDistrictForCity;

  @override
  void dispose() {
    _stateController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // ✅ Helper method to show validation errors
  void _showValidationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.isPhoneMode ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Entry Form',
            style: GoogleFonts.poppins(
              fontSize: widget.isPhoneMode ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add states, districts, and cities quickly',
            style: GoogleFonts.inter(
              fontSize: widget.isPhoneMode ? 12 : 14,
              color: AppTheme.bodyText,
            ),
          ),
          const SizedBox(height: 24),

          // State Entry
          _buildSection(
            title: 'Add State',
            icon: Iconsax.location,
            child: widget.isPhoneMode
                ? Column(
              children: [
                TextField(
                  controller: _stateController,
                  decoration: InputDecoration(
                    hintText: 'Enter state name',
                    hintStyle: GoogleFonts.inter(
                      color: AppTheme.bodyText.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: AppTheme.borderGrey.withOpacity(0.1),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // ✅ Validate empty field
                      if (_stateController.text.trim().isEmpty) {
                        _showValidationError('Please enter state name');
                        return;
                      }

                      try {
                        await widget.service
                            .insertState(_stateController.text.trim());
                        _stateController.clear();
                        widget.onSuccess();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'State added successfully'),
                              backgroundColor: AppTheme.primaryGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        widget.onError('Failed to add state: $e');
                      }
                    },
                    icon: const Icon(Iconsax.add, size: 18),
                    label: const Text('Add State'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            )
                : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      hintText: 'Enter state name',
                      hintStyle: GoogleFonts.inter(
                        color: AppTheme.bodyText.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: AppTheme.borderGrey.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    // ✅ Validate empty field
                    if (_stateController.text.trim().isEmpty) {
                      _showValidationError('Please enter state name');
                      return;
                    }

                    try {
                      await widget.service
                          .insertState(_stateController.text.trim());
                      _stateController.clear();
                      widget.onSuccess();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                            const Text('State added successfully'),
                            backgroundColor: AppTheme.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      widget.onError('Failed to add state: $e');
                    }
                  },
                  icon: const Icon(Iconsax.add, size: 18),
                  label: const Text('Add State'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // District Entry
          _buildSection(
            title: 'Add District',
            icon: Iconsax.map,
            child: widget.isPhoneMode
                ? Column(
              children: [
                // First Row: State Dropdown + District Input
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<StateModel>(
                        value: _selectedStateForDistrict,
                        decoration: InputDecoration(
                          hintText: 'Select State',
                          filled: true,
                          fillColor: AppTheme.borderGrey.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: widget.states
                            .map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(
                            state.stateName,
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedStateForDistrict = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _districtController,
                        decoration: InputDecoration(
                          hintText: 'District name',
                          hintStyle: GoogleFonts.inter(
                            color: AppTheme.bodyText.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppTheme.borderGrey.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        enabled: _selectedStateForDistrict != null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Second Row: Add Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedStateForDistrict != null
                        ? () async {
                      // ✅ Validate empty field
                      if (_districtController.text.trim().isEmpty) {
                        _showValidationError(
                            'Please enter district name');
                        return;
                      }

                      try {
                        await widget.service.insertDistrict(
                          _districtController.text.trim(),
                          _selectedStateForDistrict!.stateId,
                        );
                        _districtController.clear();
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'District added successfully'),
                              backgroundColor:
                              AppTheme.primaryGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        widget.onError('Failed to add district: $e');
                      }
                    }
                        : null,
                    icon: const Icon(Iconsax.add, size: 18),
                    label: const Text('Add District'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            )
                : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<StateModel>(
                    value: _selectedStateForDistrict,
                    decoration: InputDecoration(
                      hintText: 'Select State',
                      filled: true,
                      fillColor: AppTheme.borderGrey.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: widget.states
                        .map((state) => DropdownMenuItem(
                      value: state,
                      child: Text(state.stateName),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedStateForDistrict = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _districtController,
                    decoration: InputDecoration(
                      hintText: 'Enter district name',
                      hintStyle: GoogleFonts.inter(
                        color: AppTheme.bodyText.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: AppTheme.borderGrey.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    enabled: _selectedStateForDistrict != null,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _selectedStateForDistrict != null
                      ? () async {
                    // ✅ Validate empty field
                    if (_districtController.text.trim().isEmpty) {
                      _showValidationError(
                          'Please enter district name');
                      return;
                    }

                    try {
                      await widget.service.insertDistrict(
                        _districtController.text.trim(),
                        _selectedStateForDistrict!.stateId,
                      );
                      _districtController.clear();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'District added successfully'),
                            backgroundColor: AppTheme.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      widget.onError('Failed to add district: $e');
                    }
                  }
                      : null,
                  icon: const Icon(Iconsax.add, size: 18),
                  label: const Text('Add District'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // City Entry
          _buildSection(
            title: 'Add City',
            icon: Iconsax.buildings,
            child: widget.isPhoneMode
                ? Column(
              children: [
                // First Row: State + District Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<StateModel>(
                        value: _selectedStateForCity,
                        decoration: InputDecoration(
                          hintText: 'State',
                          filled: true,
                          fillColor: AppTheme.borderGrey.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: widget.states
                            .map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(
                            state.stateName,
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStateForCity = value;
                            _selectedDistrictForCity = null;
                          });
                          if (value != null) {
                            widget.onLoadDistricts(value.stateId);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<DistrictModel>(
                        value: _selectedDistrictForCity,
                        decoration: InputDecoration(
                          hintText: 'District',
                          filled: true,
                          fillColor: AppTheme.borderGrey.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: widget.districts
                            .map((district) => DropdownMenuItem(
                          value: district,
                          child: Text(
                            district.districtName,
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedDistrictForCity = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Second Row: City Input + Add Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          hintText: 'City name',
                          hintStyle: GoogleFonts.inter(
                            color: AppTheme.bodyText.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppTheme.borderGrey.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        enabled: _selectedDistrictForCity != null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _selectedDistrictForCity != null
                          ? () async {
                        // ✅ Validate empty field
                        if (_cityController.text.trim().isEmpty) {
                          _showValidationError(
                              'Please enter city name');
                          return;
                        }

                        try {
                          await widget.service.insertCity(
                            _cityController.text.trim(),
                            _selectedDistrictForCity!.districtId,
                          );
                          _cityController.clear();
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'City added successfully'),
                                backgroundColor:
                                AppTheme.primaryGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          widget.onError('Failed to add city: $e');
                        }
                      }
                          : null,
                      icon: const Icon(Iconsax.add, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
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
                ),
              ],
            )
                : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<StateModel>(
                    value: _selectedStateForCity,
                    decoration: InputDecoration(
                      hintText: 'Select State',
                      filled: true,
                      fillColor: AppTheme.borderGrey.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: widget.states
                        .map((state) => DropdownMenuItem(
                      value: state,
                      child: Text(state.stateName),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStateForCity = value;
                        _selectedDistrictForCity = null;
                      });
                      if (value != null) {
                        widget.onLoadDistricts(value.stateId);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<DistrictModel>(
                    value: _selectedDistrictForCity,
                    decoration: InputDecoration(
                      hintText: 'Select District',
                      filled: true,
                      fillColor: AppTheme.borderGrey.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: widget.districts
                        .map((district) => DropdownMenuItem(
                      value: district,
                      child: Text(district.districtName),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedDistrictForCity = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      hintText: 'Enter city name',
                      hintStyle: GoogleFonts.inter(
                        color: AppTheme.bodyText.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: AppTheme.borderGrey.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    enabled: _selectedDistrictForCity != null,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _selectedDistrictForCity != null
                      ? () async {
                    // ✅ Validate empty field
                    if (_cityController.text.trim().isEmpty) {
                      _showValidationError('Please enter city name');
                      return;
                    }

                    try {
                      await widget.service.insertCity(
                        _cityController.text.trim(),
                        _selectedDistrictForCity!.districtId,
                      );
                      _cityController.clear();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'City added successfully'),
                            backgroundColor: AppTheme.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      widget.onError('Failed to add city: $e');
                    }
                  }
                      : null,
                  icon: const Icon(Iconsax.add, size: 18),
                  label: const Text('Add City'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: widget.isPhoneMode ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

