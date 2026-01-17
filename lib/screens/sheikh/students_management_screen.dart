import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../models/student.dart';
import '../../services/firestore_service.dart';

/// StudentsManagementScreen: Admin tools for managing the student roster.
///
/// Responsibilities:
/// 1. Student List: Displays all students assigned to the Sheikh.
/// 2. Parent Mapping: Uses a Combined Stream to join student data with parent names for context.
/// 3. Profile Editing: Allows updating student names, ages, and re-assigning them to different parents.
/// 4. CRUD Operations: Provides interfaces for updating and deleting student profiles.
class StudentsManagementScreen extends StatefulWidget {
  const StudentsManagementScreen({super.key});

  @override
  State<StudentsManagementScreen> createState() =>
      _StudentsManagementScreenState();
}

class _StudentsManagementScreenState extends State<StudentsManagementScreen> {
  final _firestoreService = FirestoreService();
  String _searchQuery = '';
  final _searchController = TextEditingController();

  /// Reactive stream joining Student data with Parent account information.
  late Stream<List<Map<String, dynamic>>> _combinedStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  /// Initializes the joined stream using rxdart's CombineLatest.
  void _initStream() {
    _combinedStream = CombineLatestStream.combine2(
      _firestoreService.getAllStudents(),
      _firestoreService.getParents(),
      (List<Student> students, List<Map<String, dynamic>> parents) {
        // Map student object to include parent name string for the UI.
        return students.map((student) {
          final parent = parents.firstWhere(
            (p) => p['uid'] == student.parentId,
            orElse: () => {'name': null},
          );
          return {'student': student, 'parentName': parent['name']};
        }).toList();
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _combinedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = snapshot.data ?? [];
          final filteredItems = allItems.where((item) {
            final Student student = item['student'];
            return student.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          }).toList();

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                elevation: 0,
                automaticallyImplyLeading: false,
                backgroundColor: AppTheme.primaryColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.students,
                            style: GoogleFonts.tajawal(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // --- Dynamic Search Bar ---
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value),
                                style: GoogleFonts.tajawal(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'بحث عن طالب...',
                                  hintStyle: GoogleFonts.tajawal(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppTheme.primaryColor,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            body: RefreshIndicator(
              onRefresh: () async {
                setState(() => _initStream());
              },
              color: AppTheme.primaryColor,
              child: filteredItems.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _searchQuery.isEmpty
                                    ? Icons.person_add
                                    : Icons.search_off,
                                size: 48,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'لا يوجد طلاب'
                                  : 'لا توجد نتائج',
                              style: GoogleFonts.tajawal(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildStudentTile(
                          item['student'],
                          item['parentName'],
                        );
                      },
                    ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  /// Builds a student row containing metadata and management action buttons.
  Widget _buildStudentTile(Student student, String? parentName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEditStudentDialog(student),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.titleSmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            parentName ?? AppStrings.noParent,
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.cake_outlined,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${student.age} سنة',
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () => _showEditStudentDialog(student),
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_rounded,
                        color: AppTheme.errorColor,
                      ),
                      onPressed: () => _confirmDelete(student),
                      tooltip: 'حذف',
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

  /// Opens a stylized bottom sheet to modify student metadata.
  void _showEditStudentDialog(Student student) {
    final nameController = TextEditingController(text: student.name);
    final ageController = TextEditingController(text: student.age.toString());
    String? selectedParentId = student.parentId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.editStudent,
                    style: GoogleFonts.tajawal(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildModalTextField(
                nameController,
                AppStrings.studentName,
                Icons.person,
              ),
              const SizedBox(height: 16),
              _buildModalTextField(
                ageController,
                AppStrings.studentAge,
                Icons.cake,
                isNumber: true,
              ),
              const SizedBox(height: 16),
              // --- Parent Linkage Dropdown ---
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.getParents(),
                builder: (context, snapshot) {
                  final parents = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: selectedParentId,
                    decoration: InputDecoration(
                      labelText: AppStrings.selectParent,
                      labelStyle: GoogleFonts.tajawal(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      prefixIcon: Icon(
                        Icons.family_restroom,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).inputDecorationTheme.fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          AppStrings.noParent,
                          style: GoogleFonts.tajawal(),
                        ),
                      ),
                      ...parents.map(
                        (p) => DropdownMenuItem(
                          value: p['uid'],
                          child: Text(
                            p['name'] ?? '',
                            style: GoogleFonts.tajawal(),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => selectedParentId = value),
                  );
                },
              ),
              const SizedBox(height: 24),
              // --- Submission Action ---
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        ageController.text.isNotEmpty) {
                      final updated = student.copyWith(
                        name: nameController.text,
                        age: int.tryParse(ageController.text) ?? student.age,
                        parentId: selectedParentId,
                      );
                      await _firestoreService.updateStudent(updated);
                      if (context.mounted) {
                        Navigator.pop(context);
                        _showSuccessSnackBar('تم تعديل بيانات الطالب');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppStrings.save,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shared helper for building dialog text inputs with consistent RTL styling.
  Widget _buildModalTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.tajawal(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.tajawal(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  /// Triggers a destructive confirmation dialog before removing a student profile.
  void _confirmDelete(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            Text(
              AppStrings.deleteStudent,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
        content: Text(
          '${AppStrings.deleteStudentConfirm}\n\n${student.name}',
          style: GoogleFonts.tajawal(),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.cancel,
              style: GoogleFonts.tajawal(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Cascade deletion is handled within the FirestoreService.
              await _firestoreService.deleteStudent(student.id);
              if (context.mounted) {
                Navigator.pop(context);
                _showSuccessSnackBar('تم حذف الطالب');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              AppStrings.delete,
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Displays a floating feedback bar upon successful operations.
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: GoogleFonts.tajawal()),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
