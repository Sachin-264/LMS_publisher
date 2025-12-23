import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/screens/main_layout.dart';
import 'package:lms_publisher/service/board_master_service.dart';
import 'package:lms_publisher/util/beautiful_loader.dart';

class BoardMasterScreen extends StatelessWidget {
  const BoardMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 700;

    if (isPhone) {
      return MainLayout(
        activeScreen: AppScreen.boardMaster,
        child: const BoardMasterView(isPhoneMode: true),
      );
    } else {
      return DefaultTabController(
        length: 2,
        child: MainLayout(
          activeScreen: AppScreen.boardMaster,
          child: const BoardMasterView(isPhoneMode: false),
        ),
      );
    }
  }
}

class BoardMasterView extends StatefulWidget {
  final bool isPhoneMode;
  const BoardMasterView({super.key, required this.isPhoneMode});

  @override
  State<BoardMasterView> createState() => BoardMasterViewState();
}

class BoardMasterViewState extends State<BoardMasterView> {
  final BoardMasterService service = BoardMasterService();

  // Loading States
  bool isLoadingSchoolTypes = true;
  bool isLoadingMediums = false;
  bool isLoadingBoards = false;
  bool isLoadingManagements = false;
  bool isLoadingStatuses = false;

  // Data Lists
  List<Map<String, String>> schoolTypes = [];
  List<Map<String, String>> mediums = [];
  List<Map<String, String>> boards = [];
  List<Map<String, String>> managements = [];
  List<Map<String, String>> statuses = [];

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  void loadAllData() {
    loadSchoolTypes();
    loadMediums();
    loadBoards();
    loadManagements();
    loadStatuses();
  }

  // --- API Loaders ---

  Future<void> loadSchoolTypes() async {
    if (!mounted) return;
    setState(() => isLoadingSchoolTypes = true);
    try {
      final list = await service.getSchoolTypes();
      if (!mounted) return;
      setState(() {
        schoolTypes = list;
        isLoadingSchoolTypes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingSchoolTypes = false);
      showError('Failed to load school types: $e');
    }
  }

  Future<void> loadMediums() async {
    if (!mounted) return;
    setState(() => isLoadingMediums = true);
    try {
      final list = await service.getMediumInstructions();
      if (!mounted) return;
      setState(() {
        mediums = list;
        isLoadingMediums = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingMediums = false);
      showError('Failed to load mediums: $e');
    }
  }

  Future<void> loadBoards() async {
    if (!mounted) return;
    setState(() => isLoadingBoards = true);
    try {
      final list = await service.getBoardAffiliations();
      if (!mounted) return;
      setState(() {
        boards = list;
        isLoadingBoards = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingBoards = false);
      showError('Failed to load boards: $e');
    }
  }

  Future<void> loadManagements() async {
    if (!mounted) return;
    setState(() => isLoadingManagements = true);
    try {
      final list = await service.getManagementTypes();
      if (!mounted) return;
      setState(() {
        managements = list;
        isLoadingManagements = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingManagements = false);
      showError('Failed to load management types: $e');
    }
  }

  Future<void> loadStatuses() async {
    if (!mounted) return;
    setState(() => isLoadingStatuses = true);
    try {
      final list = await service.getStatuses();
      if (!mounted) return;
      setState(() {
        statuses = list;
        isLoadingStatuses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingStatuses = false);
      showError('Failed to load statuses: $e');
    }
  }

  // --- Dialogs ---

  void _showListDialog(String title, List<Map<String, String>> data, Function(Map<String, String>) onEdit, Function(String) onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: data.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text("No items found.", style: GoogleFonts.inter(color: Colors.grey)),
          )
              : ListView.separated(
            shrinkWrap: true,
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = data[index];
              return ListTile(
                dense: true,
                title: Text(item['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.edit_2, size: 18, color: AppTheme.bodyText),
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit(item);
                      },
                    ),
                    IconButton(
                      icon: Icon(Iconsax.trash, size: 18, color: Colors.red.shade400),
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete(item['id']!);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog({
    required String title,
    required String initialValue,
    required Function(String) onSave,
    required String label,
    required IconData icon,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: buildInputDecoration(label, icon),
            validator: (value) => value == null || value.trim().isEmpty ? '$label is required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.bodyText)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await onSave(controller.text.trim());
                if (!mounted) return;
                Navigator.pop(context);
              } catch (e) {
                // Error propagated to onSave
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(initialValue.isEmpty ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  // --- CRUD Wrappers ---

  void showSchoolTypeDialog([Map<String, String>? item]) {
    _showAddEditDialog(
      title: item == null ? 'Add School Type' : 'Edit School Type',
      initialValue: item?['name'] ?? '',
      label: 'School Type Name',
      icon: Iconsax.scroll,
      onSave: (val) async {
        try {
          if (item == null) {
            await service.insertSchoolType(val);
            showSuccess('School Type added');
          } else {
            await service.updateSchoolType(item['id']!, val);
            showSuccess('School Type updated');
          }
          loadSchoolTypes();
        } catch(e) { showError(e.toString()); rethrow; }
      },
    );
  }

  void showMediumDialog([Map<String, String>? item]) {
    _showAddEditDialog(
      title: item == null ? 'Add Medium' : 'Edit Medium',
      initialValue: item?['name'] ?? '',
      label: 'Medium Name',
      icon: Iconsax.language_circle,
      onSave: (val) async {
        try {
          if (item == null) {
            await service.insertMediumInstruction(val);
            showSuccess('Medium added');
          } else {
            await service.updateMediumInstruction(item['id']!, val);
            showSuccess('Medium updated');
          }
          loadMediums();
        } catch(e) { showError(e.toString()); rethrow; }
      },
    );
  }

  void showBoardDialog([Map<String, String>? item]) {
    _showAddEditDialog(
      title: item == null ? 'Add Board' : 'Edit Board',
      initialValue: item?['name'] ?? '',
      label: 'Board Name',
      icon: Iconsax.book,
      onSave: (val) async {
        try {
          if (item == null) {
            await service.insertBoardAffiliation(val);
            showSuccess('Board added');
          } else {
            await service.updateBoardAffiliation(item['id']!, val);
            showSuccess('Board updated');
          }
          loadBoards();
        } catch(e) { showError(e.toString()); rethrow; }
      },
    );
  }

  void showManagementDialog([Map<String, String>? item]) {
    _showAddEditDialog(
      title: item == null ? 'Add Management' : 'Edit Management',
      initialValue: item?['name'] ?? '',
      label: 'Management Name',
      icon: Iconsax.building,
      onSave: (val) async {
        try {
          if (item == null) {
            await service.insertManagementType(val);
            showSuccess('Management Type added');
          } else {
            await service.updateManagementType(item['id']!, val);
            showSuccess('Management Type updated');
          }
          loadManagements();
        } catch(e) { showError(e.toString()); rethrow; }
      },
    );
  }

  void showStatusDialog([Map<String, String>? item]) {
    _showAddEditDialog(
      title: item == null ? 'Add Status' : 'Edit Status',
      initialValue: item?['name'] ?? '',
      label: 'Status Name',
      icon: Iconsax.status,
      onSave: (val) async {
        try {
          if (item == null) {
            await service.insertStatus(val);
            showSuccess('Status added');
          } else {
            await service.updateStatus(item['id']!, val);
            showSuccess('Status updated');
          }
          loadStatuses();
        } catch(e) { showError(e.toString()); rethrow; }
      },
    );
  }

  Future<void> deleteItem(String type, String id, Function loader) async {
    try {
      switch(type) {
        case 'SchoolType': await service.deleteSchoolType(id); break;
        case 'Medium': await service.deleteMediumInstruction(id); break;
        case 'Board': await service.deleteBoardAffiliation(id); break;
        case 'Management': await service.deleteManagementType(id); break;
        case 'Status': await service.deleteStatus(id); break;
      }
      showSuccess('$type deleted successfully');
      loader();
    } catch(e) {
      showError('Failed to delete: $e');
    }
  }

  void showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppTheme.primaryGreen));
  }

  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  InputDecoration buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppTheme.bodyText, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryGreen),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderGrey.withOpacity(0.5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderGrey.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Phone Mode: Only show Quick Entry
    if (widget.isPhoneMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader('Board Master', 'Manage all master data'),
          const SizedBox(height: 16),
          Expanded(child: buildDirectEntryView()),
        ],
      );
    }

    // Tablet/Desktop: Tabs
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildHeader('Board Master', 'Manage School Types, Mediums, Boards, Management & Statuses'),
        const SizedBox(height: 16),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderGrey.withOpacity(0.2)),
          ),
          child: TabBar(
            indicator: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.bodyText,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.grid_1, size: 18), SizedBox(width: 8), Text("Card View")])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.add_square, size: 18), SizedBox(width: 8), Text("Quick Entry")])),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            children: [
              buildHierarchicalView(),
              buildDirectEntryView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.setting_2, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.bodyText)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Views ---

  Widget buildHierarchicalView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) crossAxisCount = 3;
        if (constraints.maxWidth > 1500) crossAxisCount = 4;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
          padding: const EdgeInsets.all(4),
          children: [
            buildCard('School Types', schoolTypes.length, Iconsax.scroll, () => showSchoolTypeDialog(), schoolTypes, isLoadingSchoolTypes,
                    (item) => showSchoolTypeDialog(item), (id) => deleteItem('SchoolType', id, loadSchoolTypes)),

            buildCard('Mediums', mediums.length, Iconsax.language_circle, () => showMediumDialog(), mediums, isLoadingMediums,
                    (item) => showMediumDialog(item), (id) => deleteItem('Medium', id, loadMediums)),

            buildCard('Boards', boards.length, Iconsax.book, () => showBoardDialog(), boards, isLoadingBoards,
                    (item) => showBoardDialog(item), (id) => deleteItem('Board', id, loadBoards)),

            buildCard('Managements', managements.length, Iconsax.building, () => showManagementDialog(), managements, isLoadingManagements,
                    (item) => showManagementDialog(item), (id) => deleteItem('Management', id, loadManagements)),

            buildCard('Statuses', statuses.length, Iconsax.status, () => showStatusDialog(), statuses, isLoadingStatuses,
                    (item) => showStatusDialog(item), (id) => deleteItem('Status', id, loadStatuses)),
          ],
        );
      },
    );
  }

  Widget buildCard(
      String title,
      int count,
      IconData icon,
      VoidCallback onAdd,
      List<Map<String, String>> data,
      bool isLoading,
      Function(Map<String, String>) onEdit,
      Function(String) onDelete,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(8)),
                  child: Text('$count', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                InkWell(onTap: onAdd, child: const Icon(Iconsax.add_circle, color: AppTheme.primaryGreen, size: 22))
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: isLoading
                ? const Center(child: BeautifulLoader(type: LoaderType.spinner, size: 30, color: AppTheme.primaryGreen))
                : data.isEmpty
                ? Center(child: Text("No items", style: GoogleFonts.inter(color: AppTheme.bodyText, fontSize: 12)))
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(item['name']!, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.darkText)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(onTap: () => onEdit(item), child: const Icon(Iconsax.edit_2, size: 16, color: AppTheme.bodyText)),
                      const SizedBox(width: 12),
                      InkWell(onTap: () => onDelete(item['id']!), child: Icon(Iconsax.trash, size: 16, color: Colors.red.shade400)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Quick Entry View ---

  Widget buildDirectEntryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            _buildDirectEntryRow('School Type', Iconsax.scroll, 'Enter school type name',
                    (val) async { await service.insertSchoolType(val); loadSchoolTypes(); showSuccess('Added School Type'); },
                    () => _showListDialog('School Types', schoolTypes, (i) => showSchoolTypeDialog(i), (id) => deleteItem('SchoolType', id, loadSchoolTypes))
            ),
            const Divider(height: 1),
            _buildDirectEntryRow('Medium', Iconsax.language_circle, 'Enter medium name',
                    (val) async { await service.insertMediumInstruction(val); loadMediums(); showSuccess('Added Medium'); },
                    () => _showListDialog('Mediums', mediums, (i) => showMediumDialog(i), (id) => deleteItem('Medium', id, loadMediums))
            ),
            const Divider(height: 1),
            _buildDirectEntryRow('Board', Iconsax.book, 'Enter board name',
                    (val) async { await service.insertBoardAffiliation(val); loadBoards(); showSuccess('Added Board'); },
                    () => _showListDialog('Boards', boards, (i) => showBoardDialog(i), (id) => deleteItem('Board', id, loadBoards))
            ),
            const Divider(height: 1),
            _buildDirectEntryRow('Management', Iconsax.building, 'Enter management name',
                    (val) async { await service.insertManagementType(val); loadManagements(); showSuccess('Added Management'); },
                    () => _showListDialog('Management Types', managements, (i) => showManagementDialog(i), (id) => deleteItem('Management', id, loadManagements))
            ),
            const Divider(height: 1),
            _buildDirectEntryRow('Status', Iconsax.status, 'Enter status name',
                    (val) async { await service.insertStatus(val); loadStatuses(); showSuccess('Added Status'); },
                    () => _showListDialog('Statuses', statuses, (i) => showStatusDialog(i), (id) => deleteItem('Status', id, loadStatuses))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectEntryRow(String label, IconData icon, String hint, Future<void> Function(String) onAdd, VoidCallback onView) {
    return _DirectEntryRow(label: label, icon: icon, hint: hint, onAdd: onAdd, onView: onView);
  }
}

// Helper Widget for Row to manage state cleanly
class _DirectEntryRow extends StatefulWidget {
  final String label;
  final IconData icon;
  final String hint;
  final Future<void> Function(String) onAdd;
  final VoidCallback onView;

  const _DirectEntryRow({
    required this.label,
    required this.icon,
    required this.hint,
    required this.onAdd,
    required this.onView,
  });

  @override
  State<_DirectEntryRow> createState() => _DirectEntryRowState();
}

class _DirectEntryRowState extends State<_DirectEntryRow> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  void _handleAdd() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await widget.onAdd(_controller.text.trim());
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(10)),
            child: Icon(widget.icon, color: AppTheme.darkText, size: 20),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 110,
            child: Text(widget.label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.darkText)),
          ),
          Expanded(
            child: SizedBox(
              height: 45,
              child: TextField(
                controller: _controller,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: AppTheme.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // View Button (New Feature)
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
            ),
            child: IconButton(
              onPressed: widget.onView,
              icon: const Icon(Iconsax.eye, size: 20, color: AppTheme.bodyText),
              tooltip: 'View List',
            ),
          ),
          const SizedBox(width: 8),

          // Add Button
          SizedBox(
            width: 80,
            height: 45,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}