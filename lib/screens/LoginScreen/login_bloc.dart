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

class LogoutRequested extends LoginEvent {}

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

class LogoutSuccess extends LoginState {}

// BLoC
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserRightsService userRightsService;
  final UserProvider userProvider;

  LoginBloc({
    required this.userRightsService,
    required this.userProvider,
  }) : super(LoginInitial()) {
    on<LoadUserGroups>(_onLoadUserGroups);
    on<UserIdChanged>(_onUserIdChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<RoleSelected>(_onRoleSelected);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
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
    // ✅ FIXED: Removed state check - allow login from any state
    final String userId;
    final String password;

    // Get credentials from current state
    if (state is UserGroupsLoaded) {
      final currentState = state as UserGroupsLoaded;
      userId = currentState.userId;
      password = currentState.password;
    } else {
      emit(LoginFailure('Please wait while loading...'));
      return;
    }

    // Validate inputs
    if (userId.isEmpty || password.isEmpty) {
      emit(LoginFailure('Please fill all fields'));
      if (state is UserGroupsLoaded) {
        emit(state as UserGroupsLoaded); // Restore state
      }
      return;
    }

    emit(LoginLoading());
    try {
      final response = await userRightsService.login(
        userId: userId,
        password: password,
      );

      // Store the user data in the UserProvider
      userProvider.initializeUser(response);
      emit(LoginSuccess(response));
    } catch (e) {
      // Reload groups and restore input
      try {
        final groups = await userRightsService.getUserGroups();
        emit(LoginFailure(e.toString()));
        emit(UserGroupsLoaded(
          userGroups: groups,
          userId: userId,
          password: password,
        ));
      } catch (_) {
        emit(LoginFailure(e.toString()));
      }
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
