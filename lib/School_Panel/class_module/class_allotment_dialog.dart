// class_allotment_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'class_bloc.dart';
import 'class_model.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'class_service.dart';
// Note: _SSearchableDropdown definition is included at the bottom of this file.


class ClassAllotmentDialog extends StatefulWidget {
  final ClassModel classModel;
  final int schoolID;

  const ClassAllotmentDialog({
    super.key,
    required this.classModel,
    required this.schoolID,
  });

  @override
  State<ClassAllotmentDialog> createState() => _ClassAllotmentDialogState();
}

class _ClassAllotmentDialogState extends State<ClassAllotmentDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Class Teacher', 'Subjects', 'Subject Allotments'];

  // Search Controllers
  final TextEditingController _availableSubjectSearchController = TextEditingController();
  final TextEditingController _assignedSubjectSearchController = TextEditingController();

  // Teacher Tab State
  int? _selectedClassTeacherRecNo;

  // Subject Tab State
  List<SubjectOptionModel> _availableSubjects = [];
  List<ClassSubjectModel> _assignedSubjects = [];
  Set<int> _selectedNewSubjectIDs = {};

  // Allotment Tab State
  List<SubjectTeacherAllotmentModel> _allotments = [];

  // Filtered lists
  List<SubjectOptionModel> _filteredAvailableSubjects = [];
  List<ClassSubjectModel> _filteredAssignedSubjects = [];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadAllotmentData();

    _availableSubjectSearchController.addListener(_filterSubjects);
    _assignedSubjectSearchController.addListener(_filterSubjects);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _availableSubjectSearchController.dispose();
    _assignedSubjectSearchController.dispose();
    super.dispose();
  }

  void _loadAllotmentData() {
    context.read<ClassBloc>().add(LoadAllotmentDataEvent(
      classRecNo: widget.classModel.classRecNo!,
      schoolID: widget.schoolID,
      academicYear: widget.classModel.academicYear,
    ));
  }

  void _filterSubjects() {
    final availableQuery = _availableSubjectSearchController.text.toLowerCase().trim();
    final assignedQuery = _assignedSubjectSearchController.text.toLowerCase().trim();

    setState(() {
      // Filter for available subjects
      _filteredAvailableSubjects = _availableSubjects.where((sub) {
        return sub.subjectName.toLowerCase().contains(availableQuery) ||
            (sub.subjectCode?.toLowerCase().contains(availableQuery) ?? false);
      }).toList();

      // Filter for assigned subjects
      _filteredAssignedSubjects = _assignedSubjects.where((sub) {
        return (sub.displayName ?? sub.subjectName).toLowerCase().contains(assignedQuery) ||
            (sub.subjectCode?.toLowerCase().contains(assignedQuery) ?? false);
      }).toList();
    });
  }

  void _handleStateChanges(ClassState state) {
    if (state is AllotmentDataLoadedState) {
      setState(() {
        _selectedClassTeacherRecNo = state.classDetails.classTeacherRecNo;
        _availableSubjects = state.availableSubjects;
        _assignedSubjects = state.assignedSubjects;
        _allotments = state.subjectAllotments;

        // Reset search/filters and selection on successful load
        _filterSubjects();
        _selectedNewSubjectIDs.removeWhere((id) => _assignedSubjects.any((sub) => sub.subjectID == id));
      });
    } else if (state is ClassOperationSuccessState) {
      CustomSnackbar.showSuccess(context, state.message);
    } else if (state is ClassErrorState) {
      CustomSnackbar.showError(context, state.error);
    }
  }

  // ==================== TEACHER ALLOTMENT LOGIC ====================
  void _changeClassTeacher(int? teacherRecNo) {
    // If null is passed, it means unassigned (recNo 0 in API)
    final effectiveRecNo = teacherRecNo ?? 0;
    if (effectiveRecNo == _selectedClassTeacherRecNo) return;
    final operationBy = Provider.of<UserProvider>(context, listen: false).userName ?? 'Admin';
    context.read<ClassBloc>().add(ChangeClassTeacherEvent(
      classRecNo: widget.classModel.classRecNo!,
      classTeacherRecNo: effectiveRecNo,
      schoolID: widget.schoolID,
      operationBy: operationBy,
    ));
  }

  // ==================== SUBJECT ASSIGNMENT/REMOVAL LOGIC ====================
  void _addSelectedSubjects() {
    if (_selectedNewSubjectIDs.isEmpty) {
      CustomSnackbar.showError(context, 'Please select at least one subject to add.');
      return;
    }

    final operationBy = Provider.of<UserProvider>(context, listen: false).userName ?? 'Admin';
    context.read<ClassBloc>().add(AddSubjectsToClassEvent(
      classRecNo: widget.classModel.classRecNo!,
      subjectIDs: _selectedNewSubjectIDs.toList(),
      schoolID: widget.schoolID,
      academicYear: widget.classModel.academicYear,
      operationBy: operationBy,
    ));
    setState(() {
      _selectedNewSubjectIDs.clear();
    });
  }

  void _showRemoveSubjectConfirmationDialog(ClassSubjectModel subject) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Remove Subject: ${subject.displayName ?? subject.subjectName}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.red)),
          content: Text(
            'Are you sure you want to remove the subject "${subject.displayName ?? subject.subjectName}" from this class? This will also remove any existing teacher allotments for this subject.',
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
                context.read<ClassBloc>().add(RemoveSubjectFromClassEvent(
                  classRecNo: widget.classModel.classRecNo!,
                  subjectID: subject.subjectID,
                  schoolID: widget.schoolID,
                  academicYear: widget.classModel.academicYear,
                  operationBy: operationBy,
                ));
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Remove Subject', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }


  // ==================== SUBJECT-TEACHER ALLOTMENT LOGIC ====================
  void _showTeacherAllotmentDialog(ClassSubjectModel subject) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<ClassBloc>(context),
          child: _TeacherAllotmentForm(
            classRecNo: widget.classModel.classRecNo!,
            subject: SubjectOptionModel(
              subjectID: subject.subjectID,
              subjectName: subject.subjectName,
              subjectCode: subject.subjectCode,
            ),
            allAvailableTeachers: (context.read<ClassBloc>().state is AllotmentDataLoadedState)
                ? (context.read<ClassBloc>().state as AllotmentDataLoadedState).availableTeachers
                : [],
            schoolID: widget.schoolID,
            academicYear: widget.classModel.academicYear,
          ),
        );
      },
    );
  }

  void _removeSubjectAllotment(SubjectTeacherAllotmentModel allotment) {
    final operationBy = Provider.of<UserProvider>(context, listen: false).userName ?? 'Admin';
    context.read<ClassBloc>().add(RemoveSubjectAllotmentEvent(
      subjectID: allotment.subjectID,
      classRecNo: widget.classModel.classRecNo!,
      teacherRecNo: allotment.teacherRecNo,
      schoolID: widget.schoolID,
      academicYear: widget.classModel.academicYear,
      operationBy: operationBy,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 1000 ? 900.0 : (screenWidth > 600 ? 600.0 : screenWidth * 0.9);
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: Colors.white,
      child: ConstrainedBox( // Ensures maximum size is respected on larger screens
        constraints: BoxConstraints(maxHeight: isMobile ? 600 : 700, maxWidth: dialogWidth),
        child: BlocConsumer<ClassBloc, ClassState>(
          listener: (context, state) => _handleStateChanges(state),
          builder: (context, state) {
            final isLoading = state is ClassLoadingState;
            final isOperationInProgress = state is AllotmentOperationInProgressState;
            return Column(
              children: [
                _buildHeader(context, isLoading, isOperationInProgress),
                TabBar(
                  controller: _tabController,
                  isScrollable: isMobile,
                  indicatorColor: AppTheme.primaryGreen,
                  labelColor: AppTheme.primaryGreen,
                  unselectedLabelColor: AppTheme.bodyText,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 13),
                  tabs: _tabs.map((title) => Tab(text: title)).toList(),
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildClassTeacherTab(state, isMobile),
                      _buildSubjectsTab(state, isMobile),
                      _buildSubjectAllotmentsTab(state),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLoading, bool isOperationInProgress) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.building, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.classModel.fullName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: isMobile ? 18 : 20, color: AppTheme.darkText),
                ),
                Text(
                  isOperationInProgress
                      ? (context.read<ClassBloc>().state as AllotmentOperationInProgressState).operation
                      : 'Academic Year: ${widget.classModel.academicYear}',
                  style: GoogleFonts.inter(color: AppTheme.bodyText, fontSize: isMobile ? 12 : 14),
                ),
              ],
            ),
          ),
          if (isLoading || isOperationInProgress)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen)),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Iconsax.close_circle, color: AppTheme.bodyText),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 1: CLASS TEACHER (RESPONSIVE) ====================
  Widget _buildClassTeacherTab(ClassState state, bool isMobile) {
    if (state is ClassLoadingState) return _buildLoading(state.message);
    if (state is AllotmentOperationInProgressState) return _buildLoading(state.operation);
    if (state is! AllotmentDataLoadedState) return const SizedBox.shrink();

    final availableTeachers = state.availableTeachers;
    final currentTeacher = availableTeachers.firstWhere(
          (t) => t.recNo == _selectedClassTeacherRecNo,
      orElse: () => TeacherOptionModel(recNo: 0, name: 'Unassigned'),
    );

    // Create a list with an 'Unassigned' option
    final teachersWithOptions = List<TeacherOptionModel>.from(availableTeachers);
    final unassignedOption = TeacherOptionModel(recNo: 0, name: '--- Unassign Teacher ---');

    if (teachersWithOptions.where((t) => t.recNo == 0).isEmpty) {
      teachersWithOptions.insert(0, unassignedOption);
    }


    return SingleChildScrollView( // Added to ensure mobile scrollability
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Class Teacher', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: isMobile ? 14 : 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, // Pure white
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderGrey),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.user_tag, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentTeacher.name.isEmpty || currentTeacher.recNo == 0 ? 'Not Assigned' : currentTeacher.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: isMobile ? 14 : 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Change Class Teacher', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: isMobile ? 14 : 16)),
          const SizedBox(height: 12),
          // Searchable Dropdown
          _SSearchableDropdown<TeacherOptionModel>(
            hintText: 'Select New Teacher',
            icon: Iconsax.teacher,
            items: teachersWithOptions,
            itemToString: (teacher) => teacher.name,
            initialValue: currentTeacher.recNo == 0 ? null : currentTeacher,
            isRequired: false,
            onChanged: (teacher) {
              // Map null or 'Unassigned' (recNo 0) back to null for the BLoC event
              _changeClassTeacher(teacher?.recNo == 0 ? null : teacher?.recNo);
            },
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: SUBJECTS (UPDATED WITH DELETE & SEARCH) ====================
  Widget _buildSubjectsTab(ClassState state, bool isMobile) {
    if (state is ClassLoadingState) return _buildLoading(state.message);
    if (state is AllotmentOperationInProgressState) return _buildLoading(state.operation);
    if (state is! AllotmentDataLoadedState) return const SizedBox.shrink();

    // FIX: Define filteredUnassignedSubjects locally for use in the list
    final unassignedSubjects = _availableSubjects.where((s) => !_assignedSubjects.any((assigned) => assigned.subjectID == s.subjectID)).toList();
    final filteredUnassignedSubjects = unassignedSubjects.where((sub) {
      final query = _availableSubjectSearchController.text.toLowerCase();
      return sub.subjectName.toLowerCase().contains(query) || (sub.subjectCode?.toLowerCase().contains(query) ?? false);
    }).toList();


    Widget assignedSubjectsList = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // Pure white
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        children: [
          _buildSearchField(_assignedSubjectSearchController, 'Search assigned subjects...', isMobile),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredAssignedSubjects.isEmpty
                ? Center(child: Text('No assigned subjects match search.', style: GoogleFonts.inter(color: AppTheme.bodyText, fontSize: isMobile ? 12 : 14)))
                : ListView.builder(
              itemCount: _filteredAssignedSubjects.length,
              itemBuilder: (context, index) {
                final sub = _filteredAssignedSubjects[index];
                return _buildAssignedSubjectCard(sub);
              },
            ),
          ),
        ],
      ),
    );

    Widget availableSubjectsList = Column(
      children: [
        _buildSearchField(_availableSubjectSearchController, 'Search available subjects...', isMobile),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderGrey),
            ),
            child: filteredUnassignedSubjects.isEmpty
                ? Center(child: Text('All available subjects assigned or no subjects match search.', style: GoogleFonts.inter(color: AppTheme.bodyText, fontSize: isMobile ? 12 : 14)))
                : ListView.builder(
              itemCount: filteredUnassignedSubjects.length,
              itemBuilder: (context, index) {
                final sub = filteredUnassignedSubjects[index];
                final isSelected = _selectedNewSubjectIDs.contains(sub.subjectID);
                return CheckboxListTile(
                  dense: isMobile,
                  title: Text(sub.subjectName, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: isMobile ? 13 : 14)),
                  subtitle: Text('Code: ${sub.subjectCode ?? '-'}', style: GoogleFonts.inter(fontSize: 12)),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedNewSubjectIDs.add(sub.subjectID);
                      } else {
                        _selectedNewSubjectIDs.remove(sub.subjectID);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppTheme.primaryGreen,
                  checkColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _selectedNewSubjectIDs.isEmpty ? null : _addSelectedSubjects,
            icon: const Icon(Iconsax.add_square, size: 18),
            label: Text('Add ${_selectedNewSubjectIDs.isEmpty ? 'Subjects' : '${_selectedNewSubjectIDs.length} Subject(s)'}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assigned Subjects', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: isMobile ? 14 : 16)),
              Text('Available Subjects', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: isMobile ? 14 : 16)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isMobile
                ? SingleChildScrollView(
              child: Column(
                children: [
                  // FIX: Use SizedBox to give the Expanded list a bounded height on mobile
                  SizedBox(height: 300, child: assignedSubjectsList),
                  const SizedBox(height: 20),
                  SizedBox(height: 400, child: availableSubjectsList),
                ],
              ),
            )
                : Row(
              children: [
                Expanded(child: assignedSubjectsList),
                const SizedBox(width: 20),
                Expanded(child: availableSubjectsList),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedSubjectCard(ClassSubjectModel sub) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          Iconsax.book,
          color: sub.hasTeacher ? AppTheme.primaryGreen : AppTheme.bodyText,
          size: isMobile ? 20 : 24,
        ),
        title: Text(
            sub.displayName ?? sub.subjectName,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: isMobile ? 14 : 15)),
        subtitle: sub.hasTeacher
            ? Text(
          'Teacher: ${sub.teacherName}',
          style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 12),
        )
            : const Text(
          'No teacher assigned',
          style: TextStyle(color: Colors.orange, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Allotment / Edit Teacher Button
            IconButton(
              icon: Icon(
                sub.hasTeacher ? Iconsax.edit : Iconsax.user_add,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              onPressed: () => _showTeacherAllotmentDialog(sub),
              tooltip: sub.hasTeacher ? 'Change Teacher' : 'Assign Teacher',
            ),
            // Remove Subject Button (NEW)
            IconButton(
              icon: const Icon(
                Iconsax.trash,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _showRemoveSubjectConfirmationDialog(sub),
              tooltip: 'Remove Subject from Class',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(TextEditingController controller, String hintText, bool isMobile) {
    return Container(
      height: isMobile ? 44 : 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: AppTheme.bodyText.withOpacity(0.6),
            fontSize: isMobile ? 12 : 14,
          ),
          prefixIcon: Icon(Iconsax.search_normal_1, size: isMobile ? 18 : 20, color: AppTheme.bodyText),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Iconsax.close_circle, size: 20),
            onPressed: controller.clear,
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isMobile ? 10 : 14),
        ),
      ),
    );
  }

  // ==================== TAB 3: SUBJECT ALLOTMENTS ====================
  Widget _buildSubjectAllotmentsTab(ClassState state) {
    if (state is ClassLoadingState) return _buildLoading(state.message);
    if (state is AllotmentOperationInProgressState) return _buildLoading(state.operation);
    if (state is! AllotmentDataLoadedState) return const SizedBox.shrink();

    final subjectsWithNoAllotment = _assignedSubjects.where((sub) => !_allotments.any((allot) => allot.subjectID == sub.subjectID)).toList();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildAllotmentHeader(subjectsWithNoAllotment, isMobile),
          const Divider(height: 20),
          Expanded(
            child: _allotments.isEmpty
                ? Center(child: Text('No teacher allotments found.', style: GoogleFonts.inter(color: AppTheme.bodyText)))
                : ListView.builder(
              itemCount: _allotments.length,
              itemBuilder: (context, index) {
                final allotment = _allotments[index];
                return _buildAllotmentCard(allotment, isMobile); // Pass isMobile
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllotmentHeader(List<ClassSubjectModel> subjectsWithNoAllotment, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
              'Subject-Teacher Allotments (${_allotments.length})',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: isMobile ? 14 : 16)
          ),
        ),
        if (subjectsWithNoAllotment.isNotEmpty)
          PopupMenuButton<ClassSubjectModel>(
            onSelected: _showTeacherAllotmentDialog,
            itemBuilder: (context) => subjectsWithNoAllotment.map((sub) {
              return PopupMenuItem<ClassSubjectModel>(
                value: sub,
                child: Text('Allot Teacher for ${sub.subjectName}'),
              );
            }).toList(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.add, color: Colors.white, size: isMobile ? 16 : 18),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    Text('Allot New Teacher', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ),
        if (subjectsWithNoAllotment.isEmpty) Flexible(child: Text('All subjects have a teacher.', style: GoogleFonts.inter(color: AppTheme.accentGreen, fontSize: isMobile ? 12 : 14))),
      ],
    );
  }

  Widget _buildAllotmentCard(SubjectTeacherAllotmentModel allotment, bool isMobile) {
    final dateFormatter = DateFormat('MMM dd, yyyy');

    // --- Mobile Layout (Column) ---
    if (isMobile) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Iconsax.book_square, color: AppTheme.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allotment.subjectName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.darkText),
                        ),
                        Text(
                          'Teacher: ${allotment.teacherName}',
                          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.bodyText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeSubjectAllotment(allotment),
                    icon: const Icon(Iconsax.trash, color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.bodyText),
                      ),
                      Text(
                        allotment.isActive == 1 ? 'Active' : 'Inactive',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: allotment.isActive == 1 ? AppTheme.accentGreen : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Period',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.bodyText),
                      ),
                      Text(
                        '${dateFormatter.format(DateTime.parse(allotment.startDate))} - ${dateFormatter.format(DateTime.parse(allotment.endDate))}',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // --- Desktop Layout (Row) ---
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.book_square, color: AppTheme.primaryGreen, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allotment.subjectName,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.darkText),
                  ),
                  Text(
                    'Teacher: ${allotment.teacherName}',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.bodyText),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${dateFormatter.format(DateTime.parse(allotment.startDate))} - ${dateFormatter.format(DateTime.parse(allotment.endDate))}',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  allotment.isActive == 1 ? 'Active' : 'Inactive',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: allotment.isActive == 1 ? AppTheme.accentGreen : Colors.red,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeSubjectAllotment(allotment),
                  icon: const Icon(Iconsax.trash, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryGreen),
            const SizedBox(height: 16),
            Text(message, style: GoogleFonts.inter(color: AppTheme.bodyText)),
          ],
        ),
      ),
    );
  }
}

// ==================== TEACHER ALLOTMENT FORM (UPDATED WITH SEARCH) ====================
class _TeacherAllotmentForm extends StatefulWidget {
  final int classRecNo;
  final SubjectOptionModel subject;
  final List<TeacherOptionModel> allAvailableTeachers;
  final int schoolID;
  final String academicYear;

  const _TeacherAllotmentForm({
    required this.classRecNo,
    required this.subject,
    required this.allAvailableTeachers,
    required this.schoolID,
    required this.academicYear,
  });

  @override
  State<_TeacherAllotmentForm> createState() => _TeacherAllotmentFormState();
}

class _TeacherAllotmentFormState extends State<_TeacherAllotmentForm> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedTeacherRecNo;
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  // Used for SSearchableDropdown
  TeacherOptionModel? _selectedTeacherModel;


  @override
  void initState() {
    super.initState();
    // Default dates
    _startDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _endDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 365)));
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }


  void _allotTeacher() {
    if (!_formKey.currentState!.validate() || _selectedTeacherModel == null) {
      CustomSnackbar.showError(context, 'Please select a teacher and valid dates.');
      return;
    }

    final operationBy = Provider.of<UserProvider>(context, listen: false).userName ?? 'Admin';
    context.read<ClassBloc>().add(AllotSubjectTeacherEvent(
      classRecNo: widget.classRecNo,
      subjectID: widget.subject.subjectID,
      teacherRecNo: _selectedTeacherModel!.recNo, // Use the recNo from the selected model
      schoolID: widget.schoolID,
      startDate: _startDateController.text,
      endDate: _endDateController.text,
      academicYear: widget.academicYear,
      operationBy: operationBy,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 450.0 : screenWidth * 0.9;
    final isMobile = screenWidth < 600;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Allot Teacher for: ${widget.subject.subjectName}',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: isMobile ? 16 : 18),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teacher Dropdown (using SSearchableDropdown)
                _SSearchableDropdown<TeacherOptionModel>(
                  hintText: 'Select Teacher',
                  icon: Iconsax.teacher,
                  items: widget.allAvailableTeachers,
                  itemToString: (teacher) => teacher.name,
                  initialValue: _selectedTeacherModel,
                  isRequired: true,
                  onChanged: (teacher) {
                    setState(() {
                      _selectedTeacherModel = teacher;
                      _selectedTeacherRecNo = teacher?.recNo;
                    });
                  },
                ),

                const SizedBox(height: 20),
                Text('Allotment Period', style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.w600, color: AppTheme.darkText)),
                const SizedBox(height: 8),

                // Date Fields (Responsive Row)
                isMobile
                    ? Column(
                  children: [
                    _buildDateField('Start Date', _startDateController, isMobile),
                    const SizedBox(height: 16),
                    _buildDateField('End Date', _endDateController, isMobile),
                  ],
                )
                    : Row(
                  children: [
                    Expanded(child: _buildDateField('Start Date', _startDateController, isMobile)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDateField('End Date', _endDateController, isMobile)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.bodyText)),
        ),
        ElevatedButton(
          onPressed: _allotTeacher,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Allot Teacher', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, bool isMobile) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: GoogleFonts.inter(color: AppTheme.darkText, fontSize: isMobile ? 13 : 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppTheme.bodyText, fontSize: isMobile ? 13 : 14),
        suffixIcon: const Icon(Iconsax.calendar, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderGrey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
      ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: controller.text.isNotEmpty ? DateTime.tryParse(controller.text) ?? DateTime.now() : DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      },
      validator: (value) => value == null || value.isEmpty ? '$label is required' : null,
    );
  }
}

// ============================================================================
// REUSABLE UI WIDGETS (SSearchableDropdown, copied to ensure local function)
// ============================================================================
class _SSearchableDropdown<T> extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final T? initialValue;
  final List<T> items;
  final String Function(T) itemToString;
  final void Function(T?)? onChanged;
  final bool isRequired;

  const _SSearchableDropdown({
    Key? key,
    required this.hintText,
    required this.icon,
    required this.items,
    required this.itemToString,
    required this.onChanged,
    this.initialValue,
    this.isRequired = false,
  }) : super(key: key);

  @override
  State<_SSearchableDropdown<T>> createState() => _SSearchableDropdownState<T>();
}
class _SSearchableDropdownState<T> extends State<_SSearchableDropdown<T>> {
  T? selectedValue;
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final LayerLink layerLink = LayerLink();
  OverlayEntry? overlayEntry;
  List<T> filteredItems = [];

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
    filteredItems = widget.items;
    searchController.addListener(filterItems);
    focusNode.addListener(onFocusChange);

    if (selectedValue != null) {
      searchController.text = widget.itemToString(selectedValue as T);
    }
  }

  @override
  void didUpdateWidget(_SSearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialValue != oldWidget.initialValue) {
      selectedValue = widget.initialValue;
      if (selectedValue != null) {
        searchController.text = widget.itemToString(selectedValue as T);
      } else {
        searchController.clear();
      }
      filteredItems = widget.items;
    }
  }

  @override
  void dispose() {
    searchController.removeListener(filterItems);
    focusNode.removeListener(onFocusChange);
    searchController.dispose();
    focusNode.dispose();
    overlayEntry?.remove();
    super.dispose();
  }

  void filterItems() {
    setState(() {
      if (searchController.text.isEmpty) {
        filteredItems = widget.items;
      } else {
        filteredItems = widget.items.where((item) {
          final itemString = widget.itemToString(item).toLowerCase();
          final searchString = searchController.text.toLowerCase();
          return itemString.contains(searchString);
        }).toList();
      }
    });
    if (overlayEntry != null) {
      overlayEntry!.markNeedsBuild();
    }
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      setState(() {
        filteredItems = widget.items;
      });
      showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!focusNode.hasFocus && overlayEntry != null) {
          removeOverlay();
          if (mounted) {
            setState(() {
              if (selectedValue != null) {
                searchController.text = widget.itemToString(selectedValue as T);
              } else {
                searchController.clear();
              }
            });
          }
        }
      });
    }
  }

  void showOverlay() {
    if (overlayEntry == null) {
      overlayEntry = createOverlayEntry();
      Overlay.of(context).insert(overlayEntry!);
    } else {
      overlayEntry!.markNeedsBuild();
    }
  }

  void removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  OverlayEntry createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGrey, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isSelected = item == selectedValue;

                    return InkWell(
                      onTap: () {
                        final selectedItem = item;
                        final selectedText = widget.itemToString(selectedItem);

                        setState(() {
                          selectedValue = selectedItem;
                          searchController.text = selectedText;
                        });

                        widget.onChanged?.call(selectedItem);

                        removeOverlay();
                        focusNode.unfocus();
                      },
                      child: Container(
                        color: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : null,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.itemToString(item),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: isSelected ? AppTheme.primaryGreen : AppTheme.darkText,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Iconsax.tick_circle,
                                size: 16,
                                color: AppTheme.primaryGreen,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              children: [
                Text(
                  widget.hintText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: focusNode.hasFocus ? AppTheme.primaryGreen : AppTheme.borderGrey,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: focusNode.hasFocus
                      ? AppTheme.primaryGreen.withOpacity(0.1)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              focusNode: focusNode,
              readOnly: false,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.darkText,
              ),
              decoration: InputDecoration(
                hintText: 'Search or ${widget.hintText.toLowerCase()}',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.bodyText.withOpacity(0.5),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                suffixIcon: Icon(
                  Iconsax.arrow_down_1,
                  size: 18,
                  color: AppTheme.primaryGreen,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}