// lib/School_Panel/subject_module/subject_module_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'subject_module_api_service.dart';
import 'subject_module_model.dart';

// ============================================================================
// EVENTS
// ============================================================================
abstract class SubjectModuleEvent {}

class FetchAvailableClassesEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final String academicYear;

  FetchAvailableClassesEvent({
    required this.schoolRecNo,
    required this.academicYear,
  });
}

class FetchSchoolClassMasterEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final String academicYear;

  FetchSchoolClassMasterEvent({
    required this.schoolRecNo,
    required this.academicYear,
  });
}

class FetchTeachersEvent extends SubjectModuleEvent {
  final int schoolRecNo;

  FetchTeachersEvent({required this.schoolRecNo});
}

class FetchAvailableSubjectsEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final int classID;
  final String academicYear;

  FetchAvailableSubjectsEvent({
    required this.schoolRecNo,
    required this.classID,
    required this.academicYear,
  });
}

class FetchAvailableChaptersEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final int subjectID;
  final String academicYear;

  FetchAvailableChaptersEvent({
    required this.schoolRecNo,
    required this.subjectID,
    required this.academicYear,
  });
}

class FetchSchoolClassesEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final String academicYear;

  FetchSchoolClassesEvent({
    required this.schoolRecNo,
    required this.academicYear,
  });
}

class FetchSchoolSubjectsEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final int classID;
  final String academicYear;

  FetchSchoolSubjectsEvent({
    required this.schoolRecNo,
    required this.classID,
    required this.academicYear,
  });
}

class FetchSchoolChaptersEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final int subjectID;
  final String academicYear;

  FetchSchoolChaptersEvent({
    required this.schoolRecNo,
    required this.subjectID,
    required this.academicYear,
  });
}

// ============================================================================
// NEW EVENTS FOR UPDATED FUNCTIONALITY
// ============================================================================

class AddSubjectEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final int subjectID;
  final String academicYear;
  final String? customSubjectName;
  final String createdBy;

  AddSubjectEvent({
    required this.schoolRecNo,
    required this.subjectID,
    required this.academicYear,
    this.customSubjectName,
    required this.createdBy,
  });
}

class BulkAddSubjectChaptersEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final int subjectID;
  final String academicYear;
  final String? customSubjectName;
  final String createdBy;

  BulkAddSubjectChaptersEvent({
    required this.schoolRecNo,
    required this.subjectID,
    required this.academicYear,
    this.customSubjectName,
    required this.createdBy,
  });
}

class AddChapterOnlyEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final int classID;
  final int subjectID;
  final int chapterID;
  final String academicYear;
  final String? customChapterName;
  final String createdBy;

  AddChapterOnlyEvent({
    required this.schoolRecNo,
    required this.classID,
    required this.subjectID,
    required this.chapterID,
    required this.academicYear,
    this.customChapterName,
    required this.createdBy,
  });
}

class AddAllotmentEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final int subjectID;
  final String academicYear;
  final List<int> classRecNoList;
  final List<int> teacherRecNoList;
  final String? startDate;
  final String? endDate;
  final String createdBy;

  AddAllotmentEvent({
    required this.schoolRecNo,
    required this.subjectID,
    required this.academicYear,
    required this.classRecNoList,
    required this.teacherRecNoList,
    this.startDate,
    this.endDate,
    required this.createdBy,
  });
}

class UpdateSubjectNameEvent extends SubjectModuleEvent {
  final int schoolRecNo;
  final int subjectID;
  final String academicYear;
  final String customSubjectName;
  final String modifiedBy;

  UpdateSubjectNameEvent({
    required this.schoolRecNo,
    required this.subjectID,
    required this.academicYear,
    required this.customSubjectName,
    required this.modifiedBy,
  });
}

class UpdateChapterNameEvent extends SubjectModuleEvent {
  final int recNo;
  final String customChapterName;
  final String modifiedBy;

  UpdateChapterNameEvent({
    required this.recNo,
    required this.customChapterName,
    required this.modifiedBy,
  });
}

class UpdateAllotmentEvent extends SubjectModuleEvent {
  final int recNo;
  final int? classRecNo;
  final int? teacherRecNo;
  final String? startDate;
  final String? endDate;
  final String modifiedBy;

  UpdateAllotmentEvent({
    required this.recNo,
    this.classRecNo,
    this.teacherRecNo,
    this.startDate,
    this.endDate,
    required this.modifiedBy,
  });
}

class DeleteChapterEvent extends SubjectModuleEvent {
  final int recNo;

  DeleteChapterEvent({required this.recNo});
}

class DeleteAllotmentEvent extends SubjectModuleEvent {
  final int recNo;

  DeleteAllotmentEvent({required this.recNo});
}

// ============================================================================
// STATES
// ============================================================================
abstract class SubjectModuleState {}

class SubjectModuleInitial extends SubjectModuleState {}

class SubjectModuleLoading extends SubjectModuleState {}

class AvailableClassesLoaded extends SubjectModuleState {
  final List<AvailableClassModel> classes;

  AvailableClassesLoaded({required this.classes});
}

class SchoolClassMasterLoaded extends SubjectModuleState {
  final List<SchoolClassMasterModel> classes;

  SchoolClassMasterLoaded({required this.classes});
}

class TeachersLoaded extends SubjectModuleState {
  final List<TeacherModel> teachers;

  TeachersLoaded({required this.teachers});
}

class AvailableSubjectsLoaded extends SubjectModuleState {
  final List<AvailableSubjectModel> subjects;

  AvailableSubjectsLoaded({required this.subjects});
}

class AvailableChaptersLoaded extends SubjectModuleState {
  final List<AvailableChapterModel> chapters;

  AvailableChaptersLoaded({required this.chapters});
}

class SchoolClassesLoaded extends SubjectModuleState {
  final List<SchoolClassModel> classes;

  SchoolClassesLoaded({required this.classes});
}

class SchoolSubjectsLoaded extends SubjectModuleState {
  final List<SchoolSubjectModel> subjects;

  SchoolSubjectsLoaded({required this.subjects});
}

class SchoolChaptersLoaded extends SubjectModuleState {
  final List<SchoolChapterModel> chapters;

  SchoolChaptersLoaded({required this.chapters});
}

class SubjectModuleOperationSuccess extends SubjectModuleState {
  final String message;

  SubjectModuleOperationSuccess({required this.message});
}

class SubjectModuleError extends SubjectModuleState {
  final String message;

  SubjectModuleError({required this.message});
}

// ============================================================================
// BLOC
// ============================================================================
class SubjectModuleBloc extends Bloc<SubjectModuleEvent, SubjectModuleState> {
  final SubjectModuleApiService _apiService;

  SubjectModuleBloc(this._apiService) : super(SubjectModuleInitial()) {
    // Fetch Available Classes
    on<FetchAvailableClassesEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.fetchAvailableClasses(
          // schoolRecNo: event.schoolRecNo,
          academicYear: event.academicYear,
        );

        if (result['success']) {
          final data = result['data']['data'] as List;
          final classes =
          data.map((json) => AvailableClassModel.fromJson(json)).toList();
          emit(AvailableClassesLoaded(classes: classes));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Fetch School Class Master
    on<FetchSchoolClassMasterEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.fetchSchoolClassMaster(
          // schoolRecNo: event.schoolRecNo,
          academicYear: event.academicYear,
        );

        if (result['success']) {
          final data = result['data']['data'] as List;
          final classes =
          data.map((json) => SchoolClassMasterModel.fromJson(json)).toList();
          emit(SchoolClassMasterLoaded(classes: classes));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Fetch Teachers
    on<FetchTeachersEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.fetchTeachers(
          // schoolRecNo: event.schoolRecNo,
        );

        if (result['success']) {
          final data = result['data']['data'] as List;
          final teachers =
          data.map((json) => TeacherModel.fromJson(json)).toList();
          emit(TeachersLoaded(teachers: teachers));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Fetch Available Subjects
    on<FetchAvailableSubjectsEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.fetchAvailableSubjects(
          // schoolRecNo: event.schoolRecNo,
          classID: event.classID,
          academicYear: event.academicYear,
        );

        if (result['success']) {
          final data = result['data']['data'] as List;
          final subjects =
          data.map((json) => AvailableSubjectModel.fromJson(json)).toList();
          emit(AvailableSubjectsLoaded(subjects: subjects));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Fetch Available Chapters
    on<FetchAvailableChaptersEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.fetchAvailableChapters(
          // schoolRecNo: event.schoolRecNo,
          subjectID: event.subjectID,
          academicYear: event.academicYear,
        );

        if (result['success']) {
          final data = result['data']['data'] as List;
          final chapters =
          data.map((json) => AvailableChapterModel.fromJson(json)).toList();
          emit(AvailableChaptersLoaded(chapters: chapters));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Fetch School Classes
    on<FetchSchoolClassesEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.fetchSchoolClasses(
          // schoolRecNo: event.schoolRecNo,
          academicYear: event.academicYear,
        );

        if (result['success']) {
          final data = result['data']['data'] as List;
          final classes = data
              .map((json) => SchoolClassModel.fromJson(json))
              .toList();
          emit(SchoolClassesLoaded(classes: classes));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Fetch School Subjects
    on<FetchSchoolSubjectsEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.fetchSchoolSubjects(
          // schoolRecNo: event.schoolRecNo,
          classID: event.classID,
          academicYear: event.academicYear,
        );

        if (result['success']) {
          final data = result['data']['data'] as List;
          final subjects = data
              .map((json) => SchoolSubjectModel.fromJson(json))
              .toList();
          emit(SchoolSubjectsLoaded(subjects: subjects));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Fetch School Chapters
    on<FetchSchoolChaptersEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.fetchSchoolChapters(
          // schoolRecNo: event.schoolRecNo,
          subjectID: event.subjectID,
          academicYear: event.academicYear,
        );

        if (result['success']) {
          final data = result['data']['data'] as List;
          final chapters = data
              .map((json) => SchoolChapterModel.fromJson(json))
              .toList();
          emit(SchoolChaptersLoaded(chapters: chapters));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // ========================================================================
    // NEW EVENT HANDLERS
    // ========================================================================

    // Add Subject (First Time)
    on<AddSubjectEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.addSubject(
          // schoolRecNo: event.schoolRecNo,
          subjectID: event.subjectID,
          academicYear: event.academicYear,
          customSubjectName: event.customSubjectName,
          createdBy: event.createdBy,
        );

        if (result['success']) {
          emit(SubjectModuleOperationSuccess(
            message: result['data']['message'] ?? 'Subject added successfully',
          ));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Bulk Add Subject Chapters
    on<BulkAddSubjectChaptersEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.bulkAddSubjectChapters(
          // schoolRecNo: event.schoolRecNo,
          subjectID: event.subjectID,
          academicYear: event.academicYear,
          customSubjectName: event.customSubjectName,
          createdBy: event.createdBy,
        );

        if (result['success']) {
          emit(SubjectModuleOperationSuccess(
            message: result['data']['message'] ?? 'Chapters added in bulk successfully',
          ));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Add Chapter Only
    on<AddChapterOnlyEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.addChapterToSchool(
          // schoolRecNo: event.schoolRecNo,
          classID: event.classID,
          subjectID: event.subjectID,
          chapterID: event.chapterID,
          academicYear: event.academicYear,
          customChapterName: event.customChapterName,
          createdBy: event.createdBy,
        );

        if (result['success']) {
          emit(SubjectModuleOperationSuccess(
            message: result['data']['message'] ?? 'Chapter added successfully',
          ));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Add Allotment
    on<AddAllotmentEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.addAllotment(
          // schoolRecNo: event.schoolRecNo,
          subjectID: event.subjectID,
          academicYear: event.academicYear,
          classRecNoList: event.classRecNoList,
          teacherRecNoList: event.teacherRecNoList,
          startDate: event.startDate,
          endDate: event.endDate,
          createdBy: event.createdBy,
        );

        if (result['success']) {
          emit(SubjectModuleOperationSuccess(
            message: result['data']['message'] ?? 'Allotment added successfully',
          ));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Update Subject Name
    on<UpdateSubjectNameEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.updateSubjectName(
          subjectID: event.subjectID,
          academicYear: event.academicYear,
          customSubjectName: event.customSubjectName,
          modifiedBy: event.modifiedBy,
        );

        if (result['success']) {
          emit(SubjectModuleOperationSuccess(
            message: result['data']['message'] ?? 'Subject updated successfully',
          ));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Update Chapter Name
    on<UpdateChapterNameEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.updateSchoolChapter(
          recNo: event.recNo,
          customChapterName: event.customChapterName,
          modifiedBy: event.modifiedBy,
        );

        if (result['success']) {
          emit(SubjectModuleOperationSuccess(
            message: result['data']['message'] ?? 'Chapter updated successfully',
          ));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Update Allotment
    on<UpdateAllotmentEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.updateAllotment(
          recNo: event.recNo,
          classRecNo: event.classRecNo,
          teacherRecNo: event.teacherRecNo,
          startDate: event.startDate,
          endDate: event.endDate,
          modifiedBy: event.modifiedBy,
        );

        if (result['success']) {
          emit(SubjectModuleOperationSuccess(
            message: result['data']['message'] ?? 'Allotment updated successfully',
          ));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Delete Chapter
    on<DeleteChapterEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.deleteSchoolChapter(recNo: event.recNo);

        if (result['success']) {
          emit(SubjectModuleOperationSuccess(
            message: result['data']['message'] ?? 'Chapter deleted successfully',
          ));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });

    // Delete Allotment
    on<DeleteAllotmentEvent>((event, emit) async {
      emit(SubjectModuleLoading());
      try {
        final result = await _apiService.deleteAllotment(recNo: event.recNo);

        if (result['success']) {
          emit(SubjectModuleOperationSuccess(
            message: result['data']['message'] ?? 'Allotment deleted successfully',
          ));
        } else {
          emit(SubjectModuleError(message: result['error']));
        }
      } catch (e) {
        emit(SubjectModuleError(message: e.toString()));
      }
    });
  }
}
