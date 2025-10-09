import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_publisher/screens/School/school_model.dart';
import 'package:lms_publisher/service/school_service.dart';

// --- EVENTS ---
abstract class SchoolManageEvent extends Equatable {
  const SchoolManageEvent();
  @override
  List<Object?> get props => [];
}

class FetchSchools extends SchoolManageEvent {}

class FetchSchoolDetails extends SchoolManageEvent {
  final String schoolId;
  const FetchSchoolDetails({required this.schoolId});
  @override
  List<Object> get props => [schoolId];
}

class SearchAndFilterSchools extends SchoolManageEvent {
  final String searchTerm;
  final SchoolStatusModel? filter; // MODIFIED: Use the status model

  const SearchAndFilterSchools({this.searchTerm = '', this.filter});

  @override
  List<Object?> get props => [searchTerm, filter];
}

class DeleteSchool extends SchoolManageEvent {
  final String schoolId;
  const DeleteSchool({required this.schoolId});
}

class FetchSubscriptionPlans extends SchoolManageEvent {}

class RenewSubscription extends SchoolManageEvent {
  final String schoolId;
  final String newSubscriptionId;
  final String newEndDate;
  const RenewSubscription(
      {required this.schoolId,
        required this.newSubscriptionId,
        required this.newEndDate});
}

// NEW: Event to update a school's status
class UpdateSchoolStatus extends SchoolManageEvent {
  final String schoolId;
  final String statusId;

  const UpdateSchoolStatus({required this.schoolId, required this.statusId});

  @override
  List<Object> get props => [schoolId, statusId];
}

// --- STATES ---
class SchoolManageState extends Equatable {
  final List<School> allSchools;
  final List<School> filteredSchools;
  final bool isLoading;
  final String? error;
  final String searchTerm;
  final SchoolStatusModel? currentFilter; // MODIFIED: Use model for the filter
  final School? selectedSchool;
  final bool isDetailLoading;
  final List<SubscriptionPlan> subscriptionPlans;
  final List<SchoolStatusModel> availableStatuses; // NEW: To hold statuses from API

  const SchoolManageState({
    this.allSchools = const [],
    this.filteredSchools = const [],
    this.isLoading = false,
    this.error,
    this.searchTerm = '',
    this.currentFilter, // MODIFIED
    this.selectedSchool,
    this.isDetailLoading = false,
    this.subscriptionPlans = const [],
    this.availableStatuses = const [], // NEW
  });

  SchoolManageState copyWith({
    List<School>? allSchools,
    List<School>? filteredSchools,
    bool? isLoading,
    String? error,
    String? searchTerm,
    SchoolStatusModel? currentFilter,
    bool? clearCurrentFilter, // Helper to handle null selection
    School? selectedSchool,
    bool? isDetailLoading,
    List<SubscriptionPlan>? subscriptionPlans,
    List<SchoolStatusModel>? availableStatuses, // NEW
  }) {
    return SchoolManageState(
      allSchools: allSchools ?? this.allSchools,
      filteredSchools: filteredSchools ?? this.filteredSchools,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchTerm: searchTerm ?? this.searchTerm,
      currentFilter: clearCurrentFilter == true ? null : currentFilter ?? this.currentFilter,
      selectedSchool: selectedSchool ?? this.selectedSchool,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      subscriptionPlans: subscriptionPlans ?? this.subscriptionPlans,
      availableStatuses: availableStatuses ?? this.availableStatuses,
    );
  }

  @override
  List<Object?> get props => [
    allSchools,
    filteredSchools,
    isLoading,
    error,
    searchTerm,
    currentFilter,
    selectedSchool,
    isDetailLoading,
    subscriptionPlans,
    availableStatuses,
  ];
}

// --- BLOC ---
class SchoolManageBloc extends Bloc<SchoolManageEvent, SchoolManageState> {
  final SchoolApiService _schoolApiService;

  SchoolManageBloc({required SchoolApiService schoolApiService})
      : _schoolApiService = schoolApiService,
        super(const SchoolManageState(isLoading: true)) {
    on<FetchSchools>(_onFetchSchools);
    on<SearchAndFilterSchools>(_onSearchAndFilterSchools);
    on<DeleteSchool>(_onDeleteSchool);
    on<RenewSubscription>(_onRenewSubscription);
    on<FetchSchoolDetails>(_onFetchSchoolDetails);
    on<FetchSubscriptionPlans>(_onFetchSubscriptionPlans);
    on<UpdateSchoolStatus>(_onUpdateSchoolStatus); // NEW: Register handler
  }

  Future<void> _onFetchSchools(
      FetchSchools event, Emitter<SchoolManageState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      // Fetch initial data
      var schools = await _schoolApiService.fetchSchools();
      final statuses = await _schoolApiService.fetchSchoolStatuses();

      // --- NEW: Automatic Status Expiration Logic ---
      final expiredStatus = statuses.firstWhere(
            (s) => s.name.toLowerCase() == 'expired',
        orElse: () => const SchoolStatusModel(id: '-1', name: 'Expired'),
      );

      // Proceed only if a valid "Expired" status is found from the API
      if (expiredStatus.id != '-1') {
        final now = DateTime.now();
        // Find all active schools with an end date in the past
        final schoolsToExpire = schools.where((school) =>
        // MODIFIED: Compare the status name string instead of the old enum
        school.status.name.toLowerCase() == 'active' &&
            school.endDate != null &&
            school.endDate!.isBefore(now)).toList();

        if (schoolsToExpire.isNotEmpty) {
          print('ℹ️ Found ${schoolsToExpire.length} schools to automatically expire.');
          // Create a list of futures for all the API update calls
          final updateFutures = schoolsToExpire.map((school) =>
              _schoolApiService.updateSchoolStatus(
                  schoolId: school.id, statusId: expiredStatus.id)).toList();

          // Execute all updates concurrently
          await Future.wait(updateFutures);

          // Re-fetch the list to ensure the UI shows the latest data
          print('✅ Re-fetching schools list after auto-expiration.');
          schools = await _schoolApiService.fetchSchools();
        }
      }
      // --- End of Auto Expiration Logic ---

      emit(state.copyWith(
        allSchools: schools,
        availableStatuses: statuses, // Store statuses in state
        isLoading: false,
      ));
      // Re-apply any existing search or filter terms
      add(SearchAndFilterSchools(
          searchTerm: state.searchTerm, filter: state.currentFilter));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  void _onSearchAndFilterSchools(
      SearchAndFilterSchools event, Emitter<SchoolManageState> emit) {
    List<School> schools = List.from(state.allSchools);

    // MODIFIED: Filter by comparing the status name with the selected filter's name
    if (event.filter != null) {
      schools = schools.where((school) {
        return school.status.name.toLowerCase() ==
            event.filter!.name.toLowerCase();
      }).toList();
    }

    if (event.searchTerm.isNotEmpty) {
      schools = schools.where((school) {
        final term = event.searchTerm.toLowerCase();
        return school.name.toLowerCase().contains(term) ||
            (school.code?.toLowerCase().contains(term) ?? false);
      }).toList();
    }

    emit(state.copyWith(
        filteredSchools: schools,
        searchTerm: event.searchTerm,
        currentFilter: event.filter,
        clearCurrentFilter: event.filter == null));
  }

  Future<void> _onFetchSchoolDetails(
      FetchSchoolDetails event, Emitter<SchoolManageState> emit) async {
    emit(state.copyWith(isDetailLoading: true, error: null));
    try {
      final school =
      await _schoolApiService.fetchSchoolDetails(schoolId: event.schoolId);
      emit(state.copyWith(selectedSchool: school, isDetailLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isDetailLoading: false));
    }
  }

  Future<void> _onFetchSubscriptionPlans(
      FetchSubscriptionPlans event, Emitter<SchoolManageState> emit) async {
    try {
      final plans = await _schoolApiService.fetchSubscriptions();
      emit(state.copyWith(subscriptionPlans: plans));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDeleteSchool(
      DeleteSchool event, Emitter<SchoolManageState> emit) async {
    emit(state.copyWith(error: null));
    try {
      print('🗑️ Deleting school with ID: ${event.schoolId}');
      final success = await _schoolApiService.deleteSchool(schoolId: event.schoolId);
      if (success) {
        print('✅ School deleted successfully, refreshing list...');
        add(FetchSchools()); // Refresh the schools list
      } else {
        print('❌ Failed to delete school');
        emit(state.copyWith(error: "Failed to delete the school."));
      }
    } catch (e) {
      print('❌ Error deleting school: $e');
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRenewSubscription(
      RenewSubscription event, Emitter<SchoolManageState> emit) async {
    emit(state.copyWith(error: null));
    try {
      final success = await _schoolApiService.renewSubscription(
        schoolId: event.schoolId,
        newSubscriptionId: int.parse(event.newSubscriptionId),
        newEndDate: event.newEndDate,
      );
      if (success) {
        add(FetchSchools());
      } else {
        emit(state.copyWith(error: "Failed to renew subscription."));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // NEW: Handler for the status update event
  Future<void> _onUpdateSchoolStatus(
      UpdateSchoolStatus event, Emitter<SchoolManageState> emit) async {
    emit(state.copyWith(error: null));
    try {
      final success = await _schoolApiService.updateSchoolStatus(
        schoolId: event.schoolId,
        statusId: event.statusId,
      );
      if (success) {
        add(FetchSchools()); // Refresh the list on success
      } else {
        emit(state.copyWith(error: "Failed to update school status."));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}