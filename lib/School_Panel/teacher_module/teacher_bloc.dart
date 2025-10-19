import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_model.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_service.dart';

// ==================== EVENTS ====================

abstract class TeacherEvent {}

class LoadTeachersEvent extends TeacherEvent {
  final int? schoolRecNo;
  final bool? isActive;

  LoadTeachersEvent({
    this.schoolRecNo,
    this.isActive,
  });
}

class LoadTeacherDetailsEvent extends TeacherEvent {
  final int recNo;
  LoadTeacherDetailsEvent({required this.recNo});
}

class AddTeacherEvent extends TeacherEvent {
  final Map<String, dynamic> teacherData;
  final int schoolRecNo;

  AddTeacherEvent({
    required this.teacherData,
    required this.schoolRecNo,
  });
}

class UpdateTeacherEvent extends TeacherEvent {
  final int recNo;
  final Map<String, dynamic> teacherData;
  final int schoolRecNo;

  UpdateTeacherEvent({
    required this.recNo,
    required this.teacherData,
    required this.schoolRecNo,
  });
}

class DeleteTeacherEvent extends TeacherEvent {
  final int recNo;
  final String operationBy;

  DeleteTeacherEvent({
    required this.recNo,
    required this.operationBy,
  });
}

class DeleteTeachersBulkEvent extends TeacherEvent {
  final List<int> recNoList;
  final String operationBy;

  DeleteTeachersBulkEvent({
    required this.recNoList,
    required this.operationBy,
  });
}

class SearchTeachersEvent extends TeacherEvent {
  final String query;
  SearchTeachersEvent({required this.query});
}

class ClearTeacherDetailsEvent extends TeacherEvent {}
class ResetTeacherStateEvent extends TeacherEvent {}

// ==================== STATES ====================

abstract class TeacherState {}

class TeacherInitialState extends TeacherState {}

class TeacherLoadingState extends TeacherState {}

class TeacherLoadedState extends TeacherState {
  final List<TeacherModel> teachers;
  final List<TeacherModel> filteredTeachers;
  final String? searchQuery;
  final bool isSecondaryLoading;

  TeacherLoadedState({
    required this.teachers,
    List<TeacherModel>? filteredTeachers,
    this.searchQuery,
    this.isSecondaryLoading = false,
  }) : filteredTeachers = filteredTeachers ?? teachers;

  TeacherLoadedState copyWith({
    bool? isSecondaryLoading,
  }) {
    return TeacherLoadedState(
      teachers: teachers,
      filteredTeachers: filteredTeachers,
      searchQuery: searchQuery,
      isSecondaryLoading: isSecondaryLoading ?? this.isSecondaryLoading,
    );
  }
}

class TeacherDetailsLoadedState extends TeacherState {
  final TeacherModel teacher;
  final TeacherLoadedState previousLoadedState;

  TeacherDetailsLoadedState({required this.teacher, required this.previousLoadedState});
}

class TeacherOperationSuccessState extends TeacherState {
  final String message;
  final Map<String, dynamic>? data;

  TeacherOperationSuccessState({
    required this.message,
    this.data,
  });
}

class TeacherErrorState extends TeacherState {
  final String error;
  TeacherErrorState({required this.error});
}

class TeacherOperationInProgressState extends TeacherState {
  final String operation;
  TeacherOperationInProgressState({required this.operation});
}

// ==================== BLOC ====================

class TeacherBloc extends Bloc<TeacherEvent, TeacherState> {
  final TeacherApiService apiService;
  List<TeacherModel> _cachedTeachers = [];
  List<TeacherModel> get cachedTeachers => List.unmodifiable(_cachedTeachers);


  TeacherBloc({required this.apiService}) : super(TeacherInitialState()) {
    on<LoadTeachersEvent>((event, emit) async {
      emit(TeacherLoadingState());
      try {
        final teachers = await apiService.fetchTeachers(
          schoolRecNo: event.schoolRecNo ?? TeacherApiService.defaultSchoolRecNo,
          isActive: event.isActive,
        );
        _cachedTeachers = teachers;
        emit(TeacherLoadedState(teachers: teachers));
      } catch (e) {
        emit(TeacherErrorState(error: e.toString()));
      }
    });

    on<LoadTeacherDetailsEvent>((event, emit) async {
      final currentState = state;
      TeacherLoadedState? previousLoadedState;

      if (currentState is TeacherLoadedState) {
        previousLoadedState = currentState.copyWith(isSecondaryLoading: true);
        emit(previousLoadedState);
      } else {
        emit(TeacherLoadingState());
      }

      try {
        final teacher = await apiService.fetchTeacherDetails(
          recNo: event.recNo,
        );
        if (previousLoadedState != null) {
          emit(TeacherDetailsLoadedState(teacher: teacher, previousLoadedState: previousLoadedState));
        } else {
          emit(TeacherDetailsLoadedState(teacher: teacher, previousLoadedState: TeacherLoadedState(teachers: _cachedTeachers)));
        }
      } catch (e) {
        if (previousLoadedState != null) {
          emit(previousLoadedState.copyWith(isSecondaryLoading: false));
        }
        emit(TeacherErrorState(error: e.toString()));
      }
    });

    on<AddTeacherEvent>((event, emit) async {
      emit(TeacherOperationInProgressState(operation: 'Adding teacher...'));
      try {
        final data = {
          'SchoolRecNo': event.schoolRecNo,
          ...event.teacherData,
        };
        final result = await apiService.addTeacher(teacherData: data);
        final message = result['Message'] as String? ?? 'Teacher added successfully';
        emit(TeacherOperationSuccessState(
          message: message,
          data: result,
        ));
      } catch (e) {
        emit(TeacherErrorState(error: e.toString()));
      }
    });

    on<UpdateTeacherEvent>((event, emit) async {
      emit(TeacherOperationInProgressState(operation: 'Updating teacher...'));
      try {
        final data = {
          'SchoolRecNo': event.schoolRecNo,
          ...event.teacherData,
        };
        final result = await apiService.updateTeacher(
          recNo: event.recNo,
          teacherData: data,
        );
        final message = result['Message'] as String? ?? 'Teacher updated successfully';
        emit(TeacherOperationSuccessState(
          message: message,
          data: result,
        ));
      } catch (e) {
        emit(TeacherErrorState(error: e.toString()));
      }
    });

    on<DeleteTeacherEvent>((event, emit) async {
      emit(TeacherOperationInProgressState(operation: 'Deleting teacher...'));
      try {
        await apiService.deleteTeacher(
          recNo: event.recNo,
          operationBy: event.operationBy,
        );
        emit(TeacherOperationSuccessState(
          message: 'Teacher deleted successfully',
        ));
      } catch (e) {
        emit(TeacherErrorState(error: e.toString()));
      }
    });

    on<DeleteTeachersBulkEvent>((event, emit) async {
      emit(TeacherOperationInProgressState(operation: 'Deleting teachers...'));
      try {
        final result = await apiService.deleteTeachersBulk(
          recNoList: event.recNoList,
          operationBy: event.operationBy,
        );
        emit(TeacherOperationSuccessState(
          message: '${event.recNoList.length} teachers deleted successfully',
          data: result,
        ));
      } catch (e) {
        emit(TeacherErrorState(error: e.toString()));
      }
    });

    on<SearchTeachersEvent>((event, emit) {
      if (_cachedTeachers.isEmpty) {
        emit(TeacherLoadedState(teachers: []));
        return;
      }

      final query = event.query.toLowerCase().trim();
      if (query.isEmpty) {
        emit(TeacherLoadedState(teachers: _cachedTeachers));
        return;
      }

      final filtered = _cachedTeachers.where((teacher) {
        return teacher.firstName.toLowerCase().contains(query) ||
            teacher.lastName.toLowerCase().contains(query) ||
            (teacher.middleName?.toLowerCase().contains(query) ?? false) ||
            (teacher.teacherCode?.toLowerCase().contains(query) ?? false) ||
            (teacher.employeeCode?.toLowerCase().contains(query) ?? false) ||
            (teacher.mobileNumber?.contains(query) ?? false) ||
            (teacher.designation?.toLowerCase().contains(query) ?? false) ||
            (teacher.department?.toLowerCase().contains(query) ?? false);
      }).toList();

      emit(TeacherLoadedState(
        teachers: _cachedTeachers,
        filteredTeachers: filtered,
        searchQuery: query,
      ));
    });

    on<ClearTeacherDetailsEvent>((event, emit) {
      if (state is TeacherDetailsLoadedState) {
        final previousState = (state as TeacherDetailsLoadedState).previousLoadedState;
        emit(previousState.copyWith(isSecondaryLoading: false));
      }
    });

    on<ResetTeacherStateEvent>((event, emit) {
      _cachedTeachers = [];
      emit(TeacherInitialState());
    });
  }
}
