import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_member.dart';
import '../services/role_service.dart';
import '../services/super_admin_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final roleServiceProvider = Provider<RoleService>((ref) => RoleService(ref.read(supabaseClientProvider)));
final superAdminServiceProvider = Provider<SuperAdminService>((ref) => SuperAdminService(ref.read(supabaseClientProvider)));

final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  final roleSvc = ref.read(roleServiceProvider);
  return roleSvc.getCurrentUserRole();
});

final isSuperAdminProvider = FutureProvider<bool>((ref) async {
  final roleSvc = ref.read(roleServiceProvider);
  return roleSvc.isSuperAdmin();
});

final groupsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final svc = ref.read(superAdminServiceProvider);
  return svc.listGroups();
});

final groupMembersProvider = FutureProvider.autoDispose.family<List<GroupMember>, String>((ref, groupId) async {
  final svc = ref.read(superAdminServiceProvider);
  return svc.getGroupMembers(groupId);
});
