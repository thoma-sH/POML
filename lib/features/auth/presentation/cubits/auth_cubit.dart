import 'package:first_flutter_app/features/auth/domain/entities/app_user.dart';
import 'package:first_flutter_app/features/auth/domain/entities/repos/auth_repo.dart';
import 'package:first_flutter_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  // The checkAuth method checks if there is a currently authenticated user by calling getCurrentUser on the authRepo. 
  // It emits an Authenticated state if a user is found, or Unauthenticated if not. 
  // This method is typically called when the app starts to determine if the user is already logged in.
  void checkAuth() async {
    final user = await authRepo.getCurrentUser();
    emit(user != null ? Authenticated(user) : Unauthenticated());
  }

  // The login method attempts to log in with the provided username and password. 
  // It uses a helper method _handleAuthResult to manage the authentication flow and state emissions. 
  // If the login is successful, it emits an Authenticated state;
  // if it fails, it emits an AuthError followed by Unauthenticated.
  Future<void> login(String username, String pw) =>
      _handleAuthResult(() => authRepo.loginWithUsernamePassword(username, pw));

  // The register method attempts to register a new user with the provided username and password. 
  // Like the login method, it uses _handleAuthResult to manage the authentication flow and state emissions. 
  // If the registration is successful, it emits an Authenticated state;
  // if it fails, it emits an AuthError followed by Unauthenticated.
  Future<void> register(String username, String pw) =>
      _handleAuthResult(() => authRepo.registerWithUsernamePassword(username, pw));

  // The logout method logs the user out by calling logout on the authRepo and then emits an Unauthenticated state.
  Future<void> logout() async {
    await authRepo.logout();
    emit(Unauthenticated());
  }

  // The _handleAuthResult method is a helper function that takes an asynchronous action (either login or register)
  // and manages the authentication flow. 
  // It emits an AuthLoading state while the action is in progress, then emits Authenticated if the action returns a user,
  // or Unauthenticated if it returns null. 
  // If an error occurs during the action, it catches the exception, emits an AuthError with the error message,
  // and then emits Unauthenticated.
  Future<void> _handleAuthResult(Future<AppUser?> Function() action) async {
    try {
      emit(AuthLoading());
      final user = await action();
      emit(user != null ? Authenticated(user) : Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }
}
