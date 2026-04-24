import 'package:first_flutter_app/features/auth/domain/entities/app_user.dart';
// The AuthState class hierarchy defines the various states that the authentication flow can be in.
// AuthInitial represents the initial state before any authentication check has been made.
// AuthLoading indicates that an authentication operation (login or registration) is currently in progress.
// Authenticated holds the authenticated user's information when the user is successfully logged in.
// Unauthenticated represents the state when there is no authenticated user.
// AuthError contains an error message when an authentication operation fails.
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AppUser user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
