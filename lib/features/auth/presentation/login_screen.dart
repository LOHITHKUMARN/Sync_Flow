import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'auth_providers.dart';
import 'widgets/glossy_3d_icon_tile.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'alex.rivera@syncflow.dev');
  final _passwordController = TextEditingController(text: 'password123');
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _errorMessage;
  int _shakeCounter = 0;

  // Teal / Cyan brand accent tying card to the header icon
  static const Color _tealAccent = Color(0xFF06B6D4);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (mounted) {
        context.go('/projects');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _shakeCounter++;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            'alex.rivera@syncflow.dev',
            'password123',
          );
      if (mounted) {
        context.go('/projects');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google SSO sign-in failed. Please try email login.';
        _shakeCounter++;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBiometricSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : 'alex.rivera@syncflow.dev',
            'password123',
          );
      if (mounted) {
        context.go('/projects');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Biometric authentication failed. Please enter password.';
        _shakeCounter++;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.12),
            ),
          ),
          title: Text(
            'Reset Password',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your workspace email address and we will send you a password reset link.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'name@company.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.12),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _tealAccent, width: 2.0),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Password reset link sent to ${resetEmailController.text.trim()}!',
                      style: GoogleFonts.plusJakartaSans(),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _tealAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Send Link'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Explicitly watch themeModeProvider so toggling theme instantly rebuilds LoginScreen
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF222731) : const Color(0xFFEBF0F5),
      body: Stack(
        children: [
          // 1. Main Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(22.0, 12.0, 22.0, bottomInset + 20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Decorative 3D Icon Header (shrink/hide when keyboard is open)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: isKeyboardOpen ? 0 : 84,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isKeyboardOpen ? 0.0 : 1.0,
                          child: Center(
                            child: SizedBox(
                              width: 130,
                              height: 78,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: 4,
                                    top: 4,
                                    child: const Glossy3DIconTile(
                                      type: Icon3DType.sync,
                                      size: 64,
                                      rotationDegrees: -8,
                                      animateFloat: true,
                                      floatOffset: 3,
                                      floatDuration: Duration(milliseconds: 2600),
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 14,
                                    child: const Glossy3DIconTile(
                                      type: Icon3DType.checklist,
                                      size: 54,
                                      rotationDegrees: 12,
                                      animateFloat: true,
                                      floatOffset: -3,
                                      floatDuration: Duration(milliseconds: 3000),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isKeyboardOpen) const SizedBox(height: 10),

                      // Brand Logo & Heading
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : const Color(0xFF09090B),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: isDark ? 0.25 : 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.sync_alt_rounded,
                              size: 20,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'SyncFlow',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : const Color(0xFF09090B),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 6),

                      // Heading: "LOGIN" in the style of the reference image
                      Text(
                        'LOGIN',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: isDark ? Colors.white : const Color(0xFF09090B),
                        ),
                      ).animate().fadeIn(delay: 50.ms),
                      const SizedBox(height: 4),

                      // Subtitle with high contrast
                      Text(
                        "Welcome back, your team's been busy",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF3F3F46),
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 18),

                      // Fully Transparent Glass Login Card with 3D Spheres
                      Animate(
                        key: ValueKey(_shakeCounter),
                        effects: _shakeCounter > 0
                            ? [
                                const ShakeEffect(
                                  duration: Duration(milliseconds: 350),
                                  hz: 4,
                                  offset: Offset(8, 0),
                                )
                              ]
                            : [],
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1. Top-Right Big 3D Golden Sphere (partially behind card)
                            Positioned(
                              top: -45,
                              right: -35,
                              child: _MetallicGoldSphere(size: 155, isDark: isDark),
                            ),
                            // 2. Bottom-Left Medium 3D Golden Sphere (partially behind card)
                            Positioned(
                              bottom: -40,
                              left: -35,
                              child: _MetallicGoldSphere(size: 135, isDark: isDark),
                            ),
                            // 3. Top-Left Small Floating 3D Golden Sphere (outside card)
                            Positioned(
                              top: 25,
                              left: -22,
                              child: _MetallicGoldSphere(size: 38, isDark: isDark),
                            ),

                            // 4. Frosted Glass Plate
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isDark
                                          ? [
                                              Colors.white.withValues(alpha: 0.16),
                                              Colors.white.withValues(alpha: 0.05),
                                            ]
                                          : [
                                              Colors.white.withValues(alpha: 0.65),
                                              Colors.white.withValues(alpha: 0.25),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.85),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                                        blurRadius: 32,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                              child: AutofillGroup(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                  // Error Banner
                                  if (_errorMessage != null) ...[
                                    Semantics(
                                      liveRegion: true,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.priorityUrgent
                                              .withValues(alpha: isDark ? 0.25 : 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.priorityUrgent.withValues(alpha: 0.6),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: AppColors.priorityUrgent,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: AppColors.priorityUrgent,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ],

                                  // Email Field with transparent glass well
                                  CustomTextField(
                                    label: 'Email',
                                    hint: 'name@company.com',
                                    controller: _emailController,
                                    fillColor: isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.white.withValues(alpha: 0.65),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    autofillHints: const [
                                      AutofillHints.email,
                                      AutofillHints.username,
                                    ],
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      size: 20,
                                      color: isDark
                                          ? const Color(0xFFA1A1AA)
                                          : const Color(0xFF71717A),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!val.contains('@') || !val.contains('.')) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Password Field with Show/Hide Toggle & transparent glass well
                                  CustomTextField(
                                    label: 'Password',
                                    hint: '••••••••',
                                    controller: _passwordController,
                                    fillColor: isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.white.withValues(alpha: 0.65),
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [AutofillHints.password],
                                    prefixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                      color: isDark
                                          ? const Color(0xFFA1A1AA)
                                          : const Color(0xFF71717A),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: isDark
                                            ? const Color(0xFFA1A1AA)
                                            : const Color(0xFF71717A),
                                      ),
                                      tooltip: _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                    ),
                                    onFieldSubmitted: (_) => _handleLogin(),
                                    validator: (val) {
                                      if (val == null || val.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),

                                  // Remember Me & Forgot Password Row with Teal Accent
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              activeColor: _tealAccent,
                                              checkColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              side: BorderSide(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.30)
                                                    : Colors.black.withValues(alpha: 0.25),
                                              ),
                                              onChanged: (val) {
                                                setState(() => _rememberMe = val ?? true);
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() => _rememberMe = !_rememberMe);
                                            },
                                            child: Text(
                                              'Remember me',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                    ? const Color(0xFFD4D4D8)
                                                    : const Color(0xFF52525B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: _showForgotPasswordDialog,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 6),
                                          minimumSize: const Size(48, 36),
                                        ),
                                        child: Text(
                                          'Forgot password?',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _tealAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // Primary Sign In Button matching the reference photo
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFF1E242F)
                                          : const Color(0xFF09090B),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.15)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'SIGN IN',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Divider "or continue with" with enhanced contrast
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.12)
                                              : Colors.black.withValues(alpha: 0.10),
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'or continue with',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? const Color(0xFFA1A1AA)
                                                : const Color(0xFF71717A),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.12)
                                              : Colors.black.withValues(alpha: 0.10),
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // SSO and Biometric Sign In Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 13),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            side: BorderSide(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.14)
                                                  : const Color(0xFFE2E8F0),
                                            ),
                                            backgroundColor: Colors.transparent,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'G',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF09090B),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Google SSO',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF09090B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Tooltip(
                                        message: 'Sign in with Biometrics',
                                        child: OutlinedButton(
                                          onPressed:
                                              _isLoading ? null : _handleBiometricSignIn,
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 13, horizontal: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            side: BorderSide(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.14)
                                                  : const Color(0xFFE2E8F0),
                                            ),
                                            backgroundColor: Colors.transparent,
                                          ),
                                          child: Icon(
                                            Icons.fingerprint_rounded,
                                            size: 20,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF09090B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Sign Up Link with Teal Accent
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: isDark
                                              ? const Color(0xFFD4D4D8)
                                              : const Color(0xFF52525B),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => context.go('/register'),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 8),
                                          child: Text(
                                            'Create one',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _tealAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08, end: 0),
                      const SizedBox(height: 16),

                      // Footer Terms & Privacy Link with readable contrast and safe padding
                      Text(
                        'By continuing, you agree to SyncFlow Terms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? const Color(0xFFA1A1AA)
                              : const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 7. Dark / Light Mode Switcher with 48dp touch target (layered on top for hit testing)
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF18181B).withValues(alpha: 0.70)
                      : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 20,
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                  ),
                  tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3D Glossy Metallic Golden Sphere replicating the reference design
class _MetallicGoldSphere extends StatelessWidget {
  final double size;
  final bool isDark;

  const _MetallicGoldSphere({
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.20),
              blurRadius: size * 0.22,
              offset: Offset(size * 0.08, size * 0.12),
            ),
          ],
          gradient: const RadialGradient(
            center: Alignment(-0.35, -0.38),
            radius: 0.85,
            colors: [
              Color(0xFFFFFBEB), // Bright specular shine highlight
              Color(0xFFFDE68A), // Light warm gold
              Color(0xFFF59E0B), // Saturated amber gold
              Color(0xFFD97706), // Deep warm gold
              Color(0xFF78350F), // Bronze ambient occlusion rim shadow
            ],
            stops: [0.0, 0.22, 0.52, 0.78, 1.0],
          ),
        ),
      ),
    );
  }
}

