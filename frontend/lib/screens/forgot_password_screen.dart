import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import '../theme.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ReminderProvider>(context, listen: false);
    final phoneNumber = _phoneController.text.trim();

    provider.sendForgotPasswordOtp(phoneNumber).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to registered number successfully.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(phoneNumber: phoneNumber),
          ),
        );
      }
    }).catchError((err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: $err'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.textPrimaryLightMode),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Forgot Password',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.textPrimaryLightMode,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Selector<ReminderProvider, bool>(
          selector: (_, provider) => provider.isLoading,
          builder: (context, isLoading, child) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: FadeInSlide(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgCard : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.getCardShadow(
                                color: AppTheme.primary,
                                isDark: isDark,
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              size: 80,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'OTP Verification',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Enter your registered email address or mobile number below to receive a 6-digit OTP code to reset your password.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppTheme.textPrimaryLightMode,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Email Address or Phone Number',
                              hintText: 'Enter registered email or phone',
                              prefixIcon: Icon(Icons.perm_identity_rounded, size: 22),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email or phone number';
                              }
                              final text = value.trim();
                              if (text.contains('@')) {
                                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
                                  return 'Please enter a valid email address';
                                }
                              } else {
                                final clean = text.replaceAll(RegExp(r'\D'), '');
                                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
                                  return 'Please enter a valid 10-digit Indian phone number';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: isLoading ? null : _sendOtp,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Send OTP'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
