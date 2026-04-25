import 'package:first_flutter_app/features/auth/domain/entities/app_user.dart';

abstract class AuthRepo {
  // The AuthRepo interface defines the contract for authentication operations in the app.
  // It includes methods for logging in, registering, logging out, and retrieving the current authenticated user.
  // This abstraction allows for different implementations (e.g., a mock repo for testing and a real repo using Supabase)
  // without affecting the rest of the app's codebase.
  Future<AppUser?> loginWithUsernamePassword(String username, String password);
  Future<AppUser?> registerWithUsernamePassword(String username, String password);
  Future<void> logout();
  Future<AppUser?> getCurrentUser();

  /// Permanently deletes the current account and all associated personal data.
  /// Required by Apple App Store Guideline 5.1.1(v). Implementations should:
  ///  - delete posts, votes, follows, profile, and any uploaded media
  ///  - sign the user out
  ///  - throw on failure with a user-friendly message
  Future<void> deleteAccount();
}
