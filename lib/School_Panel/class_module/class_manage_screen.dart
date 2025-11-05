// class_manage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'add_edit_class_dialog.dart';
import 'class_allotment_dialog.dart';
import 'class_bloc.dart';
import 'class_model.dart';

import 'class_service.dart';
import '../utils/academic_year.dart';

class ClassManageScreen extends StatelessWidget {
  final int schoolRecNo;

  const ClassManageScreen({super.key, required this.schoolRecNo});

  @override
  Widget build(BuildContext context) {
    final String defaultAcademicYear = computeCurrentAcademicYear();
    return RepositoryProvider(
      create: (context) => ClassApiService(),
      child: BlocProvider(
        create: (context) => ClassBloc(
          apiService: RepositoryProvider.of<ClassApiService>(context),
        )..add(LoadAllClassesEvent(
          schoolID: schoolRecNo,
          academicYear: defaultAcademicYear,
        )),
        child: MainLayout(
          activeScreen: AppScreen.classModule,
          child: ClassManageScreenContent(
            schoolRecNo: schoolRecNo,
            initialAcademicYear: defaultAcademicYear,
          ),
        ),
      ),
    );
  }
}

class ClassManageScreenContent extends StatefulWidget {
  final int schoolRecNo;
  final String initialAcademicYear;

  const ClassManageScreenContent({
    super.key,
    required this.schoolRecNo,
    required this.initialAcademicYear,
  });

  @override
  State<ClassManageScreenContent> createState() => _ClassManageScreenContentState();
}

class _ClassManageScreenContentState extends State<ClassManageScreenContent> {
  String selectedAcademicYear = '';
  final TextEditingController _searchController = TextEditingController();
  List<ClassModel> _cachedClasses = [];
  List<ClassModel> _filteredClasses = [];
  int currentPage = 0;
  int rowsPerPage = 8;
  final Set<int> selectedClasses = {};

  @override
  void initState() {
    super.initState();
    selectedAcademicYear = widget.initialAcademicYear;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Generate academic years
  List<String> get academicYears {
    final currentYear = DateTime.now().year;
    final List<String> years = [];
    for (int i = -5; i <= 5; i++) {
      final year = currentYear + i;
      years.add('$year-${(year + 1).toString().substring(2)}');
    }
    return years;
  }

  void _onSearchChanged() {
    setState(() {
      _filterClasses(_searchController.text);
      currentPage = 0;
    });
  }

  void _filterClasses(String query) {
    final lowerCaseQuery = query.toLowerCase().trim();
    if (lowerCaseQuery.isEmpty) {
      _filteredClasses = _cachedClasses;
      return;
    }

    _filteredClasses = _cachedClasses.where((cls) {
      return cls.className.toLowerCase().contains(lowerCaseQuery) ||
          cls.sectionName.toLowerCase().contains(lowerCaseQuery) ||
          cls.classCode.toLowerCase().contains(lowerCaseQuery) ||
          (cls.classTeacherName?.toLowerCase().contains(lowerCaseQuery) ?? false);
    }).toList();
  }

  void _handleReload(String? newAcademicYear) {
    if (newAcademicYear != null) {
      selectedAcademicYear = newAcademicYear;
    }
    context.read<ClassBloc>().add(LoadAllClassesEvent(
      schoolID: widget.schoolRecNo,
      academicYear: selectedAcademicYear,
    ));
  }

  void _navigateToAddEditClass(ClassModel? classModel) async {
    final result = await showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ClassBloc>(),
        child: AddEditClassDialog(
          schoolID: widget.schoolRecNo,

          classModel: classModel,
        ),
      ),
    );
    // FIX: Reload with current selectedAcademicYear after Add/Edit dialog closes
    if (result == true) {
      _handleReload(null);
    }
  }

  void _navigateToAllotmentScreen(ClassModel classModel) async {
    final result = await showDialog( // CHANGED from Navigator.of(context).push to showDialog
      context: context,
      builder: (context) => BlocProvider.value( // Pass existing BLoC via value
        value: context.read<ClassBloc>(),
        child: ClassAllotmentDialog(
          classModel: classModel,
          schoolID: widget.schoolRecNo,
        ),
      ),
    );
    if (result == true) {
      _handleReload(null);
    }
  }

  List<ClassModel> getPaginatedClasses() {
    if (_filteredClasses.isEmpty) return [];
    final startIndex = currentPage * rowsPerPage;
    if (startIndex >= _filteredClasses.length) {
      currentPage = 0;
      return _filteredClasses.sublist(
          0, _filteredClasses.length < rowsPerPage ? _filteredClasses.length : rowsPerPage);
    }

    final endIndex = (startIndex + rowsPerPage) > _filteredClasses.length
        ? _filteredClasses.length
        : startIndex + rowsPerPage;
    return _filteredClasses.sublist(startIndex, endIndex);
  }

  void goToPage(int page) {
    setState(() {
      currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String operationBy = Provider.of<UserProvider>(context, listen: false).userName ?? 'Admin';

    return BlocConsumer<ClassBloc, ClassState>(
      listener: (context, state) {
        if (state is ClassOperationSuccessState) {
          CustomSnackbar.showSuccess(context, state.message);
        } else if (state is ClassErrorState) {
          CustomSnackbar.showError(context, state.error);
          if (context.read<ClassBloc>().state is ClassLoadingState) {
            _handleReload(null);
          }
        } else if (state is ClassesLoadedState) {
          _cachedClasses = state.classes;
          _filterClasses(_searchController.text);
          final totalPages = (_filteredClasses.length / rowsPerPage).ceil();
          if (currentPage >= totalPages && totalPages > 0) {
            currentPage = totalPages - 1;
          } else if (totalPages == 0) {
            currentPage = 0;
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is ClassLoadingState;
        final paginatedClasses = getPaginatedClasses();
        final totalPages = (_filteredClasses.length / rowsPerPage).ceil();
        final canAdd = Provider.of<UserProvider>(context).hasPermission('M012', 'add');
        final canEdit = Provider.of<UserProvider>(context).hasPermission('M012', 'edit');
        final canDelete = Provider.of<UserProvider>(context).hasPermission('M012', 'delete');

        // --- ADDED THIS WRAPPER ---
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // --- ADDED THIS LINE ---
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPageHeader(context, canAdd),
              const SizedBox(height: AppTheme.defaultPadding * 1.5),
              StyledContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  // --- ADDED THIS LINE (Good practice for nested columns) ---
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSearchFilterHeader(context), // Passed context for responsive checks
                    const SizedBox(height: AppTheme.defaultPadding),
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                        ),
                      )
                    else if (_filteredClasses.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            _searchController.text.isNotEmpty
                                ? 'No classes match your search.'
                                : 'No classes found for academic year $selectedAcademicYear. Try adding one!',
                            style: GoogleFonts.inter(color: AppTheme.bodyText),
                          ),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 700;
                          return _buildClassTable(
                            context,
                            paginatedClasses,
                            isMobile,
                            canEdit,
                            canDelete,
                            operationBy,
                          );
                        },
                      ),
                    const SizedBox(height: AppTheme.defaultPadding),
                    if (_filteredClasses.isNotEmpty && totalPages > 1)
                      _buildPaginationControls(totalPages),
                  ],
                ),
              ),
            ],
          ),
        );
        // --- END OF CHANGES ---
      },
    );
  }

  Widget _buildPageHeader(BuildContext context, bool canAdd) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class Management',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage school classes, sections, and teacher/subject allotments.',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  color: AppTheme.bodyText,
                ),
              ),
            ],
          ),
        ),
        if (canAdd)
          Padding(
            padding: EdgeInsets.only(left: isMobile ? 8.0 : 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _navigateToAddEditClass(null),
              icon: const Icon(Iconsax.add_square, size: 20),
              label: isMobile
                  ? const SizedBox.shrink()
                  : Text(
                'Add New Class',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: isMobile
                    ? const CircleBorder()
                    : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 16 : 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchFilterHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget searchField = Container(
      height: isMobile ? 44 : 48,
      decoration: BoxDecoration(
        color: Colors.white, // Changed from AppTheme.lightGrey to pure white
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14),
        decoration: InputDecoration(
          hintText: 'Search by class name, section, or teacher...',
          hintStyle: GoogleFonts.inter(
            color: AppTheme.bodyText.withOpacity(0.6),
            fontSize: isMobile ? 12 : 14,
          ),
          prefixIcon: Icon(Iconsax.search_normal_1, size: isMobile ? 18 : 20, color: AppTheme.bodyText),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Iconsax.close_circle, size: 20),
            onPressed: _searchController.clear,
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isMobile ? 10 : 14),
        ),
      ),
    );

    Widget yearDropdown = Container(
      height: isMobile ? 44 : 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedAcademicYear,
          isDense: true,
          icon: const Icon(Iconsax.arrow_down_1, size: 20),
          hint: Text('Academic Year', style: GoogleFonts.inter()),
          items: academicYears.map((year) {
            return DropdownMenuItem<String>(
              value: year,
              child: Text(year, style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != selectedAcademicYear) {
              setState(() {
                selectedAcademicYear = newValue;
                currentPage = 0;
              });
              _handleReload(newValue);
            }
          },
          dropdownColor: Colors.white,
          style: GoogleFonts.inter(color: AppTheme.darkText, fontSize: 14),
        ),
      ),
    );

    return isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIX: Wrap search field in SizedBox to constrain width to max width
        SizedBox(width: double.infinity, child: searchField),
        const SizedBox(height: 12),
        // FIX: Wrap dropdown field in SizedBox to constrain width to max width
        SizedBox(width: double.infinity, child: yearDropdown),
      ],
    )
        : Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 12),
        yearDropdown,
      ],
    );
  }

  Widget _buildClassTable(
      BuildContext context,
      List<ClassModel> classes,
      bool isMobile,
      bool canEdit,
      bool canDelete,
      String operationBy,
      ) {
    if (isMobile) {
      return Column(
        children: classes.map((cls) => _buildMobileCard(context, cls, canEdit, canDelete, operationBy)).toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox( // Ensure minimum width for non-mobile table
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.75),
        child: DataTable(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          headingRowColor: WidgetStateProperty.all(Colors.white), // Use white for heading background
          dataRowHeight: 68,
          headingRowHeight: 50,
          columnSpacing: 24,
          columns: [
            DataColumn(label: _buildColumnHeader('Class Name')),
            DataColumn(label: _buildColumnHeader('Class Code')),
            DataColumn(label: _buildColumnHeader('Section')),
            DataColumn(label: _buildColumnHeader('Teacher')),
            DataColumn(label: _buildColumnHeader('Capacity')),
            DataColumn(label: _buildColumnHeader('Status')),
            DataColumn(label: _buildColumnHeader('Actions')),
          ],
          rows: classes
              .map(
                (cls) => DataRow(
              color: WidgetStateProperty.resolveWith(
                    (Set<WidgetState> states) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppTheme.primaryGreen.withOpacity(0.05);
                  }
                  return null;
                },
              ),
              cells: [
                DataCell(_buildClassCell(cls)),
                DataCell(Text(cls.classCode, style: GoogleFonts.inter())),
                DataCell(Text(cls.sectionName, style: GoogleFonts.inter())),
                DataCell(Text(cls.classTeacherName ?? '-', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                // FIX: Add missing DataCell for 'Capacity'
                DataCell(Text(cls.maxStudentCapacity?.toString() ?? '-', style: GoogleFonts.inter())),
                DataCell(_buildStatusBadge(cls.isActive)),
                DataCell(_buildActionsMenu(context, cls, canEdit, canDelete, operationBy)),
              ],
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildColumnHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppTheme.darkText,
      ),
    );
  }

  Widget _buildClassCell(ClassModel cls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          cls.className,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.darkText,
          ),
        ),
        Text(
          cls.roomNumber != null && cls.roomNumber!.isNotEmpty ? 'Room: ${cls.roomNumber}' : 'No Room Assigned',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.bodyText,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accentGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.inter(
          color: isActive ? AppTheme.accentGreen : Colors.grey[700],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionsMenu(
      BuildContext context,
      ClassModel cls,
      bool canEdit,
      bool canDelete,
      String operationBy,
      ) {
    return PopupMenuButton<String>(
      icon: const Icon(Iconsax.more, size: 20, color: AppTheme.bodyText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _navigateToAddEditClass(cls);
            break;
          case 'allotment':
            _navigateToAllotmentScreen(cls);
            break;
          case 'delete':
            _showDeleteConfirmationDialog(context, cls);
            break;
        }
      },
      itemBuilder: (context) => [
        if (canEdit)
          PopupMenuItem<String>(
            value: 'allotment',
            child: Row(
              children: [
                const Icon(Iconsax.teacher, size: 16, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text('Manage Allotments', style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        if (canEdit)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Iconsax.edit_2, size: 16, color: AppTheme.darkText),
                const SizedBox(width: 8),
                Text('Edit Details', style: GoogleFonts.inter()),
              ],
            ),
          ),
        if (canDelete)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Iconsax.trash, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text('Delete Class', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMobileCard(
      BuildContext context,
      ClassModel cls,
      bool canEdit,
      bool canDelete,
      String operationBy,
      ) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderGrey, width: 1),
      ),
      child: InkWell(
        onTap: () => canEdit ? _navigateToAllotmentScreen(cls) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cls.className} - ${cls.sectionName}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.darkText,
                          ),
                        ),
                        Text(
                          'Code: ${cls.classCode}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(cls.isActive),
                ],
              ),
              const Divider(height: 20),
              _buildInfoRow(Iconsax.teacher, 'Teacher', cls.classTeacherName ?? '-'),
              _buildInfoRow(Iconsax.house, 'Room', cls.roomNumber ?? '-'),
              _buildInfoRow(Iconsax.people, 'Max Students', cls.maxStudentCapacity?.toString() ?? '-'),
              const SizedBox(height: 8),
              if (canEdit || canDelete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canEdit)
                      TextButton.icon(
                        onPressed: () => _navigateToAllotmentScreen(cls),
                        icon: const Icon(Iconsax.teacher, size: 18),
                        label: Text('Allotments', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                      ),
                    if (canDelete)
                      IconButton(
                        onPressed: () => _showDeleteConfirmationDialog(context, cls),
                        icon: const Icon(Iconsax.trash, color: Colors.red),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              color: AppTheme.bodyText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.darkText,
              ),
              overflow: TextOverflow.visible, // Allow text wrapping
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Row(
      mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.end,
      children: [
        if (!isMobile) ...[
          Text('Rows:', style: GoogleFonts.inter()),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.borderGrey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: rowsPerPage,
                isDense: true,
                icon: const Icon(Iconsax.arrow_down_1, size: 20),
                items: [5, 8, 10, 15]
                    .map((e) => DropdownMenuItem<int>(
                  value: e,
                  child: Text(e.toString(), style: GoogleFonts.inter()),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      rowsPerPage = value;
                      currentPage = 0;
                    });
                  }
                },
                dropdownColor: Colors.white,
                style: GoogleFonts.inter(color: AppTheme.darkText, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Text(
          'Page ${currentPage + 1} of $totalPages',
          style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Iconsax.arrow_left_2, size: 20),
          onPressed: currentPage > 0 ? () => goToPage(currentPage - 1) : null,
        ),
        IconButton(
          icon: const Icon(Iconsax.arrow_right_3, size: 20),
          onPressed: currentPage < totalPages - 1 ? () => goToPage(currentPage + 1) : null,
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, ClassModel classModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<ClassBloc>(context),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.warning_2, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confirm Deletion',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you absolutely sure you want to delete the class "${classModel.fullName}"? This action is irreversible and will affect all linked subjects and students.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.bodyText)),
              ),
              ElevatedButton(
                onPressed: () {
                  final operationBy = Provider.of<UserProvider>(context, listen: false).userName ?? 'Admin';
                  context.read<ClassBloc>().add(DeleteClassEvent(
                    classRecNo: classModel.classRecNo!,
                    schoolID: widget.schoolRecNo,
                    operationBy: operationBy, // ADDED - This was missing!
                  ));



                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Delete Class', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StyledContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const StyledContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppTheme.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}