import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_member.dart';

class SuperAdminService {
  final SupabaseClient client;
  SuperAdminService(this.client);

  Future<List<Map<String, dynamic>>> listGroups() async {
    final res = await client.from('groups').select().order('created_at');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<String> createGroup(String name) async {
    final res = await client.rpc('super_group_create', params: {'p_name': name});
    return res as String;
  }

  Future<void> updateGroup(String groupId, String name) async {
    await client.rpc('super_group_update', params: {'p_group_id': groupId, 'p_name': name});
  }

  Future<void> deleteGroup(String groupId) async {
    await client.rpc('super_group_delete', params: {'p_group_id': groupId});
  }

  Future<void> assignAdmin(String groupId, String userId, String role) async {
    await client.rpc('super_assign_admin', params: {
      'p_group_id': groupId,
      'p_user_id': userId,
      'p_role': role,
    });
  }

  Future<void> removeAdmin(String groupId, String userId, String role) async {
    await client.rpc('super_remove_admin', params: {
      'p_group_id': groupId,
      'p_user_id': userId,
      'p_role': role,
    });
  }

  Future<List<Map<String, dynamic>>> listAdmins(String groupId) async {
    final res = await client.from('group_admins').select().eq('group_id', groupId).order('created_at');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final res = await client.from('profiles').select('id, full_name').ilike('full_name', '%$query%').limit(20);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> listExploreItems() async {
    final res = await client.from('explore_items').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> upsertExploreItem({
    String? id,
    required String title,
    required String description,
    double? latitude,
    double? longitude,
    String? city,
    String? type,
    String? imageUrl,
  }) async {
    // Debug: Check if user is superadmin
    try {
      final currentUserId = client.auth.currentUser?.id;
      print('DEBUG: Current user ID: $currentUserId');
      
      final roleCheck = await client
          .from('roles')
          .select('role')
          .eq('user_id', currentUserId ?? '')
          .single();
      print('DEBUG: User role in table: ${roleCheck['role']}');
      
      final isSuperAdmin = await client.rpc('is_superadmin');
      print('DEBUG: is_superadmin() returns: $isSuperAdmin');
    } catch (e) {
      print('DEBUG: Role check error: $e');
    }
    
    await client.rpc('super_explore_upsert', params: {
      'p_id': id,
      'p_title': title,
      'p_description': description,
      'p_latitude': latitude,
      'p_longitude': longitude,
      'p_city': city,
      'p_type': type,
      'p_image_url': imageUrl,
    });
  }

  Future<void> deleteExploreItem(String id) async {
    await client.rpc('super_explore_delete', params: {'p_id': id});
  }

  Future<List<Map<String, dynamic>>> listHomeInfo(String category) async {
    final res = await client.from('home_info').select().eq('category', category).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> upsertHomeInfo({String? id, required String category, required String title, required String description, String? imageUrl}) async {
    await client.rpc('super_homeinfo_upsert', params: {
      'p_id': id,
      'p_category': category,
      'p_title': title,
      'p_description': description,
      'p_image_url': imageUrl ?? '',
    });
  }

  Future<void> deleteHomeInfo(String id) async {
    await client.rpc('super_homeinfo_delete', params: {'p_id': id});
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final res = await client.rpc('get_group_members', params: {'in_group_id': groupId});
    final members = (res as List).map((json) => GroupMember.fromJson(json)).toList();
    return members;
  }
}
