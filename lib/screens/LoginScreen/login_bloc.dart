// lib/screens/LoginScreen/login_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Service/user_right_service.dart';


// Events
abstract class LoginEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUserGroups extends LoginEvent {}

class UserIdChanged extends LoginEvent {
  final String userId;
  UserIdChanged(this.userId);

  @override
  List<Object?> get props => [userId];
}

class PasswordChanged extends LoginEvent {
  final String password;
  PasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class RoleSelected extends LoginEvent {
  final UserGroup? role;
  RoleSelected(this.role);

  @override
  List<Object?> get props => [role];
}

class LoginSubmitted extends LoginEvent {}

class LogoutRequested extends LoginEvent {} // New event for logout

// States
abstract class LoginState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class UserGroupsLoaded extends LoginState {
  final List<UserGroup> userGroups;
  final String userId;
  final String password;
  final UserGroup? selectedRole;

  UserGroupsLoaded({
    required this.userGroups,
    this.userId = '',
    this.password = '',
    this.selectedRole,
  });

  UserGroupsLoaded copyWith({
    List<UserGroup>? userGroups,
    String? userId,
    String? password,
    UserGroup? selectedRole,
  }) {
    return UserGroupsLoaded(
      userGroups: userGroups ?? this.userGroups,
      userId: userId ?? this.userId,
      password: password ?? this.password,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }

  @override
  List<Object?> get props => [userGroups, userId, password, selectedRole];
}

class LoginSuccess extends LoginState {
  final LoginResponse response;
  LoginSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class LoginFailure extends LoginState {
  final String error;
  LoginFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class LogoutSuccess extends LoginState {} // New state for logout

// BLoC
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserRightsService userRightsService;
  final UserProvider userProvider; // Add UserProvider

  LoginBloc({
    required this.userRightsService,
    required this.userProvider, // Add UserProvider to constructor
  }) : super(LoginInitial()) {
    on<LoadUserGroups>(_onLoadUserGroups);
    on<UserIdChanged>(_onUserIdChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<RoleSelected>(_onRoleSelected);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested); // Add logout handler
  }

  Future<void> _onLoadUserGroups(
      LoadUserGroups event,
      Emitter<LoginState> emit,
      ) async {
    emit(LoginLoading());
    try {
      final groups = await userRightsService.getUserGroups();
      emit(UserGroupsLoaded(userGroups: groups));
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }

  void _onUserIdChanged(
      UserIdChanged event,
      Emitter<LoginState> emit,
      ) {
    if (state is UserGroupsLoaded) {
      final currentState = state as UserGroupsLoaded;
      emit(currentState.copyWith(userId: event.userId));
    }
  }

  void _onPasswordChanged(
      PasswordChanged event,
      Emitter<LoginState> emit,
      ) {
    if (state is UserGroupsLoaded) {
      final currentState = state as UserGroupsLoaded;
      emit(currentState.copyWith(password: event.password));
    }
  }

  void _onRoleSelected(
      RoleSelected event,
      Emitter<LoginState> emit,
      ) {
    if (state is UserGroupsLoaded) {
      final currentState = state as UserGroupsLoaded;
      emit(currentState.copyWith(selectedRole: event.role));
    }
  }

  Future<void> _onLoginSubmitted(
      LoginSubmitted event,
      Emitter<LoginState> emit,
      ) async {
    if (state is! UserGroupsLoaded) return;

    final currentState = state as UserGroupsLoaded;

    if (currentState.userId.isEmpty ||
        currentState.password.isEmpty ||
        currentState.selectedRole == null) {
      emit(LoginFailure('Please fill all fields'));
      emit(currentState);
      return;
    }

    emit(LoginLoading());

    try {
      final response = await userRightsService.login(
        userId: currentState.userId,
        password: currentState.password,
      );

      // Store the user data in the UserProvider
      userProvider.initializeUser(response);

      emit(LoginSuccess(response));
    } catch (e) {
      final groups = await userRightsService.getUserGroups();
      emit(LoginFailure(e.toString()));
      emit(UserGroupsLoaded(
        userGroups: groups,
        userId: currentState.userId,
        password: currentState.password,
        selectedRole: currentState.selectedRole,
      ));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<LoginState> emit,
      ) async {
    // Clear user data from UserProvider
    userProvider.logout();

    // Reset the login state
    emit(LoginInitial());

    // Reload user groups for next login
    add(LoadUserGroups());
  }
}