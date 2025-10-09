import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/School/add_school_screen.dart';
import 'package:lms_publisher/screens/School/school_detail_screen.dart';
import 'package:lms_publisher/screens/School/school_managebloc.dart';
import 'package:lms_publisher/screens/School/school_model.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:lms_publisher/service/school_service.dart';


class SchoolsScreen extends StatelessWidget {
  const SchoolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SchoolManageBloc(
        schoolApiService: RepositoryProvider.of<SchoolApiService>(context),
      )..add(FetchSchools()),
      child: const MainLayout(
        activeScreen: AppScreen.schools,
        child: SchoolsScreenContent(),
      ),
    );
  }
}

class SchoolsScreenContent extends StatefulWidget {
  const SchoolsScreenContent({super.key});

  @override
  State<SchoolsScreenContent> createState() => _SchoolsScreenContentState();
}

class _SchoolsScreenContentState extends State<SchoolsScreenContent> {
  int _currentPage = 0;
  int _rowsPerPage = 8;

  void _navigateToAddEditSchool({School? school}) {
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddSchoolScreen(), // Pass school for editing
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    )
        .then((result) {
      if (result == true) {
        context.read<SchoolManageBloc>().add(FetchSchools());
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(school == null
                  ? 'New school added successfully!'
                  : 'School updated successfully!'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SchoolManageBloc, SchoolManageState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: ${state.error}'),
                backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final paginatedSchools = _getPaginatedSchools(state.filteredSchools);
        final totalPages = (state.filteredSchools.length / _rowsPerPage).ceil();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isMobile = constraints.maxWidth < 600;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manage Schools',
                              style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.darkText)),
                          const SizedBox(height: 4),
                          Text('Add, view, edit, and manage all schools.',
                              style: GoogleFonts.inter(
                                  color: AppTheme.bodyText)),
                        ],
                      ),
                    if (isMobile)
                      Text('Manage School',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkText)),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddEditSchool(),
                      icon: const Icon(Iconsax.add, size: 20),
                      label: isMobile
                          ? const SizedBox.shrink()
                          : Text('Add New School',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: isMobile
                            ? const CircleBorder()
                            : RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 24, vertical: 20),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTheme.defaultPadding * 1.5),
            _StyledContainer(
              child: Column(
                children: [
                  const _SchoolsHeader(),
                  const SizedBox(height: AppTheme.defaultPadding),
                  if (state.isLoading)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator()))
                  else if (state.filteredSchools.isEmpty)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text("No schools found.")))
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 700;
                        return _ModernSchoolsTable(
                            schools: paginatedSchools, isMobile: isMobile);
                      },
                    ),
                  const SizedBox(height: AppTheme.defaultPadding),
                  if (totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text("Rows:"),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _rowsPerPage,
                          items: [5, 8, 10, 15]
                              .map((e) => DropdownMenuItem(
                              value: e, child: Text(e.toString())))
                              .toList(),
                          onChanged: (value) {
                            if (value != null)
                              setState(() {
                                _rowsPerPage = value;
                                _currentPage = 0;
                              });
                          },
                        ),
                        const SizedBox(width: 16),
                        Text('${_currentPage + 1} of $totalPages'),
                        const SizedBox(width: 16),
                        IconButton(
                            icon: const Icon(Iconsax.arrow_left_2),
                            onPressed: _currentPage == 0
                                ? null
                                : () => _goToPage(_currentPage - 1)),
                        IconButton(
                            icon: const Icon(Iconsax.arrow_right_3),
                            onPressed: _currentPage >= totalPages - 1
                                ? null
                                : () => _goToPage(_currentPage + 1)),
                      ],
                    )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<School> _getPaginatedSchools(List<School> schools) {
    if (schools.isEmpty) return [];
    final startIndex = _currentPage * _rowsPerPage;
    if (startIndex >= schools.length) {
      _currentPage = 0;
      // Re-call to handle index out of bounds after rowsPerPage change
      return schools.sublist(0, (schools.length < _rowsPerPage) ? schools.length : _rowsPerPage);
    }
    final endIndex = (startIndex + _rowsPerPage > schools.length)
        ? schools.length
        : startIndex + _rowsPerPage;
    return schools.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }
}

class _SchoolsHeader extends StatefulWidget {
  const _SchoolsHeader();

  @override
  State<_SchoolsHeader> createState() => _SchoolsHeaderState();
}

class _SchoolsHeaderState extends State<_SchoolsHeader> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<SchoolManageBloc>().add(SearchAndFilterSchools(
        searchTerm: _searchController.text,
        filter: context.read<SchoolManageBloc>().state.currentFilter,
      ));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or code...',
              prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
              filled: true,
              fillColor: AppTheme.lightGrey,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.defaultPadding),
        BlocBuilder<SchoolManageBloc, SchoolManageState>(
          builder: (context, state) {
            // NEW: Create a list of dropdown items from the available statuses
            // We add `null` at the beginning to represent the "All" option.
            final List<SchoolStatusModel?> filterOptions = [
              null,
              ...state.availableStatuses
            ];

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                borderRadius: AppTheme.defaultBorderRadius,
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: DropdownButtonHideUnderline(
                // MODIFIED: Dropdown is now typed with SchoolStatusModel?
                child: DropdownButton<SchoolStatusModel?>(
                  value: state.currentFilter,
                  onChanged: (SchoolStatusModel? newValue) {
                    context.read<SchoolManageBloc>().add(
                      SearchAndFilterSchools(
                        searchTerm: state.searchTerm,
                        filter: newValue, // Pass the selected model (or null)
                      ),
                    );
                  },
                  // MODIFIED: Map the dynamic list of statuses to DropdownMenuItems
                  items: filterOptions.map((filter) {
                    return DropdownMenuItem<SchoolStatusModel?>(
                      value: filter,
                      child: Text(filter?.name ?? 'All Statuses',
                          style: GoogleFonts.inter()),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ModernSchoolsTable extends StatelessWidget {
  final List<School> schools;
  final bool isMobile;
  const _ModernSchoolsTable({required this.schools, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _buildMobileListView();
    } else {
      return _buildDesktopTable();
    }
  }

  Widget _buildDesktopTable() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        ListView.separated(
          itemCount: schools.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _SchoolTableRow(school: schools[index]);
          },
        ),
      ],
    );
  }

  Widget _buildMobileListView() {
    return ListView.separated(
      itemCount: schools.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _SchoolMobileCard(school: schools[index]);
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _headerText('School Name')),
          Expanded(flex: 3, child: _headerText('Subscription')),
          Expanded(flex: 3, child: _headerText('Validity')),
          Expanded(flex: 2, child: _headerText('Status')),
          SizedBox(width: 80, child: Center(child: _headerText('Actions'))),
        ],
      ),
    );
  }

  Text _headerText(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.bodyText,
            fontSize: 14));
  }
}

class _SchoolTableRow extends StatefulWidget {
  final School school;
  const _SchoolTableRow({required this.school});

  @override
  State<_SchoolTableRow> createState() => _SchoolTableRowState();
}

class _SchoolTableRowState extends State<_SchoolTableRow> {
  bool _isHovered = false;

  void _navigateToDetailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<SchoolManageBloc>(context),
          child: SchoolDetailDialog(schoolId: widget.school.id),
        );
      },
    );
  }

  void _navigateToAddEditSchool() {
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddSchoolScreen(), // Pass school
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    )
        .then((result) {
      if (result == true) {
        context.read<SchoolManageBloc>().add(FetchSchools());
      }
    });
  }

  void _showRenewDialog() {
    showDialog(
        context: context,
        builder: (_) => BlocProvider.value(
          value: BlocProvider.of<SchoolManageBloc>(context),
          child: _RenewSubscriptionDialog(school: widget.school),
        ));
  }

  void _showDeleteConfirmationDialog(BuildContext context, School school) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must interact with the dialog
      builder: (BuildContext dialogContext) {
        // Use BlocProvider.value to pass the BLoC to the dialog
        return BlocProvider.value(
          value: BlocProvider.of<SchoolManageBloc>(context),
          child: _ImprovedDeleteConfirmationDialog(school: school),
        );
      },
    );
  }

  // NEW: Method to show the status change dialog
  void _showChangeStatusDialog(BuildContext context, School school) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<SchoolManageBloc>(context),
        child: _ChangeStatusDialog(school: school),
      ),
    );
  }


  // MODIFIED: Accepts SchoolStatusModel and switches on its name
  Color _getHoverColor(SchoolStatusModel status) {
    switch (status.name.toLowerCase()) {
      case 'active':
        return AppTheme.accentGreen.withOpacity(0.08);
      case 'expired':
        return Colors.red.withOpacity(0.05);
      case 'trial':
        return Colors.orange.withOpacity(0.08);
      case 'suspended':
      default: // Catches 'N/A', 'Unknown', etc.
        return AppTheme.bodyText.withOpacity(0.08);
    }
  }

  // MODIFIED: Accepts SchoolStatusModel and switches on its name
  Color _getHoverBorderColor(SchoolStatusModel status) {
    switch (status.name.toLowerCase()) {
      case 'active':
        return AppTheme.accentGreen;
      case 'expired':
        return Colors.red.shade600;
      case 'trial':
        return Colors.orange.shade700;
      case 'suspended':
      default: // Catches 'N/A', 'Unknown', etc.
        return AppTheme.bodyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final validity = widget.school.validity ?? 'N/A to N/A';
    final validityParts = validity.contains(' to ') ? validity.split(' to ') : [validity];
    final startDateStr = validityParts.isNotEmpty ? validityParts[0] : 'N/A';
    final endDateStr = validityParts.length > 1 ? validityParts[1] : 'N/A';

    String formattedStartDate = startDateStr;
    String formattedEndDate = endDateStr;
    if(widget.school.startDate != null) {
      formattedStartDate = DateFormat.yMMMd().format(widget.school.startDate!);
    }
    if(widget.school.endDate != null) {
      formattedEndDate = DateFormat.yMMMd().format(widget.school.endDate!);
    }


    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _navigateToDetailDialog,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: _isHovered
                ? _getHoverColor(widget.school.status)
                : Colors.transparent,
            borderRadius: AppTheme.defaultBorderRadius,
            border: Border.all(
                color: _isHovered
                    ? _getHoverBorderColor(widget.school.status).withOpacity(0.8)
                    : AppTheme.borderGrey.withOpacity(0.5),
                width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(widget.school.name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 3,
                child: Text(widget.school.subscription ?? 'N/A',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500, color: AppTheme.darkText)),
              ),
              Expanded(
                flex: 3,
                child: (widget.school.validity?.toLowerCase() == 'n/a' || widget.school.validity == null)
                    ? Text("N/A", style: GoogleFonts.inter(color: AppTheme.darkText, fontSize: 13, height: 1.5))
                    : RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                        color: AppTheme.darkText, fontSize: 13, height: 1.5),
                    children: [
                      TextSpan(
                        text: '$formattedStartDate\n',
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: 'to $formattedEndDate',
                        style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                  flex: 2,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: _StatusBadge(status: widget.school.status))),
              SizedBox(
                width: 80,
                child: Center(
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _navigateToAddEditSchool();
                      if (value == 'renew') _showRenewDialog();
                      if (value == 'status') _showChangeStatusDialog(context, widget.school);
                      if (value == 'delete')  _showDeleteConfirmationDialog(context, widget.school);;
                    },
                    icon: const Icon(Iconsax.more, color: AppTheme.bodyText),
                    tooltip: "Actions",
                    itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                      _buildPopupMenuItem('Edit', Iconsax.edit_2, 'edit'),
                      _buildPopupMenuItem('Change Status', Iconsax.repeat, 'status'), // NEW action
                      _buildPopupMenuItem('Renew Plan', Iconsax.refresh, 'renew',
                          color: AppTheme.primaryGreen),
                      const PopupMenuDivider(),
                      _buildPopupMenuItem('Delete', Iconsax.trash, 'delete',
                          color: Colors.red.shade700),
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

  PopupMenuItem<String> _buildPopupMenuItem(String title, IconData icon,
      String value, {Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppTheme.bodyText),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.inter(color: color)),
        ],
      ),
    );
  }
}

class _SchoolMobileCard extends StatelessWidget {
  final School school;
  const _SchoolMobileCard({required this.school});

  void _navigateToDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<SchoolManageBloc>(context),
          child: SchoolDetailDialog(schoolId: school.id),
        );
      },
    );
  }

  void _navigateToAddEditSchool(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddSchoolScreen(), // Pass school
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((result) {
      if (result == true) {
        context.read<SchoolManageBloc>().add(FetchSchools());
      }
    });
  }

  void _showRenewDialog(BuildContext context) => showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<SchoolManageBloc>(context),
        child: _RenewSubscriptionDialog(school: school),
      ));


  void _showDeleteConfirmationDialog(BuildContext context, School school) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must interact with the dialog
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<SchoolManageBloc>(context),
          child: _ImprovedDeleteConfirmationDialog(school: school),
        );
      },
    );
  }

  // NEW: Method to show the status change dialog
  void _showChangeStatusDialog(BuildContext context, School school) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<SchoolManageBloc>(context),
        child: _ChangeStatusDialog(school: school),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    String formattedStartDate = 'N/A';
    String formattedEndDate = 'N/A';
    if(school.startDate != null) {
      formattedStartDate = DateFormat.yMMMd().format(school.startDate!);
    }
    if(school.endDate != null) {
      formattedEndDate = DateFormat.yMMMd().format(school.endDate!);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.8)),
      ),
      child: InkWell(
        onTap: () => _navigateToDetailDialog(context),
        borderRadius: AppTheme.defaultBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(school.name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.darkText)),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(status: school.status),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Iconsax.crown, 'Plan', school.subscription ?? 'N/A'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.calendar_1,
                        size: 18, color: AppTheme.bodyText),
                    const SizedBox(width: 12),
                    SizedBox(
                        width: 80,
                        child: Text("Validity",
                            style: GoogleFonts.inter(color: AppTheme.bodyText))),
                    Expanded(
                      child: (school.validity?.toLowerCase() == 'n/a' || school.validity == null)
                          ? Text("N/A", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.darkText))
                          : RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                          children: [
                            TextSpan(
                                text: '$formattedStartDate\n',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade800)),
                            TextSpan(
                                text: 'to $formattedEndDate',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade800)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _navigateToAddEditSchool(context),
                    child: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'renew') _showRenewDialog(context);
                      if (value == 'status') _showChangeStatusDialog(context, school);
                      if (value == 'delete') _showDeleteConfirmationDialog(context, school);
                    },
                    itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                      _buildPopupMenuItem('Renew Plan', Iconsax.refresh, 'renew',
                          color: AppTheme.primaryGreen),
                      _buildPopupMenuItem('Change Status', Iconsax.repeat, 'status'),
                      const PopupMenuDivider(),
                      _buildPopupMenuItem('Delete', Iconsax.trash, 'delete',
                          color: Colors.red.shade700),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.borderGrey),
                      ),
                      child: const Icon(Iconsax.more, color: AppTheme.bodyText),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppTheme.bodyText),
          const SizedBox(width: 12),
          SizedBox(
              width: 80,
              child: Text(label,
                  style: GoogleFonts.inter(color: AppTheme.bodyText))),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppTheme.darkText))),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String title, IconData icon,
      String value, {Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppTheme.bodyText),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.inter(color: color)),
        ],
      ),
    );
  }
}

class _RenewSubscriptionDialog extends StatefulWidget {
  final School school;
  const _RenewSubscriptionDialog({required this.school});

  @override
  State<_RenewSubscriptionDialog> createState() => _RenewSubscriptionDialogState();
}

class _RenewSubscriptionDialogState extends State<_RenewSubscriptionDialog> {
  SubscriptionPlan? _selectedPlan;
  DurationOption? _selectedDuration;

  @override
  void initState() {
    super.initState();
    context.read<SchoolManageBloc>().add(FetchSubscriptionPlans());
  }

  DateTime get newExpiryDate {
    if (_selectedDuration == null) return DateTime.now();

    final now = DateTime.now();
    final currentEndDate = widget.school.endDate;
    final renewalBaseDate = (currentEndDate == null || currentEndDate.isBefore(now))
        ? now
        : currentEndDate;

    if (_selectedDuration!.weeks != null) {
      return renewalBaseDate.add(Duration(days: _selectedDuration!.weeks! * 7));
    } else if (_selectedDuration!.months != null) {
      return DateTime(
        renewalBaseDate.year,
        renewalBaseDate.month + _selectedDuration!.months!,
        renewalBaseDate.day,
      );
    }
    return renewalBaseDate;
  }

  double get totalCost {
    if (_selectedPlan == null || _selectedDuration == null) return 0.0;

    double baseCost = _selectedPlan!.price;

    // Calculate cost based on duration
    if (_selectedDuration!.weeks != null) {
      baseCost = baseCost * _selectedDuration!.weeks!;
    } else if (_selectedDuration!.months != null) {
      baseCost = baseCost * _selectedDuration!.months!;
    }

    // Apply discount
    final discountAmount = (baseCost * _selectedPlan!.discountPercent) / 100;
    final discountedPrice = baseCost - discountAmount;

    // Apply tax
    final taxAmount = (discountedPrice * _selectedPlan!.taxPercent) / 100;

    return discountedPrice + taxAmount;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      content: BlocBuilder<SchoolManageBloc, SchoolManageState>(
        builder: (context, state) {
          if (_selectedPlan == null && state.subscriptionPlans.isNotEmpty) {
            _selectedPlan = state.subscriptionPlans.firstWhere(
                  (p) => p.name == widget.school.subscription,
              orElse: () => state.subscriptionPlans.first,
            );
            if (_selectedPlan != null) {
              _selectedDuration = _selectedPlan!.availableDurations.first;
            }
          }

          return Container(
            width: 700,
            constraints: const BoxConstraints(maxHeight: 800),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  spreadRadius: 0,
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium Header with Gradient
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreen.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.refresh_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Renew Subscription',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.school.name,
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Area
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("1. Choose Your Plan"),
                        if (state.isDetailLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          _buildPlanSelection(state.subscriptionPlans),

                        const SizedBox(height: 32),
                        _buildSectionTitle("2. Select Duration"),
                        if (_selectedPlan != null) _buildDurationSelection(),

                        const SizedBox(height: 32),
                        _buildSectionTitle("3. Plan Details & Features"),
                        if (_selectedPlan != null) _buildPlanDetails(),

                        const SizedBox(height: 32),
                        _buildSectionTitle("4. Billing Summary"),
                        _buildBillingSummary(),

                        const SizedBox(height: 40),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanSelection(List<SubscriptionPlan> plans) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: plans.map((plan) => _buildPlanCard(plan)).toList(),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isSelected = _selectedPlan?.id == plan.id;
    final planType = plan.planType.toLowerCase();

    Color primaryColor;
    IconData icon;
    Color accentColor;

    if (planType.contains('trial')) {
      primaryColor = Colors.orange.shade600;
      accentColor = Colors.orange.shade50;
      icon = Iconsax.timer_1;
    } else if (planType.contains('basic')) {
      primaryColor = Colors.blue.shade600;
      accentColor = Colors.blue.shade50;
      icon = Iconsax.medal_star;
    } else if (planType.contains('premium')) {
      primaryColor = Colors.purple.shade600;
      accentColor = Colors.purple.shade50;
      icon = Iconsax.crown_1;
    } else {
      primaryColor = AppTheme.primaryGreen;
      accentColor = AppTheme.primaryGreen.withOpacity(0.1);
      icon = Iconsax.award;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
          _selectedDuration = plan.availableDurations.first;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (plan.discountPercent > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${plan.discountPercent.toStringAsFixed(0)}% OFF',
                            style: GoogleFonts.inter(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style: GoogleFonts.inter(
                      color: AppTheme.bodyText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${plan.currency} ${plan.price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '/${plan.billingCycle.toLowerCase()}',
                  style: GoogleFonts.inter(
                    color: AppTheme.bodyText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 14,
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available durations for ${_selectedPlan!.name}:',
            style: GoogleFonts.inter(
              color: AppTheme.bodyText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _selectedPlan!.availableDurations.map((duration) {
              final isSelected = _selectedDuration?.value == duration.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedDuration = duration),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    duration.label,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : AppTheme.darkText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildFeatureRow(
            Iconsax.profile_2user,
            'Users Allowed',
            '${_selectedPlan!.usersAllowed}',
          ),
          _buildFeatureRow(
            Iconsax.mobile,
            'Devices Allowed',
            '${_selectedPlan!.devicesAllowed}',
          ),
          _buildFeatureRow(
            Iconsax.play_circle,
            'Recorded Lectures',
            _selectedPlan!.isRecordedLectures ? 'Yes' : 'No',
            isEnabled: _selectedPlan!.isRecordedLectures,
          ),
          _buildFeatureRow(
            Iconsax.task_square,
            'Assignments & Tests',
            _selectedPlan!.isAssignmentsTests ? 'Yes' : 'No',
            isEnabled: _selectedPlan!.isAssignmentsTests,
          ),
          _buildFeatureRow(
            Iconsax.document_download,
            'Downloadable Resources',
            _selectedPlan!.isDownloadableResources ? 'Yes' : 'No',
            isEnabled: _selectedPlan!.isDownloadableResources,
          ),
          _buildFeatureRow(
            Iconsax.messages_2,
            'Discussion Forum',
            _selectedPlan!.isDiscussionForum ? 'Yes' : 'No',
            isEnabled: _selectedPlan!.isDiscussionForum,
          ),
          _buildFeatureRow(
            Iconsax.headphone,
            'Support Type',
            _selectedPlan!.supportType,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
      IconData icon,
      String label,
      String value, {
        bool isEnabled = true,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isEnabled ? AppTheme.primaryGreen : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.bodyText,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: isEnabled ? AppTheme.darkText : Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSummary() {
    if (_selectedPlan == null || _selectedDuration == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Please select a plan and duration'),
      );
    }

    final baseCost = _selectedPlan!.price *
        (_selectedDuration!.weeks ?? _selectedDuration!.months ?? 1);
    final discountAmount = (baseCost * _selectedPlan!.discountPercent) / 100;
    final discountedPrice = baseCost - discountAmount;
    final taxAmount = (discountedPrice * _selectedPlan!.taxPercent) / 100;
    final finalTotal = discountedPrice + taxAmount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withOpacity(0.05),
            AppTheme.primaryGreen.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildBillingRow(
            'Base Cost',
            '${_selectedPlan!.currency} ${baseCost.toStringAsFixed(2)}',
          ),
          if (_selectedPlan!.discountPercent > 0) ...[
            _buildBillingRow(
              'Discount (${_selectedPlan!.discountPercent.toStringAsFixed(0)}%)',
              '- ${_selectedPlan!.currency} ${discountAmount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          ],
          if (_selectedPlan!.taxPercent > 0) ...[
            _buildBillingRow(
              'Tax (${_selectedPlan!.taxPercent.toStringAsFixed(0)}%)',
              '+ ${_selectedPlan!.currency} ${taxAmount.toStringAsFixed(2)}',
            ),
          ],
          const Divider(height: 24),
          _buildBillingRow(
            'Total Amount',
            '${_selectedPlan!.currency} ${finalTotal.toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.calendar_tick,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'New Expiry Date: ',
                  style: GoogleFonts.inter(
                    color: AppTheme.bodyText,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(newExpiryDate),
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingRow(
      String label,
      String amount, {
        bool isDiscount = false,
        bool isTotal = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: isTotal ? AppTheme.darkText : AppTheme.bodyText,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: isDiscount
                  ? Colors.green.shade700
                  : isTotal
                  ? AppTheme.primaryGreen
                  : AppTheme.darkText,
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canProceed = _selectedPlan != null && _selectedDuration != null;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.bodyText,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: !canProceed
                ? null
                : () {
              context.read<SchoolManageBloc>().add(
                RenewSubscription(
                  schoolId: widget.school.id,
                  newSubscriptionId: _selectedPlan!.id,
                  newEndDate: DateFormat('yyyy-MM-dd').format(newExpiryDate),
                ),
              );
              Navigator.of(context).pop();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Subscription renewed successfully! New expiry: ${DateFormat('MMM dd, yyyy').format(newExpiryDate)}',
                  ),
                  backgroundColor: AppTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.tick_circle, size: 20),
                const SizedBox(width: 8),
                Text(
                  canProceed
                      ? 'Renew for ${_selectedPlan!.currency} ${totalCost.toStringAsFixed(2)}'
                      : 'Select Plan & Duration',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



class _ImprovedDeleteConfirmationDialog extends StatefulWidget {
  final School school;
  const _ImprovedDeleteConfirmationDialog({required this.school});

  @override
  State<_ImprovedDeleteConfirmationDialog> createState() =>
      _ImprovedDeleteConfirmationDialogState();
}

class _ImprovedDeleteConfirmationDialogState
    extends State<_ImprovedDeleteConfirmationDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      setState(() {
        _canDelete = _confirmController.text == 'DELETE';
      });
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.warning_2, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Confirm Deletion',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          color: AppTheme.bodyText,
                          height: 1.6,
                          fontSize: 15,
                        ),
                        children: <TextSpan>[
                          const TextSpan(
                              text:
                              'This is a permanent action and cannot be undone. This will permanently delete the school: '),
                          TextSpan(
                            text: widget.school.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.info_circle, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Please type "DELETE" to confirm.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmController,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'Type DELETE here',
                        filled: true,
                        fillColor: AppTheme.lightGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          BorderSide(color: Colors.red.shade700, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.borderGrey),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.bodyText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: !_canDelete
                          ? null
                          : () {
                        // Dispatch the delete event
                        context.read<SchoolManageBloc>().add(DeleteSchool(schoolId: widget.school.id));
                        Navigator.of(context).pop();

                        // Show a confirmation snackbar
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Successfully deleted ${widget.school.name}'),
                              backgroundColor: AppTheme.accentGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Iconsax.trash, size: 18),
                      label: Text(
                        'Delete',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// *** NEW AND IMPROVED DIALOG ***
class _ChangeStatusDialog extends StatefulWidget {
  final School school;
  const _ChangeStatusDialog({required this.school});

  @override
  State<_ChangeStatusDialog> createState() => _ChangeStatusDialogState();
}

class _ChangeStatusDialogState extends State<_ChangeStatusDialog> {
  SchoolStatusModel? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchoolManageBloc, SchoolManageState>(
      builder: (context, state) {
        // --- ROBUST INITIALIZATION TO PREVENT CRASH ---
        // Try to find the school's current status model within the list of available statuses.
        // This ensures the object instance is one that exists in the dropdown's item list.
        SchoolStatusModel? initialStatus;
        try {
          initialStatus = state.availableStatuses.firstWhere((s) => s.id == widget.school.status.id);
        } catch (e) {
          // This catch block runs if the school's status ID isn't found in the list.
          // Setting it to null is safe and will prevent the assertion error.
          initialStatus = null;
          print("Warning: Could not find the school's current status (${widget.school.status.id}) in the available status list.");
        }

        // Initialize the local state variable for the dropdown only once.
        _selectedStatus ??= initialStatus;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          content: Container(
            width: 500, // Constrain the width for a cleaner look
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- CUSTOM HEADER ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen.withOpacity(0.9),
                        AppTheme.primaryGreen.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.repeat, color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Change School Status',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // --- DIALOG CONTENT ---
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(color: AppTheme.bodyText, height: 1.5),
                            children: <TextSpan>[
                              const TextSpan(text: 'Select a new status for the school: '),
                              TextSpan(
                                text: widget.school.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: AppTheme.darkText),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // --- STYLED DROPDOWN ---
                        DropdownButtonFormField<SchoolStatusModel>(
                          value: _selectedStatus,
                          items: state.availableStatuses.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.name, style: GoogleFonts.inter()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.lightGrey,
                            labelText: 'New Status',
                            prefixIcon: const Icon(Iconsax.flag, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // --- DIALOG ACTIONS ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppTheme.borderGrey),
                            ),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.bodyText)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_selectedStatus == null || _selectedStatus!.id == initialStatus?.id)
                              ? null // Disable button if no status is selected or it's the same as the current one
                              : () {
                            context.read<SchoolManageBloc>().add(
                              UpdateSchoolStatus(
                                schoolId: widget.school.id,
                                statusId: _selectedStatus!.id,
                              ),
                            );
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text('Status for ${widget.school.name} updated successfully!'),
                                  backgroundColor: AppTheme.accentGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Iconsax.tick_circle, size: 18),
                          label: Text('Update', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _StatusBadge extends StatelessWidget {
  final SchoolStatusModel status;
  const _StatusBadge({required this.status});
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(status.name,
              style: GoogleFonts.inter(
                  color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StyledContainer extends StatelessWidget {
  final Widget child;
  const _StyledContainer({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.03),
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: child,
    );
  }
}