// lib/screens/School/add_school_bloc.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lms_publisher/service/school_service.dart';

//--- EVENTS ---
@immutable
abstract class AddEditSchoolEvent {}

class AddSchool extends AddEditSchoolEvent {
  final Map<String, dynamic> schoolMasterData;
  final Map<String, dynamic> subscriptionData;
  final XFile? logoFile;
  final String createdBy;
  final String? schoolId; // NEW: UserCode from insertUser
  final String? pubCode; // NEW: Current logged-in user's UserCode

  AddSchool({
    required this.schoolMasterData,
    required this.subscriptionData,
    this.logoFile,
    required this.createdBy,
    this.schoolId, // NEW
    this.pubCode, // NEW
  });
}

class UpdateSchool extends AddEditSchoolEvent {
  final int recNo;
  final String schoolId;
  final Map<String, dynamic> schoolMasterData;    // <-- Added type
  final Map<String, dynamic> subscriptionData;    // <-- Added type
  final XFile? logoFile;
  final String? createdBy;

  UpdateSchool({
    required this.recNo,
    required this.schoolId,
    required this.schoolMasterData,
    required this.subscriptionData,
    this.logoFile,
    this.createdBy,
  });
}

//--- STATES ---
@immutable
abstract class AddEditSchoolState {}

class AddEditSchoolInitial extends AddEditSchoolState {}

class AddEditSchoolLoading extends AddEditSchoolState {}

class AddEditSchoolSuccess extends AddEditSchoolState {
  final Map<String, dynamic> successResponse;
  AddEditSchoolSuccess(this.successResponse);
}

class AddEditSchoolFailure extends AddEditSchoolState {
  final String error;
  AddEditSchoolFailure(this.error);
}

//--- BLOC ---
class AddEditSchoolBloc extends Bloc<AddEditSchoolEvent, AddEditSchoolState> {
  final SchoolApiService schoolApiService;

  AddEditSchoolBloc({required this.schoolApiService}) : super(AddEditSchoolInitial()) {
    on<AddSchool>(_onAddSchool);
    on<UpdateSchool>(_onUpdateSchool);
  }

  Future<void> _onAddSchool(AddSchool event, Emitter<AddEditSchoolState> emit) async {
    emit(AddEditSchoolLoading());
    try {
      final response = await schoolApiService.addSchool(
        schoolMasterData: event.schoolMasterData,
        subscriptionData: event.subscriptionData,
        logoFile: event.logoFile,
        createdBy: event.createdBy,
        schoolId: event.schoolId, // NEW: Pass UserCode
        // pubCode: event.pubCode, // NEW: Pass PubCode
      );
      emit(AddEditSchoolSuccess(response));
    } catch (e) {
      emit(AddEditSchoolFailure(e.toString()));
    }
  }

  Future<void> _onUpdateSchool(UpdateSchool event, Emitter<AddEditSchoolState> emit) async {
    emit(AddEditSchoolLoading());
    try {
      print('🔄 BLoC: Updating school - RecNo: ${event.recNo}, SchoolID: ${event.schoolId}');
      final response = await schoolApiService.updateSchool(
        recNo: event.recNo,          // NEW: Pass RecNo
        schoolId: event.schoolId,    // Keep SchoolID
        schoolMasterData: event.schoolMasterData,
        subscriptionData: event.subscriptionData,
        logoFile: event.logoFile,
        createdBy: event.createdBy,
      );
      emit(AddEditSchoolSuccess(response));
    } catch (e) {
      emit(AddEditSchoolFailure(e.toString()));
    }
  }



}
