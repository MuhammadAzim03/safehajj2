import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/super_admin_providers.dart';

class GroupMembersPage extends ConsumerWidget {
  final String groupId;
  final String groupName;

  const GroupMembersPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Members of "$groupName"',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF1A4363),
                Color(0xFF3572A6),
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(
              child: Text(
                'This group has no members.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: members.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final member = members[index];
              final roleText = member.role.split('_').join(' ').toUpperCase();
              final roleColor = member.role == 'admin' ? Colors.blue.shade700 : Colors.grey.shade600;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: roleColor.withOpacity(0.1),
                  child: Icon(
                    member.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                    color: roleColor,
                  ),
                ),
                title: Text(
                  member.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(member.email),
                trailing: Chip(
                  label: Text(
                    roleText,
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: roleColor.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Error fetching members:',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
