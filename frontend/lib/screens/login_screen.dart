import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import '../theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final _signInIdentifierController = TextEditingController(); // email or phone
  final _signInPasswordController = TextEditingController();

  final _signUpNameController = TextEditingController();
  final _signUpPhoneController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  bool _isSignIn = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _signInIdentifierController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  void _submitSignIn() {
    if (!_signInFormKey.currentState!.validate()) return;

    final provider = Provider.of<ReminderProvider>(context, listen: false);
    final identifier = _signInIdentifierController.text.trim();
    final password = _signInPasswordController.text.trim();

    provider.loginWithCredentials(identifier, password).then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }).catchError((err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $err'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    });
  }

  void _submitSignUp() {
    if (!_signUpFormKey.currentState!.validate()) return;

    final provider = Provider.of<ReminderProvider>(context, listen: false);
    final name = _signUpNameController.text.trim();
    final phone = _signUpPhoneController.text.trim();
    final password = _signUpPasswordController.text.trim();

    provider.signUpWithCredentials(name, phone, password).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign up successful! Please sign in with your phone number and password.'),
            backgroundColor: AppTheme.success,
          ),
        );
        setState(() {
          // Pre-populate the Sign In phone number
          _signInIdentifierController.text = phone;
          // Switch tab to Sign In selection
          _isSignIn = true;
          // Clear sign up controllers
          _signUpNameController.clear();
          _signUpPhoneController.clear();
          _signUpPasswordController.clear();
        });
      }
    }).catchError((err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed: $err'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    });
  }

  void _showGoogleLoginDialog() {
    final googleNameController = TextEditingController();
    final googleEmailController = TextEditingController();
    final googleDialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return Theme(
          data: AppTheme.lightTheme,
          child: AlertDialog(
            title: const Text(
              'Sign in with Google',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            content: Form(
              key: googleDialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: googleNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: googleEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Google Email (Gmail)',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter your Gmail';
                      if (!val.trim().toLowerCase().endsWith('@gmail.com')) return 'Must be a valid @gmail.com address';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!googleDialogFormKey.currentState!.validate()) return;
                  
                  final name = googleNameController.text.trim();
                  final email = googleEmailController.text.trim();
                  Navigator.pop(context); // Close dialog

                  final provider = Provider.of<ReminderProvider>(this.context, listen: false);
                  provider.loginWithGoogle(name, email).then((_) {
                    if (mounted) {
                      Navigator.of(this.context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    }
                  }).catchError((err) {
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Google Login failed: $err'),
                          backgroundColor: AppTheme.danger,
                        ),
                      );
                    }
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Sign In', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Stack(
              children: [
                // Glowing gradient background blob 1 (Top right)
                Positioned(
                  top: -80,
                  right: -80,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withOpacity(0.15),
                    ),
                  ),
                ),
                // Glowing gradient background blob 2 (Bottom left)
                Positioned(
                  bottom: -100,
                  left: -100,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.secondary.withOpacity(0.12),
                    ),
                  ),
                ),
                // Glassmorphism blur filter
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Main scrollable content
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 450),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo & Branding
                              Hero(
                                tag: 'app_logo',
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/logo_light.png',
                                    height: 60,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Center(
                                child: Text(
                                  'Welcome to eazzio reminder',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF6E6893),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 35),

                              // Outer Card with clean borders and subtle drop shadow
                              Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: const Color(0xFFE8E7F3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withOpacity(0.04),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Segmented Sliding Tab Switcher (Pill Switcher)
                                    Container(
                                      height: 52,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F2F8),
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(() => _isSignIn = true),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 220),
                                                curve: Curves.easeInOut,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: _isSignIn ? AppTheme.primary : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(22),
                                                  boxShadow: _isSignIn
                                                      ? [
                                                          BoxShadow(
                                                            color: AppTheme.primary.withOpacity(0.3),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 3),
                                                          )
                                                        ]
                                                      : [],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.login_rounded,
                                                      color: _isSignIn ? Colors.white : const Color(0xFF757095),
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Sign In',
                                                      style: TextStyle(
                                                        color: _isSignIn ? Colors.white : const Color(0xFF757095),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(() => _isSignIn = false),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 220),
                                                curve: Curves.easeInOut,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: !_isSignIn ? AppTheme.primary : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(22),
                                                  boxShadow: !_isSignIn
                                                      ? [
                                                          BoxShadow(
                                                            color: AppTheme.primary.withOpacity(0.3),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 3),
                                                          )
                                                        ]
                                                      : [],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.person_add_rounded,
                                                      color: !_isSignIn ? Colors.white : const Color(0xFF757095),
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Sign Up',
                                                      style: TextStyle(
                                                        color: !_isSignIn ? Colors.white : const Color(0xFF757095),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 28),

                                    // Display the relevant Form
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: _isSignIn ? _buildSignInForm() : _buildSignUpForm(),
                                    ),
                                  ],
                                ),
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
          );
        }
      ),
    );
  }

  Widget _buildSignInForm() {
    final provider = Provider.of<ReminderProvider>(context);

    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign In to your Account',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your phone number or email and password to sync task schedules.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF6E6893), height: 1.3),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _signInIdentifierController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Phone Number or Email Address',
              prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppTheme.primary),
              hintText: 'Enter phone number/ Email address',
              filled: true,
              fillColor: const Color(0xFFF9F8FD),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E3F5), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.8),
              ),
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your phone number or email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signInPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF757095)),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: const Color(0xFFF9F8FD),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E3F5), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.8),
              ),
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your password' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : _submitSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFE5E3F5), thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('OR', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider(color: Color(0xFFE5E3F5), thickness: 1)),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: _showGoogleLoginDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: Color(0xFFE5E3F5), width: 1.2),
              backgroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF4285F4),
                      Color(0xFF34A853),
                      Color(0xFFFBBC05),
                      Color(0xFFEA4335),
                    ],
                  ).createShader(bounds),
                  child: const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 8),
                const Text('Sign In with Google', style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    final provider = Provider.of<ReminderProvider>(context);

    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create a new Account',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign up with phone and create a password to begin syncing schedules.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF6E6893), height: 1.3),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _signUpNameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primary),
              hintText: 'e.g. John Doe',
              filled: true,
              fillColor: const Color(0xFFF9F8FD),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E3F5), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.8),
              ),
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Full name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signUpPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primary),
              hintText: 'e.g. 9876543210',
              filled: true,
              fillColor: const Color(0xFFF9F8FD),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E3F5), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Phone number is required';
              if (value.trim().length < 10) return 'Enter a valid 10-digit number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signUpPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Create Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF757095)),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: const Color(0xFFF9F8FD),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E3F5), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Password is required';
              if (value.trim().length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : _submitSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFE5E3F5), thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('OR', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider(color: Color(0xFFE5E3F5), thickness: 1)),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: _showGoogleLoginDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: Color(0xFFE5E3F5), width: 1.2),
              backgroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF4285F4),
                      Color(0xFF34A853),
                      Color(0xFFFBBC05),
                      Color(0xFFEA4335),
                    ],
                  ).createShader(bounds),
                  child: const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 8),
                const Text('Sign Up with Google', style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final dialogKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return Theme(
          data: AppTheme.lightTheme,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, color: AppTheme.primary, size: 28),
                    SizedBox(width: 8),
                    Text('Forgot Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                  ],
                ),
                content: Form(
                  key: dialogKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Enter your registered Gmail address below and we will send you a password reset link.',
                          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.black87),
                          decoration: const InputDecoration(
                            labelText: 'Gmail / Email Address',
                            prefixIcon: Icon(Icons.mail_outline, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Please enter your email';
                            if (!value.contains('@')) return 'Please enter a valid email address';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (!dialogKey.currentState!.validate()) return;
                      
                      final provider = Provider.of<ReminderProvider>(context, listen: false);
                      final success = await provider.forgotPassword(
                        emailController.text.trim(),
                      );
  
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset link sent! Please check your email inbox.'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to request reset link. Please check your network connection.'),
                            backgroundColor: AppTheme.danger,
                          ),
                        );
                      }
                    },
                    child: const Text('Send Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
