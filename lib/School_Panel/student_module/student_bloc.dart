import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_publisher/School_Panel/student_module/student_model.dart';
import 'package:lms_publisher/School_Panel/student_module/student_service.dart';

// ==================== EVENTS ====================
abstract class StudentEvent {}

class LoadStudentsEvent extends StudentEvent {
  final int? schoolRecNo;
  final int? classRecNo;
  final bool? isActive;
  final String? academicYear;  // ADD THIS

  LoadStudentsEvent({
    this.schoolRecNo,
    this.classRecNo,
    this.isActive,
    this.academicYear,  // ADD THIS
  });
}


class LoadStudentDetailsEvent extends StudentEvent {
  final int recNo;

  LoadStudentDetailsEvent({required this.recNo});
}

class AddStudentEvent extends StudentEvent {
  final Map<String, dynamic> studentData;
  final int schoolRecNo;

  AddStudentEvent({
    required this.studentData,
    required this.schoolRecNo,
  });
}

class UpdateStudentEvent extends StudentEvent {
  final int recNo;
  final Map<String, dynamic> studentData;
  final int schoolRecNo;

  UpdateStudentEvent({
    required this.recNo,
    required this.studentData,
    required this.schoolRecNo,
  });
}

class DeleteStudentEvent extends StudentEvent {
  final int recNo;
  final String operationBy;
  final String? reasonForChange;

  DeleteStudentEvent({
    required this.recNo,
    required this.operationBy,
    this.reasonForChange,
  });
}

class DeleteStudentsBulkEvent extends StudentEvent {
  final List<int> recNoList;
  final String operationBy;
  final String? reasonForChange;

  DeleteStudentsBulkEvent({
    required this.recNoList,
    required this.operationBy,
    this.reasonForChange,
  });
}

class LoadStudentHistoryEvent extends StudentEvent {
  final int recNo;

  LoadStudentHistoryEvent({required this.recNo});
}

class SearchStudentsEvent extends StudentEvent {
  final String query;

  SearchStudentsEvent({required this.query});
}

class ClearStudentDetailsEvent extends StudentEvent {}

class ResetStudentStateEvent extends StudentEvent {}

// ==================== STATES ====================
abstract class StudentState {}

class StudentInitialState extends StudentState {}

class StudentLoadingState extends StudentState {}

class StudentLoadedState extends StudentState {
  final List<StudentModel> students;
  final List<StudentModel> filteredStudents;
  final String? searchQuery;
  // New property to indicate if a secondary loading (like details) is happening
  final bool isSecondaryLoading;

  StudentLoadedState({
    required this.students,
    List<StudentModel>? filteredStudents,
    this.searchQuery,
    this.isSecondaryLoading = false, // Default to false
  }) : filteredStudents = filteredStudents ?? students;

  // Helper method to create a new state instance with secondary loading flag
  StudentLoadedState copyWith({
    bool? isSecondaryLoading,
  }) {
    return StudentLoadedState(
      students: students,
      filteredStudents: filteredStudents,
      searchQuery: searchQuery,
      isSecondaryLoading: isSecondaryLoading ?? this.isSecondaryLoading,
    );
  }
}

class StudentDetailsLoadedState extends StudentState {
  final StudentModel student;
  // This state must also carry the main list data to prevent screen blanking
  final StudentLoadedState previousLoadedState;

  StudentDetailsLoadedState({required this.student, required this.previousLoadedState});
}

class StudentHistoryLoadedState extends StudentState {
  final List<Map<String, dynamic>> history;

  StudentHistoryLoadedState({required this.history});
}

class StudentOperationSuccessState extends StudentState {
  final String message;
  final Map<String, dynamic>? data;

  StudentOperationSuccessState({
    required this.message,
    this.data,
  });
}

class StudentErrorState extends StudentState {
  final String error;

  StudentErrorState({required this.error});
}

class StudentOperationInProgressState extends StudentState {
  final String operation;

  StudentOperationInProgressState({required this.operation});
}

// ==================== BLOC ====================
class StudentBloc extends Bloc<StudentEvent, StudentState> {
  final StudentApiService apiService;
  List<StudentModel> _cachedStudents = [];

  StudentBloc({required this.apiService}) : super(StudentInitialState()) {
    // Load Students List
// Load Students List
    on<LoadStudentsEvent>((event, emit) async {
      emit(StudentLoadingState());
      try {
        final students = await apiService.fetchStudents(
          schoolRecNo: event.schoolRecNo ?? StudentApiService.defaultSchoolRecNo,
          classRecNo: event.classRecNo,
          isActive: event.isActive,
          academicYear: event.academicYear,  // ADD THIS
        );
        _cachedStudents = students;
        emit(StudentLoadedState(students: students));
      } catch (e) {
        emit(StudentErrorState(error: e.toString()));
      }
    });


    // Load Single Student Details
    on<LoadStudentDetailsEvent>((event, emit) async {
      // FIX: Preserve the existing list state while loading details
      final currentState = state;
      StudentLoadedState? previousLoadedState;

      if (currentState is StudentLoadedState) {
        previousLoadedState = currentState.copyWith(isSecondaryLoading: true);
        emit(previousLoadedState); // Emit a state that preserves the list but shows loading
      } else {
        emit(StudentLoadingState()); // Full screen loading if list wasn't loaded
      }

      try {
        final student = await apiService.fetchStudentDetails(
          recNo: event.recNo,
        );
        // We emit StudentDetailsLoadedState which also carries the previous list state
        // to be restored after the dialog closes.
        if (previousLoadedState != null) {
          emit(StudentDetailsLoadedState(student: student, previousLoadedState: previousLoadedState));
        } else {
          // If we couldn't get the list state, just transition to details state.
          // The calling widget (Dialog) will handle the display.
          emit(StudentDetailsLoadedState(student: student, previousLoadedState: StudentLoadedState(students: _cachedStudents)));
        }
      } catch (e) {
        // Restore the previous loaded state if an error occurs
        if (previousLoadedState != null) {
          emit(previousLoadedState.copyWith(isSecondaryLoading: false)); // Stop secondary loading
        }
        emit(StudentErrorState(error: e.toString()));
      }
    });

    // Add New Student
    on<AddStudentEvent>((event, emit) async {
      emit(StudentOperationInProgressState(operation: 'Adding student...'));
      try {
        final data = {
          'School_RecNo': event.schoolRecNo,
          ...event.studentData,
        };
        final result = await apiService.addStudent(studentData: data);
        final message = result['Message'] as String? ?? 'Student added successfully';
        emit(StudentOperationSuccessState(
          message: message,
          data: result,
        ));
      } catch (e) {
        emit(StudentErrorState(error: e.toString()));
      }
    });

    // Update Student
    on<UpdateStudentEvent>((event, emit) async {
      emit(StudentOperationInProgressState(operation: 'Updating student...'));
      try {
        final data = {
          'School_RecNo': event.schoolRecNo,
          ...event.studentData,
        };
        final result = await apiService.updateStudent(
          recNo: event.recNo,
          studentData: data,
        );
        final message = result['Message'] as String? ?? 'Student updated successfully';
        emit(StudentOperationSuccessState(
          message: message,
          data: result,
        ));
      } catch (e) {
        emit(StudentErrorState(error: e.toString()));
      }
    });

    // Delete Single Student
    on<DeleteStudentEvent>((event, emit) async {
      emit(StudentOperationInProgressState(operation: 'Deleting student...'));
      try {
        await apiService.deleteStudent(
          recNo: event.recNo,
          operationBy: event.operationBy,
          reasonForChange: event.reasonForChange,
        );
        emit(StudentOperationSuccessState(
          message: 'Student deleted successfully',
        ));
      } catch (e) {
        emit(StudentErrorState(error: e.toString()));
      }
    });

    // Delete Multiple Students
    on<DeleteStudentsBulkEvent>((event, emit) async {
      emit(StudentOperationInProgressState(operation: 'Deleting students...'));
      try {
        final result = await apiService.deleteStudentsBulk(
          recNoList: event.recNoList,
          operationBy: event.operationBy,
          reasonForChange: event.reasonForChange,
        );
        emit(StudentOperationSuccessState(
          message: '${result['DeletedCount']} students deleted successfully',
          data: result,
        ));
      } catch (e) {
        emit(StudentErrorState(error: e.toString()));
      }
    });

    // Load Student History
    on<LoadStudentHistoryEvent>((event, emit) async {
      emit(StudentLoadingState());
      try {
        final history = await apiService.fetchStudentHistory(
          recNo: event.recNo,
        );
        emit(StudentHistoryLoadedState(history: history));
      } catch (e) {
        emit(StudentErrorState(error: e.toString()));
      }
    });

    // Search Students (Client-side filtering)
    on<SearchStudentsEvent>((event, emit) {
      if (_cachedStudents.isEmpty) {
        emit(StudentLoadedState(students: []));
        return;
      }

      final query = event.query.toLowerCase().trim();

      if (query.isEmpty) {
        emit(StudentLoadedState(students: _cachedStudents));
        return;
      }

      final filtered = _cachedStudents.where((student) {
        return student.firstName.toLowerCase().contains(query) ||
            student.lastName.toLowerCase().contains(query) ||
            (student.middleName?.toLowerCase().contains(query) ?? false) ||
            (student.admissionNumber?.toLowerCase().contains(query) ?? false) ||
            (student.studentId?.toLowerCase().contains(query) ?? false) ||
            (student.rollNumber?.toLowerCase().contains(query) ?? false) ||
            (student.mobileNumber?.contains(query) ?? false) ||
            (student.fatherName?.toLowerCase().contains(query) ?? false);
      }).toList();

      emit(StudentLoadedState(
        students: _cachedStudents,
        filteredStudents: filtered,
        searchQuery: query,
      ));
    });

    // Clear Student Details
    on<ClearStudentDetailsEvent>((event, emit) {
      // FIX: Restore the previous loaded state after the dialog is closed.
      if (state is StudentDetailsLoadedState) {
        final previousState = (state as StudentDetailsLoadedState).previousLoadedState;
        emit(previousState.copyWith(isSecondaryLoading: false));
      }
      // If we are in another state (like error/initial), just ignore.
    });

    // Reset State
    on<ResetStudentStateEvent>((event, emit) {
      _cachedStudents = [];
      emit(StudentInitialState());
    });
  }
}