import 'package:flutter/material.dart';
import 'package:safehajj2/screen/admin_home_screen.dart';
import 'package:safehajj2/screen/home_screen.dart';
import 'package:safehajj2/screen/sign_up_screen.dart';
import 'package:safehajj2/screen/super_admin_dashboard.dart';
import 'package:safehajj2/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await SupabaseService.signInWithPassword(email: email, password: password);
      if (res.session == null) {
        // Likely email confirmation required
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify your email before logging in.')),
        );
        return;
      }

      // Fetch profile to determine role
      final profile = await SupabaseService.getMyProfile();
      final role = (profile?['role'] ?? 'user').toString();

      // Navigate based on role
      if (!mounted) return;
      if (role == 'super_admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
          (route) => false,
        );
      } else if (role == 'admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF1A4363), // Deepest Blue
              Color(0xFF3572A6), // Medium-Dark Blue
              Color(0xFF67A9D5), // Mid-Tone Blue
              Color(0xFFA2D0E6), // Light Blue
              Color(0xFFEBF2F6), // Very Pale Blue/White
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and Title
                  Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to mosque icon if logo not found
                      return const Icon(
                        Icons.mosque,
                        size: 100,
                        color: Colors.white,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SafeHajj',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Trusted Companion for Umrah & Hajj',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4663AC),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue your journey',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Email Field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'example@mail.com',
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFC8D9ED)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFC8D9ED), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFC8D9ED)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFC8D9ED), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFFC8D9ED),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Single Login button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _login,
                            icon: _loading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.login_rounded),
                            label: Text(_loading ? 'Signing in…' : 'Log in'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                );
                              },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
