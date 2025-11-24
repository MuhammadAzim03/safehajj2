import 'package:flutter/material.dart';
import 'package:safehajj2/screen/profile_screen.dart';
import 'package:safehajj2/state/app_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _client = Supabase.instance.client;
  bool _removingDevice = false;

  Future<void> _removeDevice(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove Device?'),
        content: const Text('This will unregister your device. You can register a new device afterwards. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _removingDevice = true);
    
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not signed in')));
        return;
      }
      
      // Delete all devices registered by this user
      await _client.from('devices').delete().eq('registered_by', userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device removed successfully. You can now register a new device.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove device: $e')));
    } finally {
      if (mounted) setState(() => _removingDevice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final localeCode = settings.locale.languageCode;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF1A4363),
                Color(0xFF3572A6),
                Color(0xFF67A9D5),
                Color(0xFFA2D0E6),
                Color(0xFFEBF2F6),
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Settings Section
          _sectionHeader(context, Icons.person_outline, 'Profile Settings'),
          const SizedBox(height: 8),
          _card(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Edit Profile'),
                subtitle: const Text('Name, avatar, and password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // App Settings Section
          _sectionHeader(context, Icons.tune, 'App Settings'),
          const SizedBox(height: 8),
          _card(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(localeCode == 'ms' ? 'Bahasa Melayu' : 'English'),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: localeCode,
                    items: const [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'ms',
                        child: Text('Bahasa Melayu'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) settings.setLanguage(value);
                    },
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          // Device Management Section
          _sectionHeader(context, Icons.devices, 'Device Management'),
          const SizedBox(height: 8),
          _card(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove My Device', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Unregister device to register a new one'),
                trailing: _removingDevice 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right, color: Colors.red),
                onTap: _removingDevice ? null : () => _removeDevice(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4663AC)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
