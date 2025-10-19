import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Service/user_right_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_model.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_service.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'add_teacher_screen.dart';
import 'teacher_bloc.dart';
import 'package:provider/provider.dart';



class TeachersScreen extends StatelessWidget {
  const TeachersScreen({super.key});  // ✅ Removed schoolRecNo parameter

  @override
  Widget build(BuildContext context) {
    // ✅ Get UserCode from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final schoolRecNo = int.tryParse(userProvider.userCode ?? '1') ?? 1;

    print("🏫 TeachersScreen: Using SchoolRecNo = $schoolRecNo from UserCode");

    return RepositoryProvider(
      create: (context) => TeacherApiService(),
      child: BlocProvider(
        create: (context) => TeacherBloc(
          apiService: RepositoryProvider.of<TeacherApiService>(context),
        )..add(LoadTeachersEvent(schoolRecNo: schoolRecNo)),
        child: MainLayout(
          activeScreen: AppScreen.teachers,
          child: TeachersScreenContent(schoolRecNo: schoolRecNo),  // ✅ Pass it down
        ),
      ),
    );
  }
}


class TeachersScreenContent extends StatefulWidget {
  final int schoolRecNo;
  const TeachersScreenContent({super.key, required this.schoolRecNo});  // ✅ Made required

  @override
  State<TeachersScreenContent> createState() => _TeachersScreenContentState();
}


class _TeachersScreenContentState extends State<TeachersScreenContent> {
  int currentPage = 0;
  int rowsPerPage = 8;
  final Set<int> selectedTeachers = {};
  bool? selectedIsActive = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<TeacherBloc>();
    if (bloc.state is TeacherInitialState) {
      bloc.add(LoadTeachersEvent(schoolRecNo: widget.schoolRecNo));
    }
  }

  void navigateToAddEditTeacher(TeacherModel? teacher) async {
    if (teacher != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
          );
        },
      );

      try {
        final apiService = TeacherApiService();
        final freshTeacher = await apiService.fetchTeacherDetails(recNo: teacher.recNo!);

        if (mounted) {
          Navigator.pop(context);
        }

        if (mounted) {
          Navigator.of(context)
              .push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  BlocProvider.value(
                    value: context.read<TeacherBloc>(),
                    child: AddTeacherScreen(
                      teacher: freshTeacher,
                      schoolRecNo: widget.schoolRecNo,
                    ),
                  ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                final offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          )
              .then((result) {
            if (result == true) {
              context.read<TeacherBloc>().add(
                LoadTeachersEvent(
                  schoolRecNo: widget.schoolRecNo,
                  isActive: selectedIsActive,
                ),
              );
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Teacher list refreshed after update.'),
                    backgroundColor: AppTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading teacher details: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      Navigator.of(context)
          .push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              BlocProvider.value(
                value: context.read<TeacherBloc>(),
                child: AddTeacherScreen(
                  teacher: null,
                  schoolRecNo: widget.schoolRecNo,
                ),
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            final offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      )
          .then((result) {
        if (result == true) {
          context.read<TeacherBloc>().add(
            LoadTeachersEvent(
              schoolRecNo: widget.schoolRecNo,
              isActive: selectedIsActive,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Teacher list refreshed after enrollment.'),
                backgroundColor: AppTheme.accentGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      });
    }
  }

  void applyFilters() {
    context.read<TeacherBloc>().add(
      LoadTeachersEvent(
        schoolRecNo: widget.schoolRecNo,
        isActive: selectedIsActive,
      ),
    );
  }

  void showUpdateCredentialsDialog(BuildContext context, TeacherModel teacher) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return UpdateCredentialsDialog(teacher: teacher);
      },
    );
  }

// ✅ IMPROVED: Extract user-friendly error message from API error
  String _extractErrorMessage(String error) {
    try {
      // First, check if it's already a clean message (from our improved SP)
      if (!error.contains('[Microsoft][ODBC Driver') &&
          !error.contains('Array') &&
          !error.contains('SQLSTATE')) {
        return error;
      }

      // Check for "Cannot delete teacher" pattern (our custom error)
      if (error.contains('Cannot delete teacher')) {
        final startIndex = error.indexOf('Cannot delete teacher');
        String message = error.substring(startIndex);

        // Find the end of the sentence (before the next array or newline)
        final endIndex = message.indexOf('\n');
        if (endIndex != -1) {
          message = message.substring(0, endIndex);
        }

        // Remove any trailing array syntax or brackets
        message = message.replaceAll(RegExp(r'\s*\)\s*$'), '').trim();

        return message;
      }

      // Check for foreign key constraint errors (fallback for old errors)
      if (error.contains('FK_Allotment_Teacher') || error.contains('REFERENCE constraint')) {
        return 'This teacher has subjects allotted and cannot be deleted.\nPlease remove subject assignments first.';
      }

      // Check for other SQL errors and extract [SQL Server] message
      if (error.contains('[SQL Server]')) {
        final startIndex = error.indexOf('[SQL Server]');
        if (startIndex != -1) {
          final messageStart = startIndex + '[SQL Server]'.length;
          String message = error.substring(messageStart).trim();

          // Clean up the message - find the actual error text
          final endIndex = message.indexOf('\n');
          if (endIndex != -1) {
            message = message.substring(0, endIndex);
          }

          // Remove array syntax and extra brackets
          message = message.replaceAll(RegExp(r'\s*\)\s*$'), '').trim();

          return message;
        }
      }

      // Return original error if no pattern matches
      return error;
    } catch (e) {
      return error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeacherBloc, TeacherState>(
      listener: (context, state) {
        if (state is TeacherOperationSuccessState) {
          // ✅ Reload list after success
          context.read<TeacherBloc>().add(
            LoadTeachersEvent(
              schoolRecNo: widget.schoolRecNo,
              isActive: selectedIsActive,
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${state.message} ✅'),
              backgroundColor: AppTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is TeacherErrorState) {
          // ✅ DON'T reload - preserve current state
          final cleanError = _extractErrorMessage(state.error);
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    const Icon(Iconsax.warning_2, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Operation Failed',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  cleanError,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.bodyText,
                    height: 1.5,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'OK',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      },
      builder: (context, state) {
        // ✅ FIXED: Always preserve teachers list
        final List<TeacherModel> teachers;
        final bloc = context.read<TeacherBloc>();

        if (state is TeacherLoadedState) {
          teachers = state.filteredTeachers.cast<TeacherModel>();
        } else if (state is TeacherDetailsLoadedState) {
          teachers = state.previousLoadedState.filteredTeachers.cast<TeacherModel>();
        } else if (state is TeacherOperationInProgressState || state is TeacherErrorState) {
          // ✅ Use cached teachers from bloc
          teachers = List<TeacherModel>.from(bloc.cachedTeachers);
        } else {
          teachers = [];
        }

        final paginatedTeachers = getPaginatedTeachers(teachers);
        final totalPages = (teachers.length / rowsPerPage).ceil();

        final bool isLoading = state is TeacherLoadingState ||
            (state is TeacherLoadedState && state.isSecondaryLoading && teachers.isEmpty);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isMobile = constraints.maxWidth < 600;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teacher Directory',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add, view, and manage all teacher records effortlessly.',
                            style: GoogleFonts.inter(
                              color: AppTheme.bodyText,
                            ),
                          ),
                        ],
                      ),
                    if (isMobile)
                      Text(
                        'Teachers',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => navigateToAddEditTeacher(null),
                      icon: const Icon(Iconsax.add_square, size: 20),
                      label: isMobile
                          ? const SizedBox.shrink()
                          : Text(
                        'Add New Teacher',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: isMobile
                            ? const CircleBorder()
                            : RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTheme.defaultPadding * 1.5),

            // Teachers Table Container
            StyledContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Search and Filter Header
                  TeachersHeader(
                    selectedCount: selectedTeachers.length,
                    onBulkDelete: () {
                      if (selectedTeachers.isNotEmpty) {
                        showBulkDeleteDialog(
                          context,
                          selectedTeachers.toList(),
                        );
                      }
                    },
                    onFilterPressed: () => showFilterDialog(context),
                  ),
                  const SizedBox(height: AppTheme.defaultPadding),

                  // Loading / Empty / Table
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    )
                  else if (teachers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(Iconsax.document_cloud,
                                size: 50, color: AppTheme.bodyText),
                            const SizedBox(height: 10),
                            Text(
                              state is TeacherLoadedState &&
                                  state.searchQuery != null &&
                                  state.searchQuery!.isNotEmpty
                                  ? 'No teachers match your search.'
                                  : 'No teacher records found.',
                              style: GoogleFonts.inter(color: AppTheme.bodyText),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 700;
                        return ModernTeachersTable(
                          teachers: paginatedTeachers,
                          isMobile: isMobile,
                          selectedTeachers: selectedTeachers,
                          onSelectionChanged: (recNo, isSelected) {
                            setState(() {
                              if (isSelected) {
                                selectedTeachers.add(recNo);
                              } else {
                                selectedTeachers.remove(recNo);
                              }
                            });
                          },
                          onTapRow: (teacher) => showDetailsDialog(context, teacher),
                          onEdit: (teacher) => navigateToAddEditTeacher(teacher),
                          onDelete: (teacher) =>
                              showDeleteConfirmationDialog(context, teacher),
                          onViewHistory: (teacher) =>
                              showHistoryDialog(context, teacher),
                          onUpdateCredentials: (teacher) => showUpdateCredentialsDialog(context, teacher),
                        );
                      },
                    ),
                  const SizedBox(height: AppTheme.defaultPadding),

                  // Pagination
                  if (teachers.isNotEmpty && totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                                  .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.toString(),
                                    style: GoogleFonts.inter()),
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
                              style: GoogleFonts.inter(
                                  color: AppTheme.darkText, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Page ${currentPage + 1} of $totalPages',
                          style: GoogleFonts.inter(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Iconsax.arrow_left_2, size: 20),
                          onPressed: currentPage > 0
                              ? () => goToPage(currentPage - 1)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.arrow_right_3, size: 20),
                          onPressed: currentPage < totalPages - 1
                              ? () => goToPage(currentPage + 1)
                              : null,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<TeacherModel> getPaginatedTeachers(List<TeacherModel> teachers) {
    if (teachers.isEmpty) return [];
    final startIndex = currentPage * rowsPerPage;
    if (startIndex >= teachers.length) {
      currentPage = 0;
      return teachers.sublist(
          0, teachers.length < rowsPerPage ? teachers.length : rowsPerPage);
    }

    final endIndex = (startIndex + rowsPerPage) > teachers.length
        ? teachers.length
        : startIndex + rowsPerPage;
    return teachers.sublist(startIndex, endIndex);
  }

  void goToPage(int page) {
    setState(() {
      currentPage = page;
    });
  }

  void showDeleteConfirmationDialog(
      BuildContext context, TeacherModel teacher) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<TeacherBloc>(context),
          child: DeleteConfirmationDialog(teacher: teacher),
        );
      },
    );
  }

  void showBulkDeleteDialog(BuildContext context, List<int> recNoList) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<TeacherBloc>(context),
          child: BulkDeleteDialog(recNoList: recNoList),
        );
      },
    ).then((_) {
      setState(() {
        selectedTeachers.clear();
      });
    });
  }

  void showHistoryDialog(BuildContext context, TeacherModel teacher) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<TeacherBloc>(context),
          child: TeacherHistoryDialog(teacher: teacher),
        );
      },
    );
  }

  void showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return FilterDialog(
          selectedIsActive: selectedIsActive,
          onApply: (bool? isActive) {
            setState(() {
              selectedIsActive = isActive;
              currentPage = 0;
            });
            applyFilters();
            Navigator.pop(dialogContext);
          },
        );
      },
    );
  }

  void showDetailsDialog(BuildContext context, TeacherModel teacher) {
    final teacherBloc = context.read<TeacherBloc>();
    teacherBloc.add(ClearTeacherDetailsEvent());
    teacherBloc.add(LoadTeacherDetailsEvent(recNo: teacher.recNo!));

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: teacherBloc,
          child: BlocConsumer<TeacherBloc, TeacherState>(
            listener: (context, state) {
              if (state is TeacherErrorState) {
                Navigator.pop(context);
              }
            },
            builder: (context, state) {
              if (state is TeacherLoadedState && state.isSecondaryLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                );
              }

              if (state is TeacherDetailsLoadedState) {
                return TeacherDetailsDialog(teacher: state.teacher);
              }

              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              );
            },
          ),
        );
      },
    ).then((_) {
      teacherBloc.add(ClearTeacherDetailsEvent());
    });
  }
}


// ======================== TEACHERS HEADER ========================
class TeachersHeader extends StatefulWidget {
  final int selectedCount;
  final VoidCallback onBulkDelete;
  final VoidCallback onFilterPressed;

  const TeachersHeader({
    super.key,
    required this.selectedCount,
    required this.onBulkDelete,
    required this.onFilterPressed,
  });

  @override
  State<TeachersHeader> createState() => _TeachersHeaderState();
}

class _TeachersHeaderState extends State<TeachersHeader> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    context.read<TeacherBloc>().add(SearchTeachersEvent(query: value));
                  },
                  decoration: InputDecoration(
                    hintText: 'Search teachers by name, ID, department...',
                    hintStyle: GoogleFonts.inter(
                      color: AppTheme.bodyText.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Iconsax.close_circle, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<TeacherBloc>()
                            .add(SearchTeachersEvent(query: ''));
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: IconButton(
                icon: const Icon(Iconsax.filter, size: 20),
                onPressed: widget.onFilterPressed,
                tooltip: 'Filter',
              ),
            ),
            if (widget.selectedCount > 0) ...[ const SizedBox(width: 12),
              // ✅ FIX: Make entire container clickable
              InkWell(
                onTap: widget.onBulkDelete,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.trash,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete ${widget.selectedCount}',
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

          ],
        ),
      ],
    );
  }
}

// ======================== MODERN TEACHERS TABLE ========================
class ModernTeachersTable extends StatelessWidget {
  final List<TeacherModel> teachers;
  final bool isMobile;
  final Set<int> selectedTeachers;
  final Function(int, bool) onSelectionChanged;
  final Function(TeacherModel) onTapRow;
  final Function(TeacherModel) onEdit;
  final Function(TeacherModel) onDelete;
  final Function(TeacherModel) onViewHistory;
  final Function(TeacherModel) onUpdateCredentials;

  const ModernTeachersTable({
    super.key,
    required this.teachers,
    required this.isMobile,
    required this.selectedTeachers,
    required this.onSelectionChanged,
    required this.onTapRow,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
    required this.onUpdateCredentials,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: teachers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final teacher = teachers[index];
          final isSelected = selectedTeachers.contains(teacher.recNo);
          return TeacherMobileCard(
            teacher: teacher,
            isSelected: isSelected,
            onSelectionChanged: onSelectionChanged,
            onTap: () => onTapRow(teacher),
            onEdit: () => onEdit(teacher),
            onDelete: () => onDelete(teacher),
            onViewHistory: () => onViewHistory(teacher),
             onUpdateCredentials: () => onUpdateCredentials(teacher),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    value: teachers.isNotEmpty &&
                        teachers.every((s) => selectedTeachers.contains(s.recNo)),
                    onChanged: (bool? value) {
                      if (value == true) {
                        for (var teacher in teachers) {
                          onSelectionChanged(teacher.recNo!, true);
                        }
                      } else {
                        for (var teacher in teachers) {
                          onSelectionChanged(teacher.recNo!, false);
                        }
                      }
                    },
                    activeColor: AppTheme.primaryGreen,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Teacher Name', style: _headerTextStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Employee Code', style: _headerTextStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Designation', style: _headerTextStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Department', style: _headerTextStyle()),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Status', style: _headerTextStyle()),
                ),
                const SizedBox(width: 100, child: Text('Actions')),
              ],
            ),
          ),
          // Data Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: teachers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              final isSelected = selectedTeachers.contains(teacher.recNo);
              return TeacherTableRow(
                teacher: teacher,
                isSelected: isSelected,
                onSelectionChanged: onSelectionChanged,
                onTap: () => onTapRow(teacher),
                onEdit: () => onEdit(teacher),
                onDelete: () => onDelete(teacher),
                onViewHistory: () => onViewHistory(teacher),
                onUpdateCredentials: () => onUpdateCredentials(teacher),
              );
            },
          ),
        ],
      ),
    );
  }

  TextStyle _headerTextStyle() {
    return GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: AppTheme.darkText,
    );
  }
}

// ======================== TEACHER TABLE ROW ========================
class TeacherTableRow extends StatefulWidget {
  final TeacherModel teacher;
  final bool isSelected;
  final Function(int, bool) onSelectionChanged;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;
  final VoidCallback onUpdateCredentials;  // ✅ ADD THIS

   const TeacherTableRow({
    super.key,
    required this.teacher,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
     required this.onViewHistory,
    required this.onUpdateCredentials,  // ✅ ADD THIS
  });

  @override
  State<TeacherTableRow> createState() => _TeacherTableRowState();
}

class _TeacherTableRowState extends State<TeacherTableRow> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: widget.isSelected
              ? AppTheme.primaryGreen.withOpacity(0.08)
              : (isHovered ? AppTheme.lightGrey : Colors.white),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: widget.isSelected,
                  onChanged: (bool? value) {
                    widget.onSelectionChanged(widget.teacher.recNo!, value ?? false);
                  },
                  activeColor: AppTheme.primaryGreen,
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                            backgroundImage: widget.teacher.photograph != null && widget.teacher.photograph!.isNotEmpty
                                ? NetworkImage(TeacherApiService.getTeacherPhotoUrl(widget.teacher.photograph!))
                                : null,
                            onBackgroundImageError: widget.teacher.photograph != null ? (exception, stackTrace) {} : null,
                            child: widget.teacher.photograph == null || widget.teacher.photograph!.isEmpty
                                ? Text(
                              widget.teacher.firstName[0].toUpperCase(),
                              style: GoogleFonts.inter(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.teacher.fullName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),


                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.teacher.fullName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.teacher.employeeCode ?? '-',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.teacher.designation ?? '-',
                  style: GoogleFonts.inter(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.teacher.department ?? '-',
                  style: GoogleFonts.inter(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (widget.teacher.isActive ?? false)
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (widget.teacher.isActive ?? false) ? 'Active' : 'Inactive',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: (widget.teacher.isActive ?? false)
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 150,  // ✅ Increased width for 3 buttons
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // ✅ NEW: Update Credentials Button
                    Tooltip(
                      message: 'Update Credentials',
                      child: IconButton(
                        icon: const Icon(Iconsax.key, size: 18),
                        color: Colors.orange,
                        onPressed: widget.onUpdateCredentials,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.edit, size: 18),
                      onPressed: widget.onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.trash, size: 18),
                      color: Colors.red,
                      onPressed: widget.onDelete,
                      tooltip: 'Delete',
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

// ✅ FULLY RESPONSIVE MOBILE CARD FOR SMALL SCREENS
class TeacherMobileCard extends StatelessWidget {
  final TeacherModel teacher;
  final bool isSelected;
  final Function(int, bool) onSelectionChanged;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;
  final VoidCallback onUpdateCredentials;

  const TeacherMobileCard({
    super.key,
    required this.teacher,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
    required this.onUpdateCredentials,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Get screen width for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 360;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 8 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppTheme.primaryGreen.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isVerySmallScreen ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Header Row - Responsive
                Row(
                  children: [
                    // Checkbox - Smaller on small screens
                    SizedBox(
                      width: isVerySmallScreen ? 20 : 24,
                      height: isVerySmallScreen ? 20 : 24,
                      child: Transform.scale(
                        scale: isVerySmallScreen ? 0.9 : 1.0,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            onSelectionChanged(teacher.recNo!, value ?? false);
                          },
                          activeColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: isVerySmallScreen ? 6 : 10),

                    // Avatar - Smaller on small screens
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: isVerySmallScreen ? 22 : 26,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: isVerySmallScreen ? 20 : 24,
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                          backgroundImage: (teacher.photograph != null &&
                              teacher.photograph!.isNotEmpty)
                              ? NetworkImage(TeacherApiService.getTeacherPhotoUrl(
                              teacher.photograph!))
                              : null,
                          child: (teacher.photograph == null ||
                              teacher.photograph!.isEmpty)
                              ? Text(
                            teacher.firstName[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: isVerySmallScreen ? 16 : 18,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),

                    SizedBox(width: isVerySmallScreen ? 6 : 10),

                    // Name and ID - Flexible
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher.fullName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: isVerySmallScreen ? 13 : 15,
                              color: AppTheme.darkText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (teacher.employeeCode != null)
                            Row(
                              children: [
                                Icon(
                                  Iconsax.card,
                                  size: 10,
                                  color: AppTheme.bodyText.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'ID: ${teacher.employeeCode}',
                                    style: GoogleFonts.inter(
                                      fontSize: isVerySmallScreen ? 10 : 11,
                                      color: AppTheme.bodyText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    SizedBox(width: isVerySmallScreen ? 4 : 8),

                    // Status Badge - Compact
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallScreen ? 6 : 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (teacher.isActive ?? false)
                            ? AppTheme.accentGreen.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isVerySmallScreen ? 5 : 6,
                            height: isVerySmallScreen ? 5 : 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (teacher.isActive ?? false)
                                  ? AppTheme.accentGreen
                                  : Colors.red,
                            ),
                          ),
                          if (!isVerySmallScreen) ...[
                            const SizedBox(width: 4),
                            Text(
                              (teacher.isActive ?? false) ? 'Active' : 'Inactive',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: (teacher.isActive ?? false)
                                    ? AppTheme.accentGreen
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isVerySmallScreen ? 10 : 12),

                // ✅ Info Section - Responsive Layout
                Container(
                  padding: EdgeInsets.all(isVerySmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // Designation & Department - Stack on very small screens
                      if (isVerySmallScreen)
                        Column(
                          children: [
                            _buildInfoChipVertical(
                              icon: Iconsax.briefcase,
                              label: 'Designation',
                              value: teacher.designation ?? 'N/A',
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 6),
                            _buildInfoChipVertical(
                              icon: Iconsax.building,
                              label: 'Department',
                              value: teacher.department ?? 'N/A',
                              color: Colors.purple,
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoChipVertical(
                                icon: Iconsax.briefcase,
                                label: 'Designation',
                                value: teacher.designation ?? 'N/A',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildInfoChipVertical(
                                icon: Iconsax.building,
                                label: 'Department',
                                value: teacher.department ?? 'N/A',
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),

                      if (teacher.mobileNumber != null ||
                          teacher.personalEmail != null) ...[
                        SizedBox(height: isVerySmallScreen ? 6 : 8),

                        if (teacher.mobileNumber != null)
                          _buildContactRow(
                            icon: Iconsax.call,
                            value: teacher.mobileNumber!,
                            color: Colors.green,
                            isSmall: isVerySmallScreen,
                          ),

                        if (teacher.personalEmail != null) ...[
                          const SizedBox(height: 4),
                          _buildContactRow(
                            icon: Iconsax.sms,
                            value: teacher.personalEmail!,
                            color: Colors.orange,
                            isSmall: isVerySmallScreen,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                SizedBox(height: isVerySmallScreen ? 10 : 12),

                // ✅ Action Buttons - Responsive
                if (isVerySmallScreen)
                // Very small screens: 2 rows
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Iconsax.key,
                              label: 'Credentials',
                              color: Colors.orange,
                              onPressed: onUpdateCredentials,
                              isCompact: true,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildActionButton(
                              icon: Iconsax.edit_2,
                              label: 'Edit',
                              color: AppTheme.primaryGreen,
                              onPressed: onEdit,
                              isCompact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildActionButton(
                        icon: Iconsax.trash,
                        label: 'Delete',
                        color: Colors.red,
                        onPressed: onDelete,
                        isCompact: true,
                        fullWidth: true,
                      ),
                    ],
                  )
                else
                // Normal screens: 1 row
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Iconsax.key,
                          label: 'Credentials',
                          color: Colors.orange,
                          onPressed: onUpdateCredentials,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildActionButton(
                          icon: Iconsax.edit_2,
                          label: 'Edit',
                          color: AppTheme.primaryGreen,
                          onPressed: onEdit,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildActionButton(
                          icon: Iconsax.trash,
                          label: 'Delete',
                          color: Colors.red,
                          onPressed: onDelete,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Vertical Info Chip for small screens
  Widget _buildInfoChipVertical({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppTheme.bodyText.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Contact Row - Responsive
  Widget _buildContactRow({
    required IconData icon,
    required String value,
    required Color color,
    bool isSmall = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmall ? 4 : 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: isSmall ? 12 : 14, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isSmall ? 10 : 11,
              color: AppTheme.darkText,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ✅ Action Button - Responsive
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isCompact = false,
    bool fullWidth = false,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 8 : 10,
            horizontal: isCompact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: isCompact ? 16 : 18, color: color),
              SizedBox(height: isCompact ? 2 : 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: isCompact ? 9 : 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ======================== FILTER DIALOG (FIXED) ========================
class FilterDialog extends StatefulWidget {
  final bool? selectedIsActive;
  final void Function(bool?) onApply;  // ✅ FIXED: Changed to void Function

  const FilterDialog({
    super.key,
    required this.selectedIsActive,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  bool? _tempIsActive;

  @override
  void initState() {
    super.initState();
    _tempIsActive = widget.selectedIsActive;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.filter, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Text(
                  'Filter Teachers',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Status',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<bool?>(
              value: _tempIsActive,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: true, child: Text('Active')),
                DropdownMenuItem(value: false, child: Text('Inactive')),
              ],
              onChanged: (value) {
                setState(() {
                  _tempIsActive = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempIsActive = null;
                    });
                  },
                  child: const Text('Clear All'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onApply(_tempIsActive);  // ✅ This now matches void Function(bool?)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// ======================== TEACHER DETAILS DIALOG ========================
class TeacherDetailsDialog extends StatelessWidget {
  final TeacherModel teacher;

  const TeacherDetailsDialog({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: teacher.photograph != null && teacher.photograph!.isNotEmpty
                        ? NetworkImage(TeacherApiService.getTeacherPhotoUrl(teacher.photograph!))
                        : null,
                    onBackgroundImageError: teacher.photograph != null ? (exception, stackTrace) {} : null,
                    child: teacher.photograph == null || teacher.photograph!.isEmpty
                        ? Text(
                      teacher.firstName[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    )
                        : null,
                  ),


                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher.fullName,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (teacher.employeeCode != null)
                          Text(
                            'Employee Code: ${teacher.employeeCode}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      'Basic Information',
                      [
                        _buildDetailRow('First Name', teacher.firstName),
                        _buildDetailRow('Middle Name', teacher.middleName),
                        _buildDetailRow('Last Name', teacher.lastName),
                        _buildDetailRow('Gender', teacher.gender),
                        _buildDetailRow('Date of Birth', teacher.dateOfBirth),
                        _buildDetailRow('Blood Group', teacher.bloodGroup),
                        _buildDetailRow('Nationality', teacher.nationality),
                        _buildDetailRow('Category', teacher.category),
                        _buildDetailRow('Religion', teacher.religion),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      'Contact Information',
                      [
                        _buildDetailRow('Mobile Number', teacher.mobileNumber),
                        _buildDetailRow(
                            'Alternate Contact', teacher.alternateContactNumber),
                        _buildDetailRow('Personal Email', teacher.personalEmail),
                        _buildDetailRow(
                            'Institutional Email', teacher.institutionalEmail),
                        _buildDetailRow('Permanent Address', teacher.permanentAddress),
                        _buildDetailRow('Current Address', teacher.currentAddress),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      'Employment Details',
                      [
                        _buildDetailRow('Date of Joining', teacher.dateOfJoining),
                        _buildDetailRow('Designation', teacher.designation),
                        _buildDetailRow('Department', teacher.department),
                        _buildDetailRow('Subjects Taught', teacher.subjectsTaught),
                        _buildDetailRow('Qualification', teacher.qualification),
                        _buildDetailRow('Experience (Years)',
                            teacher.experienceYears?.toString()),
                        _buildDetailRow('Employment Type', teacher.employmentType),
                        _buildDetailRow('Employee Status', teacher.employeeStatus),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      'System Information',
                      [
                        _buildDetailRow('Status',
                            (teacher.isActive ?? false) ? 'Active' : 'Inactive'),
                        _buildDetailRow('Created Date', teacher.createdDate),
                        _buildDetailRow('Created By', teacher.createdBy),
                        _buildDetailRow('Modified Date', teacher.modifiedDate),
                        _buildDetailRow('Modified By', teacher.modifiedBy),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.bodyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ NEW: Update Credentials Dialog
class UpdateCredentialsDialog extends StatefulWidget {
  final TeacherModel teacher;

  const UpdateCredentialsDialog({super.key, required this.teacher});

  @override
  State<UpdateCredentialsDialog> createState() => _UpdateCredentialsDialogState();
}

class _UpdateCredentialsDialogState extends State<UpdateCredentialsDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentCredentials();
  }

  Future<void> _loadCurrentCredentials() async {
    try {
      final userRightsService = UserRightsService();
      final credentials = await userRightsService.getUserCredentials(
        userCode: int.parse(widget.teacher.teacherCode!),
      );

      if (mounted) {
        setState(() {
          _userIdController.text = credentials['data']?['UserID'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load current credentials: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _updateCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userRightsService = UserRightsService();

      await userRightsService.updateUserCredentials(
        userCode: int.parse(widget.teacher.teacherCode!),
        newUserID: _userIdController.text.trim().isNotEmpty ? _userIdController.text.trim() : null,
        newPassword: _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : null,
        modifiedBy: 'Admin',  // Replace with actual logged-in user
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Credentials updated successfully!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update credentials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Beautiful Header with Gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.key,
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
                          'Update Credentials',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.teacher.fullName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ✅ Form Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.info_circle, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Leave password fields empty to keep existing password',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // User ID Field
                    Text(
                      'User ID (Username)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _userIdController,
                      decoration: InputDecoration(
                        hintText: 'Enter new username',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.bodyText.withOpacity(0.5),
                        ),
                        prefixIcon: const Icon(Iconsax.user, size: 20),
                        filled: true,
                        fillColor: AppTheme.lightGrey,
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
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'User ID is required';
                        }
                        if (value.length < 3) {
                          return 'User ID must be at least 3 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // New Password Field
                    Text(
                      'New Password',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter new password (optional)',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.bodyText.withOpacity(0.5),
                        ),
                        prefixIcon: const Icon(Iconsax.lock, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: AppTheme.lightGrey,
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
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Confirm Password Field
                    Text(
                      'Confirm Password',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        hintText: 'Re-enter new password',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.bodyText.withOpacity(0.5),
                        ),
                        prefixIcon: const Icon(Iconsax.lock_1, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: AppTheme.lightGrey,
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
                      ),
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty && value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppTheme.borderGrey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _updateCredentials,
                            icon: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Icon(Iconsax.tick_circle, size: 20),
                            label: Text(
                              _isLoading ? 'Updating...' : 'Update Credentials',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ======================== DELETE CONFIRMATION DIALOG ========================
class DeleteConfirmationDialog extends StatelessWidget {
  final TeacherModel teacher;

  const DeleteConfirmationDialog({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
          Text(
            'Confirm Delete',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to delete ${teacher.fullName}? This action cannot be undone.',
        style: GoogleFonts.inter(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<TeacherBloc>().add(
              DeleteTeacherEvent(
                recNo: teacher.recNo!,
                operationBy: 'Admin',
              ),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

// ======================== BULK DELETE DIALOG ========================
class BulkDeleteDialog extends StatelessWidget {
  final List<int> recNoList;

  const BulkDeleteDialog({super.key, required this.recNoList});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
          Text(
            'Confirm Bulk Delete',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to delete ${recNoList.length} teacher(s)? This action cannot be undone.',
        style: GoogleFonts.inter(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<TeacherBloc>().add(
              DeleteTeachersBulkEvent(
                recNoList: recNoList,
                operationBy: 'Admin',
              ),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete All'),
        ),
      ],
    );
  }
}

// ======================== TEACHER HISTORY DIALOG ========================
class TeacherHistoryDialog extends StatelessWidget {
  final TeacherModel teacher;

  const TeacherHistoryDialog({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.clock, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Text(
                  'History - ${teacher.fullName}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.document_text,
                      size: 64,
                      color: AppTheme.bodyText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No history available',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================== STYLED CONTAINER ========================
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
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}


