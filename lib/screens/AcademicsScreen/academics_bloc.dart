import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_publisher/Service/academics_service.dart';
import 'package:lms_publisher/screens/AcademicsScreen/academics_content.dart';

// ==================== HELPER FUNCTIONS ====================
// Helper to check if it's a YouTube video link
bool isYoutubeVideo(String url) {
  return url.contains('youtube.com') || url.contains('youtu.be');
}

// Helper to extract YouTube video ID from URL
String? extractYoutubeVideoId(String url) {
  // Handle various YouTube URL formats
  final patterns = [
    RegExp(r'youtube\.com/watch\?v=([^&]+)'),
    RegExp(r'youtu\.be/([^?]+)'),
    RegExp(r'youtube\.com/embed/([^?]+)'),
  ];

  for (var pattern in patterns) {
    final match = pattern.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
  }
  return null;
}

// ==================== EVENTS ====================
abstract class AcademicsEvent {}

class LoadKPIEvent extends AcademicsEvent {}

class LoadClassesEvent extends AcademicsEvent {
  final int? schoolRecNo;
  final int? classId;
  LoadClassesEvent({this.schoolRecNo, this.classId});
}

class LoadSubjectsEvent extends AcademicsEvent {
  final int? schoolRecNo;
  final int? classId;
  LoadSubjectsEvent({this.schoolRecNo, this.classId});
}

class LoadChaptersEvent extends AcademicsEvent {
  final int? schoolRecNo;
  final int? classId;
  final int? subjectId;
  LoadChaptersEvent({this.schoolRecNo, this.classId, this.subjectId});
}

class LoadMaterialsEvent extends AcademicsEvent {
  final int? schoolRecNo;
  final int? classId;
  final int? subjectId;
  final int? chapterId;
  LoadMaterialsEvent({this.schoolRecNo, this.classId, this.subjectId, this.chapterId});
}

class ToggleMaterialViewEvent extends AcademicsEvent {
  final bool isGrid;
  ToggleMaterialViewEvent(this.isGrid);
}

class FilterMaterialsByTypeEvent extends AcademicsEvent {
  final String materialType;
  FilterMaterialsByTypeEvent(this.materialType);
}

// Delete Events
class DeleteClassEvent extends AcademicsEvent {
  final int classId;
  final bool hardDelete;
  final String modifiedBy;

  DeleteClassEvent({required this.classId, this.hardDelete = false, this.modifiedBy = 'Admin'});
}

class DeleteSubjectEvent extends AcademicsEvent {
  final int subjectId;
  final bool hardDelete;
  final String modifiedBy;

  DeleteSubjectEvent({required this.subjectId, this.hardDelete = false, this.modifiedBy = 'Admin'});
}

class DeleteChapterEvent extends AcademicsEvent {
  final int chapterId;
  final bool hardDelete;
  final String modifiedBy;

  DeleteChapterEvent({required this.chapterId, this.hardDelete = false, this.modifiedBy = 'Admin'});
}

class DeleteMaterialEvent extends AcademicsEvent {
  final int recNo;
  final bool hardDelete;
  final String modifiedBy;

  DeleteMaterialEvent({required this.recNo, this.hardDelete = false, this.modifiedBy = 'Admin'});
}

// ==================== STATES ====================
abstract class AcademicsState {}

class AcademicsInitial extends AcademicsState {}

class AcademicsLoading extends AcademicsState {}

class KPILoaded extends AcademicsState {
  final String totalClasses;
  final String totalSubjects;
  final String totalChapters;
  final String totalMaterials;

  KPILoaded({
    required this.totalClasses,
    required this.totalSubjects,
    required this.totalChapters,
    required this.totalMaterials,
  });
}

class ClassesLoaded extends AcademicsState {
  final List<ClassModel> classes;
  ClassesLoaded(this.classes);
}

class SubjectsLoaded extends AcademicsState {
  final List<SubjectModel> subjects;
  SubjectsLoaded(this.subjects);
}

class ChaptersLoaded extends AcademicsState {
  final List<ChapterModel> chapters;
  ChaptersLoaded(this.chapters);
}

class MaterialsLoaded extends AcademicsState {
  final List<MaterialModel> materials;
  final bool isGridView;
  MaterialsLoaded(this.materials, {this.isGridView = true});
}

class AcademicsError extends AcademicsState {
  final String message;
  AcademicsError(this.message);
}

// ==================== MODELS ====================

class ClassModel {
  final int id;
  final String name;
  final String description;
  final int displayOrder;
  final bool isActive;
  final String pubCode;
  final int? subjectCount;

  ClassModel({
    required this.id,
    required this.name,
    required this.description,
    required this.displayOrder,
    required this.isActive,
    required this.pubCode,
    this.subjectCount,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['ClassID'] ?? 0,
      name: json['ClassName']?.toString() ?? '',
      description: json['ClassDescription']?.toString() ?? '',
      displayOrder: json['DisplayOrder'] ?? 0,
      isActive: json['IsActive'] == 1 || json['IsActive'] == true,
      pubCode: json['PubCode']?.toString() ?? '0',
      subjectCount: json['TotalSubjects'],
    );
  }
}


class SubjectModel {
  final int id;
  final int classId;
  final String name;
  final String code;
  final String description;
  final String color;
  final bool isActive;
  final String pubCode;

  // Optional fields that may come from API with joins
  final String? className;
  final int? chapterCount;

  SubjectModel({
    required this.id,
    required this.classId,
    required this.name,
    required this.code,
    required this.description,
    required this.color,
    required this.isActive,
    required this.pubCode,
    this.className,
    this.chapterCount,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['SubjectID'] ?? 0,
      classId: json['ClassID'] ?? 0,
      name: json['SubjectName']?.toString() ?? '',
      code: json['SubjectCode']?.toString() ?? '',
      description: json['SubjectDescription']?.toString() ?? '',
      color: json['SubjectColor']?.toString() ?? '#4CAF50',
      isActive: json['IsActive'] == 1 || json['IsActive'] == true,
      pubCode: json['PubCode']?.toString() ?? '0',
      className: json['ClassName']?.toString(),
      chapterCount: json['TotalChapters'],
    );
  }
}

class ChapterModel {
  final int id;
  final int subjectId;
  final String name;
  final String code;
  final String description;
  final int order;
  final bool isActive;
  final String pubCode;

  // Optional fields that may come from API with joins
  final String? subjectName;
  final int? materialCount;

  ChapterModel({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.code,
    required this.description,
    required this.order,
    required this.isActive,
    required this.pubCode,
    this.subjectName,
    this.materialCount,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['ChapterID'] ?? 0,
      subjectId: json['SubjectID'] ?? 0,
      name: json['ChapterName']?.toString() ?? '',
      code: json['ChapterCode']?.toString() ?? '',
      description: json['ChapterDescription']?.toString() ?? '',
      order: json['ChapterOrder'] ?? 0,
      isActive: json['IsActive'] == 1 || json['IsActive'] == true,
      pubCode: json['PubCode']?.toString() ?? '0',
      subjectName: json['SubjectName']?.toString(),
      materialCount: json['MaterialCount'],
    );
  }
}

class MaterialModel {
  final int recNo;
  final int materialId;
  final int chapterId;
  final String chapterName;
  final int subjectId;
  final String subjectName;
  final int classId;
  final String className;
  final DateTime? uploadedOn;
  final List<Map<String, dynamic>> videoLinks;
  final List<Map<String, dynamic>> worksheets;
  final List<Map<String, dynamic>> extraQuestions;
  final List<Map<String, dynamic>> solvedQuestions;
  final List<Map<String, dynamic>> revisionNotes;
  final List<Map<String, dynamic>> lessonPlans;
  final List<Map<String, dynamic>> teachingAids;
  final List<Map<String, dynamic>> assessmentTools;
  final List<Map<String, dynamic>> homeworkTools;
  final List<Map<String, dynamic>> practiceZone;
  final List<Map<String, dynamic>> learningPath;

  MaterialModel({
    required this.recNo,
    required this.materialId,
    required this.chapterId,
    required this.chapterName,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
    required this.className,
    this.uploadedOn,
    required this.videoLinks,
    required this.worksheets,
    required this.extraQuestions,
    required this.solvedQuestions,
    required this.revisionNotes,
    required this.lessonPlans,
    required this.teachingAids,
    required this.assessmentTools,
    required this.homeworkTools,
    required this.practiceZone,
    required this.learningPath,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    print('🏭 [MaterialModel.fromJson] Starting parse for RecNo: ${json['RecNo']}');

    // ✅ CALL parseXmlFiles for each field
    final videoLinks = parseXmlFiles(json['Video_Link'] ?? '');
    final worksheets = parseXmlFiles(json['Worksheet_Path'] ?? '');
    final extraQuestions = parseXmlFiles(json['Extra_Questions_Path'] ?? '');
    final solvedQuestions = parseXmlFiles(json['Solved_Questions_Path'] ?? '');
    final revisionNotes = parseXmlFiles(json['Revision_Notes_Path'] ?? '');
    final lessonPlans = parseXmlFiles(json['Lesson_Plans_Path'] ?? '');
    final teachingAids = parseXmlFiles(json['Teaching_Aids_Path'] ?? '');
    final assessmentTools = parseXmlFiles(json['Assessment_Tools_Path'] ?? '');
    final homeworkTools = parseXmlFiles(json['Homework_Tools_Path'] ?? '');
    final practiceZone = parseXmlFiles(json['Practice_Zone_Path'] ?? '');
    final learningPath = parseXmlFiles(json['Learning_Path_Path'] ?? '');

    print('🎬 Material Debug: RecNo=${json['RecNo']}, Chapter="${json['ChapterName']}", Videos=${videoLinks.length}, Worksheets=${worksheets.length}, TotalFiles=${videoLinks.length + worksheets.length + extraQuestions.length + solvedQuestions.length + revisionNotes.length + lessonPlans.length + teachingAids.length + assessmentTools.length + homeworkTools.length + practiceZone.length + learningPath.length}');

    return MaterialModel(
      recNo: json['RecNo'] ?? 0,
      materialId: json['Material_ID'] ?? 0,
      chapterId: json['Chapter_ID'] ?? 0,
      chapterName: json['ChapterName'] ?? '',
      subjectId: json['SubjectID'] ?? 0,
      subjectName: json['SubjectName'] ?? '',
      classId: json['ClassID'] ?? 0,
      className: json['ClassName'] ?? '',
      uploadedOn: json['Uploaded_On'] != null ? DateTime.tryParse(json['Uploaded_On']) : null,
      videoLinks: videoLinks,
      worksheets: worksheets,
      extraQuestions: extraQuestions,
      solvedQuestions: solvedQuestions,
      revisionNotes: revisionNotes,
      lessonPlans: lessonPlans,
      teachingAids: teachingAids,
      assessmentTools: assessmentTools,
      homeworkTools: homeworkTools,
      practiceZone: practiceZone,
      learningPath: learningPath,
    );
  }


  // Helper methods to check if material types exist
  bool get hasVideos => videoLinks.isNotEmpty;
  bool get hasWorksheets => worksheets.isNotEmpty;
  bool get hasExtraQuestions => extraQuestions.isNotEmpty;
  bool get hasSolvedQuestions => solvedQuestions.isNotEmpty;
  bool get hasRevisionNotes => revisionNotes.isNotEmpty;
  bool get hasLessonPlans => lessonPlans.isNotEmpty;
  bool get hasTeachingAids => teachingAids.isNotEmpty;
  bool get hasAssessmentTools => assessmentTools.isNotEmpty;
  bool get hasHomeworkTools => homeworkTools.isNotEmpty;
  bool get hasPracticeZone => practiceZone.isNotEmpty;
  bool get hasLearningPath => learningPath.isNotEmpty;

  bool get hasAnyMaterial =>
      hasVideos ||
          hasWorksheets ||
          hasExtraQuestions ||
          hasSolvedQuestions ||
          hasRevisionNotes ||
          hasLessonPlans ||
          hasTeachingAids ||
          hasAssessmentTools ||
          hasHomeworkTools ||
          hasPracticeZone ||
          hasLearningPath;
}



// ==================== BLOC CLASS ====================
class AcademicsBloc extends Bloc<AcademicsEvent, AcademicsState> {
  AcademicsBloc() : super(AcademicsInitial()) {
    print('🎯 AcademicsBloc initialized');
    on<LoadKPIEvent>(_onLoadKPI);
    on<LoadClassesEvent>(_onLoadClasses);
    on<LoadSubjectsEvent>(_onLoadSubjects);
    on<LoadChaptersEvent>(_onLoadChapters);
    on<LoadMaterialsEvent>(_onLoadMaterials);
    on<ToggleMaterialViewEvent>(_onToggleMaterialView);
    on<FilterMaterialsByTypeEvent>(_onFilterMaterialsByType);
    on<DeleteClassEvent>(_onDeleteClass);
    on<DeleteSubjectEvent>(_onDeleteSubject);
    on<DeleteChapterEvent>(_onDeleteChapter);
    on<DeleteMaterialEvent>(_onDeleteMaterial);
  }

  bool _isGridView = true;
  List<MaterialModel> _cachedMaterials = [];
  List<MaterialModel> _allMaterials = [];
  String _currentMaterialTypeFilter = 'All';

  String get currentMaterialTypeFilter => _currentMaterialTypeFilter;

  Future<void> _onLoadKPI(LoadKPIEvent event, Emitter<AcademicsState> emit) async {
    print("📊 Loading KPI data...");
    emit(AcademicsLoading());

    try {
      final response = await ApiService.getAcademicsKPI();
      print("📊 KPI Response: $response");

      if (response['success'] == true && response['EntityCounts'] != null) {
        // EntityCounts is an object, not an array - access it directly
        final data = response['EntityCounts'];
        print("✅ KPI Data loaded successfully: $data");

        emit(KPILoaded(
          totalClasses: data['TotalClasses']?.toString() ?? '0',
          totalSubjects: data['TotalSubjects']?.toString() ?? '0',
          totalChapters: data['TotalChapters']?.toString() ?? '0',
          totalMaterials: data['TotalMaterials']?.toString() ?? '0',
        ));
      } else {
        print("❌ KPI Failed: Response format incorrect");
        emit(AcademicsError('Failed to load KPI data'));
      }
    } catch (e) {
      print("❌ KPI Error: $e");
      emit(AcademicsError('Error loading KPI: $e'));
    }
  }


  Future<void> _onLoadClasses(LoadClassesEvent event, Emitter<AcademicsState> emit) async {
    print('🏫 Loading Classes...');
    emit(AcademicsLoading()); // Always emit loading state to force refresh

    try {
      final response = await ApiService.getClasses(
        schoolRecNo: event.schoolRecNo ?? 1,
        classId: event.classId,
      );
      print('🏫 Classes Response: $response');

      if ((response['status'] == 'success' || response['success'] == true) &&
          response['data'] != null) {
        final List<dynamic> data = response['data'];
        final classes = data.map((json) => ClassModel.fromJson(json)).toList();
        print('✅ Parsed ${classes.length} classes');
        emit(ClassesLoaded(classes));
      } else {
        print('⚠️ No classes data found');
        emit(ClassesLoaded([]));
      }
    } catch (e) {
      print('❌ Classes Error: $e');
      emit(AcademicsError('Error loading classes: $e'));
    }
  }

  Future<void> _onLoadSubjects(LoadSubjectsEvent event, Emitter<AcademicsState> emit) async {
    print('📚 Loading Subjects...');
    emit(AcademicsLoading()); // Always emit loading state to force refresh

    try {
      print('🔎 [Bloc] LoadSubjectsEvent → ClassID=${event.classId}');
      final response = await ApiService.getSubjects(classId: event.classId);
      print('📚 Subjects Response: $response');

      if ((response['status'] == 'success' || response['success'] == true) &&
          response['data'] != null) {
        final List<dynamic> data = response['data'];
        final subjects = data.map((json) => SubjectModel.fromJson(json)).toList();
        print('✅ Parsed ${subjects.length} subjects');
        emit(SubjectsLoaded(subjects));
      } else {
        print('⚠️ No subjects data found');
        emit(SubjectsLoaded([]));
      }
    } catch (e) {
      print('❌ Subjects Error: $e');
      emit(AcademicsError('Error loading subjects: $e'));
    }
  }

  Future<void> _onLoadChapters(LoadChaptersEvent event, Emitter<AcademicsState> emit) async {
    print('📖 Loading Chapters...');
    emit(AcademicsLoading()); // Always emit loading state to force refresh

    try {
      print('🔎 [Bloc] LoadChaptersEvent → ClassID=${event.classId}, SubjectID=${event.subjectId}');
      final response = await ApiService.getChapters(classId: event.classId, subjectId: event.subjectId);
      print('📖 Chapters Response: $response');

      if ((response['status'] == 'success' || response['success'] == true) &&
          response['data'] != null) {
        final List<dynamic> data = response['data'];
        final chapters = data.map((json) => ChapterModel.fromJson(json)).toList();
        print('✅ Parsed ${chapters.length} chapters');
        emit(ChaptersLoaded(chapters));
      } else {
        print('⚠️ No chapters data found');
        emit(ChaptersLoaded([]));
      }
    } catch (e) {
      print('❌ Chapters Error: $e');
      emit(AcademicsError('Error loading chapters: $e'));
    }
  }

  void _onFilterMaterialsByType(FilterMaterialsByTypeEvent event, Emitter<AcademicsState> emit) {
    print('🔄 Filtering materials by type: ${event.materialType}');
    _currentMaterialTypeFilter = event.materialType;

    List<MaterialModel> filteredMaterials;
    if (event.materialType == 'All') {
      filteredMaterials = _allMaterials;
    } else {
      filteredMaterials = _allMaterials.where((material) {
        switch (event.materialType) {
          case 'Video':
            return material.hasVideos;
          case 'Worksheet':
            return material.hasWorksheets;
          case 'Extra Questions':
            return material.hasExtraQuestions;
          case 'Solved Questions':
            return material.hasSolvedQuestions;
          case 'Revision Notes':
            return material.hasRevisionNotes;
          case 'Lesson Plans':
            return material.hasLessonPlans;
          case 'Teaching Aids':
            return material.hasTeachingAids;
          case 'Assessment Tools':
            return material.hasAssessmentTools;
          case 'Homework Tools':
            return material.hasHomeworkTools;
          case 'Practice Zone':
            return material.hasPracticeZone;
          case 'Learning Path':
            return material.hasLearningPath;
          default:
            return true;

        }
      }).toList();
    }

    _cachedMaterials = filteredMaterials;
    print('✅ Filtered ${filteredMaterials.length} materials for type: ${event.materialType}');
    emit(MaterialsLoaded(_cachedMaterials, isGridView: _isGridView));
  }

  Future<void> _onLoadMaterials(LoadMaterialsEvent event, Emitter<AcademicsState> emit) async {
    print('📁 Loading Materials...');
    emit(AcademicsLoading()); // Always emit loading state to force refresh

    try {
      print('🔎 [Bloc] LoadMaterialsEvent → ClassID=${event.classId}, SubjectID=${event.subjectId}, ChapterID=${event.chapterId}');
      final response = await ApiService.getMaterials(
        classId: event.classId,
        subjectId: event.subjectId,
        chapterId: event.chapterId,
      );
      print('📁 Materials Response: $response');

      if ((response['status'] == 'success' || response['success'] == true) &&
          response['data'] != null) {
        final List<dynamic> data = response['data'];
        _allMaterials = data.map((json) {
          final material = MaterialModel.fromJson(json);
          // Updated debug info using new MaterialModel structure
          print('🎬 Material Debug: RecNo=${material.recNo}, Chapter="${material.chapterName}", '
              'Videos=${material.videoLinks.length}, Worksheets=${material.worksheets.length}, '
              'TotalFiles=${material.videoLinks.length + material.worksheets.length + material.extraQuestions.length}');
          return material;
        }).toList();
        print('✅ Parsed ${_allMaterials.length} materials');

        // Re-apply current filter
        if (_currentMaterialTypeFilter != 'All') {
          _onFilterMaterialsByType(
              FilterMaterialsByTypeEvent(_currentMaterialTypeFilter),
              emit
          );
        } else {
          _cachedMaterials = _allMaterials;
          emit(MaterialsLoaded(_cachedMaterials, isGridView: _isGridView));
        }
      } else {
        print('⚠️ No materials data found');
        _allMaterials = [];
        _cachedMaterials = [];
        emit(MaterialsLoaded([], isGridView: _isGridView));
      }
    } catch (e) {
      print('❌ Materials Error: $e');
      emit(AcademicsError('Error loading materials: $e'));
    }
  }


  void _onToggleMaterialView(ToggleMaterialViewEvent event, Emitter<AcademicsState> emit) {
    print('🔄 Toggling material view to: ${event.isGrid ? "Grid" : "List"}');
    _isGridView = event.isGrid;
    emit(MaterialsLoaded(_cachedMaterials, isGridView: _isGridView));
  }

  // ==================== UPDATED DELETE HANDLERS ====================

  Future<void> _onDeleteClass(DeleteClassEvent event, Emitter<AcademicsState> emit) async {
    print('🗑️ AcademicsBloc: Deleting Class ID: ${event.classId}, Hard Delete: ${event.hardDelete}');
    emit(AcademicsLoading());

    try {
      final response = await ApiService.manageAcademicModule({
        'table': 'Class_Master',
        'operation': 'DELETE',
        'ClassID': event.classId,
        'HardDelete': event.hardDelete ? 1 : 0,
        'ModifiedBy': event.modifiedBy,
      });

      print('📥 AcademicsBloc: Delete Class Response: $response');

      if (response['status'] == 'success' || response['success'] == true) {
        print('✅ AcademicsBloc: Class deleted successfully. Reloading...');
        // ✅ FIX: Use event to reload instead of manual fetch
        add(LoadClassesEvent(schoolRecNo: 1));
        add(LoadKPIEvent());
      } else {
        print('❌ AcademicsBloc: Failed to delete class');
        emit(AcademicsError('Failed to delete class'));
        // ✅ FIX: Reload to reset UI from loading state
        add(LoadClassesEvent(schoolRecNo: 1));
      }
    } catch (e) {
      print('❌ AcademicsBloc: Exception during delete - $e');
      emit(AcademicsError('Error deleting class: $e'));
      // ✅ FIX: Reload to reset UI from loading state
      add(LoadClassesEvent(schoolRecNo: 1));
    }
  }

  Future<void> _onDeleteSubject(DeleteSubjectEvent event, Emitter<AcademicsState> emit) async {
    print('🗑️ AcademicsBloc: Deleting Subject ID: ${event.subjectId}, Hard Delete: ${event.hardDelete}');
    emit(AcademicsLoading());

    try {
      final response = await ApiService.manageAcademicModule({
        'table': 'Subject_Name_Master',
        'operation': 'DELETE',
        'SubjectID': event.subjectId,
        'HardDelete': event.hardDelete ? 1 : 0,
        'ModifiedBy': event.modifiedBy,
      });

      print('📥 AcademicsBloc: Delete Subject Response: $response');

      if (response['status'] == 'success' || response['success'] == true) {
        print('✅ AcademicsBloc: Subject deleted successfully. Reloading...');
        // ✅ FIX: Use event to reload
        add(LoadSubjectsEvent(schoolRecNo: 1));
        add(LoadKPIEvent());
      } else {
        print('❌ AcademicsBloc: Failed to delete subject - ${response['message'] ?? 'Unknown error'}');
        emit(AcademicsError('Failed to delete subject'));
        // ✅ FIX: Reload to reset UI
        add(LoadSubjectsEvent(schoolRecNo: 1));
      }
    } catch (e) {
      print('❌ AcademicsBloc: Exception during delete - $e');
      emit(AcademicsError('Error deleting subject: $e'));
      // ✅ FIX: Reload to reset UI
      add(LoadSubjectsEvent(schoolRecNo: 1));
    }
  }

  Future<void> _onDeleteChapter(DeleteChapterEvent event, Emitter<AcademicsState> emit) async {
    print('🗑️ AcademicsBloc: Deleting Chapter ID: ${event.chapterId}, Hard Delete: ${event.hardDelete}');
    emit(AcademicsLoading());

    try {
      final response = await ApiService.manageAcademicModule({
        'table': 'Chapter_Master',
        'operation': 'DELETE',
        'ChapterID': event.chapterId,
        'HardDelete': event.hardDelete ? 1 : 0,
        'ModifiedBy': event.modifiedBy,
      });

      print('📥 AcademicsBloc: Delete Chapter Response: $response');

      if (response['status'] == 'success' || response['success'] == true) {
        print('✅ AcademicsBloc: Chapter deleted successfully. Reloading...');
        // ✅ FIX: Use event to reload
        add(LoadChaptersEvent(schoolRecNo: 1));
        add(LoadKPIEvent());
      } else {
        print('❌ AcademicsBloc: Failed to delete chapter');
        emit(AcademicsError('Failed to delete chapter'));
        // ✅ FIX: Reload to reset UI
        add(LoadChaptersEvent(schoolRecNo: 1));
      }
    } catch (e) {
      print('❌ AcademicsBloc: Exception during delete - $e');
      emit(AcademicsError('Error deleting chapter: $e'));
      // ✅ FIX: Reload to reset UI
      add(LoadChaptersEvent(schoolRecNo: 1));
    }
  }

  Future<void> _onDeleteMaterial(DeleteMaterialEvent event, Emitter<AcademicsState> emit) async {
    print('🗑️ AcademicsBloc: Deleting Material RecNo: ${event.recNo}, Hard Delete: ${event.hardDelete}');
    emit(AcademicsLoading());

    try {
      final response = await ApiService.manageAcademicModule({
        'table': 'Study_Material',
        'operation': 'DELETE',
        'RecNo': event.recNo,
        'HardDelete': event.hardDelete ? 1 : 0,
        'ModifiedBy': event.modifiedBy,
      });

      print('📥 AcademicsBloc: Delete Material Response: $response');

      if (response['status'] == 'success' || response['success'] == true) {
        print('✅ AcademicsBloc: Material deleted successfully. Reloading...');
        // ✅ FIX: Use event to reload
        // Note: schoolRecNo: 1 ensures default load. You can adjust params if needed.
        add(LoadMaterialsEvent(schoolRecNo: 1));
        add(LoadKPIEvent());
      } else {
        print('❌ AcademicsBloc: Failed to delete material');
        emit(AcademicsError('Failed to delete material'));
        // ✅ FIX: Reload to reset UI
        add(LoadMaterialsEvent(schoolRecNo: 1));
      }
    } catch (e) {
      print('❌ AcademicsBloc: Exception during delete - $e');
      emit(AcademicsError('Error deleting material: $e'));
      // ✅ FIX: Reload to reset UI
      add(LoadMaterialsEvent(schoolRecNo: 1));
    }
  }
}