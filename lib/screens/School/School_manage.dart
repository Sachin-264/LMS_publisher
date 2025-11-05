import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/screens/School/add_school_screen.dart';
import 'package:lms_publisher/screens/School/school_detail_screen.dart';
import 'package:lms_publisher/screens/School/school_managebloc.dart';
import 'package:lms_publisher/screens/School/school_model.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:lms_publisher/service/school_service.dart';
import 'package:lms_publisher/service/user_right_service.dart';
import 'package:provider/provider.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';


class SchoolsScreen extends StatelessWidget {
  const SchoolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏫 SchoolsScreen: Building...');
    return BlocProvider(
      create: (context) {
        print('🏫 SchoolsScreen: Creating SchoolManageBloc...');
        return SchoolManageBloc(
          schoolApiService: RepositoryProvider.of<SchoolApiService>(context),
        )..add(FetchSchools());
      },
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

  @override
  void initState() {
    super.initState();
    print('🏫 SchoolsScreenContent: initState');
  }

  void _navigateToAddEditSchool(String? schoolId) {
    print('🚀 Navigating to AddEditSchool. SchoolId: ${schoolId ?? "NEW"}');

    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddSchoolScreen(schoolId: schoolId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    )
        .then((result) async {
      print('✅ Returned from AddEditSchool. Result: $result');

      if (result == true) {
        print('🔄 Triggering FetchSchools event...');
        context.read<SchoolManageBloc>().add(FetchSchools());

        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(schoolId == null
                    ? 'New school added successfully!'
                    : 'School updated successfully!'),
                backgroundColor: AppTheme.accentGreen,
              ),
            );
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    print('🏫 SchoolsScreenContent: Building widget tree...');
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final canAdd = userProvider.hasPermission('M002', 'add');
        print('🏫 Permissions - canAdd: $canAdd');

        return BlocConsumer<SchoolManageBloc, SchoolManageState>(
          listener: (context, state) {
            print('🏫 BlocListener - isLoading: ${state.isLoading}, error: ${state.error}');
            if (state.error != null) {
              print('❌ Error in state: ${state.error}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            print('🏫 BlocBuilder - Schools count: ${state.filteredSchools.length}, isLoading: ${state.isLoading}');

            final paginatedSchools = _getPaginatedSchools(state.filteredSchools);
            final totalPages = (state.filteredSchools.length / _rowsPerPage).ceil();

            print('🏫 Pagination - Current page: $_currentPage, Total pages: $totalPages, Showing: ${paginatedSchools.length} schools');

            // --- ADDED THIS WRAPPER ---
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // --- ADDED THIS LINE ---
                mainAxisSize: MainAxisSize.min,
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
                          if (canAdd)
                            ElevatedButton.icon(
                              onPressed: () {
                                print('➕ Add New School button pressed');
                                _navigateToAddEditSchool(null);
                              },
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
                      // --- ADDED THIS LINE (Good practice) ---
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _SchoolsHeader(),
                        const SizedBox(height: AppTheme.defaultPadding),
                        if (state.isLoading)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(64.0),
                              child: BeautifulLoader(
                                type: LoaderType.dots,
                                message: 'Loading schools...',
                                color: AppTheme.primaryGreen,
                                size: 50,
                              ),
                            ),
                          )
                        else if (state.filteredSchools.isEmpty)
                          Center(
                              child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      const Text("No schools found."),
                                      Text('Total schools: ${state.allSchools.length}'),
                                      Text('Filtered schools: ${state.filteredSchools.length}'),
                                    ],
                                  )))
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              bool isMobile = constraints.maxWidth < 700;
                              print('🏫 Building table - isMobile: $isMobile, Schools: ${paginatedSchools.length}');
                              return _ModernSchoolsTable(
                                  schools: paginatedSchools,
                                  isMobile: isMobile,
                                  canEdit: userProvider.hasPermission('M002', 'edit'),
                                  canDelete: userProvider.hasPermission('M002', 'delete'));
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
                                  if (value != null) {
                                    print('📄 Rows per page changed to: $value');
                                    setState(() {
                                      _rowsPerPage = value;
                                      _currentPage = 0;
                                    });
                                  }
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
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
            // --- END OF CHANGES ---
          },
        );
      },
    );
  }

  List<School> _getPaginatedSchools(List<School> schools) {
    if (schools.isEmpty) {
      print('⚠️ No schools to paginate');
      return [];
    }
    final totalSchools = schools.length;
    final startIndex = _currentPage * _rowsPerPage;

    if (startIndex >= totalSchools) {
      final lastValidPage = (totalSchools - 1) ~/ _rowsPerPage;

      final newPage = lastValidPage < 0 ? 0 : lastValidPage;

      if (_currentPage != newPage) {
        print('⚠️ Start index ($startIndex) out of range for total schools ($totalSchools). Resetting page from $_currentPage to $newPage');
        _currentPage = newPage;
      } else {
        print('⚠️ Edge case: startIndex out of range but currentPage did not change. Returning empty list.');
        return [];
      }
    }

    final newStartIndex = _currentPage * _rowsPerPage;
    final endIndex = (newStartIndex + _rowsPerPage > totalSchools)
        ? totalSchools
        : newStartIndex + _rowsPerPage;

    print('📄 Paginating: $newStartIndex to $endIndex of $totalSchools');

    if (newStartIndex >= endIndex && totalSchools > 0) {
      if (newStartIndex < totalSchools) {
        return schools.sublist(newStartIndex, newStartIndex + 1);
      }
      return [];
    }

    return schools.sublist(newStartIndex, endIndex);
  }

  void _goToPage(int page) {
    print('📄 Navigating to page: $page');
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
      print('🔍 Search term changed: ${_searchController.text}');
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
            final List<SchoolStatusModel?> filterOptions = [
              null,
              ...state.availableStatuses
            ];
            print('🎛️ Filter options: ${filterOptions.length}, Current: ${state.currentFilter?.name}');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                borderRadius: AppTheme.defaultBorderRadius,
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SchoolStatusModel?>(
                  value: state.currentFilter,
                  onChanged: (SchoolStatusModel? newValue) {
                    print('🎛️ Filter changed to: ${newValue?.name ?? "All"}');
                    context.read<SchoolManageBloc>().add(
                      SearchAndFilterSchools(
                        searchTerm: state.searchTerm,
                        filter: newValue,
                      ),
                    );
                  },
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
  final bool canEdit;
  final bool canDelete;

  const _ModernSchoolsTable({
    required this.schools,
    this.isMobile = false,
    required this.canEdit,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    print('📊 Building table with ${schools.length} schools, isMobile: $isMobile');
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
            print('📊 Building row $index: ${schools[index].name}');
            return _SchoolTableRow(
              school: schools[index],
              canEdit: canEdit,
              canDelete: canDelete,
            );
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
        return _SchoolMobileCard(
          school: schools[index],
          canEdit: canEdit,
          canDelete: canDelete,
        );
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
  final bool canEdit;
  final bool canDelete;

  const _SchoolTableRow({
    required this.school,
    required this.canEdit,
    required this.canDelete,
  });

  @override
  State<_SchoolTableRow> createState() => _SchoolTableRowState();
}

class _SchoolTableRowState extends State<_SchoolTableRow> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    print('📊 SchoolTableRow: ${widget.school.name} (ID: ${widget.school.id})');
  }

  void _navigateToDetailDialog() {
    print('👁️ Opening detail dialog for: ${widget.school.name}');
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
    print('📝 Editing school: ${widget.school.name} (ID: ${widget.school.id})');

    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddSchoolScreen(schoolId: widget.school.id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    )
        .then((result) async {
      print('✅ Returned from edit. Result: $result');

      if (result == true) {
        print('🔄 Refreshing schools list after edit...');
        context.read<SchoolManageBloc>().add(FetchSchools());

        await Future.delayed(const Duration(milliseconds: 300));
      }
    });
  }


  void _showUpdateCredentialsDialog() {
    print('🔑 Opening credentials dialog for: ${widget.school.name}');
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => BlocProvider.value(
        value: BlocProvider.of<SchoolManageBloc>(context),
        child: UpdateCredentialsDialog(school: widget.school),
      ),
    );
  }

  void _showRenewDialog() {
    print('🔄 Opening renew dialog for: ${widget.school.name}');
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<SchoolManageBloc>(context),
        child: _RenewSubscriptionDialog(school: widget.school),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, School school) {
    print('🗑️ Opening delete dialog for: ${school.name}');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<SchoolManageBloc>(context),
          child: _ImprovedDeleteConfirmationDialog(school: school),
        );
      },
    );
  }

  void _showChangeStatusDialog(BuildContext context, School school) {
    print('🔄 Opening status change dialog for: ${school.name}');
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<SchoolManageBloc>(context),
        child: _ChangeStatusDialog(school: school),
      ),
    );
  }

  Color _getHoverColor(SchoolStatusModel status) {
    switch (status.name.toLowerCase()) {
      case 'active':
        return AppTheme.accentGreen.withOpacity(0.08);
      case 'expired':
        return Colors.red.withOpacity(0.05);
      case 'trial':
        return Colors.orange.withOpacity(0.08);
      case 'suspended':
      default:
        return AppTheme.bodyText.withOpacity(0.08);
    }
  }

  Color _getHoverBorderColor(SchoolStatusModel status) {
    switch (status.name.toLowerCase()) {
      case 'active':
        return AppTheme.accentGreen;
      case 'expired':
        return Colors.red.shade600;
      case 'trial':
        return Colors.orange.shade700;
      case 'suspended':
      default:
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

    if (widget.school.startDate != null) {
      formattedStartDate = DateFormat.yMMMd().format(widget.school.startDate!);
    }

    if (widget.school.endDate != null) {
      formattedEndDate = DateFormat.yMMMd().format(widget.school.endDate!);
    }

    List<PopupMenuEntry<String>> menuItems = [];

    if (widget.canEdit) {
      menuItems.add(_buildPopupMenuItem('Edit', Iconsax.edit_2, 'edit'));
      menuItems.add(_buildPopupMenuItem('Update Credentials', Iconsax.key, 'credentials'));
      menuItems.add(_buildPopupMenuItem('Change Status', Iconsax.repeat, 'status'));
      menuItems.add(_buildPopupMenuItem('Renew Plan', Iconsax.refresh, 'renew',
          color: AppTheme.primaryGreen));
    }

    if (widget.canEdit && widget.canDelete) {
      menuItems.add(const PopupMenuDivider());
    }

    if (widget.canDelete) {
      menuItems.add(_buildPopupMenuItem('Delete', Iconsax.trash, 'delete',
          color: Colors.red.shade700));
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
                child: (widget.school.validity?.toLowerCase() == 'n/a' ||
                    widget.school.validity == null)
                    ? Text("N/A",
                    style: GoogleFonts.inter(
                        color: AppTheme.darkText, fontSize: 13, height: 1.5))
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
                    child: _StatusBadge(status: widget.school.status)),
              ),
              SizedBox(
                width: 80,
                child: Center(
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      print('🎯 Menu action: $value for ${widget.school.name}');
                      if (value == 'edit') _navigateToAddEditSchool();
                      if (value == 'credentials') _showUpdateCredentialsDialog();
                      if (value == 'renew') _showRenewDialog();
                      if (value == 'status') _showChangeStatusDialog(context, widget.school);
                      if (value == 'delete')
                        _showDeleteConfirmationDialog(context, widget.school);
                    },
                    icon: const Icon(Iconsax.more, color: AppTheme.bodyText),
                    tooltip: "Actions",
                    itemBuilder: (BuildContext context) => menuItems,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      String title, IconData icon, String value,
      {Color? color}) {
    return PopupMenuItem(
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
  final bool canEdit;
  final bool canDelete;

  const _SchoolMobileCard({
    required this.school,
    required this.canEdit,
    required this.canDelete,
  });

  void _navigateToDetailDialog(BuildContext context) {
    print('👁️ Mobile: Opening detail for ${school.name}');
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
    print('✏️ Mobile: Editing ${school.name}');
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddSchoolScreen(schoolId: school.id),
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

  void _showUpdateCredentialsDialog(BuildContext context) {
    print('🔑 Mobile: Opening credentials for ${school.name}');
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => BlocProvider.value(
        value: BlocProvider.of<SchoolManageBloc>(context),
        child: UpdateCredentialsDialog(school: school),
      ),
    );
  }

  void _showRenewDialog(BuildContext context) {
    print('🔄 Mobile: Opening renew for ${school.name}');
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<SchoolManageBloc>(context),
        child: _RenewSubscriptionDialog(school: school),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, School school) {
    print('🗑️ Mobile: Opening delete for ${school.name}');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<SchoolManageBloc>(context),
          child: _ImprovedDeleteConfirmationDialog(school: school),
        );
      },
    );
  }

  void _showChangeStatusDialog(BuildContext context, School school) {
    print('🔄 Mobile: Opening status change for ${school.name}');
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
    List<PopupMenuEntry<String>> menuItems = [];

    if (canEdit) {
      menuItems.add(_buildPopupMenuItem('Edit', Iconsax.edit_2, 'edit'));
      menuItems.add(_buildPopupMenuItem('Update Credentials', Iconsax.key, 'credentials'));
      menuItems.add(_buildPopupMenuItem('Change Status', Iconsax.repeat, 'status'));
      menuItems.add(_buildPopupMenuItem('Renew Plan', Iconsax.refresh, 'renew',
          color: AppTheme.primaryGreen));
    }

    if (canEdit && canDelete) {
      menuItems.add(const PopupMenuDivider());
    }

    if (canDelete) {
      menuItems.add(_buildPopupMenuItem('Delete', Iconsax.trash, 'delete',
          color: Colors.red.shade700));
    }

    return GestureDetector(
      onTap: () => _navigateToDetailDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    school.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    print('🎯 Mobile action: $value for ${school.name}');
                    if (value == 'edit') _navigateToAddEditSchool(context);
                    if (value == 'credentials') _showUpdateCredentialsDialog(context);
                    if (value == 'renew') _showRenewDialog(context);
                    if (value == 'status') _showChangeStatusDialog(context, school);
                    if (value == 'delete')
                      _showDeleteConfirmationDialog(context, school);
                  },
                  icon: const Icon(Iconsax.more, color: AppTheme.bodyText),
                  tooltip: "Actions",
                  itemBuilder: (BuildContext context) => menuItems,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                Iconsax.crown, 'Subscription', school.subscription ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(
                Iconsax.calendar, 'Validity', school.validity ?? 'N/A'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Iconsax.status, size: 16, color: AppTheme.bodyText),
                const SizedBox(width: 8),
                Text('Status: ',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.bodyText,
                        fontWeight: FontWeight.w500)),
                _StatusBadge(status: school.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.bodyText),
        const SizedBox(width: 8),
        Text('$label: ',
            style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.bodyText,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.darkText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      String title, IconData icon, String value,
      {Color? color}) {
    return PopupMenuItem(
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

class _StatusBadge extends StatelessWidget {
  final SchoolStatusModel status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.name.toLowerCase()) {
      case 'active':
        backgroundColor = AppTheme.accentGreen.withOpacity(0.15);
        textColor = AppTheme.accentGreen;
        icon = Iconsax.tick_circle;
        break;
      case 'expired':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        icon = Iconsax.close_circle;
        break;
      case 'trial':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        icon = Iconsax.timer_1;
        break;
      case 'suspended':
        backgroundColor = AppTheme.bodyText.withOpacity(0.1);
        textColor = AppTheme.bodyText;
        icon = Iconsax.pause_circle;
        break;
      default:
        backgroundColor = AppTheme.bodyText.withOpacity(0.1);
        textColor = AppTheme.bodyText;
        icon = Iconsax.info_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: textColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// IMPROVED DELETE CONFIRMATION DIALOG
// ============================================================================

class _ImprovedDeleteConfirmationDialog extends StatefulWidget {
  final School school;

  const _ImprovedDeleteConfirmationDialog({required this.school});

  @override
  State<_ImprovedDeleteConfirmationDialog> createState() =>
      _ImprovedDeleteConfirmationDialogState();
}

class _ImprovedDeleteConfirmationDialogState
    extends State<_ImprovedDeleteConfirmationDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _confirmController = TextEditingController();
  bool _canDelete = false;
  bool _isDeleting = false;
  bool _operationCompleted = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    print('🗑️ DeleteDialog: Opening for ${widget.school.name}');

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _confirmController.addListener(() {
      setState(() {
        _canDelete = _confirmController.text == 'DELETE';
      });
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _confirmDelete() {
    if (!_canDelete) {
      _shakeController.forward(from: 0);
      return;
    }

    print('🗑️ Deleting school: ${widget.school.name} (ID: ${widget.school.id})');
    setState(() => _isDeleting = true);
    context.read<SchoolManageBloc>().add(DeleteSchool(schoolId: widget.school.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SchoolManageBloc, SchoolManageState>(
      listener: (context, state) {
        if (_isDeleting && !state.isLoading && !_operationCompleted) {
          _operationCompleted = true;
          Future.microtask(() {
            if (mounted) {
              Navigator.of(context).pop();
              if (state.error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${widget.school.name} has been deleted successfully',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete: ${state.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          });
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 10,
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final offset = _shakeController.value < 0.5
                ? _shakeController.value * 20
                : (1 - _shakeController.value) * 20;
            return Transform.translate(
              offset: Offset(offset * (1 - _shakeController.value * 2).abs(), 0),
              child: child,
            );
          },
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.red.shade50.withOpacity(0.3),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient and icon
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade600,
                        Colors.red.shade700,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.danger,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm Deletion',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This action cannot be undone',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Warning message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Iconsax.info_circle,
                                color: Colors.red.shade700,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.inter(
                                      color: Colors.red.shade900,
                                      height: 1.5,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'You are about to permanently delete ',
                                      ),
                                      TextSpan(
                                        text: widget.school.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(
                                        text:
                                        '. All associated data will be permanently removed.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Confirmation instruction
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.edit,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.orange.shade900,
                                    ),
                                    children: const [
                                      TextSpan(text: 'Type '),
                                      TextSpan(
                                        text: 'DELETE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      TextSpan(text: ' to confirm'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Text field
                        TextField(
                          controller: _confirmController,
                          autocorrect: false,
                          style: GoogleFonts.robotoMono(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type DELETE here',
                            hintStyle: GoogleFonts.inter(
                              color: AppTheme.bodyText.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon: Icon(
                              Iconsax.keyboard,
                              color: _canDelete
                                  ? Colors.green.shade600
                                  : AppTheme.bodyText,
                            ),
                            suffixIcon: _canDelete
                                ? Icon(
                              Iconsax.tick_circle,
                              color: Colors.green.shade600,
                            )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppTheme.borderGrey,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppTheme.borderGrey,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _canDelete
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isDeleting
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: AppTheme.borderGrey,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppTheme.darkText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_canDelete && !_isDeleting)
                              ? _confirmDelete
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade500,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: _canDelete ? 4 : 0,
                            shadowColor: Colors.red.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isDeleting
                              ? const ButtonLoader(size: 20)
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.trash, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Delete Forever',
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// IMPROVED RENEW SUBSCRIPTION DIALOG (REFACTORED UI)
// ============================================================================

class _RenewSubscriptionDialog extends StatefulWidget {
  final School school;

  const _RenewSubscriptionDialog({required this.school});

  @override
  State<_RenewSubscriptionDialog> createState() =>
      _RenewSubscriptionDialogState();
}

class _RenewSubscriptionDialogState extends State<_RenewSubscriptionDialog> {
  List<SubscriptionPlan> _plans = [];
  SubscriptionPlan? _selectedPlan;
  bool _isLoadingPlans = true;
  bool _isRenewing = false;
  bool _renewalCompleted = false;
  DateTime _selectedStartDate = DateTime.now();
  DateTime? _calculatedEndDate;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      // Assuming SchoolApiService can be instantiated directly for this
      final service = SchoolApiService();
      final plans = await service.fetchSubscriptions();
      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlans = false);
        // Optionally, show an error message
      }
    }
  }

  void _calculateEndDate() {
    if (_selectedPlan == null) {
      setState(() => _calculatedEndDate = null);
      return;
    }

    DateTime endDate;
    final planType = _selectedPlan!.planType.toLowerCase();
    // A more robust way to calculate duration
    if (planType.contains('week')) {
      final weeks = int.tryParse(planType.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      endDate = _selectedStartDate.add(Duration(days: 7 * weeks));
    } else if (planType.contains('month')) {
      final months = int.tryParse(planType.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      endDate = DateTime(
        _selectedStartDate.year,
        _selectedStartDate.month + months,
        _selectedStartDate.day,
      );
    } else if (planType.contains('year') || planType.contains('annual')) {
      final years = int.tryParse(planType.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      endDate = DateTime(
        _selectedStartDate.year + years,
        _selectedStartDate.month,
        _selectedStartDate.day,
      );
    } else {
      // Default fallback (e.g., 30 days)
      endDate = _selectedStartDate.add(const Duration(days: 30));
    }
    setState(() => _calculatedEndDate = endDate);
  }


  Future<void> _renewSubscription() async {
    if (_selectedPlan == null || _calculatedEndDate == null) return;

    setState(() => _isRenewing = true);
    context.read<SchoolManageBloc>().add(
      RenewSubscription(
        schoolId: widget.school.id,
        newSubscriptionId: _selectedPlan!.id,
        newEndDate: DateFormat('yyyy-MM-dd').format(_calculatedEndDate!),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Allow picking a recent past date if needed
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedStartDate = date;
        _calculateEndDate(); // Recalculate when date changes
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<SchoolManageBloc, SchoolManageState>(
      listener: (context, state) {
        if (_isRenewing && !state.isLoading && !_renewalCompleted) {
          _renewalCompleted = true;
          // Use a microtask to ensure the build context is valid
          Future.microtask(() {
            if (mounted) {
              Navigator.of(context).pop();
              if (state.error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Subscription renewed successfully!',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            }
          });
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 8,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
             _isLoadingPlans
                 ? Padding(
               padding: const EdgeInsets.symmetric(vertical: 64.0),
               child: BeautifulLoader(
                 type: LoaderType.pulse,
                 message: 'Loading subscription plans...',
                 color: AppTheme.primaryGreen,
               ),
             )
                 : Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(
                        icon: Iconsax.building_4,
                        label: 'School Name',
                        value: widget.school.name,
                        iconColor: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('1. Select New Subscription Plan'),
                      const SizedBox(height: 12),
                      _buildPlanSelector(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('2. Choose Subscription Start Date'),
                      const SizedBox(height: 12),
                      _buildDatePicker(),
                      const SizedBox(height: 24),
                      if (_calculatedEndDate != null) _buildSummary(),
                    ],
                  ),
                ),
              ),
              if (!_isLoadingPlans) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withOpacity(0.9),
            AppTheme.primaryGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.refresh, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Renew Subscription',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Extend the validity for the selected school',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: AppTheme.darkText,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.bodyText),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPlanSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _selectedPlan != null ? AppTheme.primaryGreen : AppTheme.borderGrey,
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<SubscriptionPlan>(
        value: _selectedPlan,
        decoration: InputDecoration(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          prefixIcon: Icon(
            Iconsax.crown_1,
            color: _selectedPlan != null ? AppTheme.primaryGreen : AppTheme.bodyText,
          ),
        ),
        hint: Text('Choose a subscription plan', style: GoogleFonts.inter()),
        items: _plans.map((plan) {
          return DropdownMenuItem(
            value: plan,
            child: Text('${plan.name} - ${plan.planType}', style: GoogleFonts.inter()),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedPlan = value;
            _calculateEndDate();
          });
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectStartDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: AppTheme.borderGrey, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.calendar_1, color: AppTheme.primaryGreen),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Start Date',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.bodyText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.yMMMMd().format(_selectedStartDate),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.darkText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.edit_2, size: 18, color: AppTheme.bodyText),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('New Plan:',
                  style: GoogleFonts.inter(color: AppTheme.bodyText)),
              Text(_selectedPlan?.name ?? 'N/A',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: AppTheme.darkText)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Starts On:',
                  style: GoogleFonts.inter(color: AppTheme.bodyText)),
              Text(DateFormat.yMMMd().format(_selectedStartDate),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: AppTheme.darkText)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('New Expiry Date:',
                  style: GoogleFonts.inter(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600)),
              Text(
                _calculatedEndDate != null
                    ? DateFormat.yMMMd().format(_calculatedEndDate!)
                    : 'N/A',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isRenewing ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppTheme.borderGrey, width: 1.5),
                ),
              ),
              child: Text('Cancel',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (_selectedPlan != null && !_isRenewing)
                  ? _renewSubscription
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: _selectedPlan != null ? 4 : 0,
                shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isRenewing
                  ? const ButtonLoader(size: 20, color: Colors.white)

                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.tick_circle, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Confirm & Renew',
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
      ),
    );
  }
}

class _ChangeStatusDialog extends StatefulWidget {
  final School school;

  const _ChangeStatusDialog({required this.school});

  @override
  State<_ChangeStatusDialog> createState() => _ChangeStatusDialogState();
}

class _ChangeStatusDialogState extends State<_ChangeStatusDialog> {
  SchoolStatusModel? _selectedStatus;
  bool _isChanging = false;
  List<SchoolStatusModel> _availableStatuses = [];
  bool _isLoading = true;
  bool _operationCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    try {
      final service = SchoolApiService();
      final statuses = await service.fetchSchoolStatuses();
      if (mounted) {
        setState(() {
          _availableStatuses = statuses;
          _selectedStatus = statuses.firstWhere(
                (s) => s.name == widget.school.status.name,
            orElse: () => statuses.first,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeStatus() {
    if (_selectedStatus == null) return;
    setState(() => _isChanging = true);
    context.read<SchoolManageBloc>().add(
      UpdateSchoolStatus(
        schoolId: widget.school.id,
        statusId: _selectedStatus!.id,
      ),
    );
  }

  Color _getStatusColor(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'active':
        return AppTheme.accentGreen;
      case 'expired':
        return Colors.red.shade600;
      case 'trial':
        return Colors.orange.shade600;
      case 'suspended':
        return Colors.grey.shade600;
      default:
        return AppTheme.bodyText;
    }
  }

  IconData _getStatusIcon(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'active':
        return Iconsax.tick_circle;
      case 'expired':
        return Iconsax.close_circle;
      case 'trial':
        return Iconsax.timer_1;
      case 'suspended':
        return Iconsax.pause_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SchoolManageBloc, SchoolManageState>(
      listener: (context, state) {
        if (_isChanging && !state.isLoading && !_operationCompleted) {
          _operationCompleted = true;
          Future.microtask(() {
            if (mounted) {
              Navigator.of(context).pop();
              if (state.error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Status updated successfully!'),
                        ),
                      ],
                    ),
                    backgroundColor: AppTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            }
          });
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade700,
                    ],
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
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.repeat,
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
                            'Change Status',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update school status',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              _isLoading
                  ? const Padding(
                padding: EdgeInsets.all(48.0),
                child: BeautifulLoader(
                  type: LoaderType.spinner,
                  message: 'Loading statuses...',
                  color: AppTheme.primaryGreen,
                ),
              )
                  : Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // School info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.building,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'School',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.bodyText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.school.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkText,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Current status
                      Text(
                        'Current Status',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.school.status.name)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(widget.school.status.name)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(widget.school.status.name),
                              color: _getStatusColor(
                                  widget.school.status.name),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.school.status.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(
                                    widget.school.status.name),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // New status
                      Text(
                        'Select New Status',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedStatus != null
                                ? Colors.blue.shade600
                                : AppTheme.borderGrey,
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButtonFormField<SchoolStatusModel>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Iconsax.status,
                              color: _selectedStatus != null
                                  ? Colors.blue.shade600
                                  : AppTheme.bodyText,
                            ),
                          ),
                          items: _availableStatuses.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(status.name),
                                    size: 18,
                                    color: _getStatusColor(status.name),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    status.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedStatus = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              if (!_isLoading)
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isChanging
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: AppTheme.borderGrey,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: (_selectedStatus != null &&
                              _selectedStatus!.name !=
                                  widget.school.status.name &&
                              !_isChanging)
                              ? _changeStatus
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 4,
                            shadowColor: Colors.blue.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isChanging
                              ? const ButtonLoader(size: 20)
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.tick_circle, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Update Status',
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
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class UpdateCredentialsDialog extends StatefulWidget {
  final School school;
  const UpdateCredentialsDialog({super.key, required this.school});

  @override
  State<UpdateCredentialsDialog> createState() =>
      _UpdateCredentialsDialogState();
}

class _UpdateCredentialsDialogState extends State<UpdateCredentialsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _userPasswordController = TextEditingController();
  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    print('🔑 UpdateCredentialsDialog: Opening for ${widget.school.name} (ID: ${widget.school.id})');
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _userPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateCredentials() async {
    if (_formKey.currentState!.validate()) {
      print('🔑 Updating credentials for School_ID: ${widget.school.id}');
      print('🔑 UserID: ${_userIdController.text}');
      print('🔑 Password: ${_userPasswordController.text.isEmpty ? "Not changed" : "New password provided"}');

      setState(() => _isSaving = true);

      try {
        final userRightsService = UserRightsService();

        await userRightsService.updateUserCredentials(
          userCode: int.parse(widget.school.id),
          newUserID: _userIdController.text.trim().isNotEmpty
              ? _userIdController.text.trim()
              : null,
          newPassword: _userPasswordController.text.trim().isNotEmpty
              ? _userPasswordController.text.trim()
              : null,
          modifiedBy: 'admin', // Replace with actual logged-in username
        );


        print('✅ Credentials updated successfully');
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Credentials updated successfully for ${widget.school.name}'),
              backgroundColor: AppTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        print('❌ Error updating credentials: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update credentials: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      print('⚠️ Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      content: Container(
        width: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  const Icon(Iconsax.key, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Update Login Credentials',
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                              color: AppTheme.bodyText, height: 1.5),
                          children: [
                            const TextSpan(
                                text: 'Update login credentials for '),
                            TextSpan(
                              text: widget.school.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _userIdController,
                        decoration: InputDecoration(
                          labelText: 'User ID / Login Username',
                          prefixIcon: const Icon(Iconsax.user, size: 20),
                          filled: true,
                          fillColor: AppTheme.lightGrey,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryGreen, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter User ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _userPasswordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'New Password (leave blank to keep current)',
                          prefixIcon: const Icon(Iconsax.lock, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Iconsax.eye_slash
                                  : Iconsax.eye,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(
                                      () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          filled: true,
                          fillColor: AppTheme.lightGrey,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryGreen, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.info_circle,
                                size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Leave password field blank if you don\'t want to change it',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.blue.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        print('🔑 Credentials update cancelled');
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.borderGrey),
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
                      onPressed: _isSaving ? null : _updateCredentials,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSaving
                          ? const ButtonLoader(size: 18, color: Colors.white)
                          : const Icon(Iconsax.tick_circle, size: 18),
                      label: Text(
                        'Update',
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

class _StyledContainer extends StatelessWidget {
  final Widget child;

  const _StyledContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}