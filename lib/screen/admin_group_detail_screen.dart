import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safehajj2/screen/admin_member_detail_screen.dart';

class AdminGroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const AdminGroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<AdminGroupDetailScreen> createState() => _AdminGroupDetailScreenState();
}

class _AdminGroupDetailScreenState extends State<AdminGroupDetailScreen> {
  final _client = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _members = [];
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      // Load members for this group (exclude admin role)
      final memRes = await _client
          .from('group_members')
          .select()
          .eq('group_id', widget.groupId)
          .neq('role', 'admin');
      _members = List<Map<String, dynamic>>.from(memRes as List<dynamic>);

      // Collect user IDs
      final Set<String> userIds = {};
      for (final m in _members) {
        final uid = m['user_id'] as String?;
        if (uid != null) userIds.add(uid);
      }

      // Fetch full profiles with all details
      if (userIds.isNotEmpty) {
        try {
          final profileRes = await _client
              .from('profiles')
              .select('id, full_name, age, health_condition')
              .inFilter('id', userIds.toList());
          final profiles = List<Map<String, dynamic>>.from(profileRes as List<dynamic>);
          
          // Attach profile data to members
          for (final m in _members) {
            final uid = m['user_id'] as String?;
            final profile = profiles.firstWhere(
              (p) => p['id'] == uid,
              orElse: () => <String, dynamic>{},
            );
            m['profile'] = profile;
            
            final name = profile['full_name'] as String?;
            if (uid != null && name != null && name.isNotEmpty) {
              _userNames[uid] = name;
            }
          }
        } catch (e) {
          debugPrint('load profiles error: $e');
        }
      }
    } catch (e) {
      debugPrint('load members error: $e');
      _members = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: const Color(0xFF4663AC),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMembers,
              child: _members.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(32),
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.people_outline, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 20),
                        const Text(
                          'No members in this group yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final userId = member['user_id'] as String? ?? '';
                        final role = member['role'] as String? ?? 'member';
                        final username = _userNames[userId] ?? 'Unknown User';
                        final profile = member['profile'] as Map<String, dynamic>? ?? {};
                        final age = profile['age']?.toString() ?? 'Not set';
                        final health = (profile['health_condition'] as String?)?.isNotEmpty == true 
                            ? profile['health_condition'] as String 
                            : 'Not set';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminMemberDetailScreen(
                                    userId: userId,
                                    userName: username,
                                    groupId: widget.groupId,
                                    groupName: widget.groupName,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF1A4363).withOpacity(0.9),
                                    const Color(0xFF3572A6).withOpacity(0.9),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            username,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: role == 'admin' ? Colors.green : Colors.blue,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            role.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDetailRow(Icons.person_outline, 'Name', username),
                                    const SizedBox(height: 12),
                                    _buildDetailRow(Icons.cake_outlined, 'Age', age),
                                    const SizedBox(height: 12),
                                    _buildDetailRow(Icons.health_and_safety_outlined, 'Health', health),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: const [
                                        Icon(Icons.chevron_right, color: Colors.white70),
                                        SizedBox(width: 4),
                                        Text(
                                          'View IoT Data',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
