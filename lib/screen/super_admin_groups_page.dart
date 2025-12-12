import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/super_admin_providers.dart';
import 'group_members_page.dart';

class SuperAdminGroupsPage extends ConsumerStatefulWidget {
  const SuperAdminGroupsPage({super.key});

  @override
  ConsumerState<SuperAdminGroupsPage> createState() => _SuperAdminGroupsPageState();
}

class _SuperAdminGroupsPageState extends ConsumerState<SuperAdminGroupsPage> {
  final _groupNameController = TextEditingController();
  String? _editingGroupId;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _groupNameController.clear();
    _editingGroupId = null;
  }

  Future<void> _saveGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    try {
      final superSvc = ref.read(superAdminServiceProvider);
      if (_editingGroupId == null) {
        await superSvc.createGroup(name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully')),
          );
        }
      } else {
        await superSvc.updateGroup(_editingGroupId!, name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group updated successfully')),
          );
        }
      }
      ref.invalidate(groupsProvider);
      _resetForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final superSvc = ref.read(superAdminServiceProvider);
        await superSvc.deleteGroup(groupId);
        ref.invalidate(groupsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
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
        title: const Text('Groups Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Form Card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingGroupId == null ? 'Create New Group' : 'Edit Group',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveGroup,
                          icon: Icon(_editingGroupId == null ? Icons.add : Icons.save),
                          label: Text(_editingGroupId == null ? 'Create Group' : 'Update Group'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A4363),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_editingGroupId != null) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _resetForm,
                          icon: const Icon(Icons.clear),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Groups List
          Expanded(
            child: groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(
                    child: Text('No groups yet. Create your first group above!'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1A4363),
                          child: Text(
                            group['name'][0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          group['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Created: ${group['created_at']?.toString().substring(0, 10) ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.people_alt_outlined, color: Colors.green),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GroupMembersPage(
                                    groupId: group['id'],
                                    groupName: group['name'],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF1A4363)),
                              onPressed: () {
                                setState(() {
                                  _editingGroupId = group['id'];
                                  _groupNameController.text = group['name'];
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteGroup(group['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
