import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/super_admin_providers.dart';
import '../services/supabase_service.dart';
import 'super_admin_groups_page.dart';
import 'super_admin_explore_page.dart';
import 'login_screen.dart';

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
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
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
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
        title: const Text(
          'Super Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A4363), Color(0xFF3572A6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome, Super Admin!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage groups and explore content',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  groupsAsync.when(
                    data: (groups) => Row(
                      children: [
                        _buildStatChip(Icons.group, '${groups.length}', 'Groups'),
                        const SizedBox(width: 12),
                        _buildStatChip(Icons.admin_panel_settings, 'Admin', 'Access'),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Management Cards
            const Text(
              'Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A4363),
              ),
            ),
            const SizedBox(height: 16),
            _buildManagementCard(
              context,
              icon: Icons.group_outlined,
              title: 'Groups Management',
              description: 'Create, edit, and manage user groups',
              color: const Color(0xFF1A4363),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminGroupsPage()),
              ),
            ),
            const SizedBox(height: 12),
            _buildManagementCard(
              context,
              icon: Icons.explore_outlined,
              title: 'Explore Management',
              description: 'Manage map locations and explore items',
              color: const Color(0xFF2E7D32),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminExplorePage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
