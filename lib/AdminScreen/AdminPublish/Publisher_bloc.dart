import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/publish_model.dart';
import 'package:lms_publisher/Service/publisher_api_service.dart';
import 'package:meta/meta.dart';

// ==================== EVENTS ====================

@immutable
abstract class PublisherEvent {}

class LoadPublisherData extends PublisherEvent {}

class DeletePublisher extends PublisherEvent {
  final int recNo;
  final String deleteType; // 'soft' or 'hard'

  DeletePublisher({required this.recNo, required this.deleteType});
}

class ActivatePublisher extends PublisherEvent {
  final int recNo;

  ActivatePublisher({required this.recNo});
}

// NEW EVENT - Load credentials for a publisher
class LoadPublisherCredentials extends PublisherEvent {
  final int pubCode;

  LoadPublisherCredentials({required this.pubCode});
}

// NEW EVENT - Update credentials
class UpdatePublisherCredentials extends PublisherEvent {
  final int pubCode;
  final String userID;
  final String userPassword;
  final String modifiedBy;

  UpdatePublisherCredentials({
    required this.pubCode,
    required this.userID,
    required this.userPassword,
    required this.modifiedBy,
  });
}

// ==================== STATES ====================

@immutable
abstract class PublisherState {}

class PublisherInitial extends PublisherState {}

class PublisherLoading extends PublisherState {}

class PublisherLoaded extends PublisherState {
  final List<Publisher> activePublishers;
  final List<Publisher> inactivePublishers;
  final AdminKPIs kpis;

  PublisherLoaded({
    required this.activePublishers,
    required this.inactivePublishers,
    required this.kpis,
  });
}

class PublisherError extends PublisherState {
  final String message;

  PublisherError(this.message);
}

// NEW STATE - Credentials loaded
class PublisherCredentialsLoaded extends PublisherState {
  final Map<String, dynamic> credentials;

  PublisherCredentialsLoaded(this.credentials);
}

// NEW STATE - Credentials loading
class PublisherCredentialsLoading extends PublisherState {}

// NEW STATE - Credentials updated
class PublisherCredentialsUpdated extends PublisherState {
  final String message;

  PublisherCredentialsUpdated(this.message);
}

// ==================== BLOC ====================

class PublisherBloc extends Bloc<PublisherEvent, PublisherState> {
  final PublisherApiService _apiService;

  PublisherBloc(this._apiService) : super(PublisherInitial()) {

    // ========== Load Publisher Data ==========
    on<LoadPublisherData>((event, emit) async {
      print('[PublisherBloc] Loading publisher data...');
      emit(PublisherLoading());

      try {
        final results = await Future.wait([
          _apiService.getAdminKPIs(),
          _apiService.getAllPublishers(),
        ]);

        final kpis = results[0] as AdminKPIs;
        final allPublishers = results[1] as List<Publisher>;

        // Split publishers into active and inactive
        final activePublishers = allPublishers.where((p) => p.isActive == 1).toList();
        final inactivePublishers = allPublishers.where((p) => p.isActive == 0).toList();

        print('[PublisherBloc] KPIs loaded: ${kpis.publisherCount} total publishers');
        print('[PublisherBloc] Active: ${activePublishers.length}, Inactive: ${inactivePublishers.length}');

        emit(PublisherLoaded(
          kpis: kpis,
          activePublishers: activePublishers,
          inactivePublishers: inactivePublishers,
        ));
      } catch (e) {
        print('[PublisherBloc] Error loading data: $e');
        emit(PublisherError(e.toString()));
      }
    });

    // ========== Delete Publisher ==========
    on<DeletePublisher>((event, emit) async {
      print('[PublisherBloc] Attempting to ${event.deleteType} delete publisher with RecNo: ${event.recNo}');

      try {
        bool success = false;

        if (event.deleteType == 'soft') {
          success = await _apiService.softDeletePublisher(event.recNo);
        } else {
          success = await _apiService.hardDeletePublisher(event.recNo);
        }

        if (success) {
          print('[PublisherBloc] Successfully deleted publisher. Reloading data...');
          add(LoadPublisherData());
        } else {
          print('[PublisherBloc] Failed to delete publisher from API.');
          emit(PublisherError('Failed to delete publisher.'));
        }
      } catch (e) {
        print('[PublisherBloc] Error deleting publisher: $e');
        emit(PublisherError(e.toString()));
      }
    });

    // ========== Activate Publisher ==========
    on<ActivatePublisher>((event, emit) async {
      print('[PublisherBloc] Attempting to activate publisher with RecNo: ${event.recNo}');

      try {
        bool success = await _apiService.activatePublisher(event.recNo);

        if (success) {
          print('[PublisherBloc] Successfully activated publisher. Reloading data...');
          add(LoadPublisherData());
        } else {
          print('[PublisherBloc] Failed to activate publisher from API.');
          emit(PublisherError('Failed to activate publisher.'));
        }
      } catch (e) {
        print('[PublisherBloc] Error activating publisher: $e');
        emit(PublisherError(e.toString()));
      }
    });

    // ========== NEW: Load Publisher Credentials ==========
    on<LoadPublisherCredentials>((event, emit) async {
      print('[PublisherBloc] Loading credentials for PubCode: ${event.pubCode}');
      emit(PublisherCredentialsLoading());

      try {
        final credentials = await _apiService.getPublisherCredentials(event.pubCode);
        print('[PublisherBloc] Credentials loaded successfully');
        emit(PublisherCredentialsLoaded(credentials));
      } catch (e) {
        print('[PublisherBloc] Error loading credentials: $e');
        emit(PublisherError('Failed to load credentials: $e'));
      }
    });

    // ========== NEW: Update Publisher Credentials ==========
    on<UpdatePublisherCredentials>((event, emit) async {
      print('[PublisherBloc] Updating credentials for PubCode: ${event.pubCode}');
      emit(PublisherLoading());

      try {
        bool success = await _apiService.updatePublisherCredentials(
          event.pubCode,
          event.userID,
          event.userPassword,
          event.modifiedBy,
        );

        if (success) {
          print('[PublisherBloc] Credentials updated successfully');
          emit(PublisherCredentialsUpdated('Credentials updated successfully'));
          // Reload publisher data
          add(LoadPublisherData());
        } else {
          print('[PublisherBloc] Failed to update credentials');
          emit(PublisherError('Failed to update credentials'));
        }
      } catch (e) {
        print('[PublisherBloc] Error updating credentials: $e');
        emit(PublisherError('Failed to update credentials: $e'));
      }
    });
  }
}
