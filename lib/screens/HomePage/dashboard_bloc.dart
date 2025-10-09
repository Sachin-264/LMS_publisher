import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_publisher/Service/dashboard_service.dart';


// ================== EVENTS ==================
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class FetchDashboardData extends DashboardEvent {}

// ================== STATES ==================
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoadSuccess extends DashboardState {
  final Map<String, dynamic> data;

  const DashboardLoadSuccess(this.data);

  @override
  List<Object> get props => [data];
}

class DashboardLoadFailure extends DashboardState {
  final String error;

  const DashboardLoadFailure(this.error);

  @override
  List<Object> get props => [error];
}

// ================== BLOC ==================
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardApiService dashboardApiService;

  DashboardBloc({required this.dashboardApiService}) : super(DashboardInitial()) {
    on<FetchDashboardData>(_onFetchDashboardData);
  }

  void _onFetchDashboardData(FetchDashboardData event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final data = await dashboardApiService.fetchDashboardData();
      emit(DashboardLoadSuccess(data));
    } catch (e) {
      emit(DashboardLoadFailure(e.toString()));
    }
  }
}
