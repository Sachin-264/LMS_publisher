import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/StudentPannel/MySubject/chapter_Detail_Screen.dart';
import 'package:lms_publisher/StudentPannel/Service/student_subject_service.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Util/beautiful_loader.dart';
import 'package:lms_publisher/Util/custom_snackbar.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MyFavouritesScreen extends StatefulWidget {
  const MyFavouritesScreen({super.key});

  @override
  State<MyFavouritesScreen> createState() => _MyFavouritesScreenState();
}

class _MyFavouritesScreenState extends State<MyFavouritesScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<FavoriteChapter> _favorites = [];
  List<FavoriteChapter> _filteredFavorites = [];
  String _sortBy = 'recent'; // recent, name, progress
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _loadFavorites();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final studentId = userProvider.userCode;

      if (studentId == null) {
        throw Exception('Student ID not found. Please login again.');
      }

      final response = await http.post(
        Uri.parse('${StudentSubjectService.baseUrl}/Mysubject.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_FAVORITES',
          'Student_ID': studentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              _favorites = (data['favorites'] as List)
                  .map((item) => FavoriteChapter.fromJson(item))
                  .toList();
              _applyFilters();
              _isLoading = false;
            });
            _fadeController.forward();
          }
        } else {
          throw Exception(data['error'] ?? 'Failed to load favorites');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        CustomSnackbar.showError(
          context,
          _errorMessage!,
          title: 'Failed to Load Favorites',
        );
      }
    }
  }

  void _applyFilters() {
    List<FavoriteChapter> filtered = List.from(_favorites);

    // Search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((f) => f.chapterName
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'recent':
        filtered.sort((a, b) {
          if (a.lastAccessedDate == null) return 1;
          if (b.lastAccessedDate == null) return -1;
          return b.lastAccessedDate!.compareTo(a.lastAccessedDate!);
        });
        break;
      case 'name':
        filtered.sort((a, b) => a.chapterName.compareTo(b.chapterName));
        break;
      case 'progress':
        filtered.sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
        break;
    }

    setState(() {
      _filteredFavorites = filtered;
    });
  }

  Future<void> _removeFavorite(int chapterId, int index) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final studentId = userProvider.userCode;

      final response = await http.post(
        Uri.parse('${StudentSubjectService.baseUrl}/student_analytics_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'MANAGE_FAVORITE',
          'Student_ID': studentId,
          'ChapterID': chapterId,
          'FavoriteAction': 'REMOVE',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            _favorites.removeWhere((f) => f.chapterId == chapterId);
            _applyFilters();
          });

          if (mounted) {
            CustomSnackbar.showSuccess(
              context,
              'Removed from favorites',
              title: 'Success',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context,
          'Failed to remove favorite',
          title: 'Error',
        );
      }
    }
  }

  void _openChapterDetails(FavoriteChapter favorite) {
    final chapterModel = ChapterModel(
      chapterId: favorite.chapterId,
      chapterName: favorite.chapterName,
      displayChapterName: favorite.chapterName,
      chapterDescription: null,
      chapterOrder: favorite.chapterOrder,
      materialCount: 0,
      completionStatus: favorite.completionStatus,
      progressPercentage: favorite.progressPercentage,
      timeSpentMinutes: 0,
      lastAccessedDate: favorite.lastAccessedDate,
      isFavorite: true,
      isLocked: false,
      lastAccessedDisplay: favorite.lastAccessedDisplay,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterDetailsScreen(
          chapter: chapterModel,
          subjectColor: _getSubjectColor(favorite.subjectId),
          subjectName: favorite.subjectName,
          subjectId: favorite.subjectId,
        ),
      ),
    ).then((_) {
      _loadFavorites();
    });
  }

  Color _getSubjectColor(int subjectId) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
    ];
    return colors[subjectId % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      activeScreen: AppScreen.mySubjects,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 32),

            if (_isLoading)
              _buildLoadingState()
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_favorites.isEmpty)
                _buildEmptyState()
              else ...[
                  _buildSearchAndSort(),
                  const SizedBox(height: 28),
                  _buildFavoritesGrid(),
                ],
          ],
        ),
      ),
    );
  }

  // ========== PAGE HEADER ==========
  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B9D).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Iconsax.heart, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 24),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Favourites',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Your Chapter',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppTheme.bodyText.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!_isLoading && _favorites.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_favorites.length} ${_favorites.length == 1 ? "Chapter" : "Chapters"}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        _buildActionButton(
          icon: Iconsax.refresh,
          onTap: () {
            _loadFavorites();
            CustomSnackbar.showInfo(context, 'Refreshing favorites...');
          },
          tooltip: 'Refresh',
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isPrimary = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary
            ? const Color(0xFFFF6B9D).withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isPrimary
                    ? const Color(0xFFFF6B9D).withOpacity(0.3)
                    : AppTheme.borderGrey.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isPrimary ? const Color(0xFFFF6B9D) : AppTheme.bodyText,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // ========== SEARCH AND SORT ==========
  Widget _buildSearchAndSort() {
    return Row(
      children: [
        // Search bar
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderGrey.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search favorites...',
                hintStyle: GoogleFonts.inter(
                  color: AppTheme.bodyText.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  color: AppTheme.bodyText.withOpacity(0.5),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Iconsax.close_circle,
                    color: AppTheme.bodyText.withOpacity(0.5),
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Sort dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderGrey.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Iconsax.sort,
                size: 18,
                color: AppTheme.bodyText.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortBy,
                underline: const SizedBox(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
                items: const [
                  DropdownMenuItem(value: 'recent', child: Text('Recently Accessed')),
                  DropdownMenuItem(value: 'name', child: Text('Chapter Name')),
                  DropdownMenuItem(value: 'progress', child: Text('Progress')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _applyFilters();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== FAVORITES GRID ==========
  Widget _buildFavoritesGrid() {
    if (_filteredFavorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(80),
          child: Column(
            children: [
              Icon(
                Iconsax.search_normal_1,
                size: 64,
                color: AppTheme.bodyText.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No favorites match your search',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.bodyText.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: _filteredFavorites
            .asMap()
            .entries
            .map((entry) => TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (entry.key * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _EnhancedFavoriteCard(
                  favorite: entry.value,
                  index: entry.key,
                  onTap: () => _openChapterDetails(entry.value),
                  onRemove: () => _removeFavorite(
                    entry.value.chapterId,
                    entry.key,
                  ),
                  subjectColor: _getSubjectColor(entry.value.subjectId),
                ),
              ),
            );
          },
        ))
            .toList(),
      ),
    );
  }

  // ========== LOADING STATE ==========
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 120),
          BeautifulLoader(
            type: LoaderType.pulse,
            size: 80,
            color: const Color(0xFFFF6B9D),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your favorites...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.bodyText,
            ),
          ),
        ],
      ),
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 120),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Iconsax.danger, size: 72, color: Colors.red),
          ),
          const SizedBox(height: 28),
          Text(
            'Oops! Something Went Wrong',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.bodyText.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadFavorites,
            icon: const Icon(Iconsax.refresh, size: 20),
            label: Text(
              'Try Again',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== EMPTY STATE ==========
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 120),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D).withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF6B9D).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Iconsax.heart,
              size: 80,
              color: const Color(0xFFFF6B9D).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'No Favorites Yet',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start adding chapters to your favorites\nto access them quickly',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.bodyText.withOpacity(0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ========== ENHANCED FAVORITE CARD ==========
class _EnhancedFavoriteCard extends StatefulWidget {
  final FavoriteChapter favorite;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final Color subjectColor;

  const _EnhancedFavoriteCard({
    required this.favorite,
    required this.index,
    required this.onTap,
    required this.onRemove,
    required this.subjectColor,
  });

  @override
  State<_EnhancedFavoriteCard> createState() => _EnhancedFavoriteCardState();
}

class _EnhancedFavoriteCardState extends State<_EnhancedFavoriteCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String _getStatusIcon() {
    switch (widget.favorite.completionStatus) {
      case 'Completed':
        return '✓';
      case 'In Progress':
        return '⟳';
      default:
        return '○';
    }
  }

  Color _getStatusColor() {
    switch (widget.favorite.completionStatus) {
      case 'Completed':
        return const Color(0xFF10B981);
      case 'In Progress':
        return const Color(0xFF6366F1);
      default:
        return AppTheme.bodyText.withOpacity(0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _scaleController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _scaleController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 420,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered
                    ? widget.subjectColor.withOpacity(0.5)
                    : AppTheme.borderGrey.withOpacity(0.12),
                width: _isHovered ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.subjectColor.withOpacity(0.25)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: _isHovered ? 32 : 12,
                  offset: Offset(0, _isHovered ? 16 : 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.subjectColor.withOpacity(0.1),
                        widget.subjectColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.subjectColor,
                                  widget.subjectColor.withOpacity(0.75),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.subjectColor.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Iconsax.book_1,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.favorite.subjectName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: widget.subjectColor,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Chapter ${widget.favorite.chapterOrder}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.bodyText.withOpacity(0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: widget.onRemove,
                            icon: const Icon(
                              Iconsax.heart,
                              color: Color(0xFFFF6B9D),
                              size: 22,
                            ),
                            tooltip: 'Remove from favorites',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.favorite.chapterName,
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkText,
                          letterSpacing: -0.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Content area
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and Progress
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor().withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getStatusIcon(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getStatusColor(),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.favorite.completionStatus,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _getStatusColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.subjectColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.chart_21,
                                  size: 14,
                                  color: widget.subjectColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${widget.favorite.progressPercentage.toStringAsFixed(0)}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: widget.subjectColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.bodyText.withOpacity(0.75),
                                ),
                              ),
                              Text(
                                '${widget.favorite.progressPercentage.toStringAsFixed(1)}% Complete',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.bodyText.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: widget.subjectColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              AnimatedFractionallySizedBox(
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOutCubic,
                                widthFactor:
                                widget.favorite.progressPercentage / 100,
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.subjectColor,
                                        widget.subjectColor.withOpacity(0.75),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                        widget.subjectColor.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Additional info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.bodyText.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.borderGrey.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.clock,
                              size: 16,
                              color: AppTheme.bodyText.withOpacity(0.5),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Last Accessed',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.bodyText.withOpacity(0.5),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.favorite.lastAccessedDisplay,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppTheme.darkText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.favorite.favoritedDate != null) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Iconsax.heart,
                                size: 16,
                                color: const Color(0xFFFF6B9D).withOpacity(0.7),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Added to Favorites',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppTheme.bodyText.withOpacity(0.5),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDate(widget.favorite.favoritedDate!),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppTheme.darkText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onTap,
                          icon: const Icon(Iconsax.play_circle, size: 20),
                          label: Text(
                            widget.favorite.completionStatus == 'Completed'
                                ? 'Review Chapter'
                                : widget.favorite.completionStatus == 'In Progress'
                                ? 'Continue Learning'
                                : 'Start Chapter',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.subjectColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, y').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }
}

// ========== FAVORITE CHAPTER MODEL ==========
class FavoriteChapter {
  final int recNo;
  final int chapterId;
  final String chapterName;
  final int chapterOrder;
  final int subjectId;
  final String subjectName;
  final double progressPercentage;
  final String completionStatus;
  final String? lastAccessedDate;
  final String lastAccessedDisplay;
  final String? favoritedDate;

  FavoriteChapter({
    required this.recNo,
    required this.chapterId,
    required this.chapterName,
    required this.chapterOrder,
    required this.subjectId,
    required this.subjectName,
    required this.progressPercentage,
    required this.completionStatus,
    this.lastAccessedDate,
    required this.lastAccessedDisplay,
    this.favoritedDate,
  });

  factory FavoriteChapter.fromJson(Map<String, dynamic> json) {
    return FavoriteChapter(
      recNo: json['RecNo'] ?? 0,
      chapterId: json['ChapterID'] ?? 0,
      chapterName: json['ChapterName'] ?? '',
      chapterOrder: json['ChapterOrder'] ?? 0,
      subjectId: json['SubjectID'] ?? 0,
      subjectName: json['SubjectName'] ?? '',
      progressPercentage: (json['Progress_Percentage'] ?? 0).toDouble(),
      completionStatus: json['Completion_Status'] ?? 'Not Started',
      lastAccessedDate: json['Last_Accessed_Date'],
      lastAccessedDisplay: json['Last_Accessed_Display'] ?? 'Never',
      favoritedDate: json['Favorited_Date'],
    );
  }
}
