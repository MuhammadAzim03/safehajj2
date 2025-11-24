import 'package:flutter/material.dart';
import 'package:safehajj2/screen/admin_home_screen.dart';
import 'package:safehajj2/screen/home_screen.dart';
import 'package:safehajj2/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _role = 'user'; // 'admin' or 'user'
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();

      final res = await SupabaseService.signUpWithPassword(email: email, password: password);

      final user = res.user;
      final session = res.session; // may be null if email confirmation required

      if (user != null && session != null) {
        // Authenticated immediately: upsert profile now
        await SupabaseService.upsertProfile(
          id: user.id,
          role: _role,
          fullName: name.isEmpty ? null : name,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        // Navigate based on role
        if (_role == 'admin') {
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
      } else if (user != null && session == null) {
        // Likely email confirmation required: can't upsert without session.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your email to confirm your account. After verifying, log in to complete setup.'),
          ),
        );
        Navigator.of(context).pop(); // Return to login
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up failed. Please try again.')),
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
        SnackBar(content: Text('Unexpected error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text('Join SafeHajj', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 4),
                Text('Create your account to continue', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 24),

                // Full name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name (optional)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm Password
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Role selector
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _role,
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('Pilgrim / User')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (v) => setState(() => _role = v ?? 'user'),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loading ? null : _signUp,
                  icon: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(_loading ? 'Creating account…' : 'Create account'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
