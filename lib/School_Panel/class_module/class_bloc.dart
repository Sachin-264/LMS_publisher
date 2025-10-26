// class_bloc.dart - COMPLETE UPDATED VERSION
// Updated: October 25, 2025, 8:40 PM IST

import 'package:flutter_bloc/flutter_bloc.dart';
import 'class_model.dart';
import 'class_service.dart';

// ==================== EVENTS ====================

abstract class ClassEvent {}

class LoadAllClassesEvent extends ClassEvent {
  final int schoolID;
  final String? academicYear;

  LoadAllClassesEvent({
    required this.schoolID,
    this.academicYear,
  });
}

class AddClassEvent extends ClassEvent {
  final ClassModel classData;
  final String operationBy;

  AddClassEvent({
    required this.classData,
    required this.operationBy,
  });
}

class UpdateClassEvent extends ClassEvent {
  final ClassModel classData;
  final String operationBy;

  UpdateClassEvent({
    required this.classData,
    required this.operationBy,
  });
}

class DeleteClassEvent extends ClassEvent {
  final int classRecNo;
  final int schoolID;
  final String operationBy;

  DeleteClassEvent({
    required this.classRecNo,
    required this.schoolID,
    required this.operationBy,
  });
}

class LoadAllotmentDataEvent extends ClassEvent {
  final int classRecNo;
  final int schoolID;
  final String academicYear;

  LoadAllotmentDataEvent({
    required this.classRecNo,
    required this.schoolID,
    required this.academicYear,
  });
}

class ChangeClassTeacherEvent extends ClassEvent {
  final int classRecNo;
  final int classTeacherRecNo;
  final int schoolID;
  final String operationBy;

  ChangeClassTeacherEvent({
    required this.classRecNo,
    required this.classTeacherRecNo,
    required this.schoolID,
    required this.operationBy,
  });
}

class AddSubjectsToClassEvent extends ClassEvent {
  final int classRecNo;
  final List<int> subjectIDs;
  final int schoolID;
  final String academicYear;
  final String operationBy;

  AddSubjectsToClassEvent({
    required this.classRecNo,
    required this.subjectIDs,
    required this.schoolID,
    required this.academicYear,
    required this.operationBy,
  });
}

// NEW: Remove Subject Event
class RemoveSubjectFromClassEvent extends ClassEvent {
  final int classRecNo;
  final int subjectID;
  final int schoolID;
  final String academicYear;
  final String operationBy;

  RemoveSubjectFromClassEvent({
    required this.classRecNo,
    required this.subjectID,
    required this.schoolID,
    required this.academicYear,
    required this.operationBy,
  });
}

class AllotSubjectTeacherEvent extends ClassEvent {
  final int classRecNo;
  final int subjectID;
  final int teacherRecNo;
  final int schoolID;
  final String startDate;
  final String endDate;
  final String academicYear;
  final String operationBy;

  AllotSubjectTeacherEvent({
    required this.classRecNo,
    required this.subjectID,
    required this.teacherRecNo,
    required this.schoolID,
    required this.startDate,
    required this.endDate,
    required this.academicYear,
    required this.operationBy,
  });
}

class RemoveSubjectAllotmentEvent extends ClassEvent {
  final int subjectID;
  final int classRecNo;
  final int teacherRecNo;
  final int schoolID;
  final String academicYear;
  final String operationBy;

  RemoveSubjectAllotmentEvent({
    required this.subjectID,
    required this.classRecNo,
    required this.teacherRecNo,
    required this.schoolID,
    required this.academicYear,
    required this.operationBy,
  });
}

// ==================== STATES ====================

abstract class ClassState {}

class ClassInitialState extends ClassState {}

class ClassLoadingState extends ClassState {
  final String message;
  ClassLoadingState({this.message = 'Loading...'});
}

class ClassesLoadedState extends ClassState {
  final List<ClassModel> classes;

  ClassesLoadedState({required this.classes});
}

class AllotmentDataLoadedState extends ClassState {
  final ClassModel classDetails;
  final List<SubjectOptionModel> availableSubjects;
  final List<ClassSubjectModel> assignedSubjects;
  final List<TeacherOptionModel> availableTeachers;
  final List<SubjectTeacherAllotmentModel> subjectAllotments;

  AllotmentDataLoadedState({
    required this.classDetails,
    required this.availableSubjects,
    required this.assignedSubjects,
    required this.availableTeachers,
    required this.subjectAllotments,
  });
}

class AllotmentOperationInProgressState extends ClassState {
  final String operation;
  AllotmentOperationInProgressState({required this.operation});
}

class ClassOperationSuccessState extends ClassState {
  final String message;
  ClassOperationSuccessState({required this.message});
}

class ClassErrorState extends ClassState {
  final String error;
  ClassErrorState({required this.error});
}

// ==================== BLOC ====================

class ClassBloc extends Bloc<ClassEvent, ClassState> {
  final ClassApiService apiService;

  ClassBloc({required this.apiService}) : super(ClassInitialState()) {
    on<LoadAllClassesEvent>(_onLoadAllClasses);
    on<AddClassEvent>(_onAddClass);
    on<UpdateClassEvent>(_onUpdateClass);
    on<DeleteClassEvent>(_onDeleteClass);
    on<LoadAllotmentDataEvent>(_onLoadAllotmentData);
    on<ChangeClassTeacherEvent>(_onChangeClassTeacher);
    on<AddSubjectsToClassEvent>(_onAddSubjectsToClass);
    on<RemoveSubjectFromClassEvent>(_onRemoveSubjectFromClass); // NEW
    on<AllotSubjectTeacherEvent>(_onAllotSubjectTeacher);
    on<RemoveSubjectAllotmentEvent>(_onRemoveSubjectAllotment);
  }

  Future<void> _onLoadAllClasses(LoadAllClassesEvent event, Emitter<ClassState> emit) async {
    emit(ClassLoadingState(message: 'Loading classes...'));
    try {
      final classes = await apiService.fetchAllClasses(
        schoolID: event.schoolID,
        academicYear: event.academicYear,
      );
      emit(ClassesLoadedState(classes: classes));
    } catch (e) {
      emit(ClassErrorState(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddClass(AddClassEvent event, Emitter<ClassState> emit) async {
    emit(ClassLoadingState(message: 'Adding class...'));
    try {
      await apiService.addClass(
        classData: event.classData,
        operationBy: event.operationBy,
      );
      // FIX: Removed internal LoadAllClassesEvent to rely on the calling UI to
      // reload using its currently selected academic year, fixing the display bug.
      emit(ClassOperationSuccessState(message: 'Class added successfully'));
    } catch (e) {
      emit(ClassErrorState(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateClass(UpdateClassEvent event, Emitter<ClassState> emit) async {
    emit(ClassLoadingState(message: 'Updating class...'));
    try {
      await apiService.updateClass(
        classData: event.classData,
        operationBy: event.operationBy,
      );
      // FIX: Removed internal LoadAllClassesEvent to rely on the calling UI to
      // reload using its currently selected academic year, fixing the display bug.
      emit(ClassOperationSuccessState(message: 'Class updated successfully'));
    } catch (e) {
      emit(ClassErrorState(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteClass(DeleteClassEvent event, Emitter<ClassState> emit) async {
    emit(ClassLoadingState(message: 'Deleting class...'));
    try {
      await apiService.deleteClass(
        classRecNo: event.classRecNo,
        schoolID: event.schoolID,
        operationBy: event.operationBy,
      );
      add(LoadAllClassesEvent(schoolID: event.schoolID));
      emit(ClassOperationSuccessState(message: 'Class deleted successfully'));
    } catch (e) {
      emit(ClassErrorState(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadAllotmentData(LoadAllotmentDataEvent event, Emitter<ClassState> emit) async {
    emit(ClassLoadingState(message: 'Loading allotment data...'));
    try {
      final classDetails = await apiService.fetchClassDetails(
        classRecNo: event.classRecNo,
        schoolID: event.schoolID,
      );

      if (classDetails == null) {
        emit(ClassErrorState(error: 'Class details not found'));
        return;
      }

      final availableSubjects = await apiService.fetchAvailableSubjects(
        schoolID: event.schoolID,
        classRecNo: event.classRecNo,
        academicYear: event.academicYear,
      );

      final assignedSubjects = await apiService.fetchClassSubjects(
        schoolID: event.schoolID,
        classRecNo: event.classRecNo,
        academicYear: event.academicYear,
      );

      final availableTeachers = await apiService.fetchAvailableTeachers(
        schoolID: event.schoolID,
      );

      final subjectAllotments = await apiService.fetchSubjectAllotments(
        schoolID: event.schoolID,
        classRecNo: event.classRecNo,
        academicYear: event.academicYear,
      );

      emit(AllotmentDataLoadedState(
        classDetails: classDetails,
        availableSubjects: availableSubjects,
        assignedSubjects: assignedSubjects,
        availableTeachers: availableTeachers,
        subjectAllotments: subjectAllotments,
      ));
    } catch (e) {
      emit(ClassErrorState(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onChangeClassTeacher(ChangeClassTeacherEvent event, Emitter<ClassState> emit) async {
    final currentState = state;
    if (currentState is! AllotmentDataLoadedState) return;

    emit(AllotmentOperationInProgressState(operation: 'Changing class teacher...'));
    try {
      await apiService.changeClassTeacher(
        classRecNo: event.classRecNo,
        classTeacherRecNo: event.classTeacherRecNo,
        schoolID: event.schoolID,
        operationBy: event.operationBy,
      );
      add(LoadAllotmentDataEvent(
        classRecNo: event.classRecNo,
        schoolID: event.schoolID,
        academicYear: currentState.classDetails.academicYear,
      ));
      emit(ClassOperationSuccessState(message: 'Class teacher changed successfully'));
    } catch (e) {
      emit(currentState);
      emit(ClassErrorState(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddSubjectsToClass(AddSubjectsToClassEvent event, Emitter<ClassState> emit) async {
    final currentState = state;
    if (currentState is! AllotmentDataLoadedState) return;

    emit(AllotmentOperationInProgressState(operation: 'Adding subjects...'));
    try {
      await apiService.addSubjectsToClass(
        schoolID: event.schoolID,
        classRecNo: event.classRecNo,
        subjectIDs: event.subjectIDs,
        academicYear: event.academicYear,
        operationBy: event.operationBy,
      );
      add(LoadAllotmentDataEvent(
        classRecNo: event.classRecNo,
        schoolID: event.schoolID,
        academicYear: event.academicYear,
      ));
      emit(ClassOperationSuccessState(message: 'Subjects added successfully'));
    } catch (e) {
      emit(currentState);
      emit(ClassErrorState(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  // NEW: Remove Subject Handler
  Future<void> _onRemoveSubjectFromClass(RemoveSubjectFromClassEvent event, Emitter<ClassState> emit) async {
    final currentState = state;
    if (currentState is! AllotmentDataLoadedState) return;

    emit(AllotmentOperationInProgressState(operation: 'Removing subject...'));
    try {
      await apiService.removeSubjectFromClass(
        classRecNo: event.classRecNo,
        subjectID: event.subjectID,
        schoolID: event.schoolID,
        academicYear: event.academicYear,
        operationBy: event.operationBy,
      );
      add(LoadAllotmentDataEvent(
        classRecNo: event.classRecNo,
        schoolID: event.schoolID,
        academicYear: event.academicYear,
      ));
      emit(ClassOperationSuccessState(message: 'Subject removed successfully'));
    } catch (e) {
      emit(currentState);
      emit(ClassErrorState(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAllotSubjectTeacher(AllotSubjectTeacherEvent event, Emitter<ClassState> emit) async {
    final currentState = state;
    if (currentState is! AllotmentDataLoadedState) return;

    emit(AllotmentOperationInProgressState(operation: 'Allotting teacher...'));
    try {
      await apiService.allotSubjectTeacher(
        classRecNo: event.classRecNo,
        subjectID: event.subjectID,
        teacherRecNo: event.teacherRecNo,
        schoolID: event.schoolID,
        startDate: event.startDate,
        endDate: event.endDate,
        academicYear: event.academicYear,
        operationBy: event.operationBy,
      );
      add(LoadAllotmentDataEvent(
        classRecNo: event.classRecNo,
        schoolID: event.schoolID,
        academicYear: event.academicYear,
      ));
      emit(ClassOperationSuccessState(message: 'Teacher allotted successfully'));
    } catch (e) {
      emit(currentState);
      emit(ClassErrorState(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRemoveSubjectAllotment(RemoveSubjectAllotmentEvent event, Emitter<ClassState> emit) async {
    final currentState = state;
    if (currentState is! AllotmentDataLoadedState) return;

    emit(AllotmentOperationInProgressState(operation: 'Removing allotment...'));
    try {
      await apiService.removeSubjectAllotment(
        subjectID: event.subjectID,
        classRecNo: event.classRecNo,
        teacherRecNo: event.teacherRecNo,
        schoolID: event.schoolID,
        academicYear: event.academicYear,
        operationBy: event.operationBy,
      );
      add(LoadAllotmentDataEvent(
        classRecNo: event.classRecNo,
        schoolID: event.schoolID,
        academicYear: event.academicYear,
      ));
      emit(ClassOperationSuccessState(message: 'Allotment removed successfully'));
    } catch (e) {
      emit(currentState);
      emit(ClassErrorState(error: e.toString().replaceAll('Exception: ', '')));
    }
  }
}