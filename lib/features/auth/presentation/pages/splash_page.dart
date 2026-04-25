import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.blur_circular_rounded,
              color: AppColors.accent,
              size: 88,
            ),
            const SizedBox(height: 18),
            Text(
              'lacuna',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
