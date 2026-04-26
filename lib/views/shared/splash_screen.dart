import 'package:alimenta_peru/app/routes.dart';
import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/core/constants/app_strings.dart';
import 'package:alimenta_peru/core/constants/app_styles.dart';
import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleUp = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _redirigir();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redirigir() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final authVM = context.read<AuthViewModel>();
    if (authVM.isAuthenticated && authVM.rolUsuario != null) {
      Navigator.pushReplacementNamed(
        context,
        authVM.rolUsuario!.dashboardRoute,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleUp,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: AppStyles.borderRadiusXL,
                    boxShadow: AppStyles.shadowElevated,
                  ),
                  child: const Center(
                    child: Text(
                      '🥗',
                      style: TextStyle(fontSize: 52),
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.spacingL),
                Text(
                  AppStrings.appName,
                  style: AppStyles.displayMedium.copyWith(
                    color: AppColors.cardBackground,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingS),
                Text(
                  AppStrings.appTagline,
                  style: AppStyles.bodyLarge.copyWith(
                    color: AppColors.cardBackground.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: AppStyles.spacingXXL),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.cardBackground.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
