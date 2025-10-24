import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/add_edit_publisher.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/publish_model.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/publisher_detail_dialog.dart';
import 'package:lms_publisher/Service/publisher_api_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/AcademicsScreen/academics_content.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'publisher_bloc.dart';

class PublisherScreen extends StatelessWidget {
  const PublisherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PublisherBloc(PublisherApiService())..add(LoadPublisherData()),
      child: MainLayout(
        activeScreen: AppScreen.publishers,
        child: const PublisherView(),
      ),
    );
  }
}

class PublisherView extends StatefulWidget {
  const PublisherView({super.key});

  @override
  State<PublisherView> createState() => _PublisherViewState();
}

class _PublisherViewState extends State<PublisherView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIXED: Removed mainAxisSize.min and Expanded, using Column directly
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Publisher Management',
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Oversee all publishers and their content contributions.',
                style: GoogleFonts.inter(color: AppTheme.bodyText),
              ),
            ],
          ),
        ),

        // KPI Cards
        BlocBuilder<PublisherBloc, PublisherState>(
          builder: (context, state) {
            bool isLoading = state is! PublisherLoaded;
            AdminKPIs? kpis = (state is PublisherLoaded) ? state.kpis : null;
            int activeCount = (state is PublisherLoaded) ? state.activePublishers.length : 0;
            int inactiveCount = (state is PublisherLoaded) ? state.inactivePublishers.length : 0;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                final kpiCards = [
                  AnimatedKPICard(
                    icon: Iconsax.user_square,
                    color: AppTheme.primaryGreen,
                    value: kpis?.publisherCount.toString() ?? '0',
                    label: 'Total Publishers',
                    isLoading: isLoading,
                  ),
                  AnimatedKPICard(
                    icon: Iconsax.tick_circle,
                    color: Colors.green,
                    value: activeCount.toString(),
                    label: 'Active Publishers',
                    isLoading: isLoading,
                  ),
                  AnimatedKPICard(
                    icon: Iconsax.close_circle,
                    color: Colors.red,
                    value: inactiveCount.toString(),
                    label: 'Inactive Publishers',
                    isLoading: isLoading,
                  ),
                  AnimatedKPICard(
                    icon: Iconsax.book_1,
                    color: Colors.blue,
                    value: kpis?.subjectCount.toString() ?? '0',
                    label: 'Total Subjects',
                    isLoading: isLoading,
                  ),
                ];

                if (isMobile) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: kpiCards
                        .map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.defaultPadding),
                      child: card,
                    ))
                        .toList(),
                  );
                }

                return Row(
                  children: kpiCards
                      .map((card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.defaultPadding / 2),
                      child: card,
                    ),
                  ))
                      .toList(),
                );
              },
            );
          },
        ),

        const SizedBox(height: AppTheme.defaultPadding * 1.5),

        // FIXED: No Expanded here - let ScrollView in MainLayout handle scrolling
        _buildPublisherListWithTabs(),
      ],
    );
  }

  Widget _buildPublisherListWithTabs() {
    return BlocBuilder<PublisherBloc, PublisherState>(
      builder: (context, state) {
        if (state is PublisherLoading || state is PublisherInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PublisherError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.danger, size: 48, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load data',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: GoogleFonts.inter(color: AppTheme.bodyText),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is PublisherLoaded) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;

              // FIXED: Using fixed height container for TabBarView
              return SizedBox(
                height: 600, // Adjust this value based on your needs
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryGreen,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.primaryGreen,
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Iconsax.tick_circle, size: 18),
                                const SizedBox(width: 8),
                                Text('Active (${state.activePublishers.length})'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Iconsax.close_circle, size: 18),
                                const SizedBox(width: 8),
                                Text('Inactive (${state.inactivePublishers.length})'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPublisherList(
                            context,
                            state.activePublishers,
                            isMobile,
                            isActive: true,
                          ),
                          _buildPublisherList(
                            context,
                            state.inactivePublishers,
                            isMobile,
                            isActive: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPublisherList(
      BuildContext context,
      List<Publisher> publishers,
      bool isMobile, {
        required bool isActive,
      }) {
    if (isMobile) {
      return _buildMobileView(context, publishers, isActive);
    } else {
      return _buildDesktopView(context, publishers, isActive);
    }
  }

  Widget _buildDesktopView(
      BuildContext context,
      List<Publisher> publishers,
      bool isActive,
      ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isActive ? "Active Publishers" : "Inactive Publishers",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isActive)
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(context),
                  icon: const Icon(Iconsax.add, size: 18),
                  label: const Text('Add Publisher'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const ResponsiveTableHeader(headers: [
          HeaderItem(text: "PUBLISHER NAME", flex: 4),
          HeaderItem(text: "TYPE", flex: 2),
          HeaderItem(text: "STATUS", flex: 2),
          HeaderItem(text: "ACTIONS", flex: 1, alignment: Alignment.centerRight),
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: publishers.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.folder_open, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    isActive ? "No active publishers found." : "No inactive publishers found.",
                    style: GoogleFonts.inter(color: AppTheme.bodyText),
                  ),
                ],
              ),
            ),
          )
              : ListView.builder(
            itemCount: publishers.length,
            itemBuilder: (context, index) {
              return PublisherListItem(
                publisher: publishers[index],
                isActive: isActive,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(
      BuildContext context,
      List<Publisher> publishers,
      bool isActive,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isActive)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Active Publishers",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(context),
                  icon: const Icon(Iconsax.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: publishers.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.folder_open, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    isActive ? "No active publishers found." : "No inactive publishers found.",
                    style: GoogleFonts.inter(color: AppTheme.bodyText),
                  ),
                ],
              ),
            ),
          )
              : ListView(
            children: publishers
                .map((publisher) => PublisherMobileCard(
              publisher: publisher,
              isActive: isActive,
            ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddEditDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddEditPublisherDialog(),
    );
    if (result == true && context.mounted) {
      context.read<PublisherBloc>().add(LoadPublisherData());
    }
  }
}

// AnimatedKPICard Widget
class AnimatedKPICard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool isLoading;

  const AnimatedKPICard({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.isLoading,
  });

  @override
  State<AnimatedKPICard> createState() => _AnimatedKPICardState();
}

class _AnimatedKPICardState extends State<AnimatedKPICard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? widget.color.withOpacity(0.3) : AppTheme.borderGrey.withOpacity(0.3),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? widget.color.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  if (_isHovered)
                    Icon(Iconsax.arrow_right_3, color: widget.color, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              widget.isLoading
                  ? Container(
                height: 24,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
                  : Text(
                widget.value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.bodyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PublisherListItem Widget
class PublisherListItem extends StatefulWidget {
  final Publisher publisher;
  final bool isActive;

  const PublisherListItem({
    super.key,
    required this.publisher,
    required this.isActive,
  });

  @override
  State<PublisherListItem> createState() => _PublisherListItemState();
}

class _PublisherListItemState extends State<PublisherListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => _showPublisherDetails(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryGreen.withOpacity(0.02) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primaryGreen.withOpacity(0.3)
                  : AppTheme.borderGrey.withOpacity(0.5),
            ),
            boxShadow: _isHovered
                ? [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : [],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: widget.isActive ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.publisher.publisherName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: _isHovered ? AppTheme.primaryGreen : Colors.black87,
                        ),
                      ),
                    ),
                    if (_isHovered) ...[ const SizedBox(width: 8),
                      Icon(Iconsax.eye, size: 16, color: AppTheme.primaryGreen.withOpacity(0.6)),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.publisher.publisherType,
                  style: GoogleFonts.inter(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.isActive
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isActive ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: widget.isActive ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: widget.isActive ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.isActive) ...[
                      IconButton(
                        icon: const Icon(Iconsax.edit, size: 20),
                        tooltip: 'Edit Publisher',
                        onPressed: () => _showEditDialog(context),
                      ),
                      PopupMenuButton(
                        tooltip: 'More Options',
                        onSelected: (value) => _handleMenuAction(context, value),
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Iconsax.eye, size: 18),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'update_credentials',  // NEW
                            child: Row(
                              children: [
                                Icon(Iconsax.key, size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Update Credentials', style: TextStyle(color: Colors.blue)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'soft_delete',
                            child: Row(
                              children: [
                                Icon(Iconsax.archive_minus, size: 18),
                                SizedBox(width: 8),
                                Text('Deactivate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'hard_delete',
                            child: Row(
                              children: [
                                Icon(Iconsax.trash, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),

                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () => _showActivateDialog(context),
                        icon: const Icon(Iconsax.tick_circle, size: 18),
                        label: const Text('Activate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Iconsax.eye, size: 20),
                        tooltip: 'View Details',
                        onPressed: () => _showPublisherDetails(context),
                      ),
                    ],
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showPublisherDetails(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (_) => PublisherDetailDialog(publisherRecNo: widget.publisher.recNo),
    );
    if (result == true && context.mounted) {
      context.read<PublisherBloc>().add(LoadPublisherData());
    }
  }

  void _showEditDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditPublisherDialog(publisherRecNo: widget.publisher.recNo),
    );
    if (result == true && context.mounted) {
      context.read<PublisherBloc>().add(LoadPublisherData());
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    if (action == 'view') {
      _showPublisherDetails(context);
    } else if (action == 'update_credentials') {  // NEW
      _showUpdateCredentialsDialog(context);
    } else if (action == 'soft_delete') {
      _showSoftDeleteDialog(context);
    } else if (action == 'hard_delete') {
      _showHardDeleteDialog(context);
    }
  }

  void _showUpdateCredentialsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => UpdateCredentialsDialog(
        pubCode: widget.publisher.pubCode!,
        publisherName: widget.publisher.publisherName,
      ),
    );
  }


  void _showActivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.tick_circle, color: Colors.green),
              ),
              const SizedBox(width: 12),
              const Text('Activate Publisher'),
            ],
          ),
          content: Text(
            'Are you sure you want to activate "${widget.publisher.publisherName}"?',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context.read<PublisherBloc>().add(
                  ActivatePublisher(recNo: widget.publisher.recNo),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Activate'),
            ),
          ],
        );
      },
    );
  }

  void _showSoftDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.archive_minus, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('Deactivate Publisher'),
            ],
          ),
          content: Text(
            'Are you sure you want to deactivate "${widget.publisher.publisherName}"? This action can be reversed later.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context.read<PublisherBloc>().add(
                  DeletePublisher(recNo: widget.publisher.recNo, deleteType: 'soft'),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );
  }

  void _showHardDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<PublisherBloc>(),
        child: _ImprovedDeleteConfirmationDialog(publisher: widget.publisher),
      ),
    );
  }
}

// PublisherMobileCard Widget
class PublisherMobileCard extends StatelessWidget {
  final Publisher publisher;
  final bool isActive;

  const PublisherMobileCard({
    super.key,
    required this.publisher,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPublisherDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        publisher.publisherName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Iconsax.category, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      publisher.publisherType,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isActive) ...[
                      TextButton.icon(
                        onPressed: () => _showEditDialog(context),
                        icon: const Icon(Iconsax.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleMenuAction(context, value),
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'soft_delete',
                            child: Text('Deactivate'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'hard_delete',
                            child: Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () => _showActivateDialog(context),
                        icon: const Icon(Iconsax.tick_circle, size: 16),
                        label: const Text('Activate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPublisherDetails(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (_) => PublisherDetailDialog(publisherRecNo: publisher.recNo),
    );
    if (result == true && context.mounted) {
      context.read<PublisherBloc>().add(LoadPublisherData());
    }
  }

  void _showEditDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditPublisherDialog(publisherRecNo: publisher.recNo),
    );
    if (result == true && context.mounted) {
      context.read<PublisherBloc>().add(LoadPublisherData());
    }
  }

  void _showActivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.tick_circle, color: Colors.green),
              ),
              const SizedBox(width: 12),
              const Text('Activate Publisher'),
            ],
          ),
          content: Text(
            'Are you sure you want to activate "${publisher.publisherName}"?',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context.read<PublisherBloc>().add(
                  ActivatePublisher(recNo: publisher.recNo),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Activate'),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    if (action == 'soft_delete') {
      _showSoftDeleteDialog(context);
    } else if (action == 'hard_delete') {
      _showHardDeleteDialog(context);
    }
  }

  void _showSoftDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.archive_minus, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('Deactivate Publisher'),
            ],
          ),
          content: Text(
            'Are you sure you want to deactivate "${publisher.publisherName}"? This action can be reversed later.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context.read<PublisherBloc>().add(
                  DeletePublisher(recNo: publisher.recNo, deleteType: 'soft'),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );
  }

  void _showHardDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ImprovedDeleteConfirmationDialog(publisher: publisher),
    );
  }
}

// Delete Confirmation Dialog
class _ImprovedDeleteConfirmationDialog extends StatefulWidget {
  final Publisher publisher;
  const _ImprovedDeleteConfirmationDialog({required this.publisher});

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
                              'This is a permanent action and cannot be undone. This will permanently delete the publisher: '),
                          TextSpan(
                            text: widget.publisher.publisherName,
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
                        context.read<PublisherBloc>().add(
                          DeletePublisher(
                            recNo: widget.publisher.recNo,
                            deleteType: 'hard',
                          ),
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Successfully deleted ${widget.publisher.publisherName}'),
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

// ResponsiveTableHeader Widget
class ResponsiveTableHeader extends StatelessWidget {
  final List<HeaderItem> headers;

  const ResponsiveTableHeader({Key? key, required this.headers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
      ),
      child: Row(
        children: headers.map((header) {
          return Expanded(
            flex: header.flex,
            child: Align(
              alignment: header.alignment,
              child: Text(
                header.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class HeaderItem {
  final String text;
  final int flex;
  final Alignment alignment;

  const HeaderItem({
    required this.text,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });
}

// Ultra-Modern Update Credentials Dialog
class UpdateCredentialsDialog extends StatefulWidget {
  final int pubCode;
  final String publisherName;

  const UpdateCredentialsDialog({
    super.key,
    required this.pubCode,
    required this.publisherName,
  });

  @override
  State<UpdateCredentialsDialog> createState() => _UpdateCredentialsDialogState();
}

class _UpdateCredentialsDialogState extends State<UpdateCredentialsDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userIDController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = PublisherApiService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _userIDController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _apiService.updatePublisherCredentials(
        widget.pubCode,
        _userIDController.text.trim(),
        _passwordController.text.trim(),
        'admin',
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.tick_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Credentials updated successfully for ${widget.publisherName}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Header with Gradient
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(Iconsax.key, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Credentials',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.publisherName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Security Badge
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryGreen.withOpacity(0.08),
                                AppTheme.accentGreen.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Iconsax.shield_tick, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Secure Update',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Password will be encrypted using SHA-256',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // User ID Field with Icon
                        Text(
                          'New User ID',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _userIDController,
                          decoration: InputDecoration(
                            hintText: 'Enter new user ID',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Iconsax.user, size: 20, color: AppTheme.primaryGreen),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'User ID is required';
                            }
                            if (value.length < 4) {
                              return 'User ID must be at least 4 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Field with Strength Indicator
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
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Iconsax.lock, size: 20, color: AppTheme.primaryGreen),
                            ),
                            suffixIcon: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _showPassword ? Iconsax.eye : Iconsax.eye_slash,
                                  size: 20,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
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
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Iconsax.tick_circle, size: 22),
                                label: Text(
                                  _isLoading ? 'Updating...' : 'Update Credentials',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  shadowColor: AppTheme.primaryGreen.withOpacity(0.5),
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
        ),
      ),
    );
  }
}

