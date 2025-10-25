import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/School_Panel/student_module/student_model.dart';
import 'package:lms_publisher/School_Panel/student_module/student_service.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'add_student_screen.dart';
import 'student_bloc.dart';
import 'package:crypto/crypto.dart';
import 'package:lms_publisher/Service/user_right_service.dart';


class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 GET schoolRecNo FROM UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final schoolRecNo = int.tryParse(userProvider.userCode ?? '0') ?? 0;

    print("🔍 [StudentsScreen] School_RecNo from UserProvider: $schoolRecNo");

    return RepositoryProvider<StudentApiService>(
      create: (context) => StudentApiService(),
      child: BlocProvider(
        create: (context) => StudentBloc(
          apiService: RepositoryProvider.of<StudentApiService>(context),
        )..add(LoadStudentsEvent(schoolRecNo: schoolRecNo)),

        child: MainLayout(
          activeScreen: AppScreen.students,
          child: StudentsScreenContent(schoolRecNo: schoolRecNo ),
        ),
      ),
    );
  }
}

class StudentsScreenContent extends StatefulWidget {
  final int schoolRecNo;

  const StudentsScreenContent({super.key, required this .schoolRecNo});

  @override
  State<StudentsScreenContent> createState() => _StudentsScreenContentState();
}

class _StudentsScreenContentState extends State<StudentsScreenContent> {
  int currentPage = 0;
  int rowsPerPage = 8;
  final Set<int> selectedStudents = {};
  int? selectedClassRecNo;
  bool? selectedIsActive = true;
  String? selectedAcademicYear;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use the BlocProvider from the parent StudentsScreen build
    final bloc = context.read<StudentBloc>();
    if (bloc.state is StudentInitialState) {
      bloc.add(LoadStudentsEvent(schoolRecNo: widget.schoolRecNo));
    }
  }

  void navigateToAddEditStudent(StudentModel? student) async {
    // If editing, fetch fresh data via API first
    if (student != null) {
      // Show loading while fetching student details
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
        // Fetch fresh student data
        final apiService = StudentApiService();
        final freshStudent = await apiService.fetchStudentDetails(recNo: student.recNo!);

        // Close loading dialog
        if (mounted) {
          Navigator.pop(context);
        }

        // Now navigate with fresh data
        if (mounted) {
          Navigator.of(context)
              .push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  BlocProvider.value(
                    value: context.read<StudentBloc>(),
                    child: AddStudentScreen(
                      student: freshStudent, // Use fresh data from API
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
              context.read<StudentBloc>().add(
                LoadStudentsEvent(
                  schoolRecNo: widget.schoolRecNo,
                  classRecNo: selectedClassRecNo,
                  isActive: selectedIsActive,
                  academicYear: selectedAcademicYear,
                ),
              );

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Student list refreshed after update.'),
                    backgroundColor: AppTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
          });
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) {
          Navigator.pop(context);
        }

        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading student details: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // For new student (student is null), navigate directly
      Navigator.of(context)
          .push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              BlocProvider.value(
                value: context.read<StudentBloc>(),
                child: AddStudentScreen(
                  student: null,
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
          context.read<StudentBloc>().add(
            LoadStudentsEvent(
              schoolRecNo: widget.schoolRecNo,
              classRecNo: selectedClassRecNo,
              isActive: selectedIsActive,
              academicYear: selectedAcademicYear,
            ),
          );

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Student list refreshed after enrollment.'),
                backgroundColor: AppTheme.accentGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      });
    }
  }


  void applyFilters() {
    context.read<StudentBloc>().add(
      LoadStudentsEvent(
        schoolRecNo: widget.schoolRecNo,
        classRecNo: selectedClassRecNo,
        isActive: selectedIsActive,
        academicYear: selectedAcademicYear, // ADD THIS
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudentBloc, StudentState>(
      listener: (context, state) {
        if (state is StudentOperationSuccessState) {
          // Refresh API call after Delete/Bulk Delete
          context.read<StudentBloc>().add(
            LoadStudentsEvent(
              schoolRecNo: widget.schoolRecNo,
              classRecNo: selectedClassRecNo,
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
        } else if (state is StudentErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.error} ❌'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final students = state is StudentLoadedState
            ? state.filteredStudents
            : (state is StudentDetailsLoadedState
            ? state.previousLoadedState.filteredStudents // Use the cached list from the details state
            : <StudentModel>[]);
        final paginatedStudents = getPaginatedStudents(students);
        final totalPages = (students.length / rowsPerPage).ceil();

        // Check for primary loading or secondary loading (for the list view itself)
        final bool isLoading = state is StudentLoadingState || (state is StudentLoadedState && state.isSecondaryLoading && students.isEmpty);

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
                            'Student Directory',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add, view, and manage all student records effortlessly.',
                            style: GoogleFonts.inter(
                              color: AppTheme.bodyText,
                            ),
                          ),
                        ],
                      ),
                    if (isMobile)
                      Text(
                        'Students',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => navigateToAddEditStudent(null),
                      icon: const Icon(Iconsax.add_square, size: 20),
                      label: isMobile
                          ? const SizedBox.shrink()
                          : Text(
                        'Add New Student',
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

            // Students Table Container
            // IMPORTANT: The StyledContainer provides all necessary horizontal padding (24)
            // for the table content on all screen sizes, solving the "table coming under layout" issue
            // by ensuring the content is restricted within the container's bounds.
            StyledContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Search and Filter Header
                  StudentsHeader(
                    selectedCount: selectedStudents.length,
                    onBulkDelete: () {
                      if (selectedStudents.isNotEmpty) {
                        showBulkDeleteDialog(
                          context,
                          selectedStudents.toList(),
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
                  else if (students.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(Iconsax.document_cloud,
                                size: 50, color: AppTheme.bodyText),
                            const SizedBox(height: 10),
                            Text(
                              state is StudentLoadedState &&
                                  state.searchQuery != null &&
                                  state.searchQuery!.isNotEmpty
                                  ? 'No students match your search.'
                                  : 'No student records found.',
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
                        return ModernStudentsTable(
                          students: paginatedStudents,
                          isMobile: isMobile,
                          selectedStudents: selectedStudents,
                          onSelectionChanged: (recNo, isSelected) {
                            setState(() {
                              if (isSelected) {
                                selectedStudents.add(recNo);
                              } else {
                                selectedStudents.remove(recNo);
                              }
                            });
                          },
                          onTapRow: (student) => showDetailsDialog(context, student),
                          onEdit: (student) =>
                              navigateToAddEditStudent(student),
                          onDelete: (student) =>
                              showDeleteConfirmationDialog(context, student),
                          onViewHistory: (student) =>
                              showHistoryDialog(context, student),
                          onUpdateCredentials: _showUpdateCredentialsDialog,
                        );
                      },
                    ),

                  const SizedBox(height: AppTheme.defaultPadding),

                  // Pagination
                  if (students.isNotEmpty && totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Rows:', style: GoogleFonts.inter()),
                        const SizedBox(width: 8),
                        // Professional Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white, // Made white
                            border: Border.all(color: AppTheme.borderGrey),
                            borderRadius: BorderRadius.circular(12), // Smooth corners
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: rowsPerPage,
                              isDense: true,
                              icon: const Icon(Iconsax.arrow_down_1, size: 20),
                              items: [5, 8, 10, 15]
                                  .map((e) => DropdownMenuItem(
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

  // Helper function to check if we are in the middle of a list load
  bool _paginatedStudentsLoading(List<StudentModel> students, StudentLoadingState state) {
    // Show loading only if the student list is currently empty, meaning a full list load is pending.
    // Otherwise, assume the displayed list is the cached one during search/filter load.
    return students.isEmpty;
  }

  List<StudentModel> getPaginatedStudents(List<StudentModel> students) {
    if (students.isEmpty) return [];
    final startIndex = currentPage * rowsPerPage;
    if (startIndex >= students.length) {
      // Reset to first page if current page index is out of bounds
      currentPage = 0;
      return students.sublist(
          0, students.length < rowsPerPage ? students.length : rowsPerPage);
    }
    final endIndex = (startIndex + rowsPerPage) > students.length
        ? students.length
        : startIndex + rowsPerPage;
    return students.sublist(startIndex, endIndex);
  }

  void goToPage(int page) {
    setState(() {
      currentPage = page;
    });
  }

  void showDeleteConfirmationDialog(
      BuildContext context, StudentModel student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<StudentBloc>(context),
          child: DeleteConfirmationDialog(student: student),
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
          value: BlocProvider.of<StudentBloc>(context),
          child: BulkDeleteDialog(recNoList: recNoList),
        );
      },
    ).then((_) {
      setState(() {
        selectedStudents.clear();
      });
    });
  }

  void showHistoryDialog(BuildContext context, StudentModel student) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<StudentBloc>(context),
          child: StudentHistoryDialog(student: student),
        );
      },
    );
  }

  // Update showFilterDialog
  void showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return FilterDialog(
          selectedClassRecNo: selectedClassRecNo,
          selectedIsActive: selectedIsActive,
          selectedAcademicYear: selectedAcademicYear, // ADD THIS
          onApply: (classRecNo, isActive, academicYear) { // UPDATE THIS
            setState(() {
              selectedClassRecNo = classRecNo;
              selectedIsActive = isActive;
              selectedAcademicYear = academicYear; // ADD THIS
              currentPage = 0;
            });
            applyFilters();
            Navigator.pop(dialogContext);
          },
        );
      },
    );
  }
  void showDetailsDialog(BuildContext context, StudentModel student) {
    final studentBloc = context.read<StudentBloc>();

    // Clear any previous detail states/errors before starting new fetch
    studentBloc.add(ClearStudentDetailsEvent());

    // 1. Dispatch the event to fetch the specific student's details
    studentBloc.add(LoadStudentDetailsEvent(recNo: student.recNo!));

    // 2. Show the Dialog which will listen for the state change
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissal when not loading
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: studentBloc,
          child: BlocConsumer<StudentBloc, StudentState>(
            // The listener handles errors or immediate state transitions that should close the loading screen
            listener: (context, state) {
              if (state is StudentErrorState) {
                // The error is already handled by the main screen's listener,
                // but we need to ensure the dialog itself closes if an error occurs during fetch.
                // We rely on the outer .then(() { ... }) block to restore state.
                Navigator.pop(context);
              }
            },
            // The builder decides what widget to show based on the bloc state
            builder: (context, state) {
              // Show loading if the main list is in a secondary loading state
              if (state is StudentLoadedState && state.isSecondaryLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                );
              }
              // Show the loaded data
              if (state is StudentDetailsLoadedState) {
                return StudentDetailsDialog(student: state.student);
              }

              // Default state while waiting for initial details load (or fallback for non-list states)
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              );
            },
          ),
        );
      },
    ).then((_) {
      // 3. IMPORTANT FIX: Dispatch an event to restore the previous StudentLoadedState
      // This is called when the dialog closes (via Navigator.pop or barrier dismiss).
      studentBloc.add(ClearStudentDetailsEvent());
    });
  }

  void _showUpdateCredentialsDialog(BuildContext context, StudentModel student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return UpdateCredentialsDialog(student: student);
      },
    );
  }

}

// ============================================================================
// UPDATE CREDENTIALS DIALOG
// ============================================================================
class UpdateCredentialsDialog extends StatefulWidget {
  final StudentModel student;

  const UpdateCredentialsDialog({
    super.key,
    required this.student,
  });

  @override
  State<UpdateCredentialsDialog> createState() => _UpdateCredentialsDialogState();
}

class _UpdateCredentialsDialogState extends State<UpdateCredentialsDialog> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final UserRightsService _credentialService = UserRightsService();

  bool isLoading = true;
  bool isSaving = false;
  bool showPassword = false;
  String? currentUserId;
  String? encryptedPassword;

  @override
  void initState() {
    super.initState();
    _fetchCurrentCredentials();
  }

  @override
  void dispose() {
    userIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentCredentials() async {
    try {
      final data = await _credentialService.getUserCredentials(
        userCode: int.parse(widget.student.studentId!),
      );

      setState(() {
        currentUserId = data['data']['UserID'];
        encryptedPassword = data['data']['EncryptPassword'];
        userIdController.text = currentUserId ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading credentials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateCredentials() async {
    if (userIdController.text.trim().isEmpty && passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please update at least UserID or Password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await _credentialService.updateUserCredentials(
        userCode: int.parse(widget.student.studentId!),
        newUserID: userIdController.text.trim().isNotEmpty &&
            userIdController.text != currentUserId
            ? userIdController.text.trim()
            : null,
        newPassword: passwordController.text.trim().isNotEmpty
            ? passwordController.text.trim()
            : null,
        modifiedBy: 'admin', // Replace with actual logged-in user
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credentials updated successfully'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.key, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Credentials',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: AppTheme.darkText,
                  ),
                ),
                Text(
                  widget.student.fullName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.bodyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: isLoading
          ? const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
          ),
        ),
      )
          : SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student ID: ${widget.student.studentId ?? 'N/A'}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current Password: ${encryptedPassword != null ? "●●●●●●●● (Encrypted)" : "Not Set"}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // UserID Field
              Text(
                'Login UserID',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: userIdController,
                decoration: InputDecoration(
                  hintText: 'Enter new UserID',
                  hintStyle: GoogleFonts.inter(color: AppTheme.bodyText),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Iconsax.user, size: 20, color: AppTheme.primaryGreen),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              Text(
                'New Password',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  hintText: 'Enter new password (optional)',
                  hintStyle: GoogleFonts.inter(color: AppTheme.bodyText),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Iconsax.lock, size: 20, color: AppTheme.primaryGreen),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Iconsax.eye : Iconsax.eye_slash,
                      size: 20,
                      color: AppTheme.bodyText,
                    ),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // Info Note
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.info_circle, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Password will be securely encrypted. Leave empty to keep current password.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.blue.shade700,
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
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: AppTheme.bodyText),
          ),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _updateCredentials,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
          ),
          child: isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Text(
            'Update',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}


// ==================== FILTER DIALOG (Dropdowns Updated for Professional Look) ====================
class FilterDialog extends StatefulWidget {
  final int? selectedClassRecNo;
  final bool? selectedIsActive;
  final String? selectedAcademicYear;
  final Function(int?, bool?, String?) onApply;

  const FilterDialog({
    super.key,
    this.selectedClassRecNo,
    this.selectedIsActive,
    this.selectedAcademicYear,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  int? selectedClassRecNo;
  bool? selectedIsActive;
  String? selectedAcademicYear;
  List<Map<String, dynamic>> classList = [];
  bool isLoadingClasses = true;

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

  @override
  void initState() {
    super.initState();
    selectedClassRecNo = widget.selectedClassRecNo;
    selectedIsActive = widget.selectedIsActive;
    selectedAcademicYear = widget.selectedAcademicYear;
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    try {
      final apiService = StudentApiService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final schoolRecNo = int.tryParse(userProvider.userCode ?? '0') ?? 0;
      final classes = await apiService.fetchClassesBySchool(
        schoolRecNo: schoolRecNo,
      );
      setState(() {
        classList = classes;
        isLoadingClasses = false;
      });
    } catch (e) {
      setState(() {
        isLoadingClasses = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.filter_search, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Text(
            'Filter Students',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppTheme.darkText,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Dropdown
            Text(
              'Filter by Class',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            isLoadingClasses
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                ),
              ),
            )
                : DropdownButtonFormField<int>(
              value: selectedClassRecNo,
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'All Classes',
                hintStyle: GoogleFonts.inter(color: AppTheme.bodyText),
                filled: true,
                fillColor: Colors.white,
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
                  borderSide:
                  const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('All Classes',
                      style: TextStyle(color: AppTheme.bodyText)),
                ),
                ...classList.map((cls) {
                  return DropdownMenuItem<int>(
                    value: cls['ClassRecNo'],
                    child: Text(
                      '${cls['Class_Name']} - ${cls['Section_Name']}',
                      style: GoogleFonts.inter(),
                    ),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  selectedClassRecNo = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // Academic Year Dropdown
            Text(
              'Filter by Academic Year',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedAcademicYear,
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'All Years',
                hintStyle: GoogleFonts.inter(color: AppTheme.bodyText),
                filled: true,
                fillColor: Colors.white,
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
                  borderSide:
                  const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Years',
                      style: TextStyle(color: AppTheme.bodyText)),
                ),
                ...academicYears.map((year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year, style: GoogleFonts.inter()),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  selectedAcademicYear = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // Status Dropdown
            Text(
              'Filter by Status',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<bool?>(
              value: selectedIsActive,
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'All Students',
                hintStyle: GoogleFonts.inter(color: AppTheme.bodyText),
                filled: true,
                fillColor: Colors.white,
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
                  borderSide:
                  const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: const [
                DropdownMenuItem<bool?>(
                  value: null,
                  child: Text('All Students',
                      style: TextStyle(color: AppTheme.bodyText)),
                ),
                DropdownMenuItem<bool?>(
                  value: true,
                  child: Text('Active Only'),
                ),
                DropdownMenuItem<bool?>(
                  value: false,
                  child: Text('Inactive Only'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedIsActive = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              selectedClassRecNo = null;
              selectedIsActive = true;
              selectedAcademicYear = null;
            });
          },
          child: Text('Clear', style: GoogleFonts.inter(color: AppTheme.bodyText)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.darkText)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(selectedClassRecNo, selectedIsActive, selectedAcademicYear);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
          ),
          child: Text('Apply Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}




// ==================== STUDENTS HEADER ====================
class StudentsHeader extends StatefulWidget {
  final int selectedCount;
  final VoidCallback onBulkDelete;
  final VoidCallback onFilterPressed;

  const StudentsHeader({
    super.key,
    required this.selectedCount,
    required this.onBulkDelete,
    required this.onFilterPressed,
  });

  @override
  State<StudentsHeader> createState() => _StudentsHeaderState();
}

class _StudentsHeaderState extends State<StudentsHeader> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _performSearch(String value) {
    context.read<StudentBloc>().add(SearchStudentsEvent(query: value));
  }

  void _clearSearch() {
    searchController.clear();
    _performSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mobile Layout: Search, then Buttons
            if (isMobile)
              Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildFilterButton()),
                      if (widget.selectedCount > 0) ...[
                        const SizedBox(width: 8),
                        Expanded(child: _buildBulkDeleteButton()),
                      ],
                    ],
                  ),
                ],
              )
            // Desktop Layout: All in a row
            else
              Row(
                children: [
                  Expanded(child: _buildSearchBar()),
                  const SizedBox(width: 12),
                  _buildFilterButton(),
                  if (widget.selectedCount > 0) ...[
                    const SizedBox(width: 8),
                    _buildBulkDeleteButton(),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: TextField(
        controller: searchController,
        onChanged: _performSearch,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name, ID, mobile, etc...',
          hintStyle: GoogleFonts.inter(
            color: AppTheme.bodyText.withOpacity(0.6),
            fontSize: 14,
          ),
          prefixIcon: const Icon(Iconsax.search_normal_1, size: 20, color: AppTheme.bodyText),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Iconsax.close_circle, size: 20),
            onPressed: _clearSearch,
          )
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return OutlinedButton.icon(
      onPressed: widget.onFilterPressed,
      icon: const Icon(Iconsax.filter_search, size: 20),
      label: Text('Filter', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.darkText,
        side: const BorderSide(color: AppTheme.borderGrey),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBulkDeleteButton() {
    return ElevatedButton.icon(
      onPressed: widget.onBulkDelete,
      icon: const Icon(Iconsax.trash, size: 20),
      label: Text('Delete (${widget.selectedCount})',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ==================== MODERN STUDENTS TABLE (Desktop) ====================
class ModernStudentsTable extends StatelessWidget {
  final List<StudentModel> students;
  final bool isMobile;
  final Set<int> selectedStudents;
  final Function(int, bool) onSelectionChanged;
  final Function(StudentModel) onTapRow;
  final Function(StudentModel) onEdit;
  final Function(StudentModel) onDelete;
  final Function(StudentModel) onViewHistory;
  final Function(BuildContext, StudentModel) onUpdateCredentials; // ADD THIS

  const ModernStudentsTable({
    super.key,
    required this.students,
    required this.isMobile,
    required this.selectedStudents,
    required this.onSelectionChanged,
    required this.onTapRow,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
    required this.onUpdateCredentials, // ADD THIS
  });


  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      // Mobile View: Column of Cards
      return Column(
        // Wrap with Padding here to ensure cards don't touch the screen edge on mobile
        children: students
            .map((student) => StudentMobileCard(
          student: student,
          isSelected: selectedStudents.contains(student.recNo),
          onSelectionChanged: (isSelected) =>
              onSelectionChanged(student.recNo!, isSelected),
          onTap: () => onTapRow(student),
          onEdit: () => onEdit(student),
          onDelete: () => onDelete(student),
          onViewHistory: () => onViewHistory(student),
        ))
            .toList(),
      );
    }

    // Desktop/Web Table View
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        // General table styling
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        headingRowColor: WidgetStateProperty.all(AppTheme.lightGrey),
        dataRowHeight: 68,
        headingRowHeight: 50,
        columnSpacing: 24,
        columns: [
          DataColumn(label: _buildHeader('Select')), // Ticking option
          DataColumn(label: _buildHeader('Student')),
          DataColumn(label: _buildHeader('Admission No.')),
          DataColumn(label: _buildHeader('Class/Section')),
          DataColumn(label: _buildHeader('Roll No.')),
          DataColumn(label: _buildHeader('Contact')),
          DataColumn(label: _buildHeader('Father Name')),
          DataColumn(label: _buildHeader('Status')),
          DataColumn(label: _buildHeader('Actions')),
        ],
        rows: students
            .map((student) => DataRow(
          // Using onLongPress for touch/details on the row without interfering with checkbox
          onLongPress: () => onTapRow(student),
          color: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return AppTheme.primaryGreen.withOpacity(0.05);
              }
              return null; // Use default
            },
          ),
          cells: [
            // Checkbox with borderRadius
            DataCell(
              Checkbox(
                value: selectedStudents.contains(student.recNo),
                onChanged: (value) => onSelectionChanged(student.recNo!, value ?? false),
                activeColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            DataCell(_buildStudentNameCell(student)),  // ✅ Keep this one
            DataCell(
              Text(
                student.admissionNumber ?? '-',
                style: GoogleFonts.inter(color: AppTheme.darkText),
              ),
            ),
            DataCell(
              Text(
                '${student.currentClass ?? ''} ${student.sectionDivision ?? ''}'.trim(),
                style: GoogleFonts.inter(color: AppTheme.darkText),
              ),
            ),
            DataCell(
              Text(
                student.rollNumber ?? '-',
                style: GoogleFonts.inter(color: AppTheme.darkText),
              ),
            ),
            DataCell(
              Text(
                student.mobileNumber ?? '-',
                style: GoogleFonts.inter(color: AppTheme.darkText),
              ),
            ),
            DataCell(
              Text(
                student.fatherName ?? '-',
                style: GoogleFonts.inter(color: AppTheme.darkText),
              ),
            ),
            DataCell(_buildStatusBadge(student.isActive ?? true)),
            DataCell(_buildActionsMenu(context, student)),
          ],

        ))
            .toList(),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppTheme.darkText,
      ),
    );
  }

  Widget _buildStudentNameCell(StudentModel student) {
    return Row(
      children: [
        // Photo Avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
          backgroundImage: student.studentPhotoPath != null && student.studentPhotoPath!.isNotEmpty
              ? NetworkImage(StudentApiService.getStudentPhotoUrl(student.studentPhotoPath!))
              : null,

          onBackgroundImageError: student.studentPhotoPath != null ? (exception, stackTrace) {} : null,
          child: student.studentPhotoPath == null || student.studentPhotoPath!.isEmpty
              ? Text(
            student.firstName[0].toUpperCase(),
            style: GoogleFonts.inter(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          )
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              student.fullName,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.darkText,
              ),
            ),
            Text(
              student.emailId ?? '-',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.bodyText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.accentGreen.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
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

  Widget _buildActionsMenu(BuildContext context, StudentModel student) {
    return PopupMenuButton<String>(
      icon: const Icon(Iconsax.more, size: 20, color: AppTheme.bodyText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Colors.white, // FIX: Ensure pure white background
      surfaceTintColor: Colors.white, // FIX: Ensure pure white background
      onSelected: (value) {
        switch (value) {
          case 'details':
            onTapRow(student);
            break;
          case 'edit':
            onEdit(student);
            break;
          case 'history':
            onViewHistory(student);
            break;
          case 'credentials':
            onUpdateCredentials(context, student);

            break;
          case 'delete':
            onDelete(student);
            break;
        }
      },

      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              const Icon(Iconsax.eye, size: 16, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text('View Details', style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Iconsax.edit_2, size: 16, color: AppTheme.darkText),
              const SizedBox(width: 8),
              Text('Edit', style: GoogleFonts.inter()),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'credentials',
          child: Row(
            children: [
              Icon(Iconsax.key, size: 16, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text(
                'Update Credentials',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Iconsax.trash, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text('Delete',
                  style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== MOBILE CARD (UI Updated for White Background) ====================
class StudentMobileCard extends StatelessWidget {
  final StudentModel student;
  final bool isSelected;
  final Function(bool) onSelectionChanged;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;

  const StudentMobileCard({
    super.key,
    required this.student,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // FIX: Explicitly set color to white to remove the "pinkish white" tint
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => onSelectionChanged(value ?? false),
                    activeColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4), // Square with border radius
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    backgroundImage: student.studentPhotoPath != null && student.studentPhotoPath!.isNotEmpty
                        ? NetworkImage(StudentApiService.getStudentPhotoUrl(student.studentPhotoPath!))
                        : null,
                    onBackgroundImageError: student.studentPhotoPath != null
                        ? (exception, stackTrace) {}
                        : null,
                    child: student.studentPhotoPath == null || student.studentPhotoPath!.isEmpty
                        ? Text(
                      student.firstName[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    )
                        : null,
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.darkText,
                          ),
                        ),
                        Text(
                          'ID: ${student.studentId ?? '-'}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.bodyText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(student.isActive ?? true),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Iconsax.more, color: AppTheme.bodyText),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                    color: Colors.white, // FIX: Ensure pure white background
                    surfaceTintColor: Colors.white, // FIX: Ensure pure white background
                    onSelected: (value) {
                      switch (value) {
                        case 'details':
                          onTap();
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'history':
                          onViewHistory();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            const Icon(Iconsax.eye, size: 16, color: AppTheme.primaryGreen),
                            const SizedBox(width: 8),
                            Text('View Details', style: GoogleFonts.inter(color: AppTheme.primaryGreen)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Iconsax.edit_2, size: 16),
                            const SizedBox(width: 8),
                            Text('Edit', style: GoogleFonts.inter()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'history',
                        child: Row(
                          children: [
                            const Icon(Iconsax.document_text, size: 16),
                            const SizedBox(width: 8),
                            Text('History', style: GoogleFonts.inter()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Iconsax.trash, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Delete',
                                style: GoogleFonts.inter(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildInfoRow(Iconsax.book, 'Class',
                  '${student.currentClass ?? ''} ${student.sectionDivision ?? ''}'
                      .trim()),
              _buildInfoRow(Iconsax.call, 'Mobile', student.mobileNumber ?? '-'),
              _buildInfoRow(Iconsax.user, 'Father', student.fatherName ?? '-'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.accentGreen.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
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
            ),
          ),
        ],
      ),
    );
  }
}


// ==================== DELETE CONFIRMATION DIALOG (UI Updated) ====================
class DeleteConfirmationDialog extends StatefulWidget {
  final StudentModel student;

  const DeleteConfirmationDialog({super.key, required this.student});

  @override
  State<DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  final TextEditingController reasonController = TextEditingController();

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentBloc, StudentState>(
      builder: (context, state) {
        final isDeleting =
            state is StudentOperationInProgressState && state.operation.contains('Deleting');
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          surfaceTintColor: Colors.white,
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
                'Confirm Deletion',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you absolutely sure you want to permanently delete this student record?',
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.darkText),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.student.fullName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.darkText,
                      ),
                    ),
                    Text(
                      'Admission No: ${widget.student.admissionNumber}',
                      style: GoogleFonts.inter(
                        color: AppTheme.bodyText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason for deletion (optional)',
                  labelStyle: GoogleFonts.inter(color: AppTheme.bodyText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  hintText: 'Enter reason...',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action is irreversible. The student data will be archived in the history log.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.red[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppTheme.bodyText),
              ),
            ),
            ElevatedButton(
              onPressed: isDeleting ? null : () => _handleDelete(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: isDeleting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text('Delete Student', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _handleDelete(BuildContext context) {
    context.read<StudentBloc>().add(
      DeleteStudentEvent(
        recNo: widget.student.recNo!,
        operationBy: 'Admin', // Replace with actual user
        reasonForChange: reasonController.text.isEmpty
            ? null
            : reasonController.text,
      ),
    );
    Navigator.pop(context); // Close the dialog immediately
  }
}

// ==================== BULK DELETE DIALOG (UI Updated) ====================
class BulkDeleteDialog extends StatefulWidget {
  final List<int> recNoList;

  const BulkDeleteDialog({super.key, required this.recNoList});

  @override
  State<BulkDeleteDialog> createState() => _BulkDeleteDialogState();
}

class _BulkDeleteDialogState extends State<BulkDeleteDialog> {
  final TextEditingController reasonController = TextEditingController();

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentBloc, StudentState>(
      builder: (context, state) {
        final isDeleting =
            state is StudentOperationInProgressState && state.operation.contains('Deleting');
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          surfaceTintColor: Colors.white,
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete ${widget.recNoList.length} student records?',
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.darkText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason for bulk deletion (optional)',
                  labelStyle: GoogleFonts.inter(color: AppTheme.bodyText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  hintText: 'Enter reason...',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action is irreversible. All selected students will be archived in the history log.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.red[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppTheme.bodyText),
              ),
            ),
            ElevatedButton(
              onPressed: isDeleting ? null : () => _handleBulkDelete(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: isDeleting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text('Delete All (${widget.recNoList.length})', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _handleBulkDelete(BuildContext context) {
    context.read<StudentBloc>().add(
      DeleteStudentsBulkEvent(
        recNoList: widget.recNoList,
        operationBy: 'Admin', // Replace with actual user
        reasonForChange: reasonController.text.isEmpty
            ? null
            : reasonController.text,
      ),
    );
    Navigator.pop(context); // Close the dialog immediately
  }
}

// ==================== HISTORY DIALOG (UI Updated) ====================
class StudentHistoryDialog extends StatefulWidget {
  final StudentModel student;

  const StudentHistoryDialog({super.key, required this.student});

  @override
  State<StudentHistoryDialog> createState() => _StudentHistoryDialogState();
}

class _StudentHistoryDialogState extends State<StudentHistoryDialog> {
  @override
  void initState() {
    super.initState();
    // Clear any previous error state before loading history
    context.read<StudentBloc>().add(ResetStudentStateEvent());
    context
        .read<StudentBloc>()
        .add(LoadStudentHistoryEvent(recNo: widget.student.recNo!));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: Colors.white,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.document_text,
                      color: AppTheme.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record History',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppTheme.darkText,
                        ),
                      ),
                      Text(
                        'Changes for: ${widget.student.fullName}',
                        style: GoogleFonts.inter(
                          color: AppTheme.bodyText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle, color: AppTheme.bodyText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: BlocBuilder<StudentBloc, StudentState>(
                builder: (context, state) {
                  if (state is StudentLoadingState) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    );
                  }

                  if (state is StudentHistoryLoadedState) {
                    if (state.history.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No history records found for this student.',
                            style: GoogleFonts.inter(color: AppTheme.bodyText),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: state.history.length,
                      itemBuilder: (context, index) {
                        final record = state.history[index];
                        return _buildHistoryItem(record);
                      },
                    );
                  }

                  if (state is StudentErrorState) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'Error loading history: ${state.error}',
                          style: GoogleFonts.inter(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> record) {
    final operationType = record['Operation_Type'] ?? 'N/A';
    final operationDate = record['Operation_Date'] ?? '';
    final operationBy = record['Operation_By'] ?? '-';
    final reason = record['Reason_For_Change'] ?? '-';

    final isDelete = operationType == 'DELETE';
    final color = isDelete ? Colors.red : AppTheme.accentGreen;
    final icon = isDelete ? Iconsax.trash : Iconsax.edit_2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  operationType,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(operationDate),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.bodyText,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildInfoRow('Performed By', operationBy),
          if (reason != '-') _buildInfoRow('Reason/Note', reason),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.bodyText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class StudentDetailsDialog extends StatefulWidget {
  final StudentModel student;

  const StudentDetailsDialog({super.key, required this.student});

  @override
  State<StudentDetailsDialog> createState() => _StudentDetailsDialogState();
}

class _StudentDetailsDialogState extends State<StudentDetailsDialog> {
  final StudentApiService apiService = StudentApiService();

  String? permanentAddressDisplay;
  String? currentAddressDisplay;
  bool isLoadingAddresses = true;

  @override
  void initState() {
    super.initState();
    _loadAddressDetails();
  }

  // ✅ Load real address names on dialog open
  Future<void> _loadAddressDetails() async {
    try {
      // Load permanent address
      if (widget.student.permanentStateId != null) {
        permanentAddressDisplay = await apiService.getCompleteAddress(
          streetAddress: widget.student.permanentAddress,
          cityId: widget.student.permanentCityId,
          districtId: widget.student.permanentDistrictId,
          stateId: widget.student.permanentStateId,
          country: widget.student.permanentCountry,
          pin: widget.student.permanentPIN,
        );
      }

      // Load current address
      if (widget.student.currentStateId != null) {
        currentAddressDisplay = await apiService.getCompleteAddress(
          streetAddress: widget.student.currentAddress,
          cityId: widget.student.currentCityId,
          districtId: widget.student.currentDistrictId,
          stateId: widget.student.currentStateId,
          country: widget.student.currentCountry,
          pin: widget.student.currentPIN,
        );
      }

      setState(() {
        isLoadingAddresses = false;
      });
    } catch (e) {
      print("❌ Error loading address details: $e");
      setState(() {
        isLoadingAddresses = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width > 1000 ? 900 : 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    buildSection('Basic Information', Iconsax.user_octagon, [
                      buildInfoRow('Student ID', widget.student.studentId),
                      buildInfoRow('Admission No.', widget.student.admissionNumber),
                      buildInfoRow('Full Name', widget.student.fullName),
                      buildInfoRow('Gender', widget.student.gender),
                      buildInfoRow('Date of Birth', widget.student.dateOfBirth),
                      buildInfoRow('Blood Group', widget.student.bloodGroup),
                      buildInfoRow('Nationality', widget.student.nationality),
                      buildInfoRow('Religion', widget.student.religion),
                      buildInfoRow('Category', widget.student.category),
                    ]),

                    buildSection('Contact Information', Iconsax.call, [
                      buildInfoRow('Mobile Number', widget.student.mobileNumber),
                      buildInfoRow('Email ID', widget.student.emailId),

                      // ✅ UPDATED: Show real address with names
                      isLoadingAddresses
                          ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      )
                          : buildInfoRow('Permanent Address', permanentAddressDisplay),

                      isLoadingAddresses
                          ? const SizedBox.shrink()
                          : buildInfoRow('Current Address', currentAddressDisplay),
                    ]),

                    buildSection('Parent/Guardian', Iconsax.people, [
                      buildInfoRow('Father Name', widget.student.fatherName),
                      buildInfoRow('Father Mobile', widget.student.fatherMobileNumber),
                      buildInfoRow('Mother Name', widget.student.motherName),
                      buildInfoRow('Mother Mobile', widget.student.motherMobileNumber),
                      buildInfoRow('Guardian Name', widget.student.guardianName),
                    ]),

                    buildSection('Academic Information', Iconsax.book, [
                      buildInfoRow('Admission Date', widget.student.admissionDate),
                      buildInfoRow('Current Class', '${widget.student.currentClass ?? ''} ${widget.student.sectionDivision ?? ''}'.trim()),
                      buildInfoRow('Roll Number', widget.student.rollNumber),
                      buildInfoRow('Academic Year', widget.student.academicYear),
                      buildInfoRow('Previous School', widget.student.previousSchoolName),
                      buildInfoRow('Medium', widget.student.mediumOfInstruction),
                    ]),

                    buildSection('Other Details', Iconsax.info_circle, [
                      buildInfoRow('Active Status', (widget.student.isActive ?? true) ? 'Active' : 'Inactive', isStatus: true),
                      buildInfoRow('Hostel Facility', (widget.student.hostelFacility ?? false) ? 'Yes' : 'No'),
                      buildInfoRow('Transport Facility', (widget.student.transportFacility ?? false) ? 'Yes' : 'No'),
                      buildInfoRow('Bus Route', widget.student.busRouteNo),
                      buildInfoRow('Scholarship Aid', (widget.student.scholarshipFinancialAid ?? false) ? 'Yes' : 'No'),
                      buildInfoRow('Special Needs', widget.student.specialNeedsDisability),
                      buildInfoRow('Extra Curricular', widget.student.extraCurricularInterests),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Rest of your existing methods (buildHeader, buildSection, buildInfoRow)...
  // (Keep all the existing helper methods as they are)

  Widget buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
            backgroundImage: (widget.student.studentPhotoPath != null && widget.student.studentPhotoPath!.isNotEmpty)
                ? NetworkImage(StudentApiService.getStudentPhotoUrl(widget.student.studentPhotoPath!))
                : null,
            child: (widget.student.studentPhotoPath == null || widget.student.studentPhotoPath!.isEmpty)
                ? Text(
              widget.student.firstName[0].toUpperCase(),
              style: GoogleFonts.inter(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 20,
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
                  widget.student.fullName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppTheme.darkText,
                  ),
                ),
                Text(
                  widget.student.emailId ?? 'No Email Provided',
                  style: GoogleFonts.inter(
                    color: AppTheme.bodyText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.close_circle, color: AppTheme.bodyText),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget buildSection(String title, IconData icon, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 40,
            runSpacing: 12,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(String label, String? value, {bool isStatus = false}) {
    final displayValue = (value?.isNotEmpty == true) ? value! : '-';
    final isActive = value == 'Active';

    return SizedBox(
      width: 380,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.bodyText,
              ),
            ),
          ),
          Expanded(
            child: isStatus
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.accentGreen.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                displayValue,
                style: GoogleFonts.inter(
                  color: isActive ? AppTheme.accentGreen : Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
                : Text(
              displayValue,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ==================== STYLED CONTAINER ====================
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