import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safehajj2/screen/admin_group_detail_screen.dart';
import 'login_screen.dart';
import '../services/supabase_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _client = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _groups = [];
  Map<String, List<Map<String, dynamic>>> _membersByGroup = {};
  Map<String, List<Map<String, dynamic>>> _devicesByGroup = {};
  Map<String, String> _userNames = {};
  Map<String, int> _panicAlertCounts = {}; // Count of unresolved panic alerts per group
  Map<String, Set<String>> _alertMembersByGroup = {}; // Track members per group with alerts

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Load groups A-G
      final res = await _client.from('groups').select();
      var list = List<Map<String, dynamic>>.from(res as List<dynamic>);
      final allowed = {'Group A','Group B','Group C','Group D','Group E','Group F','Group G'};
      list = list.where((g)=> allowed.contains(g['name'])).toList();
      list.sort((a,b)=> (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      _groups = list;

      // Fetch members and devices for these groups
      _membersByGroup = {};
      _devicesByGroup = {};
      
      // Collect all user IDs to fetch profiles in one query
      final Set<String> userIds = {};
      
      // Also collect admin user IDs from groups
      for (final g in _groups) {
        final adminUserId = g['admin_user'] as String?;
        if (adminUserId != null) userIds.add(adminUserId);
      }
      
      for (final g in _groups) {
        final gid = g['id'] as String?;
        if (gid == null) continue;
        try {
          // Load members (exclude admin role - they're shown in the group header)
          final memRes = await _client.from('group_members').select().eq('group_id', gid).neq('role', 'admin');
          final memList = List<Map<String,dynamic>>.from(memRes as List<dynamic>);
          _membersByGroup[gid] = memList;
          
          // Collect user IDs
          for (final m in memList) {
            final uid = m['user_id'] as String?;
            if (uid != null) userIds.add(uid);
          }
          
          // Load devices
          final devRes = await _client.from('devices').select().eq('group_id', gid);
          final devList = List<Map<String,dynamic>>.from(devRes as List<dynamic>);
          _devicesByGroup[gid] = devList;
          
          // Collect registered_by user IDs
          for (final d in devList) {
            final regBy = d['registered_by'] as String?;
            if (regBy != null) userIds.add(regBy);
          }
        } catch (e) {
          debugPrint('load data error for $gid: $e');
          _membersByGroup[gid] = [];
          _devicesByGroup[gid] = [];
        }
      }
      
      // Fetch all profiles in one query
      _userNames = {};
      if (userIds.isNotEmpty) {
        try {
          debugPrint('Fetching profiles for user IDs: ${userIds.toList()}');
          final profileRes = await _client.from('profiles').select('id, full_name').inFilter('id', userIds.toList());
          final profiles = List<Map<String,dynamic>>.from(profileRes as List<dynamic>);
          debugPrint('Profiles fetched: ${profiles.length} profiles');
          for (final p in profiles) {
            final id = p['id'] as String?;
            final name = p['full_name'] as String?;
            debugPrint('Profile: id=$id, name=$name');
            if (id != null && name != null && name.isNotEmpty) {
              _userNames[id] = name;
            }
          }
          debugPrint('Final userNames map: $_userNames');
        } catch (e) {
          debugPrint('load profiles error: $e');
        }
      }
      
      // Attach usernames to members and devices
      for (final gid in _membersByGroup.keys) {
        for (final m in _membersByGroup[gid]!) {
          final uid = m['user_id'] as String?;
          m['username'] = _userNames[uid] ?? 'Unknown User';
        }
      }
      for (final gid in _devicesByGroup.keys) {
        for (final d in _devicesByGroup[gid]!) {
          final regBy = d['registered_by'] as String?;
          d['username'] = _userNames[regBy] ?? 'Unknown User';
        }
      }

      // Load panic alert counts for each group
      _panicAlertCounts = {};
      _alertMembersByGroup = {};
      try {
        for (final g in _groups) {
          final gid = g['id'] as String?;
          if (gid == null) continue;
          
          final alertRes = await _client
              .from('panic_alerts')
              .select('id, user_id')
              .eq('group_id', gid)
              .filter('resolved_at', 'is', null); // Only count unresolved alerts
          
          final alerts = List<Map<String, dynamic>>.from(alertRes as List<dynamic>);
          final count = alerts.length;
          _panicAlertCounts[gid] = count;
            _alertMembersByGroup[gid] = alerts
              .map((a) => a['user_id'] as String?)
              .whereType<String>()
              .toSet();
        }
      } catch (e) {
        debugPrint('load panic alerts error: $e');
      }
    } catch (e) {
      debugPrint('admin dashboard load error: $e');
      _groups = [];
      _membersByGroup = {};
      _devicesByGroup = {};
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _claim(String groupId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      
      // Check if user already administers a group
      final adminCheck = await _client.from('groups').select().eq('admin_user', userId);
      if ((adminCheck as List).isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only assign one group. Unassign your current group first.')));
        return;
      }
      
      await _client.from('groups').update({'admin_user': userId}).eq('id', groupId);
      final existing = await _client.from('group_members').select().eq('group_id', groupId).eq('user_id', userId);
      if ((existing as List).isEmpty) {
        await _client.from('group_members').insert({'group_id': groupId, 'user_id': userId, 'role': 'admin'});
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group assigned successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assign failed: $e')));
    } finally {
      await _load();
    }
  }

  Future<void> _unclaim(String groupId) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Unassign Group?'),
        content: const Text('Choose an option:'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, 'unclaim_only'),
            child: const Text('Unassign (stay as member)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, 'unclaim_and_leave'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unassign & Leave'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      
      // Update to set admin_user to null only if current user is the admin
      final result = await _client
          .from('groups')
          .update({'admin_user': null})
          .eq('id', groupId)
          .eq('admin_user', userId)
          .select();
      
      if ((result as List).isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are not the admin of this group')));
        return;
      }
      
      // If user chose to leave, also remove membership
      if (choice == 'unclaim_and_leave') {
        await _client.from('group_members').delete().eq('group_id', groupId).eq('user_id', userId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unassigned and left group')));
      } else {
        // Update role to member if staying
        await _client.from('group_members').update({'role': 'member'}).eq('group_id', groupId).eq('user_id', userId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unassigned, you remain as a member')));
      }
    } catch (e) {
      debugPrint('Unassign error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unassign failed: $e')));
    } finally {
      await _load();
    }
  }

  Future<void> _leaveGroup(String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Leave Group?'),
        content: const Text('You will be removed from this group.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client.from('group_members').delete().eq('group_id', groupId).eq('user_id', userId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left group successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave failed: $e')));
    } finally {
      await _load();
    }
  }

  Future<void> _joinGroup(String groupId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client.from('group_members').insert({'group_id': groupId, 'user_id': userId, 'role': 'member'});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined group successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Join failed: $e')));
    } finally {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _groups.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(32),
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.groups, size: 72, color: Colors.blueGrey.shade200),
                        const SizedBox(height: 20),
                        Text(
                          _client.auth.currentUser == null
                              ? 'You are not signed in. Sign in to view and claim groups.'
                              : 'No groups visible yet. If Groups A–G are unclaimed you can claim one. Pull down to refresh.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final g = _groups[index];
                        final gid = g['id'] as String? ?? '';
                        final adminUser = g['admin_user'] as String?;
                        final isAdmin = adminUser == _client.auth.currentUser?.id;
                        final members = _membersByGroup[gid] ?? [];
                        final devices = _devicesByGroup[gid] ?? [];
                        final currentUserId = _client.auth.currentUser?.id;
                        final isMember = members.any((m) => m['user_id'] == currentUserId);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: InkWell(
                            onTap: isAdmin ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminGroupDetailScreen(
                                    groupId: gid,
                                    groupName: g['name'] ?? 'Group',
                                  ),
                                ),
                              );
                            } : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(g['name'] ?? 'Group', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                          if (adminUser != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '(${isAdmin ? "You" : _userNames[adminUser] ?? "Admin"})',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isAdmin ? Colors.green.shade700 : Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                          if ((_panicAlertCounts[gid] ?? 0) > 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade600,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '🚨 ${_panicAlertCounts[gid]}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (adminUser == null) ...[
                                      ElevatedButton(
                                        onPressed: () => _claim(gid),
                                        child: const Text('Assign'),
                                      )
                                    ] else if (isAdmin) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.verified, color: Colors.green),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _unclaim(gid),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red.shade400,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Unassign'),
                                          ),
                                        ],
                                      ),
                                    ] else if (!isMember) ...[
                                      ElevatedButton(
                                        onPressed: () => _joinGroup(gid),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                        child: const Text('Join'),
                                      )
                                    ] else ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => _leaveGroup(gid),
                                            child: const Text('Leave', style: TextStyle(color: Colors.orange)),
                                          ),
                                        ],
                                      ),
                                    ]
                                  ],
                                ),
                                const Divider(height: 18),
                                if (members.isEmpty && devices.isEmpty)
                                  const Text('No members or devices yet', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54))
                                else ...[
                                  if (members.isNotEmpty) ...[
                                    const Text('Members:', style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    ...members.map((m) {
                                      final role = m['role'] ?? 'member';
                                      final username = m['username'] as String? ?? 'Unknown User';
                                      final userId = m['user_id'] as String?;
                                      final hasAlert = userId != null && (_alertMembersByGroup[gid]?.contains(userId) ?? false);
                                      final memberColor = hasAlert ? Colors.red.shade700 : Colors.black87;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.person, size: 16, color: hasAlert ? Colors.red.shade700 : Colors.blueGrey),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$username  •  $role',
                                              style: TextStyle(
                                                color: memberColor,
                                                fontWeight: hasAlert ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    const SizedBox(height: 12),
                                  ],
                                  if (devices.isNotEmpty) ...[
                                    const Text('Devices:', style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    ...devices.map((d) {
                                      final name = d['name'] as String? ?? 'Unnamed Device';
                                      final registeredBy = d['username'] as String? ?? 'Unknown User';
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.watch, size: 16, color: Colors.green),
                                            const SizedBox(width: 6),
                                            Text('$name  •  by $registeredBy'),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ]
                              ],
                            ),
                          ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
