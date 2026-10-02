import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:clearedtogo/theme/app_colors.dart';
import 'package:clearedtogo/services/supabase_auth_service.dart';
import 'package:clearedtogo/screens/home_screen.dart';
import 'package:clearedtogo/screens/auth/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _auth = SupabaseAuthService();
  bool _isLoading = false;
  bool _acceptedTerms = false;
  String? _errorMessage;

  String _friendlyError(Object e) {
    if (e is sb.AuthException) {
      switch (e.code) {
        case 'user_already_exists':
        case 'email_exists':
          return 'An account with this email already exists. Try logging in instead.';
        case 'weak_password':
          return 'That password is too weak — use at least 8 characters with a mix of letters and numbers.';
        case 'over_email_send_rate_limit':
          return 'Too many attempts. Please wait a moment and try again.';
      }
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists')) {
        return 'An account with this email already exists. Try logging in instead.';
      }
      return e.message;
    }
    if (e is sb.PostgrestException && e.code == 'P0002') {
      return 'Invalid invite code. Double-check it with your flight school and try again.';
    }
    return 'Something went wrong creating your account. Please try again.';
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'You must accept the Terms & Conditions to continue';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final inviteCode = _inviteCodeController.text.trim();

    try {
      final codeIsValid = await _auth.validateInviteCode(inviteCode);
      if (!codeIsValid) {
        setState(() {
          _errorMessage = 'Invalid invite code. Double-check it with your '
              'flight school and try again.';
          _isLoading = false;
        });
        return;
      }

      final profile = await _auth.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        inviteCode: inviteCode,
        acceptedTerms: _acceptedTerms,
      );

      if (!mounted) return;

      if (profile == null) {
        // Email confirmation is required on this project — no session yet,
        // so there's nothing to log in to. Tell the pilot what's next.
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Check your email'),
            content: const Text(
              'We sent a confirmation link to your email address. '
              'Confirm it, then log in below.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = _friendlyError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign up to get started",
                  style: TextStyle(
                    fontSize: 16,
                    // Dark navy, not a light grey - readable against the
                    // light background at normal-text contrast ratios.
                    color: Color(0xFF0C2942),
                  ),
                ),
                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Full name field (optional)
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name (optional)',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Flight school invite code (required)
                TextFormField(
                  controller: _inviteCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Flight School Invite Code',
                    helperText: 'Not with a real school? Ask your '
                        'business_admin for the Independent Pilots code',
                    prefixIcon: const Icon(Icons.school),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'An invite code is required to create an account';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Terms & Conditions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Liability Terms & Conditions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: SingleChildScrollView(
                          child: Text(
                            '''
IMPORTANT: READ CAREFULLY BEFORE USING THIS APPLICATION

1. DISCLAIMER OF LIABILITY
ClearedToGo and its operators accept no liability for any loss, damage, injury, or death arising from the use of this application. This app is provided as a reference tool only and must not be considered authoritative or a substitute for proper pilot training, official aircraft manuals, or regulatory compliance.

2. NO GUARANTEE OF ACCURACY
While we strive to provide accurate and up-to-date information, we make no warranties or representations about the accuracy, reliability, completeness, or timeliness of the content. Flight operations are inherently risky and depend on numerous factors beyond the scope of this application.

3. PILOT RESPONSIBILITY
Users acknowledge that they are solely responsible for:
- Verifying all information against official sources
- Complying with all applicable aviation regulations
- Using current Pilot Operating Handbooks (POH)
- Maintaining proper certification and currency
- Making final decisions regarding flight safety

4. USE AT YOUR OWN RISK
By using this application, you acknowledge and accept all risks associated with its use. You agree to hold harmless ClearedToGo, its developers, operators, and affiliates from any claims, damages, losses, or expenses arising from your use of this application.

5. NOT A SUBSTITUTE FOR TRAINING
This application is not a substitute for proper flight training, recurrent training, or professional instruction. Users must maintain appropriate certifications and follow all regulatory requirements.

6. WEATHER AND REAL-TIME DATA
Weather information and real-time data provided through this app may be delayed, incomplete, or inaccurate. Always verify critical information through official channels and use multiple sources when making flight decisions.

7. TECHNICAL LIMITATIONS
Users acknowledge that software may contain bugs, errors, or technical limitations. We are not liable for any consequences arising from technical issues, including but not limited to data loss, incorrect calculations, or system failures.

By clicking "I agree to the Liability Terms & Conditions" below, you acknowledge that you have read, understood, and agree to be bound by these terms.
                            ''',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.subtleText,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Terms checkbox
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                    });
                  },
                  title: const Text(
                    'I agree to the Liability Terms & Conditions',
                    style: TextStyle(fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF87CEEB),
                ),
                const SizedBox(height: 24),

                // Sign up button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading || !_acceptedTerms) ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF87CEEB),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Color(0xFF0C2942)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFF2575FC),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }
}
