import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_publisher/Service/academics_service.dart';

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
  final String id, name, description;
  final int subjectCount;
  final bool isActive;

  ClassModel({
    required this.id,
    required this.name,
    required this.description,
    required this.subjectCount,
    required this.isActive,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    print('📦 ClassModel.fromJson: $json');
    return ClassModel(
      id: json['ClassID']?.toString() ?? '',
      name: json['ClassName'] ?? '',
      description: json['ClassDescription'] ?? '',
      subjectCount: int.tryParse(json['TotalSubjects']?.toString() ?? '0') ?? 0,
      isActive: json['IsActive'] == 1 || json['IsActive'] == '1',
    );
  }
}

class SubjectModel {
  final String id, name, className, description, classId;
  final int chapterCount;
  final bool isActive;

  SubjectModel({
    required this.id,
    required this.name,
    required this.className,
    required this.description,
    required this.classId,
    required this.chapterCount,
    required this.isActive,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    print('📦 SubjectModel.fromJson: $json');
    return SubjectModel(
      id: json['SubjectID']?.toString() ?? '',
      name: json['SubjectName'] ?? '',
      className: json['ClassName'] ?? '',
      description: json['SubjectDescription'] ?? '',
      classId: json['ClassID']?.toString() ?? '',
      chapterCount: int.tryParse(json['TotalChapters']?.toString() ?? '0') ?? 0,
      isActive: json['IsActive'] == 1 || json['IsActive'] == '1',
    );
  }
}

class ChapterModel {
  final String id, name, subjectName, description;
  final int materialCount, chapterOrder;

  ChapterModel({
    required this.id,
    required this.name,
    required this.subjectName,
    required this.description,
    required this.materialCount,
    required this.chapterOrder,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    print('📦 ChapterModel.fromJson: $json');
    return ChapterModel(
      id: json['ChapterID']?.toString() ?? '',
      name: json['ChapterName'] ?? '',
      subjectName: json['SubjectName'] ?? '',
      description: json['ChapterDescription'] ?? '',
      chapterOrder: int.tryParse(json['ChapterOrder']?.toString() ?? '0') ?? 0,
      materialCount: int.tryParse(json['TotalStudyMaterials']?.toString() ?? '0') ?? 0,
    );
  }
}

class MaterialModel {
  final String id, name, type, link, chapterName;
  final DateTime uploadedOn;
  final String? thumbnail;
  final bool isVideoFile;
  final String videoLink;

  final String worksheetPath;
  final String extraQuestionsPath;
  final String solvedQuestionsPath;
  final String revisionNotesPath;
  final String lessonPlansPath;
  final String teachingAidsPath;
  final String assessmentToolsPath;
  final String homeworkToolsPath;
  final String practiceZonePath;
  final String learningPathPath;

  MaterialModel({
    required this.id,
    required this.name,
    required this.type,
    required this.link,
    required this.chapterName,
    required this.uploadedOn,
    this.thumbnail,
    this.isVideoFile = false,
    required this.videoLink,
    required this.worksheetPath,
    required this.extraQuestionsPath,
    required this.solvedQuestionsPath,
    required this.revisionNotesPath,
    required this.lessonPlansPath,
    required this.teachingAidsPath,
    required this.assessmentToolsPath,
    required this.homeworkToolsPath,
    required this.practiceZonePath,
    required this.learningPathPath,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    print('📦 MaterialModel.fromJson: $json');
    String type = 'Document';
    String link = '';
    String? thumbnail;
    String name = '';
    bool isVideoFile = false;
    String videoLink = '';

    final String video = json['Video_Link'] ?? '';
    final String worksheet = json['Worksheet_Path'] ?? '';
    final String extraQuestions = json['Extra_Questions_Path'] ?? '';
    final String solvedQuestions = json['Solved_Questions_Path'] ?? '';
    final String notes = json['Revision_Notes_Path'] ?? '';
    final String lessonPlans = json['Lesson_Plans_Path'] ?? '';
    final String teachingAids = json['Teaching_Aids_Path'] ?? '';
    final String assessmentTools = json['Assessment_Tools_Path'] ?? '';
    final String homeworkTools = json['Homework_Tools_Path'] ?? '';
    final String practiceZone = json['Practice_Zone_Path'] ?? '';
    final String learningPath = json['Learning_Path_Path'] ?? '';

    // Check if there's a video file
    if (json['Is_Video_File'] == true || json['Is_Video_File'] == 1) {
      type = 'Video_File';
      link = json['Video_File_Path'] ?? '';
      isVideoFile = true;
      name = 'Video - ${json['ChapterName'] ?? 'Material'}';
    } else if (video.isNotEmpty) {
      type = 'Video_Link';
      link = video;
      videoLink = video;
      name = 'Video - ${json['ChapterName'] ?? 'Material'}';

      // Extract YouTube thumbnail
      if (isYoutubeVideo(video)) {
        final videoId = extractYoutubeVideoId(video);
        if (videoId != null) {
          thumbnail = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
          print('🎬 YouTube thumbnail generated: $thumbnail');
        }
      }
    } else if (worksheet.isNotEmpty) {
      type = 'Worksheet_Path';
      link = worksheet;
      name = 'Worksheet - ${json['ChapterName'] ?? 'Material'}';
    } else if (notes.isNotEmpty) {
      type = 'Revision_Notes_Path';
      link = notes;
      name = 'Notes - ${json['ChapterName'] ?? 'Material'}';
    } else if (extraQuestions.isNotEmpty) {
      type = 'Extra_Questions_Path';
      link = extraQuestions;
      name = 'Extra Questions - ${json['ChapterName'] ?? 'Material'}';
    } else if (solvedQuestions.isNotEmpty) {
      type = 'Solved_Questions_Path';
      link = solvedQuestions;
      name = 'Solved Questions - ${json['ChapterName'] ?? 'Material'}';
    } else {
      name = json['ChapterName'] ?? 'Study Material';
    }

    return MaterialModel(
      id: json['RecNo']?.toString() ?? json['Material_ID']?.toString() ?? '',
      name: name,
      type: type,
      link: link,
      chapterName: json['ChapterName'] ?? '',
      uploadedOn: json['Uploaded_On'] != null
          ? DateTime.tryParse(json['Uploaded_On']) ?? DateTime.now()
          : DateTime.now(),
      thumbnail: thumbnail,
      isVideoFile: isVideoFile,
      videoLink: videoLink,
      worksheetPath: worksheet,
      extraQuestionsPath: extraQuestions,
      solvedQuestionsPath: solvedQuestions,
      revisionNotesPath: notes,
      lessonPlansPath: lessonPlans,
      teachingAidsPath: teachingAids,
      assessmentToolsPath: assessmentTools,
      homeworkToolsPath: homeworkTools,
      practiceZonePath: practiceZone,
      learningPathPath: learningPath,
    );
  }
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
    print('📊 Loading KPI data...');
    emit(AcademicsLoading());

    try {
      final response = await ApiService.getAcademicsKPI();
      print('📊 KPI Response: $response');

      if (response['success'] == true &&
          response['EntityCounts'] != null &&
          response['EntityCounts'].isNotEmpty) {
        final data = response['EntityCounts'][0];
        print('✅ KPI Data loaded successfully: $data');
        emit(KPILoaded(
          totalClasses: data['TotalClasses']?.toString() ?? '0',
          totalSubjects: data['TotalSubjects']?.toString() ?? '0',
          totalChapters: data['TotalChapters']?.toString() ?? '0',
          totalMaterials: data['TotalMaterials']?.toString() ?? '0',
        ));
      } else {
        print('❌ KPI Failed: Response format incorrect');
        emit(AcademicsError('Failed to load KPI data'));
      }
    } catch (e) {
      print('❌ KPI Error: $e');
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
      final response = await ApiService.getSubjects(
        schoolRecNo: event.schoolRecNo ?? 1,
        classId: event.classId,
      );
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
      final response = await ApiService.getChapters(
        schoolRecNo: event.schoolRecNo ?? 1,
        classId: event.classId,
        subjectId: event.subjectId,
      );
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
            return material.videoLink.isNotEmpty || material.isVideoFile;
          case 'Worksheet':
            return material.worksheetPath.isNotEmpty;
          case 'Extra Questions':
            return material.extraQuestionsPath.isNotEmpty;
          case 'Solved Questions':
            return material.solvedQuestionsPath.isNotEmpty;
          case 'Revision Notes':
            return material.revisionNotesPath.isNotEmpty;
          case 'Lesson Plans':
            return material.lessonPlansPath.isNotEmpty;
          case 'Teaching Aids':
            return material.teachingAidsPath.isNotEmpty;
          case 'Assessment Tools':
            return material.assessmentToolsPath.isNotEmpty;
          case 'Homework Tools':
            return material.homeworkToolsPath.isNotEmpty;
          case 'Practice Zone':
            return material.practiceZonePath.isNotEmpty;
          case 'Learning Path':
            return material.learningPathPath.isNotEmpty;
          default:
            return false;
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
      final response = await ApiService.getMaterials(
        schoolRecNo: event.schoolRecNo ?? 1,
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
          print('🎬 Material Debug: ID=${material.id}, videoLink="${material.videoLink}", isVideoFile=${material.isVideoFile}, link="${material.link}", thumbnail="${material.thumbnail}"');
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
        print('✅ AcademicsBloc: Subject deleted successfully');
        await Future.delayed(const Duration(milliseconds: 500));

        print('🔄 AcademicsBloc: Fetching fresh subjects data...');
        final subjectsResponse = await ApiService.getSubjects(schoolRecNo: 1);

        if ((subjectsResponse['status'] == 'success' || subjectsResponse['success'] == true) &&
            subjectsResponse['data'] != null) {
          final List<dynamic> data = subjectsResponse['data'];
          final subjects = data.map((json) => SubjectModel.fromJson(json)).toList();
          print('✅ AcademicsBloc: Loaded ${subjects.length} subjects after delete');
          emit(SubjectsLoaded(subjects));
          add(LoadKPIEvent());
        } else {
          print('⚠️ AcademicsBloc: No subjects data found after delete');
          emit(SubjectsLoaded([]));
        }
      } else {
        print('❌ AcademicsBloc: Failed to delete subject - ${response['message'] ?? 'Unknown error'}');
        emit(AcademicsError('Failed to delete subject'));
        await Future.delayed(const Duration(seconds: 1));
        print('🔄 AcademicsBloc: Reloading subjects after error...');
        final subjectsResponse = await ApiService.getSubjects(schoolRecNo: 1);
        if ((subjectsResponse['status'] == 'success' || subjectsResponse['success'] == true) &&
            subjectsResponse['data'] != null) {
          final subjects = (subjectsResponse['data'] as List)
              .map((json) => SubjectModel.fromJson(json))
              .toList();
          emit(SubjectsLoaded(subjects));
        }
      }
    } catch (e) {
      print('❌ AcademicsBloc: Exception during delete - $e');
      emit(AcademicsError('Error deleting subject: $e'));
      await Future.delayed(const Duration(seconds: 1));
      print('🔄 AcademicsBloc: Reloading subjects after exception...');
      try {
        final subjectsResponse = await ApiService.getSubjects(schoolRecNo: 1);
        if ((subjectsResponse['status'] == 'success' || subjectsResponse['success'] == true) &&
            subjectsResponse['data'] != null) {
          final subjects = (subjectsResponse['data'] as List)
              .map((json) => SubjectModel.fromJson(json))
              .toList();
          emit(SubjectsLoaded(subjects));
        }
      } catch (reloadError) {
        print('❌ AcademicsBloc: Failed to reload after exception: $reloadError');
        emit(SubjectsLoaded([]));
      }
    }
  }

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
        print('✅ AcademicsBloc: Class deleted successfully');
        await Future.delayed(const Duration(milliseconds: 500));

        print('🔄 AcademicsBloc: Fetching fresh classes data...');
        final classesResponse = await ApiService.getClasses(schoolRecNo: 1);

        if ((classesResponse['status'] == 'success' || classesResponse['success'] == true) &&
            classesResponse['data'] != null) {
          final classes = (classesResponse['data'] as List)
              .map((json) => ClassModel.fromJson(json))
              .toList();
          print('✅ AcademicsBloc: Loaded ${classes.length} classes after delete');
          emit(ClassesLoaded(classes));
          add(LoadKPIEvent());
        } else {
          emit(ClassesLoaded([]));
        }
      } else {
        print('❌ AcademicsBloc: Failed to delete class');
        emit(AcademicsError('Failed to delete class'));
        await Future.delayed(const Duration(seconds: 1));
        final classesResponse = await ApiService.getClasses(schoolRecNo: 1);
        if ((classesResponse['status'] == 'success' || classesResponse['success'] == true) &&
            classesResponse['data'] != null) {
          final classes = (classesResponse['data'] as List)
              .map((json) => ClassModel.fromJson(json))
              .toList();
          emit(ClassesLoaded(classes));
        }
      }
    } catch (e) {
      print('❌ AcademicsBloc: Exception during delete - $e');
      emit(AcademicsError('Error deleting class: $e'));
      await Future.delayed(const Duration(seconds: 1));
      try {
        final classesResponse = await ApiService.getClasses(schoolRecNo: 1);
        if ((classesResponse['status'] == 'success' || classesResponse['success'] == true) &&
            classesResponse['data'] != null) {
          final classes = (classesResponse['data'] as List)
              .map((json) => ClassModel.fromJson(json))
              .toList();
          emit(ClassesLoaded(classes));
        }
      } catch (reloadError) {
        emit(ClassesLoaded([]));
      }
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
        print('✅ AcademicsBloc: Chapter deleted successfully');
        await Future.delayed(const Duration(milliseconds: 500));

        print('🔄 AcademicsBloc: Fetching fresh chapters data...');
        final chaptersResponse = await ApiService.getChapters(schoolRecNo: 1);

        if ((chaptersResponse['status'] == 'success' || chaptersResponse['success'] == true) &&
            chaptersResponse['data'] != null) {
          final chapters = (chaptersResponse['data'] as List)
              .map((json) => ChapterModel.fromJson(json))
              .toList();
          print('✅ AcademicsBloc: Loaded ${chapters.length} chapters after delete');
          emit(ChaptersLoaded(chapters));
          add(LoadKPIEvent());
        } else {
          emit(ChaptersLoaded([]));
        }
      } else {
        print('❌ AcademicsBloc: Failed to delete chapter');
        emit(AcademicsError('Failed to delete chapter'));
        await Future.delayed(const Duration(seconds: 1));
        final chaptersResponse = await ApiService.getChapters(schoolRecNo: 1);
        if ((chaptersResponse['status'] == 'success' || chaptersResponse['success'] == true) &&
            chaptersResponse['data'] != null) {
          final chapters = (chaptersResponse['data'] as List)
              .map((json) => ChapterModel.fromJson(json))
              .toList();
          emit(ChaptersLoaded(chapters));
        }
      }
    } catch (e) {
      print('❌ AcademicsBloc: Exception during delete - $e');
      emit(AcademicsError('Error deleting chapter: $e'));
      await Future.delayed(const Duration(seconds: 1));
      try {
        final chaptersResponse = await ApiService.getChapters(schoolRecNo: 1);
        if ((chaptersResponse['status'] == 'success' || chaptersResponse['success'] == true) &&
            chaptersResponse['data'] != null) {
          final chapters = (chaptersResponse['data'] as List)
              .map((json) => ChapterModel.fromJson(json))
              .toList();
          emit(ChaptersLoaded(chapters));
        }
      } catch (reloadError) {
        emit(ChaptersLoaded([]));
      }
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
        print('✅ AcademicsBloc: Material deleted successfully');
        await Future.delayed(const Duration(milliseconds: 500));

        print('🔄 AcademicsBloc: Fetching fresh materials data...');
        final materialsResponse = await ApiService.getMaterials(schoolRecNo: 1);

        if ((materialsResponse['status'] == 'success' || materialsResponse['success'] == true) &&
            materialsResponse['data'] != null) {
          _allMaterials = (materialsResponse['data'] as List)
              .map((json) => MaterialModel.fromJson(json))
              .toList();

          // Re-apply filter
          if (_currentMaterialTypeFilter != 'All') {
            _onFilterMaterialsByType(
              FilterMaterialsByTypeEvent(_currentMaterialTypeFilter),
              emit,
            );
          } else {
            _cachedMaterials = _allMaterials;
            print('✅ AcademicsBloc: Loaded ${_cachedMaterials.length} materials after delete');
            emit(MaterialsLoaded(_cachedMaterials, isGridView: _isGridView));
          }

          add(LoadKPIEvent());
        } else {
          _allMaterials = [];
          _cachedMaterials = [];
          emit(MaterialsLoaded([], isGridView: _isGridView));
        }
      } else {
        print('❌ AcademicsBloc: Failed to delete material');
        emit(AcademicsError('Failed to delete material'));
        await Future.delayed(const Duration(seconds: 1));
        final materialsResponse = await ApiService.getMaterials(schoolRecNo: 1);
        if ((materialsResponse['status'] == 'success' || materialsResponse['success'] == true) &&
            materialsResponse['data'] != null) {
          _allMaterials = (materialsResponse['data'] as List)
              .map((json) => MaterialModel.fromJson(json))
              .toList();
          _cachedMaterials = _allMaterials;
          emit(MaterialsLoaded(_cachedMaterials, isGridView: _isGridView));
        }
      }
    } catch (e) {
      print('❌ AcademicsBloc: Exception during delete - $e');
      emit(AcademicsError('Error deleting material: $e'));
      await Future.delayed(const Duration(seconds: 1));
      try {
        final materialsResponse = await ApiService.getMaterials(schoolRecNo: 1);
        if ((materialsResponse['status'] == 'success' || materialsResponse['success'] == true) &&
            materialsResponse['data'] != null) {
          _allMaterials = (materialsResponse['data'] as List)
              .map((json) => MaterialModel.fromJson(json))
              .toList();
          _cachedMaterials = _allMaterials;
          emit(MaterialsLoaded(_cachedMaterials, isGridView: _isGridView));
        }
      } catch (reloadError) {
        _allMaterials = [];
        _cachedMaterials = [];
        emit(MaterialsLoaded([], isGridView: _isGridView));
      }
    }
  }
}