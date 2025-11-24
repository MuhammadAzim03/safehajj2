import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:safehajj2/services/supabase_service.dart';
import 'package:safehajj2/screen/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _healthController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _email;
  String? _role;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = SupabaseService.currentUser;
    final prof = await SupabaseService.getMyProfile();
    setState(() {
      _email = user?.email;
      _role = (prof?['role'] ?? 'user').toString();
      _nameController.text = (prof?['full_name'] ?? '').toString();
      _ageController.text = (prof?['age'] != null) ? prof!['age'].toString() : '';
      _healthController.text = (prof?['health_condition'] ?? '').toString();
      _avatarUrl = (prof?['avatar_url'] ?? '').toString().isEmpty ? null : (prof?['avatar_url'] as String);
      _loading = false;
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
      if (file == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressQuality: 90,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Theme.of(context).colorScheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
        ],
      );

      if (croppedFile == null) return;

      final bytes = await croppedFile.readAsBytes();
      final url = await SupabaseService.uploadAvatarBytes(bytes,
          contentType: 'image/${file.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg'}');
      if (url != null) {
        await SupabaseService.updateMyProfile(avatarUrl: url);
        setState(() => _avatarUrl = url);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Avatar upload failed: $e')));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final ageText = _ageController.text.trim();
      final int? age = ageText.isEmpty ? null : int.tryParse(ageText);
      await SupabaseService.updateMyProfile(
        fullName: _nameController.text.trim(),
        age: age,
        healthCondition: _healthController.text.trim().isEmpty ? null : _healthController.text.trim(),
      );
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmController.text) {
          throw Exception('Passwords do not match');
        }
        if (_passwordController.text.length < 6) {
          throw Exception('Password must be at least 6 characters');
        }
        await SupabaseService.updatePassword(_passwordController.text);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
      _passwordController.clear();
      _confirmController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    await SupabaseService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _healthController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickAndUploadAvatar,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Email (read-only)
            TextFormField(
              initialValue: _email ?? '',
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Role (read-only)
            TextFormField(
              initialValue: (_role ?? 'user').toUpperCase(),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Full name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 12),
            // Age
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_outlined),
                hintText: 'e.g. 35',
              ),
            ),

            const SizedBox(height: 12),
            // Health condition
            TextFormField(
              controller: _healthController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Health condition',
                prefixIcon: Icon(Icons.health_and_safety_outlined),
                hintText: 'e.g. Hypertension, diabetes, None',
              ),
            ),

            const SizedBox(height: 24),
            Text('Change password', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _saveProfile,
              icon: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving…' : 'Save changes'),
            ),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
