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
  final String createdBy; // FIXED: Corrected the duplicate declaration

   AddSchool({
    required this.schoolMasterData,
    required this.subscriptionData,
    this.logoFile,
    required this.createdBy, // FIXED: Now a single required parameter
  });
}

class UpdateSchool extends AddEditSchoolEvent {
  final String schoolId;
  final Map<String, dynamic> schoolMasterData;
  final Map<String, dynamic> subscriptionData;
  final XFile? logoFile;
  final String? createdBy; // CHANGED: Renamed from modifiedBy to createdBy

  UpdateSchool({
    required this.schoolId,
    required this.schoolMasterData,
    required this.subscriptionData,
    this.logoFile,
    this.createdBy, // CHANGED: This will hold the original creator's value
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
      );
      emit(AddEditSchoolSuccess(response));
    } catch (e) {
      emit(AddEditSchoolFailure(e.toString()));
    }
  }

  // UPDATED: This handler now passes the `createdBy` value to the service
  Future<void> _onUpdateSchool(UpdateSchool event, Emitter<AddEditSchoolState> emit) async {
    emit(AddEditSchoolLoading());
    try {
      final response = await schoolApiService.updateSchool(
        schoolId: event.schoolId,
        schoolMasterData: event.schoolMasterData,
        subscriptionData: event.subscriptionData,
        logoFile: event.logoFile,
        createdBy: event.createdBy, // CHANGED: Pass createdBy instead of modifiedBy
      );
      emit(AddEditSchoolSuccess(response));
    } catch (e) {
      emit(AddEditSchoolFailure(e.toString()));
    }
  }
}