import 'package:first_flutter_app/features/auth/domain/entities/app_user.dart';
import 'package:first_flutter_app/features/auth/domain/entities/repos/auth_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepo implements AuthRepo {
  // This implementation of AuthRepo uses Supabase for authentication. 
  // It converts between the app's username/password model and Supabase's email/password model by 
  // appending a fixed domain to the username. 
  // It also handles the conversion between Supabase's user model and the app's AppUser model. 
  // The getCurrentUser method retrieves the current authenticated user from Supabase and converts it to an AppUser if it exists.
  final _client = Supabase.instance.client;

  static const _emailDomain = '@lacuna.app';
  String _toEmail(String username) => '$username$_emailDomain';
  String _toUsername(String email) => email.replaceAll(_emailDomain, '');

  // The loginWithUsernamePassword method attempts to sign in with Supabase using the converted email and password. 
  // If successful, it converts the Supabase user to an AppUser and returns it. 
  // If the sign-in fails (e.g., due to incorrect credentials), it throws a generic exception with a user-friendly message.
  @override
  Future<AppUser?> loginWithUsernamePassword(
      String username, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: _toEmail(username),
        password: password,
      );
      final user = response.user;
      if (user == null) return null;
      return AppUser(userId: user.id, username: username);
    } catch (_) {
      throw Exception('Incorrect username or password.');
    }
  }

  // The registerWithUsernamePassword method attempts to sign up with Supabase using the converted email and password. 
  // If successful, it converts the Supabase user to an AppUser and returns it. 
  // If the sign-up fails because the email is already registered, it throws a specific exception
  // with a user-friendly message. For any other failure, it throws a generic exception.
  @override
  Future<AppUser?> registerWithUsernamePassword(
      String username, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: _toEmail(username),
        password: password,
        data: {'username': username},
      );
      final user = response.user;
      if (user == null) return null;
      // Profile row is created atomically by the on_auth_user_created trigger.
      return AppUser(userId: user.id, username: username);
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw Exception('That username is already taken.');
      }
      throw Exception('Registration failed. Please try again.');
    } catch (_) {
      throw Exception('Registration failed. Please try again.');
    }
  }

  // The logout method simply calls Supabase's signOut method to log the user out.
  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // The getCurrentUser method retrieves the current authenticated user from Supabase. 
  // If there is a user, it attempts to extract the username from the user's metadata or email. 
  // If a valid username can be determined, it returns an AppUser; otherwise, it returns null.
  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final username = user.userMetadata?['username'] as String? ??
        _toUsername(user.email ?? '');
    if (username.isEmpty) return null;
    return AppUser(userId: user.id, username: username);
  }
}
