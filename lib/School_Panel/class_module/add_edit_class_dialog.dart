// add_edit_class_dialog.dart - COMPLETE WITH ACADEMIC YEAR DROPDOWN
// Updated: October 25, 2025, 10:23 PM IST

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:provider/provider.dart';
import 'class_bloc.dart';
import 'class_model.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';

import 'class_service.dart';
// Imported necessary widgets from class_allotment_dialog.dart
import 'class_allotment_dialog.dart';


class AddEditClassDialog extends StatefulWidget {
  final int schoolID;
  final ClassModel? classModel;

  const AddEditClassDialog({
    super.key,
    required this.schoolID,
    this.classModel,
  });

  @override
  State<AddEditClassDialog> createState() => _AddEditClassDialogState();
}

class _AddEditClassDialogState extends State<AddEditClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _classCodeController = TextEditingController();
  final _sectionNameController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _maxCapacityController = TextEditingController();

  bool _isActive = true;
  int? _selectedClassID;
  int? _selectedClassTeacherRecNo;
  String? _selectedAcademicYear;

  List<MasterClassOption> _masterClasses = [];
  List<TeacherOptionModel> _availableTeachers = [];
  List<String> _academicYearOptions = [];

  bool _isLoadingMasterClasses = true;
  bool _isLoadingTeachers = true;

  bool get isEditMode => widget.classModel != null;

  @override
  void initState() {
    super.initState();
    _generateAcademicYearOptions();
    _fetchMasterClasses();
    _fetchAvailableTeachers();
    if (isEditMode) {
      _initializeEditMode();
    }
  }

  void _generateAcademicYearOptions() {
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    final currentAcademicStartYear = currentMonth >= 4 ? currentYear : currentYear - 1;

    _academicYearOptions = List.generate(11, (index) {
      final startYear = currentAcademicStartYear - 5 + index;
      final endYear = startYear + 1;
      return '$startYear-${endYear.toString().substring(2)}';
    });

    _selectedAcademicYear = widget.classModel?.academicYear ?? '$currentAcademicStartYear-${(currentAcademicStartYear + 1).toString().substring(2)}';
  }

  void _initializeEditMode() {
    final cls = widget.classModel!;
    _selectedClassID = cls.classID;
    _selectedAcademicYear = cls.academicYear;
    _classCodeController.text = cls.classCode;
    _sectionNameController.text = cls.sectionName;
    _roomNumberController.text = cls.roomNumber ?? '';
    _maxCapacityController.text = cls.maxStudentCapacity?.toString() ?? '';
    _isActive = cls.isActive;
    _selectedClassTeacherRecNo = cls.classTeacherRecNo;
  }

  Future<void> _fetchMasterClasses() async {
    setState(() => _isLoadingMasterClasses = true);
    try {
      final apiService = ClassApiService();
      _masterClasses = await apiService.fetchMasterClasses(schoolID: widget.schoolID);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load classes: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoadingMasterClasses = false);
    }
  }

  Future<void> _fetchAvailableTeachers() async {
    setState(() => _isLoadingTeachers = true);
    try {
      final apiService = ClassApiService();
      _availableTeachers = await apiService.fetchAvailableTeachers(schoolID: widget.schoolID);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load teachers: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoadingTeachers = false);
    }
  }

  @override
  void dispose() {
    _classCodeController.dispose();
    _sectionNameController.dispose();
    _roomNumberController.dispose();
    _maxCapacityController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClassID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedAcademicYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an academic year'), backgroundColor: Colors.red),
      );
      return;
    }

    final operationBy = Provider.of<UserProvider>(context, listen: false).userName ?? 'Admin';

    final selectedClass = _masterClasses.firstWhere((c) => c.classID == _selectedClassID);

    final classData = ClassModel(
      classRecNo: widget.classModel?.classRecNo,
      schoolID: widget.schoolID,
      classID: _selectedClassID!,
      className: selectedClass.className,
      classCode: _classCodeController.text.trim(),
      sectionName: _sectionNameController.text.trim(),
      roomNumber: _roomNumberController.text.trim().isNotEmpty ? _roomNumberController.text.trim() : null,
      maxStudentCapacity: int.tryParse(_maxCapacityController.text.trim()),
      academicYear: _selectedAcademicYear!,
      classTeacherRecNo: _selectedClassTeacherRecNo,
      isActive: _isActive,
    );

    if (isEditMode) {
      context.read<ClassBloc>().add(UpdateClassEvent(
        classData: classData,
        operationBy: operationBy,
      ));
    } else {
      context.read<ClassBloc>().add(AddClassEvent(
        classData: classData,
        operationBy: operationBy,
      ));
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 700 ? 500.0 : screenWidth * 0.9;
    final isMobile = screenWidth < 700;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: Colors.white,
      title: Row(
        children: [
          Icon(isEditMode ? Iconsax.edit_2 : Iconsax.add_square, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEditMode ? 'Edit Class: ${widget.classModel!.fullName}' : 'Add New Class',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: isMobile ? 16 : 18, color: AppTheme.darkText),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth, // Responsive width
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAcademicYearDropdown(isMobile),
                const SizedBox(height: 20),

                _buildSectionHeader('Class Definition', Iconsax.building),
                _buildClassDropdown(),
                _buildTextField('Section Name', _sectionNameController, 'e.g., A', isRequired: true),
                _buildTextField('Class Code', _classCodeController, 'e.g., C10-A', isRequired: true),
                const SizedBox(height: 20),

                _buildSectionHeader('Capacity & Location', Iconsax.box_search),
                isMobile
                    ? Column(children: [
                  _buildTextField('Max Capacity', _maxCapacityController, 'e.g., 40', keyboardType: TextInputType.number),
                  _buildTextField('Room Number', _roomNumberController, 'e.g., R-101'),
                ])
                    : _buildResponsiveRow([
                  _buildTextField('Max Capacity', _maxCapacityController, 'e.g., 40', keyboardType: TextInputType.number),
                  _buildTextField('Room Number', _roomNumberController, 'e.g., R-101'),
                ]),
                const SizedBox(height: 8),

                _buildSectionHeader('Class Teacher', Iconsax.teacher),
                _buildTeacherDropdown(),
                const SizedBox(height: 20),

                _buildCheckboxListTile(
                  title: 'Active Status',
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value ?? true),
                  subtitle: 'Deactivate to prevent new enrollment in this class.',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.bodyText)),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
          ),
          child: Text(isEditMode ? 'Update' : 'Add Class', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildAcademicYearDropdown(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Academic Year',
            style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.w600, color: AppTheme.darkText),
            children: const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedAcademicYear,
          dropdownColor: Colors.white,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Select Academic Year',
            prefixIcon: const Icon(Iconsax.calendar_1, color: AppTheme.primaryGreen, size: 20),
            hintStyle: GoogleFonts.inter(color: AppTheme.bodyText.withOpacity(0.6), fontSize: isMobile ? 13 : 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _academicYearOptions.map((year) {
            return DropdownMenuItem<String>(
              value: year,
              child: Text(
                year,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: year == _selectedAcademicYear ? FontWeight.w600 : FontWeight.normal,
                  color: AppTheme.darkText,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedAcademicYear = value),
          validator: (value) => value == null ? 'Academic Year is required' : null,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.darkText)),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Select Class',
            style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.w600, color: AppTheme.darkText),
            children: const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingMasterClasses
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 2))
            : DropdownButtonFormField<int>(
          value: _selectedClassID,
          dropdownColor: Colors.white,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Select class (LKG, UKG, 1-12)',
            hintStyle: GoogleFonts.inter(color: AppTheme.bodyText.withOpacity(0.6), fontSize: isMobile ? 13 : 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderGrey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _masterClasses.map((masterClass) {
            return DropdownMenuItem<int>(
              value: masterClass.classID,
              child: Text(masterClass.className, style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedClassID = value),
          validator: (value) => value == null ? 'Class is required' : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTeacherDropdown() {
    // Determine the initial selected TeacherOptionModel object for the searchable dropdown
    final initialTeacher = _selectedClassTeacherRecNo != null
        ? _availableTeachers.firstWhere(
          (t) => t.recNo == _selectedClassTeacherRecNo,
      orElse: () => TeacherOptionModel(recNo: 0, name: 'Unassigned'),
    )
        : null;

    // Create a list with an 'Unassigned' option (recNo 0)
    final teachersWithOptions = List<TeacherOptionModel>.from(_availableTeachers);
    final unassignedOption = TeacherOptionModel(recNo: 0, name: '--- Unassigned ---');

    // Only add if it's not already present (safety check)
    if (teachersWithOptions.where((t) => t.recNo == 0).isEmpty) {
      teachersWithOptions.insert(0, unassignedOption);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Primary Class Teacher (Optional)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.darkText)),
        const SizedBox(height: 8),
        _isLoadingTeachers
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 2))
            : _SSearchableDropdown<TeacherOptionModel>(
          hintText: 'Select Class Teacher',
          icon: Iconsax.teacher,
          items: teachersWithOptions,
          itemToString: (teacher) => teacher.name,
          // If the initial teacher is 'Unassigned' (recNo 0), pass null to the initialValue
          initialValue: initialTeacher?.recNo == 0 ? null : initialTeacher,
          isRequired: false,
          onChanged: (teacher) {
            setState(() {
              // Map null or 'Unassigned' (recNo 0) back to null for the BLoC event
              _selectedClassTeacherRecNo = teacher?.recNo == 0 ? null : teacher?.recNo;
            });
          },
        ),
      ],
    );
  }

  Widget _buildResponsiveRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((child) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          child: child,
        ),
      )).toList(),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      String hint, {
        bool isRequired = false,
        TextInputType keyboardType = TextInputType.text,
      }) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.w600, color: AppTheme.darkText),
            children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: AppTheme.darkText, fontSize: isMobile ? 13 : 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppTheme.bodyText.withOpacity(0.6), fontSize: isMobile ? 13 : 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderGrey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: isRequired
              ? (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          }
              : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCheckboxListTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: isMobile ? 14 : 15),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.bodyText),
        )
            : null,
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.primaryGreen,
        checkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}

// ============================================================================
// NEW REUSABLE UI WIDGETS (Copied from class_allotment_dialog.dart for dependency)
// ============================================================================
// NEW REUSABLE UI WIDGETS - Searchable Dropdown
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