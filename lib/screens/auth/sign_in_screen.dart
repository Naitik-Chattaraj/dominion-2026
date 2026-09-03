import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/local_auth_service.dart';
import '../../widgets/liquid_glass_container.dart';
import '../../widgets/liquid_glass_text_field.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onSignInSuccess;
  const SignInScreen({super.key, required this.onSignInSuccess});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _localAuthService = LocalAuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isCreateAccountMode = true;
  bool _staySignedIn = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    HapticFeedback.mediumImpact();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_isCreateAccountMode) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')),
        );
        return;
      }
      await _localAuthService.createAccount(
        name: name,
        email: email,
        password: password,
        staySignedIn: _staySignedIn,
      );
      HapticFeedback.lightImpact();
      widget.onSignInSuccess();
    } else {
      final success = await _localAuthService.signIn(
        email: email,
        password: password,
        staySignedIn: _staySignedIn,
      );
      if (success) {
        HapticFeedback.lightImpact();
        widget.onSignInSuccess();
      } else {
        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07040A),
      body: Stack(
        children: [
          // Atmospheric Top Linear Gradient with anti-banding 9-step stops
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 520,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6E1C44),
                    Color(0xFF5E173A),
                    Color(0xFF4C122F),
                    Color(0xFF3B0D24),
                    Color(0xFF2A091A),
                    Color(0xFF1D0612),
                    Color(0xFF12040B),
                    Color(0xFF0A0307),
                    Color(0xFF07040A),
                  ],
                  stops: [
                    0.0,
                    0.10,
                    0.22,
                    0.36,
                    0.50,
                    0.64,
                    0.78,
                    0.90,
                    1.0,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                    // RiskGrid Shield Logo (Heroic, larger as requested)
                    Center(
                      child: Image.asset(
                        'assets/riskgrid.png',
                        height: 110,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.shield, size: 90, color: Color(0xFFD9779F));
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title: Capitalized "Risk Grid" in Winter Solace font (larger & centered)
                    const Center(
                      child: Text(
                        'Risk Grid',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'WinterSolace',
                          fontSize: 52,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD9779F),
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Color(0x66D9779F),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Subtitle
                    Text(
                      _isCreateAccountMode ? 'Create an account' : 'Sign in to RiskGrid',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isCreateAccountMode
                          ? 'Get onboard by creating your account.'
                          : 'Welcome back! Enter your credentials.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF908A99),
                        fontSize: 14.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Input Form Fields (Generously sized for mobile)
                    if (_isCreateAccountMode) ...[
                      LiquidGlassTextField(
                        controller: _nameController,
                        hintText: 'Name',
                      ),
                      const SizedBox(height: 16),
                    ],
                    LiquidGlassTextField(
                      controller: _emailController,
                      hintText: 'email@domain.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    LiquidGlassTextField(
                      controller: _passwordController,
                      hintText: 'password',
                      obscureText: _obscurePassword,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF7A7482),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Stay signed in option
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _staySignedIn,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _staySignedIn = val ?? true;
                              });
                            },
                            activeColor: const Color(0xFF8A1E4A),
                            checkColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF5E5466), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Stay signed in',
                          style: TextStyle(
                            color: Color(0xFFA69EB0),
                            fontSize: 14.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Continue Button (Wine/Plum Liquid Glass Pill - larger & touch friendly)
                    LiquidGlassContainer(
                      onTap: _submit,
                      borderRadius: 14,
                      tintColor: const Color(0xFF381223),
                      tintOpacity: 0.85,
                      blurSigma: 16.0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Divider: "or"
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Color(0xFF282030), thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Color(0xFF6E6678),
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFF282030), thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Mode Switcher
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isCreateAccountMode = !_isCreateAccountMode;
                          });
                        },
                        child: Text(
                          _isCreateAccountMode
                              ? 'Already have an account? Sign In'
                              : 'Don\'t have an account? Create one',
                          style: const TextStyle(
                            color: Color(0xFFC487A8),
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Footer Terms & Privacy Policy
                    const Text.rich(
                      TextSpan(
                        text: 'By clicking continue, you agree to our ',
                        style: TextStyle(
                          color: Color(0xFF6B6475),
                          fontSize: 12.5,
                          height: 1.4,
                          fontFamily: 'Inter',
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: Color(0xFF38BDF8), // Light Cyan / Blue
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(text: '\nand '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
