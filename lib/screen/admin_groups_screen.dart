import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminGroupsScreen extends StatefulWidget {
  const AdminGroupsScreen({super.key});
  @override
  State<AdminGroupsScreen> createState() => _AdminGroupsScreenState();
}

class _AdminGroupsScreenState extends State<AdminGroupsScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final res = await _client.from('groups').select();
      var list = List<Map<String, dynamic>>.from(res as List<dynamic>);
      final allowed = {'Group A','Group B','Group C','Group D','Group E','Group F','Group G'};
      list = list.where((g)=> allowed.contains(g['name'])).toList();
      list.sort((a,b)=> (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      _groups = list;
    } catch (e) {
      debugPrint('admin loadGroups error: $e');
      _groups = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _claimGroup(String id) async {
    try {
      // Set admin_user if null and add membership
      // Claim only if currently unassigned: we optimistically update and rely on RLS policy to enforce
      await _client.from('groups').update({'admin_user': _client.auth.currentUser?.id}).eq('id', id);
      await _client.from('group_members').insert({'group_id': id, 'user_id': _client.auth.currentUser?.id, 'role': 'admin'});
    } catch (e) {
      debugPrint('claimGroup error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Claim failed: $e')));
    } finally {
      await _loadGroups();
    }
  }

  // Delete removed in new flow (fixed set of groups A-G)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Groups')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGroups,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Groups A–G', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._groups.map((g) {
                    final isAdmin = g['admin_user'] == _client.auth.currentUser?.id;
                    final unassigned = g['admin_user'] == null;
                    return Card(
                      child: ListTile(
                        title: Text(g['name'] ?? 'Group'),
                        subtitle: Text('id: ${g['id']}\nAdmin: ${g['admin_user'] ?? 'None'}'),
                        trailing: unassigned
                            ? ElevatedButton(
                                onPressed: () => _claimGroup(g['id'] as String),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                child: const Text('Claim'),
                              )
                            : isAdmin
                                ? const Icon(Icons.verified, color: Colors.green)
                                : const Icon(Icons.lock, color: Colors.grey),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
