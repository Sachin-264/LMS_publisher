import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/School/add_school_screen.dart';
import 'package:lms_publisher/screens/School/school_managebloc.dart';
import 'package:lms_publisher/screens/School/school_model.dart';
import 'package:lms_publisher/service/school_service.dart';

class SchoolDetailDialog extends StatefulWidget {
  final String schoolId;

  const SchoolDetailDialog({super.key, required this.schoolId});

  @override
  State<SchoolDetailDialog> createState() => _SchoolDetailDialogState();
}

class _SchoolDetailDialogState extends State<SchoolDetailDialog> {
  final String _logoBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";

  String? _feeStructureName;
  String? _stateName, _districtName, _cityName;
  String? _boardName, _schoolTypeName, _mediumName, _managementName;

  @override
  void initState() {
    super.initState();
    if (widget.schoolId != '0') {
      context.read<SchoolManageBloc>().add(FetchSchoolDetails(schoolId: widget.schoolId));
    }
  }

  Future<void> _fetchAcademicAndManagementNames(School school) async {
    if (mounted) setState(() {
      _boardName = '...'; _schoolTypeName = '...'; _mediumName = '...'; _managementName = '...';
    });

    try {
      final apiService = SchoolApiService();
      final results = await Future.wait([
        apiService.fetchBoardAffiliations(),
        apiService.fetchSchoolTypes(),
        apiService.fetchMediumInstructions(),
        apiService.fetchManagementTypes(),
      ]);

      final boards = results[0];
      final schoolTypes = results[1];
      final mediums = results[2];
      final managements = results[3];

      if (mounted) {
        setState(() {
          _boardName = boards.firstWhere((b) => b['id'] == school.board, orElse: () => {'name': 'ID: ${school.board}'})['name'];
          _schoolTypeName = schoolTypes.firstWhere((st) => st['id'] == school.schoolType, orElse: () => {'name': 'ID: ${school.schoolType}'})['name'];
          _mediumName = mediums.firstWhere((m) => m['id'] == school.medium, orElse: () => {'name': 'ID: ${school.medium}'})['name'];
          _managementName = managements.firstWhere((m) => m['id'] == school.managementType, orElse: () => {'name': 'ID: ${school.managementType}'})['name'];
        });
      }
    } catch (e) {
      print("Error fetching academic/management names: $e");
      if (mounted) setState(() {
        _boardName = "Error"; _schoolTypeName = "Error"; _mediumName = "Error"; _managementName = "Error";
      });
    }
  }

  Future<void> _fetchLocationNames(School school) async {
    if (mounted) setState(() {
      _stateName = '...'; _districtName = '...'; _cityName = '...';
    });

    try {
      final apiService = SchoolApiService();
      String? tempStateName, tempDistrictName, tempCityName;

      if (school.stateId != null) {
        final states = await apiService.fetchStates();
        tempStateName = states.firstWhere((s) => s.id == school.stateId, orElse: () => StateModel(id: '', name: 'ID: ${school.stateId}')).name;
      }
      if (school.stateId != null && school.districtId != null) {
        final districts = await apiService.fetchDistricts(school.stateId!);
        tempDistrictName = districts.firstWhere((d) => d.id == school.districtId, orElse: () => DistrictModel(id: '', name: 'ID: ${school.districtId}')).name;
      }
      if (school.districtId != null && school.cityId != null) {
        final cities = await apiService.fetchCities(school.districtId!);
        tempCityName = cities.firstWhere((c) => c.id == school.cityId, orElse: () => CityModel(id: '', name: 'ID: ${school.cityId}')).name;
      }

      if (mounted) setState(() {
        _stateName = tempStateName ?? 'N/A';
        _districtName = tempDistrictName ?? 'N/A';
        _cityName = tempCityName ?? 'N/A';
      });
    } catch (e) {
      if (mounted) setState(() {
        _stateName = "Error"; _districtName = "Error"; _cityName = "Error";
      });
    }
  }

  Future<void> _fetchAndSetFeeStructureName(String feeId) async {
    if (mounted) setState(() => _feeStructureName = '...');
    try {
      final structures = await SchoolApiService().fetchFeeStructures();
      final name = structures.firstWhere((s) => s.id == feeId, orElse: () => FeeStructure(id: '', name: 'Unknown')).name;
      if (mounted) setState(() => _feeStructureName = name);
    } catch (e) {
      if (mounted) setState(() => _feeStructureName = "N/A");
    }
  }

  void _navigateToAddEditSchool(BuildContext parentContext, School school) {
    Navigator.of(parentContext).pop();
    Navigator.of(parentContext).push(
      MaterialPageRoute(builder: (context) => AddSchoolScreen(schoolId: school.id)),
    ).then((result) {
      if (result == true) {
        parentContext.read<SchoolManageBloc>().add(FetchSchools());
      }
    });
  }

  // MODIFIED: This method now contains the responsive logic
  void _showFeeDetails(BuildContext context, String feeId) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final feeDetails = await SchoolApiService().fetchFeeStructureDetails(feeId);
      Navigator.of(context).pop(); // Dismiss loading indicator

      final isSmallScreen = MediaQuery.of(context).size.width < 600;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppTheme.background,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Iconsax.wallet_money, color: AppTheme.primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Fee Structure Details",
                  style: GoogleFonts.poppins(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: isSmallScreen ? double.maxFinite : MediaQuery.of(context).size.width * 0.7,
            child: _buildFeeDetailsContent(feeDetails, isSmallScreen), // Use the new helper widget
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Close", style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to fetch fee details: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // NEW: Helper widget to build responsive fee content
  Widget _buildFeeDetailsContent(List<dynamic> feeDetails, bool isSmallScreen) {
    if (isSmallScreen) {
      // Mobile View: Use a ListView for better readability
      return ListView.builder(
        shrinkWrap: true,
        itemCount: feeDetails.length,
        itemBuilder: (context, index) {
          final detail = feeDetails[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: index.isEven ? Colors.transparent : AppTheme.lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        detail['FeeName'] ?? 'N/A',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Text(
                      '₹${detail['Amount'] ?? '0.00'}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(height: 16),
                _FeeDetailRow(label: 'Class', value: detail['ClassID'] == '0' ? 'All Classes' : detail['ClassID'] ?? 'N/A'),
                _FeeDetailRow(label: 'Fee Type', value: detail['FeeType'] ?? 'N/A'),
                if (detail['Remarks'] != null && detail['Remarks'].isNotEmpty)
                  _FeeDetailRow(label: 'Remarks', value: detail['Remarks']),
              ],
            ),
          );
        },
      );
    } else {
      // Web/Tablet View: Use the existing DataTable
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(AppTheme.primaryGreen.withOpacity(0.1)),
            dataRowHeight: 56,
            headingRowHeight: 56,
            columnSpacing: 24,
            horizontalMargin: 16,
            columns: [
              DataColumn(label: Text('S.No.', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Fee Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Class', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Fee Type', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Amount', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Remarks', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
            ],
            rows: feeDetails.asMap().entries.map((entry) {
              int index = entry.key;
              var detail = entry.value;
              return DataRow(
                color: MaterialStateProperty.all(index.isEven ? Colors.transparent : AppTheme.lightGrey.withOpacity(0.3)),
                cells: [
                  DataCell(Text((index + 1).toString(), style: GoogleFonts.inter())),
                  DataCell(Text(detail['FeeName'] ?? 'N/A', style: GoogleFonts.inter())),
                  DataCell(Text(detail['ClassID'] == '0' ? 'All Classes' : detail['ClassID'] ?? 'N/A', style: GoogleFonts.inter())),
                  DataCell(Text(detail['FeeType'] ?? 'N/A', style: GoogleFonts.inter())),
                  DataCell(Text('₹${detail['Amount'] ?? '0.00'}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primaryGreen))),
                  DataCell(Text(detail['Remarks'] ?? 'N/A', style: GoogleFonts.inter(color: AppTheme.bodyText))),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  void _showExpandedLogo(BuildContext context, String logoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Hero(
                tag: 'school_logo_hero',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: Colors.white, size: 80),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    return BlocConsumer<SchoolManageBloc, SchoolManageState>(
      listener: (context, state) {
        if (state.selectedSchool != null) {
          if (state.selectedSchool!.feeStructureRef != null) {
            _fetchAndSetFeeStructureName(state.selectedSchool!.feeStructureRef!);
          }
          _fetchLocationNames(state.selectedSchool!);
          _fetchAcademicAndManagementNames(state.selectedSchool!);
        }
      },
      builder: (context, state) {
        final school = state.selectedSchool;
        final bool showLoading = state.isDetailLoading || school == null || school.id != widget.schoolId || widget.schoolId == '0';

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : (isMediumScreen ? 40 : 80),
            vertical: isSmallScreen ? 24 : 40,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? double.infinity : (isMediumScreen ? 900 : 1200),
              maxHeight: screenHeight * (isSmallScreen ? 0.9 : 0.85),
            ),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: showLoading
                ? Center(
              child: (widget.schoolId == '0')
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.danger, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Invalid School ID provided.",
                    style: GoogleFonts.inter(fontSize: 16, color: AppTheme.bodyText),
                  ),
                ],
              )
                  : const CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
                : _buildDialogContent(context, school!, isSmallScreen, isMediumScreen),
          ),
        );
      },
    );
  }

  Widget _buildDialogContent(BuildContext context, School school, bool isSmallScreen, bool isMediumScreen) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          _buildHeader(context, school, isSmallScreen, isMediumScreen),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderGrey.withOpacity(0.3), width: 1),
              ),
            ),
            child: isSmallScreen
                ? TabBar(
              isScrollable: true,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.bodyText,
              indicatorColor: AppTheme.primaryGreen,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Iconsax.info_circle_copy, size: 20), text: "General"),
                Tab(icon: Icon(Iconsax.book_1_copy, size: 20), text: "Academics"),
                Tab(icon: Icon(Iconsax.call_copy, size: 20), text: "Contact"),
                Tab(icon: Icon(Iconsax.building_copy, size: 20), text: "Facilities"),
                Tab(icon: Icon(Iconsax.crown_copy, size: 20), text: "Subscription"),
              ],
            )
                : TabBar(
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.bodyText,
              indicatorColor: AppTheme.primaryGreen,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
              tabs: const [
                Tab(icon: Icon(Iconsax.info_circle_copy), text: "General Info"),
                Tab(icon: Icon(Iconsax.book_1_copy), text: "Academics"),
                Tab(icon: Icon(Iconsax.call_copy), text: "Contact"),
                Tab(icon: Icon(Iconsax.building_copy), text: "Facilities & Finance"),
                Tab(icon: Icon(Iconsax.crown_copy), text: "Subscription"),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.lightGrey.withOpacity(0.3),
                    AppTheme.lightGrey.withOpacity(0.1),
                  ],
                ),
              ),
              padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
              child: TabBarView(
                children: [
                  _buildGeneralInfoTab(school, isSmallScreen),
                  _buildAcademicsTab(school, isSmallScreen),
                  _buildContactTab(school, isSmallScreen),
                  _buildFacilitiesAndFinancialsTab(school, isSmallScreen),
                  _buildSubscriptionTab(context, school, isSmallScreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, School school, bool isSmallScreen, bool isMediumScreen) {
    final String? fullLogoUrl = (school.logoPath != null && school.logoPath!.isNotEmpty)
        ? '$_logoBaseUrl${school.logoPath}'
        : null;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isSmallScreen ? 16 : 24),
          topRight: Radius.circular(isSmallScreen ? 16 : 24),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (fullLogoUrl != null) {
                    _showExpandedLogo(context, fullLogoUrl);
                  }
                },
                child: Hero(
                  tag: 'school_logo_hero',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen.withOpacity(0.2),
                          AppTheme.accentGreen.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: isSmallScreen ? 28 : 36,
                      backgroundColor: Colors.transparent,
                      child: fullLogoUrl != null
                          ? ClipOval(
                        child: Image.network(
                          fullLogoUrl,
                          fit: BoxFit.cover,
                          width: isSmallScreen ? 56 : 72,
                          height: isSmallScreen ? 56 : 72,
                          errorBuilder: (_, __, ___) => Icon(
                            Iconsax.building_4,
                            size: isSmallScreen ? 28 : 36,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      )
                          : Icon(
                        Iconsax.building_4,
                        size: isSmallScreen ? 28 : 36,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // MODIFIED: This call is now correct as we will update the widget
                    _StatusBadge(status: school.status, isSmall: isSmallScreen),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.bodyText),
                  onPressed: () => Navigator.of(context).pop(),
                  iconSize: isSmallScreen ? 20 : 24,
                  splashRadius: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          isSmallScreen
              ? Column(
            children: [
              Row(
                children: [
                  Expanded(child: _HeaderStat(icon: Iconsax.hashtag_copy, label: "School Code", value: school.code, isSmall: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _HeaderStat(icon: Iconsax.book_copy, label: "Board", value: _boardName, isSmall: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _HeaderStat(icon: Iconsax.translate_copy, label: "Medium", value: _mediumName, isSmall: true)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToAddEditSchool(context, school),
                      icon: const Icon(Iconsax.edit_copy, size: 16),
                      label: const Text("Edit"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeaderStat(icon: Iconsax.hashtag_copy, label: "School Code", value: school.code),
              _HeaderStat(icon: Iconsax.book_copy, label: "Board", value: _boardName),
              _HeaderStat(icon: Iconsax.translate_copy, label: "Medium", value: _mediumName),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddEditSchool(context, school),
                icon: const Icon(Iconsax.edit_copy, size: 18),
                label: const Text("Edit School"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<Widget> children, bool isSmallScreen) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 8, horizontal: isSmallScreen ? 2 : 4),
        child: Column(
          children: children.map((child) =>
              Padding(
                padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                child: child,
              )
          ).toList(),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoTab(School school, bool isSmallScreen) {
    return _buildTabContent([
      _DetailCard(
        title: 'Basic Information',
        icon: Iconsax.building_4,
        isSmall: isSmallScreen,
        children: [
          _InfoTile(label: "Short Name", value: school.shortName, isSmall: isSmallScreen),
          _InfoTile(label: "School Type", value: _schoolTypeName, isSmall: isSmallScreen),
          _InfoTile(label: "Affiliation No.", value: school.affiliationNo, isSmall: isSmallScreen),
          _InfoTile(label: "Established Date", value: school.establishmentDate, isSmall: isSmallScreen),
        ],
      ),
      _DetailCard(
        title: 'Organizational Details',
        icon: Iconsax.people,
        isSmall: isSmallScreen,
        children: [
          _InfoTile(label: "Parent Organization", value: school.parentOrganization, isSmall: isSmallScreen),
          _InfoTile(label: "Management Type", value: _managementName, isSmall: isSmallScreen),
          _InfoTile(label: "Branch Count", value: school.branchCount, isSmall: isSmallScreen),
        ],
      ),
    ], isSmallScreen);
  }

  Widget _buildAcademicsTab(School school, bool isSmallScreen) {
    return _buildTabContent([
      _DetailCard(
        title: 'Academic Details',
        icon: Iconsax.book_1,
        isSmall: isSmallScreen,
        children: [
          _InfoTile(label: "Classes Offered", value: school.classesOffered, isSmall: isSmallScreen),
          _InfoTile(label: "Sections per Class", value: school.sectionsPerClass, isSmall: isSmallScreen),
          _InfoTile(label: "Student Capacity", value: school.studentCapacity, isSmall: isSmallScreen),
          _InfoTile(label: "Current Enrollment", value: school.currentEnrollment, isSmall: isSmallScreen),
          _InfoTile(label: "Teacher Strength", value: school.teacherStrength, isSmall: isSmallScreen),
        ],
      ),
    ], isSmallScreen);
  }

  Widget _buildContactTab(School school, bool isSmallScreen) {
    return _buildTabContent([
      _DetailCard(
        title: 'Key Personnel',
        icon: Iconsax.user_square_copy,
        isSmall: isSmallScreen,
        children: [
          _InfoTile(label: "Principal", value: school.principalName, isSmall: isSmallScreen),
          _InfoTile(label: "Principal's Contact", value: school.principalContact, isSmall: isSmallScreen),
          _InfoTile(label: "Contact Person", value: school.contactPerson, isSmall: isSmallScreen),
          _InfoTile(label: "Chairman", value: school.chairmanName, isSmall: isSmallScreen),
        ],
      ),
      _DetailCard(
        title: 'Location & Online Presence',
        icon: Iconsax.location_copy,
        isSmall: isSmallScreen,
        children: [
          _InfoTile(label: "Email", value: school.email, isSmall: isSmallScreen),
          _InfoTile(label: "Mobile", value: school.mobile, isSmall: isSmallScreen),
          _InfoTile(label: "Phone", value: school.phone, isSmall: isSmallScreen),
          _InfoTile(label: "Website", value: school.website, isSmall: isSmallScreen),
          _InfoTile(label: "Address", value: "${school.address1 ?? ''}, ${school.address2 ?? ''}", isSmall: isSmallScreen),
          _InfoTile(label: "Pincode", value: school.pincode, isSmall: isSmallScreen),
          _InfoTile(label: "Country", value: school.country, isSmall: isSmallScreen),
          _InfoTile(label: "State", value: _stateName, isSmall: isSmallScreen),
          _InfoTile(label: "District", value: _districtName, isSmall: isSmallScreen),
          _InfoTile(label: "City", value: _cityName, isSmall: isSmallScreen),
        ],
      ),
    ], isSmallScreen);
  }

  Widget _buildFacilitiesAndFinancialsTab(School school, bool isSmallScreen) {
    return _buildTabContent([
      _DetailCard(
        title: 'Financials',
        icon: Iconsax.wallet_money,
        isSmall: isSmallScreen,
        children: [
          _InfoTile(label: "PAN", value: school.pan, isSmall: isSmallScreen),
          _InfoTile(label: "GST", value: school.gst, isSmall: isSmallScreen),
          _InfoTile(label: "Bank Details", value: school.bankAccountDetails, isSmall: isSmallScreen),
          _InfoTile(label: "Scholarships / Grants", value: school.scholarshipsGrants, isSmall: isSmallScreen),
        ],
      ),
      _DetailCard(
        title: 'On-Campus Facilities',
        icon: Iconsax.safe_home,
        isSmall: isSmallScreen,
        children: [
          GridView.count(
            crossAxisCount: isSmallScreen ? 2 : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isSmallScreen ? 4 : 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _FacilityRow(label: "Hostel", isAvailable: school.isHostel, isSmall: isSmallScreen),
              _FacilityRow(label: "Transport", isAvailable: school.isTransport, isSmall: isSmallScreen),
              _FacilityRow(label: "Library", isAvailable: school.isLibrary, isSmall: isSmallScreen),
              _FacilityRow(label: "Computer Lab", isAvailable: school.isComputerLab, isSmall: isSmallScreen),
              _FacilityRow(label: "Playground", isAvailable: school.isPlayground, isSmall: isSmallScreen),
              _FacilityRow(label: "Auditorium", isAvailable: school.isAuditorium, isSmall: isSmallScreen),
            ],
          )
        ],
      ),
    ], isSmallScreen);
  }

  Widget _buildSubscriptionTab(BuildContext context, School school, bool isSmallScreen) {
    return _buildTabContent([
      _DetailCard(
        title: 'Subscription & Plan',
        icon: Iconsax.crown,
        isSmall: isSmallScreen,
        children: [
          _InfoTile(label: "Current Plan", value: school.subscription, isSmall: isSmallScreen),
          _InfoTile(label: "Start Date", value: school.startDate != null ? DateFormat.yMMMMd().format(school.startDate!) : 'N/A', isSmall: isSmallScreen),
          _InfoTile(label: "End Date", value: school.endDate != null ? DateFormat.yMMMMd().format(school.endDate!) : 'N/A', isSmall: isSmallScreen),
          _InfoTile(label: "Payment Ref ID", value: school.paymentRefId, isSmall: isSmallScreen),
          _InfoTile(label: "Auto Renewal", value: school.isAutoRenewal == true ? 'Enabled' : 'Disabled', isSmall: isSmallScreen),
          _InfoTile(
            label: "Fee Structure",
            value: _feeStructureName ?? (school.feeStructureRef != null ? '...' : 'N/A'),
            isSmall: isSmallScreen,
            trailing: school.feeStructureRef != null
                ? TextButton.icon(
              onPressed: () => _showFeeDetails(context, school.feeStructureRef!),
              icon: const Icon(Iconsax.eye, size: 16),
              label: Text(isSmallScreen ? "View" : "View Details"),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 8 : 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
                : null,
          ),
        ],
      ),
    ], isSmallScreen);
  }
}

// --- HELPER WIDGETS ---

// NEW: Helper widget for mobile fee detail list view
class _FeeDetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _FeeDetailRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.bodyText),
          ),
          Text(
            value ?? 'N/A',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool isSmall;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.children,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryGreen, size: isSmall ? 18 : 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                  fontSize: isSmall ? 14 : 16,
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
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final bool isSmall;

  const _InfoTile({
    required this.label,
    this.value,
    this.trailing,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (value != null && value!.isNotEmpty) ? value : 'N/A';

    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12, horizontal: isSmall ? 8 : 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isSmall
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.bodyText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayValue!,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                    fontSize: 13,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.bodyText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              displayValue!,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
                fontSize: 14,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _FacilityRow extends StatelessWidget {
  final String label;
  final bool? isAvailable;
  final bool isSmall;

  const _FacilityRow({
    required this.label,
    this.isAvailable,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final available = isAvailable ?? false;
    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 6 : 8, horizontal: isSmall ? 8 : 12),
      decoration: BoxDecoration(
        color: available
            ? AppTheme.accentGreen.withOpacity(0.1)
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: available
              ? AppTheme.accentGreen.withOpacity(0.3)
              : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            available ? Iconsax.tick_circle_copy : Iconsax.close_circle_copy,
            size: isSmall ? 14 : 16,
            color: available ? AppTheme.accentGreen : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.darkText,
                fontSize: isSmall ? 12 : 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isSmall;

  const _HeaderStat({
    required this.icon,
    required this.label,
    this.value,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isSmall ? 10 : 12,
              color: AppTheme.bodyText,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isSmall ? 4 : 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: isSmall ? 14 : 16, color: AppTheme.primaryGreen),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value ?? 'N/A',
                  style: GoogleFonts.inter(
                    fontSize: isSmall ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// *** FIX APPLIED HERE ***
// The _StatusBadge widget is now properly defined to be responsive.
class _StatusBadge extends StatelessWidget {
  final SchoolStatusModel status;
  final bool isSmall; // Added this parameter

  // Updated the constructor to accept isSmall, with a default value
  const _StatusBadge({super.key, required this.status, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status.name.toLowerCase()) {
      case 'active':
        color = AppTheme.accentGreen;
        icon = Iconsax.verify;
        break;
      case 'expired':
        color = Colors.red.shade600;
        icon = Iconsax.close_circle;
        break;
      case 'trial':
        color = Colors.orange.shade700;
        icon = Iconsax.clock;
        break;
      case 'suspended':
        color = AppTheme.bodyText;
        icon = Iconsax.minus_cirlce;
        break;
      default: // Handles 'N/A', 'Unknown', etc.
        color = AppTheme.bodyText;
        icon = Iconsax.minus_cirlce;
        break;
    }

    return Container(
      // Made padding responsive
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 4 : 5,
      ),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Made Icon size responsive
          Icon(icon, color: color, size: isSmall ? 12 : 14),
          const SizedBox(width: 6),
          Text(status.name,
              style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.w600,
                  // Made font size responsive
                  fontSize: isSmall ? 11 : 12)),
        ],
      ),
    );
  }
}