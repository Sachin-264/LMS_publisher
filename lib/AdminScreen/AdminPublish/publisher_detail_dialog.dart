import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/add_edit_publisher.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/publish_model.dart';
import 'package:lms_publisher/Service/publisher_api_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';

class PublisherDetailDialog extends StatefulWidget {
  final int publisherRecNo;

  const PublisherDetailDialog({super.key, required this.publisherRecNo});

  @override
  State<PublisherDetailDialog> createState() => _PublisherDetailDialogState();
}

class _PublisherDetailDialogState extends State<PublisherDetailDialog>
    with SingleTickerProviderStateMixin {
  final _apiService = PublisherApiService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  bool _isLoadingCredentials = false;
  PublisherDetail? _publisherDetail;
  Map<String, dynamic>? _credentials;
  String? _error;

  bool _showUserID = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _loadPublisherDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPublisherDetails() async {
    try {
      final details =
      await _apiService.getPublisherDetails(widget.publisherRecNo);
      if (mounted) {
        setState(() {
          _publisherDetail = details;
          _isLoading = false;
        });
        _animationController.forward();

        if (details.pubCode != null) {
          _loadCredentials(details.pubCode!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCredentials(int pubCode) async {
    setState(() => _isLoadingCredentials = true);
    try {
      final credentials = await _apiService.getPublisherCredentials(pubCode);
      if (mounted) {
        setState(() {
          _credentials = credentials;
          _isLoadingCredentials = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCredentials = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load credentials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('$label copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 40,
        vertical: isSmallScreen ? 24 : 40,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? double.infinity : 950,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: AppTheme.background,
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
          children: [
            _buildModernHeader(context),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                  ? _buildErrorState()
                  : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding:
                    EdgeInsets.all(isSmallScreen ? 20 : 32),
                    child: _buildDetailsContent(isSmallScreen),
                  ),
                ),
              ),
            ),
            _buildModernFooter(context, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // REDUCED from 32
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.accentGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
            padding: const EdgeInsets.all(12), // REDUCED from 16
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12), // REDUCED from 16
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(Iconsax.building, color: Colors.white, size: 24), // REDUCED from 28
          ),
          const SizedBox(width: 14), // REDUCED from 20
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publisher Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 20, // REDUCED from 24
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2), // REDUCED from 4
                Text(
                  'Complete information & credentials',
                  style: GoogleFonts.inter(
                    fontSize: 13, // REDUCED from 14
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10), // REDUCED from 12
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24), // REDUCED from 28
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
              padding: const EdgeInsets.all(8), // ADD padding control
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading publisher details...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait a moment',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.danger, size: 64, color: Colors.red[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Details',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.inter(
                color: AppTheme.bodyText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFooter(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1.5)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final result = await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AddEditPublisherDialog(
                        publisherRecNo: widget.publisherRecNo),
                  );
                  if (result == true && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                icon: const Icon(Iconsax.edit, size: 20),
                label: Text(
                  'Edit Publisher',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 28 : 36,
                    vertical: 16,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: AppTheme.primaryGreen.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsContent(bool isSmallScreen) {
    if (_publisherDetail == null) return const SizedBox.shrink();
    final detail = _publisherDetail!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo & Status Card
        _buildLogoAndStatusCard(detail),
        const SizedBox(height: 28),

        // Credentials Section - PROMINENT
        _buildUltraModernCredentialsSection(),
        const SizedBox(height: 28),

        // Rest of sections in 2-column grid for desktop
        if (MediaQuery.of(context).size.width > 900) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildModernSection(
                      icon: Iconsax.info_circle,
                      title: 'Basic Information',
                      color: Colors.blue,
                      children: [
                        _buildModernInfoRow('Publisher Name',
                            detail.publisherName, Iconsax.building),
                        _buildModernInfoRow('Pub Code',
                            detail.pubCode?.toString() ?? 'N/A', Iconsax.code),
                        _buildModernInfoRow('Admin Code',
                            detail.adminCode ?? 'N/A', Iconsax.user_tag),
                        _buildModernInfoRow(
                            'Type', detail.publisherType, Iconsax.category),
                        _buildModernInfoRow(
                            'Year',
                            detail.yearOfEstablishment?.toString() ?? 'N/A',
                            Iconsax.calendar),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildModernSection(
                      icon: Iconsax.location,
                      title: 'Address',
                      color: Colors.purple,
                      children: [
                        _buildModernInfoRow('Address 1',
                            detail.addressLine1 ?? 'N/A', Iconsax.location),
                        if (detail.addressLine2?.isNotEmpty ?? false)
                          _buildModernInfoRow('Address 2',
                              detail.addressLine2!, Iconsax.location),
                        _buildModernInfoRow(
                            'Country', detail.country ?? 'N/A', Iconsax.global),
                        _buildModernInfoRow(
                            'PIN', detail.pinZipCode ?? 'N/A', Iconsax.map),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildModernSection(
                      icon: Iconsax.call,
                      title: 'Contact',
                      color: Colors.green,
                      children: [
                        _buildModernInfoRow('Contact Person',
                            detail.contactPersonName ?? 'N/A', Iconsax.user),
                        _buildModernInfoRow(
                            'Designation',
                            detail.contactPersonDesignation ?? 'N/A',
                            Iconsax.briefcase),
                        _buildModernInfoRow(
                            'Email', detail.emailID ?? 'N/A', Iconsax.sms),
                        _buildModernInfoRow('Phone',
                            detail.phoneNumber ?? 'N/A', Iconsax.call),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildModernSection(
                      icon: Iconsax.dollar_circle,
                      title: 'Business',
                      color: Colors.orange,
                      children: [
                        if (detail.website?.isNotEmpty ?? false)
                          _buildModernInfoRow(
                              'Website', detail.website!, Iconsax.global),
                        if (detail.gstNumber?.isNotEmpty ?? false)
                          _buildModernInfoRow(
                              'GST', detail.gstNumber!, Iconsax.document_text),
                        if (detail.panNumber?.isNotEmpty ?? false)
                          _buildModernInfoRow(
                              'PAN', detail.panNumber!, Iconsax.card),
                        _buildModernInfoRow(
                            'Titles',
                            detail.numberOfTitles?.toString() ?? '0',
                            Iconsax.book),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          _buildModernSection(
            icon: Iconsax.info_circle,
            title: 'Basic Information',
            color: Colors.blue,
            children: [
              _buildModernInfoRow(
                  'Publisher Name', detail.publisherName, Iconsax.building),
              _buildModernInfoRow('Pub Code',
                  detail.pubCode?.toString() ?? 'N/A', Iconsax.code),
              _buildModernInfoRow(
                  'Admin Code', detail.adminCode ?? 'N/A', Iconsax.user_tag),
              _buildModernInfoRow('Type', detail.publisherType, Iconsax.category),
            ],
          ),
          const SizedBox(height: 24),
          _buildModernSection(
            icon: Iconsax.call,
            title: 'Contact',
            color: Colors.green,
            children: [
              _buildModernInfoRow('Contact Person',
                  detail.contactPersonName ?? 'N/A', Iconsax.user),
              _buildModernInfoRow('Email', detail.emailID ?? 'N/A', Iconsax.sms),
              _buildModernInfoRow(
                  'Phone', detail.phoneNumber ?? 'N/A', Iconsax.call),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLogoAndStatusCard(PublisherDetail detail) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (detail.logoFileName?.isNotEmpty ?? false)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  _apiService.getLogoUrl(detail.logoFileName!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Iconsax.gallery, size: 40, color: Colors.grey),
                ),
              ),
            ),
          if (detail.logoFileName?.isNotEmpty ?? false) const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.publisherName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: detail.isActive == 1
                        ? LinearGradient(colors: [
                      Colors.green[400]!,
                      Colors.green[600]!
                    ])
                        : LinearGradient(
                        colors: [Colors.red[400]!, Colors.red[600]!]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (detail.isActive == 1 ? Colors.green : Colors.red)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        detail.isActive == 1
                            ? Iconsax.tick_circle
                            : Iconsax.close_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        detail.isActive == 1 ? 'Active' : 'Inactive',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltraModernCredentialsSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withOpacity(0.08),
            AppTheme.accentGreen.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // COMPACT HEADER - NO GRADIENT BOX
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Iconsax.shield_tick, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Login Credentials',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (_isLoadingCredentials)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
              ],
            ),
          ),

          // CONTENT
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _credentials != null
                ? Column(
              children: [
                _buildCredentialField(
                  label: 'User ID',
                  value: _credentials!['UserID']?.toString() ?? 'N/A',
                  isVisible: _showUserID,
                  onToggle: () => setState(() => _showUserID = !_showUserID),
                  icon: Iconsax.user,
                ),
                const SizedBox(height: 14),
                _buildPasswordInfoCard(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCredentialChip(
                        'User Group',
                        _credentials!['UserGroupCode']?.toString() ?? 'N/A',
                        Iconsax.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCredentialChip(
                        'Account',
                        (_credentials!['IsBlocked'] ?? 0) == 0 ? 'Active' : 'Blocked',
                        Iconsax.shield_tick,
                        (_credentials!['IsBlocked'] ?? 0) == 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            )
                : Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Iconsax.info_circle, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text(
                      'No credentials available',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPasswordInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.info_circle, color: Colors.amber[800], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Security',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Password is encrypted and cannot be displayed. Use "Update Credentials" to change it.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.amber[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialField({
    required String label,
    required String value,
    required bool isVisible,
    required VoidCallback onToggle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.15),
                  AppTheme.accentGreen.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isVisible ? value : '••••••••••••',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                    letterSpacing: isVisible ? 0.5 : 3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: onToggle,
              icon: Icon(
                isVisible ? Iconsax.eye : Iconsax.eye_slash,
                size: 20,
                color: AppTheme.primaryGreen,
              ),
              tooltip: isVisible ? 'Hide' : 'Show',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () => _copyToClipboard(value, label),
              icon: const Icon(Iconsax.copy, size: 18, color: Colors.grey),
              tooltip: 'Copy',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
