import 'package:supabase_flutter/supabase_flutter.dart';

class RoleService {
  final SupabaseClient client;
  RoleService(this.client);

  Future<String?> getCurrentUserRole() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final res = await client.from('roles').select('role').eq('user_id', user.id).limit(1);
    if (res is List && res.isNotEmpty) {
      return res.first['role'] as String?;
    }
    return null;
  }

  Future<bool> isSuperAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'superadmin';
  }

  Future<void> promoteCurrentUserToSuperAdminWithCode(String code) async {
    await client.rpc('superadmin_promote_with_code', params: {'p_code': code});
  }
}
