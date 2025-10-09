// lib/screens/SubscriptionScreen/plan_details_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/screens/SubscriptionScreen/subscription_model.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class PlanDetailsDialog extends StatefulWidget {
  final Plan plan;
  const PlanDetailsDialog({super.key, required this.plan});

  @override
  State<PlanDetailsDialog> createState() => _PlanDetailsDialogState();
}

class _PlanDetailsDialogState extends State<PlanDetailsDialog>
    with SingleTickerProviderStateMixin {
  bool isEditing = false;
  late TabController _tabController;

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController discountController;
  late TextEditingController trialController;
  late TextEditingController usersController;
  late TextEditingController devicesController;
  late TextEditingController supportController;

  bool isRecordedLectures = false;
  bool isAssignmentsTests = false;
  bool isDownloadableResources = false;
  bool isDiscussionForum = false;
  bool isAutoRenewal = false;
  bool isActive = false;
  String? selectedBillingCycle;

  final List<String> billingCycles = ['Monthly', 'Quarterly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeControllers();
  }

  void _initializeControllers() {
    nameController = TextEditingController(text: widget.plan.name);
    descriptionController = TextEditingController(text: widget.plan.description);
    priceController = TextEditingController(text: widget.plan.price.toString());
    discountController = TextEditingController(
        text: widget.plan.discountPercent?.toString() ?? '0');
    trialController = TextEditingController(
        text: widget.plan.trialPeriodDays?.toString() ?? '0');
    usersController =
        TextEditingController(text: widget.plan.usersAllowed.toString());
    devicesController =
        TextEditingController(text: widget.plan.devicesAllowed.toString());
    supportController = TextEditingController(text: widget.plan.supportType);

    isRecordedLectures = widget.plan.isRecordedLectures;
    isAssignmentsTests = widget.plan.isAssignmentsTests;
    isDownloadableResources = widget.plan.isDownloadableResources;
    isDiscussionForum = widget.plan.isDiscussionForum;
    isAutoRenewal = widget.plan.isAutoRenewal;
    isActive = widget.plan.isActive;
    selectedBillingCycle = widget.plan.billingCycle;
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    discountController.dispose();
    trialController.dispose();
    usersController.dispose();
    devicesController.dispose();
    supportController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
      if (!isEditing) {
        _initializeControllers();
      }
    });
  }

  void _saveChanges() {
    // Implement save logic here
    setState(() {
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Plan updated successfully!'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.borderGrey.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              _buildHeader(isMobile),
              _buildTabBar(isMobile),
              Expanded(
                child: _buildTabBarView(),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
              Iconsax.crown_1,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isEditing
                    ? TextField(
                  controller: nameController,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                )
                    : Text(
                  nameController.text,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (!isMobile)
                  Text(
                    'Manage plan details and features',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _toggleEditMode,
            icon: Icon(
              isEditing ? Iconsax.close_circle : Iconsax.edit,
              color: Colors.white,
              size: 24,
            ),
            tooltip: isEditing ? 'Cancel' : 'Edit Plan',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderGrey.withOpacity(0.3),
          ),
        ),
      ),
      child: isMobile
          ? SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildTabs(isMobile),
      )
          : _buildTabs(isMobile),
    );
  }

  Widget _buildTabs(bool isMobile) {
    return TabBar(
      controller: _tabController,
      isScrollable: isMobile,
      labelColor: AppTheme.primaryGreen,
      unselectedLabelColor: AppTheme.bodyText,
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: isMobile ? 13 : 15,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: isMobile ? 13 : 15,
      ),
      indicatorColor: AppTheme.primaryGreen,
      indicatorWeight: 3,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      tabs: [
        Tab(
          icon: const Icon(Iconsax.money, size: 20),
          text: 'Pricing',
        ),
        Tab(
          icon: const Icon(Iconsax.profile_2user, size: 20),
          text: 'Allocation',
        ),
        Tab(
          icon: const Icon(Iconsax.tick_circle, size: 20),
          text: 'Features',
        ),
        Tab(
          icon: const Icon(Iconsax.setting_2, size: 20),
          text: 'Settings',
        ),
      ],
    );
  }

  Widget _buildTabBarView() {
    final currencyFormat =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM, yyyy');

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPricingTab(currencyFormat),
        _buildAllocationTab(),
        _buildFeaturesTab(),
        _buildSettingsTab(dateFormat),
      ],
    );
  }

  Widget _buildPricingTab(NumberFormat currencyFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Pricing Information'),
          const SizedBox(height: 20),
          _buildEditableField(
            label: 'Description',
            controller: descriptionController,
            icon: Iconsax.document_text,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              if (isMobile) {
                return Column(
                  children: [
                    _buildEditableField(
                      label: 'Price (₹)',
                      controller: priceController,
                      icon: Iconsax.money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    isEditing
                        ? _buildDropdownField(
                      label: 'Billing Cycle',
                      value: selectedBillingCycle,
                      items: billingCycles,
                      icon: Iconsax.calendar,
                      onChanged: (value) {
                        setState(() {
                          selectedBillingCycle = value;
                        });
                      },
                    )
                        : _buildInfoCard(
                      'Billing Cycle',
                      selectedBillingCycle ?? '',
                      Iconsax.calendar,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildEditableField(
                      label: 'Price (₹)',
                      controller: priceController,
                      icon: Iconsax.money,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isEditing
                        ? _buildDropdownField(
                      label: 'Billing Cycle',
                      value: selectedBillingCycle,
                      items: billingCycles,
                      icon: Iconsax.calendar,
                      onChanged: (value) {
                        setState(() {
                          selectedBillingCycle = value;
                        });
                      },
                    )
                        : _buildInfoCard(
                      'Billing Cycle',
                      selectedBillingCycle ?? '',
                      Iconsax.calendar,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              if (isMobile) {
                return Column(
                  children: [
                    _buildEditableField(
                      label: 'Discount (%)',
                      controller: discountController,
                      icon: Iconsax.ticket_discount,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildEditableField(
                      label: 'Trial Period (Days)',
                      controller: trialController,
                      icon: Iconsax.timer,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildEditableField(
                      label: 'Discount (%)',
                      controller: discountController,
                      icon: Iconsax.ticket_discount,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEditableField(
                      label: 'Trial Period (Days)',
                      controller: trialController,
                      icon: Iconsax.timer,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Resource Allocation'),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              if (isMobile) {
                return Column(
                  children: [
                    _buildEditableField(
                      label: 'Users Allowed',
                      controller: usersController,
                      icon: Iconsax.profile_2user,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildEditableField(
                      label: 'Devices Allowed',
                      controller: devicesController,
                      icon: Iconsax.mobile,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildEditableField(
                      label: 'Users Allowed',
                      controller: usersController,
                      icon: Iconsax.profile_2user,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEditableField(
                      label: 'Devices Allowed',
                      controller: devicesController,
                      icon: Iconsax.mobile,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Support Configuration'),
          const SizedBox(height: 20),
          _buildEditableField(
            label: 'Support Type',
            controller: supportController,
            icon: Iconsax.support,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Included Features'),
          const SizedBox(height: 20),
          _buildFeatureToggle(
            'Recorded Lectures',
            'Access to pre-recorded video lectures',
            isRecordedLectures,
            Iconsax.video_play,
                (value) => setState(() => isRecordedLectures = value),
          ),
          const SizedBox(height: 16),
          _buildFeatureToggle(
            'Assignments & Tests',
            'Create and manage assignments and tests',
            isAssignmentsTests,
            Iconsax.task_square,
                (value) => setState(() => isAssignmentsTests = value),
          ),
          const SizedBox(height: 16),
          _buildFeatureToggle(
            'Downloadable Resources',
            'Download study materials and resources',
            isDownloadableResources,
            Iconsax.document_download,
                (value) => setState(() => isDownloadableResources = value),
          ),
          const SizedBox(height: 16),
          _buildFeatureToggle(
            'Discussion Forum',
            'Access to community discussion forum',
            isDiscussionForum,
            Iconsax.messages_2,
                (value) => setState(() => isDiscussionForum = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(DateFormat dateFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Subscription Dates'),
          const SizedBox(height: 20),
          if (widget.plan.startDate != null)
            _buildInfoCard(
              'Start Date',
              dateFormat.format(widget.plan.startDate!),
              Iconsax.calendar_1,
            ),
          if (widget.plan.endDate != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              'End Date',
              dateFormat.format(widget.plan.endDate!),
              Iconsax.calendar_remove,
            ),
          ],
          const SizedBox(height: 24),
          _buildSectionTitle('Status & Renewal'),
          const SizedBox(height: 20),
          _buildFeatureToggle(
            'Auto Renewal',
            'Automatically renew subscription',
            isAutoRenewal,
            Iconsax.refresh,
                (value) => setState(() => isAutoRenewal = value),
          ),
          const SizedBox(height: 16),
          _buildFeatureToggle(
            'Active Status',
            'Plan is currently active',
            isActive,
            Iconsax.status,
                (value) => setState(() => isActive = value),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(color: AppTheme.borderGrey.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isEditing) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _toggleEditMode,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppTheme.borderGrey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.bodyText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Iconsax.tick_circle, size: 20),
                label: Text(
                  'Save Changes',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
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
          ] else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.darkText,
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    if (!isEditing) {
      return _buildInfoCard(label, controller.text, icon);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.bodyText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppTheme.darkText,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.bodyText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    items: items.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: GoogleFonts.inter(fontSize: 15),
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.bodyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureToggle(
      String title,
      String description,
      bool value,
      IconData icon,
      ValueChanged<bool> onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: value
            ? AppTheme.primaryGreen.withOpacity(0.05)
            : AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppTheme.primaryGreen.withOpacity(0.3)
              : AppTheme.borderGrey.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.primaryGreen.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? AppTheme.primaryGreen : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.bodyText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isEditing)
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryGreen,
            )
          else
            Icon(
              value ? Iconsax.tick_circle : Iconsax.close_circle,
              color: value ? AppTheme.primaryGreen : Colors.grey,
              size: 24,
            ),
        ],
      ),
    );
  }
}
