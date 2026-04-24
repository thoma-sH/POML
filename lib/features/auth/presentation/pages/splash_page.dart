import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  // The SplashPage is a simple stateless widget that displays a splash screen with a 
  // gradient background, an icon, and the app name. 
  // It is shown while the app is checking the authentication status of the user
  // (e.g., during the AuthInitial and AuthLoading states) before deciding 
  // whether to navigate to the login page or the main app shell. 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5225B8), Color(0xFF9B5CFF)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.blur_circular_rounded, color: Colors.white, size: 96),
              SizedBox(height: 12),
              Text(
                'Lacuna',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
