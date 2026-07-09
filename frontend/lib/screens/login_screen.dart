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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App branding logo
                      Center(
                        child: Image.asset(
                          'assets/images/logo_light.png',
                          height: 55,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Welcome to eazzio reminder',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Sign In / Sign Up Selector Tabs
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSignIn = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _isSignIn
                                      ? AppTheme.primary.withOpacity(0.12)
                                      : Colors.black.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _isSignIn ? AppTheme.primary : const Color(0xFFD6D4EB),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.login_rounded,
                                      color: _isSignIn ? AppTheme.primary : Colors.black54,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _isSignIn ? AppTheme.primary : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSignIn = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: !_isSignIn
                                      ? AppTheme.primary.withOpacity(0.12)
                                      : Colors.black.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: !_isSignIn ? AppTheme.primary : const Color(0xFFD6D4EB),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.person_add_outlined,
                                      color: !_isSignIn ? AppTheme.primary : Colors.black54,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: !_isSignIn ? AppTheme.primary : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Form Container Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFD6D4EB),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _isSignIn ? _buildSignInForm() : _buildSignUpForm(),
                      ),
                    ],
                  ),
                ),
              ),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your phone number or email and password to sync task schedules.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _signInIdentifierController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Phone Number or Email Address',
              prefixIcon: Icon(Icons.mail_outline),
              hintText: 'e.g. user@gmail.com or 9876543210',
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your phone number or email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signInPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: provider.isLoading ? null : _submitSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: provider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFD6D4EB))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              Expanded(child: Divider(color: Color(0xFFD6D4EB))),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _showGoogleLoginDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Color(0xFFD6D4EB)),
            ),
            icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
            label: const Text('Sign In with Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign up with phone and create a password to begin syncing schedules.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _signUpNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
              hintText: 'e.g. John Doe',
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Full name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signUpPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: 'e.g. 9876543210',
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
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Password is required';
              if (value.trim().length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: provider.isLoading ? null : _submitSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: provider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFD6D4EB))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              Expanded(child: Divider(color: Color(0xFFD6D4EB))),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _showGoogleLoginDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Color(0xFFD6D4EB)),
            ),
            icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
            label: const Text('Sign Up with Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailPhoneController = TextEditingController();
    final nameConfirmController = TextEditingController();
    final newPasswordController = TextEditingController();
    final dialogKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
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
                        'Confirm your account details below to reset your password.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailPhoneController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          labelText: 'Phone or Email Address',
                          prefixIcon: Icon(Icons.mail_outline, size: 20),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required field' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameConfirmController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          labelText: 'Your Account Name',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required field' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                        ),
                        validator: (value) => value == null || value.trim().length < 4 ? 'Must be at least 4 characters' : null,
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
                    final success = await provider.resetPassword(
                      identifier: emailPhoneController.text.trim(),
                      name: nameConfirmController.text.trim(),
                      newPassword: newPasswordController.text.trim(),
                    );

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset successfully! Please sign in with your new password.'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid account details. Please check your name and email/phone.'),
                          backgroundColor: AppTheme.warning,
                        ),
                      );
                    }
                  },
                  child: const Text('Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
