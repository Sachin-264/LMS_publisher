// lib/screens/SubscriptionScreen/add_edit_plan_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Service/Subscription_service.dart';
import 'package:lms_publisher/screens/SubscriptionScreen/subscription_model.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'dart:ui';

import 'package:provider/provider.dart';

class AddEditPlanDialog extends StatefulWidget {
  final Plan? plan;

  const AddEditPlanDialog({super.key, this.plan});

  @override
  State<AddEditPlanDialog> createState() => _AddEditPlanDialogState();
}

class _AddEditPlanDialogState extends State<AddEditPlanDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final SubscriptionApiService _apiService = SubscriptionApiService();
  bool _isLoading = false;
  late TabController _tabController;

  bool get _isEditing => widget.plan != null;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _trialController = TextEditingController();
  final TextEditingController _usersController = TextEditingController();
  final TextEditingController _devicesController = TextEditingController();
  final TextEditingController _supportController =
  TextEditingController(text: 'Email Support');

  // Toggles
  bool _isRecordedLectures = false;
  bool _isAssignmentsTests = false;
  bool _isDownloadableResources = false;
  bool _isDiscussionForum = false;
  bool _isAutoRenewal = false;
  bool _isPopular = false;
  bool _isActive = true;

  String _selectedBillingCycle = 'Monthly';
  final List<String> _billingCycles = ['Monthly', 'Quarterly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // 🔥 Wizard Logic: Listen to tab changes to update the button text/icon
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    if (_isEditing) {
      _populateFieldsForEdit();
    }
  }

  void _populateFieldsForEdit() {
    final plan = widget.plan!;
    _nameController.text = plan.name;
    _descController.text = plan.description;
    _priceController.text = plan.price.toString();
    _discountController.text = plan.discountPercent.toString();
    _trialController.text = plan.trialPeriodDays.toString();
    _usersController.text = plan.usersAllowed.toString();
    _devicesController.text = plan.devicesAllowed.toString();
    _supportController.text = plan.supportType;
    _selectedBillingCycle = plan.billingCycle;

    // Assuming features are stored as a list of strings in the Plan model.
    // Ensure your Plan model has a 'features' list or adapt this logic.
    _isRecordedLectures = plan.features.contains('Recorded Lectures');
    _isAssignmentsTests = plan.features.contains('Assignments & Tests');
    _isDownloadableResources = plan.features.contains('Downloadable Resources');
    _isDiscussionForum = plan.features.contains('Discussion Forum');

    _isAutoRenewal = plan.isAutoRenewal;
    _isPopular = plan.isPopular;
    _isActive = plan.isActive;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _trialController.dispose();
    _usersController.dispose();
    _devicesController.dispose();
    _supportController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 1. Get PubCode
      int pubCode = 0;
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        pubCode = int.tryParse(userProvider.userCode ?? '0') ?? 0;
        print("✅ Retrieved PubCode from Provider: $pubCode");
      } catch (e) {
        print("⚠️ Could not fetch PubCode from provider: $e");
      }

      Map<String, dynamic> body;

      if (_isEditing) {
        // Body for UPDATE
        body = {
          "RecNo": widget.plan!.recNo,
          "Subscription_ID": widget.plan!.subscriptionId,
          "Subscription_Name": _nameController.text,
          "Description": _descController.text,
          "Plan_Type": "Annual",
          "Currency": "INR", // 🔥 Fix: Changed to INR
          "Price": double.tryParse(_priceController.text) ?? 0,
          "Billing_Cycle": _selectedBillingCycle,
          "Discount_Percent": int.tryParse(_discountController.text) ?? 0,
          "Trial_Period_Days": int.tryParse(_trialController.text) ?? 0,
          "Users_Allowed": int.tryParse(_usersController.text) ?? 1,
          "Devices_Allowed": int.tryParse(_devicesController.text) ?? 1,
          "Is_Recorded_Lectures": _isRecordedLectures ? 1 : 0,
          "Is_Assignments_Tests": _isAssignmentsTests ? 1 : 0,
          "Is_Downloadable_Resources": _isDownloadableResources ? 1 : 0,
          "Is_Discussion_Forum": _isDiscussionForum ? 1 : 0,
          "Support_Type": _supportController.text,
          "Start_Date": "2025-10-01", // Ideally make dynamic
          "End_Date": "2026-09-30",   // Ideally make dynamic
          "Is_Auto_Renewal": _isAutoRenewal ? 1 : 0,
          "Is_Status": _isActive ? 1 : 0,
          "Modified_By": "Admin",
          "Payment_Gateway_Ref": "PG123",
          "Tax_Percent": 18,
          "IsPopular": _isPopular ? 1 : 0,
        };
      } else {
        // Body for ADD
        body = {
          "Subscription_ID": (DateTime.now().millisecondsSinceEpoch ~/ 1000),
          "Subscription_Name": _nameController.text,
          "Description": _descController.text,
          "Plan_Type": "Annual",
          "Currency": "INR", // 🔥 Fix: Changed to INR
          "Price": double.tryParse(_priceController.text) ?? 0,
          "Billing_Cycle": _selectedBillingCycle,
          "Discount_Percent": int.tryParse(_discountController.text) ?? 0,
          "Trial_Period_Days": int.tryParse(_trialController.text) ?? 0,
          "Users_Allowed": int.tryParse(_usersController.text) ?? 1,
          "Devices_Allowed": int.tryParse(_devicesController.text) ?? 1,
          "Is_Recorded_Lectures": _isRecordedLectures ? 1 : 0,
          "Is_Assignments_Tests": _isAssignmentsTests ? 1 : 0,
          "Is_Downloadable_Resources": _isDownloadableResources ? 1 : 0,
          "Is_Discussion_Forum": _isDiscussionForum ? 1 : 0,
          "Support_Type": _supportController.text,
          "Start_Date": "2025-10-01",
          "End_Date": "2026-09-30",
          "Is_Auto_Renewal": _isAutoRenewal ? 1 : 0,
          "Is_Status": _isActive ? 1 : 0,
          "Created_By": "Admin",
          "Modified_By": "Admin",
          "Payment_Gateway_Ref": "PG123",
          "Tax_Percent": 18,
          "IsPopular": _isPopular ? 1 : 0,
        };
      }

      bool success = false;
      try {
        if (_isEditing) {
          success = await _apiService.updatePlan(body, pubCode);
        } else {
          success = await _apiService.addPlan(body, pubCode);
        }

        if (mounted) {
          final action = _isEditing ? 'updated' : 'created';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Plan ${success ? '$action successfully!' : 'Failed to $action plan!'}'),
              backgroundColor: success ? AppTheme.primaryGreen : Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (success) {
            Navigator.of(context).pop(true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
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
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 5,
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(isMobile),
                _buildTabBar(isMobile),
                Expanded(child: _buildTabBarView()),
                _buildFooter(), // 🔥 Updated Footer
              ],
            ),
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
            child: Icon(
              _isEditing ? Iconsax.edit : Iconsax.add_circle,
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
                  _isEditing ? 'Edit Plan' : 'Create New Plan',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (!isMobile)
                  Text(
                    'Configure pricing, features, and settings',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Iconsax.close_circle,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Close',
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
      tabs: const [
        Tab(icon: Icon(Iconsax.money, size: 20), text: 'Pricing'),
        Tab(icon: Icon(Iconsax.profile_2user, size: 20), text: 'Allocation'),
        Tab(icon: Icon(Iconsax.tick_circle, size: 20), text: 'Features'),
        Tab(icon: Icon(Iconsax.setting_2, size: 20), text: 'Settings'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPricingTab(),
        _buildAllocationTab(),
        _buildFeaturesTab(),
        _buildSettingsTab(),
      ],
    );
  }

  Widget _buildPricingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Plan Information'),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Plan Name *',
            controller: _nameController,
            icon: Iconsax.bookmark,
            hint: 'e.g., Basic Plan, Premium Plan',
            validator: (value) =>
            value!.isEmpty ? 'Plan name is required' : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Description *',
            controller: _descController,
            icon: Iconsax.document_text,
            hint: 'Brief description of the plan',
            maxLines: 3,
            validator: (value) =>
            value!.isEmpty ? 'Description is required' : null,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Pricing Details'),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              if (isMobile) {
                return Column(
                  children: [
                    _buildTextField(
                      label: 'Price (₹) *',
                      controller: _priceController,
                      icon: Iconsax.money,
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Price is required';
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Billing Cycle *',
                      value: _selectedBillingCycle,
                      items: _billingCycles,
                      icon: Iconsax.calendar,
                      onChanged: (value) {
                        setState(() => _selectedBillingCycle = value!);
                      },
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Price (₹) *',
                      controller: _priceController,
                      icon: Iconsax.money,
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Price is required';
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Billing Cycle *',
                      value: _selectedBillingCycle,
                      items: _billingCycles,
                      icon: Iconsax.calendar,
                      onChanged: (value) {
                        setState(() => _selectedBillingCycle = value!);
                      },
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
                    _buildTextField(
                      label: 'Discount (%)',
                      controller: _discountController,
                      icon: Iconsax.ticket_discount,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Trial Period (Days)',
                      controller: _trialController,
                      icon: Iconsax.timer,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Discount (%)',
                      controller: _discountController,
                      icon: Iconsax.ticket_discount,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Trial Period (Days)',
                      controller: _trialController,
                      icon: Iconsax.timer,
                      hint: '0',
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
          _buildSectionTitle('Resource Limits'),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              if (isMobile) {
                return Column(
                  children: [
                    _buildTextField(
                      label: 'Users Allowed *',
                      controller: _usersController,
                      icon: Iconsax.profile_2user,
                      hint: '1',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Devices Allowed *',
                      controller: _devicesController,
                      icon: Iconsax.mobile,
                      hint: '1',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Users Allowed *',
                      controller: _usersController,
                      icon: Iconsax.profile_2user,
                      hint: '1',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Devices Allowed *',
                      controller: _devicesController,
                      icon: Iconsax.mobile,
                      hint: '1',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Support Configuration'),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Support Type *',
            controller: _supportController,
            icon: Iconsax.support,
            hint: 'e.g., Email Support, 24/7 Support',
            validator: (value) =>
            value!.isEmpty ? 'Support type is required' : null,
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
            _isRecordedLectures,
            Iconsax.video_play,
                (value) => setState(() => _isRecordedLectures = value),
          ),
          const SizedBox(height: 16),
          _buildFeatureToggle(
            'Assignments & Tests',
            'Create and manage assignments and tests',
            _isAssignmentsTests,
            Iconsax.task_square,
                (value) => setState(() => _isAssignmentsTests = value),
          ),
          const SizedBox(height: 16),
          _buildFeatureToggle(
            'Downloadable Resources',
            'Download study materials and resources',
            _isDownloadableResources,
            Iconsax.document_download,
                (value) => setState(() => _isDownloadableResources = value),
          ),
          const SizedBox(height: 16),
          _buildFeatureToggle(
            'Discussion Forum',
            'Access to community discussion forum',
            _isDiscussionForum,
            Iconsax.messages_2,
                (value) => setState(() => _isDiscussionForum = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Plan Settings'),
          const SizedBox(height: 20),
          _buildFeatureToggle(
            'Auto Renewal',
            'Automatically renew subscription at the end of billing cycle',
            _isAutoRenewal,
            Iconsax.refresh,
                (value) => setState(() => _isAutoRenewal = value),
          ),
          const SizedBox(height: 16),
          _buildFeatureToggle(
            'Mark as Popular',
            'Highlight this plan as popular choice',
            _isPopular,
            Iconsax.star_1,
                (value) => setState(() => _isPopular = value),
          ),
          const SizedBox(height: 16),
          _buildFeatureToggle(
            'Active Status',
            'Plan is currently active and visible to users',
            _isActive,
            Iconsax.status,
                (value) => setState(() => _isActive = value),
          ),
        ],
      ),
    );
  }

  // 🔥 Wizard Footer Implementation
  Widget _buildFooter() {
    // Check if we are on the last tab (Settings tab is index 3)
    bool isLastTab = _tabController.index == 3;

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
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                Navigator.of(context).pop();
              },
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
              onPressed: _isLoading
                  ? null
                  : () {
                if (isLastTab) {
                  _submitForm();
                } else {
                  // Move to next tab
                  _tabController.animateTo(_tabController.index + 1);
                }
              },
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(
                  isLastTab
                      ? (_isEditing ? Iconsax.edit : Iconsax.tick_circle)
                      : Iconsax.arrow_right_1,
                  size: 20),
              label: Text(
                _isLoading
                    ? 'Saving...'
                    : (isLastTab
                    ? (_isEditing ? 'Update Plan' : 'Create Plan')
                    : 'Next Step'),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppTheme.darkText,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.all(16),
            hintText: hint,
            hintStyle:
            GoogleFonts.inter(color: AppTheme.bodyText.withOpacity(0.5)),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}