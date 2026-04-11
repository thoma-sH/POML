import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_flutter_app/features/auth/domain/entities/app_user.dart';
import 'package:first_flutter_app/features/auth/domain/entities/repos/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  
  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      //attempt sign in
      UserCredential userCredential = await firebaseAuth
        .signInWithEmailAndPassword(email: email, password: password);
      
      // create the user
      AppUser user = AppUser(
        userId: userCredential.user!.uid,
        email: email,
        name: ''
        );

      // return user
      return user;
    }

    catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<AppUser?> registerWithEmailPassword(
    String name, String email, String password) async {
    try {
      //attempt sign up
      UserCredential userCredential = await firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);
      
      // create the user
      AppUser user = AppUser(
        userId: userCredential.user!.uid,
        email: email,
        name: ''
        );

      // return user
      return user;
    }

    catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    // get current login from firebase
    final firebaseUser = firebaseAuth.currentUser;

    // no one logged in
    if (firebaseUser == null) {
      return null;
    }

    // user exists
    return AppUser(
      userId: firebaseUser.uid,
      email: firebaseUser.email!,
      name: '',
      );
  }
}