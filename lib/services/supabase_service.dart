import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

/// Centralized access to Supabase client and common helpers.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  /// Returns the currently signed-in user (if any).
  static User? get currentUser => auth.currentUser;

  /// Sign in with email and password.
  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithPassword(email: email, password: password);
  }

  /// Sign up with email and password.
  static Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    return await auth.signUp(email: email, password: password);
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    await auth.signOut();
  }

  /// Example: fetch a table (replace 'profiles' with your table name).
  static Future<List<Map<String, dynamic>>> fetchTable(String table) async {
    final data = await client.from(table).select();
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Upsert profile data into `profiles` table.
  /// Expects a `profiles` table with primary key `id` referencing `auth.users(id)`.
  static Future<void> upsertProfile({
    required String id,
    required String role, // 'admin' or 'user'
    String? fullName,
    int? age,
    String? healthCondition,
  }) async {
    await client.from('profiles').upsert({
      'id': id,
      'full_name': fullName,
      'role': role,
      if (age != null) 'age': age,
      if (healthCondition != null) 'health_condition': healthCondition,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetch a single profile row for current user
  static Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = auth.currentUser?.id;
    if (uid == null) return null;
    final rows = await client.from('profiles').select().eq('id', uid).limit(1);
    if (rows.isNotEmpty) return rows.first;
    return null;
  }

  /// Update current user's profile fields
  static Future<void> updateMyProfile({String? fullName, String? avatarUrl, int? age, String? healthCondition}) async {
    final uid = auth.currentUser?.id;
    if (uid == null) return;
    final patch = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (age != null) 'age': age,
      if (healthCondition != null) 'health_condition': healthCondition,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await client.from('profiles').update(patch).eq('id', uid);
  }

  /// Update auth user's password
  static Future<void> updatePassword(String newPassword) async {
    await auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Upload avatar to Supabase Storage bucket 'avatars' and return public URL
  static Future<String?> uploadAvatarBytes(Uint8List bytes, {String contentType = 'image/jpeg'}) async {
    final uid = auth.currentUser?.id;
    if (uid == null) return null;
  // Store as '<uid>.jpg' within the 'avatars' bucket
  final path = '$uid.jpg';
    await client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    final url = client.storage.from('avatars').getPublicUrl(path);
    return url;
  }
}
