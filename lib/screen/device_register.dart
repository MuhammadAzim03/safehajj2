import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceRegisterScreen extends StatefulWidget {
  final VoidCallback? onRegistered;
  const DeviceRegisterScreen({super.key, this.onRegistered});

  @override
  State<DeviceRegisterScreen> createState() => _DeviceRegisterScreenState();
}

class _DeviceRegisterScreenState extends State<DeviceRegisterScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      await Future.wait([_loadDevices(), _loadGroups()]);
    } catch (e, st) {
      debugPrint('loadAll error: $e\n$st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDevices() async {
    try {
      final res = await _client.from('my_devices').select();
      if (mounted) {
        _devices = List<Map<String, dynamic>>.from(res as List<dynamic>);
      }
    } catch (e) {
      debugPrint('loadDevices error: $e');
      if (mounted) _devices = [];
    }
  }

  Future<void> _loadGroups() async {
    try {
      // Load all Groups A-G (now showing all, not just where user is member)
      final res = await _client.from('groups').select();
      var allGroups = List<Map<String, dynamic>>.from(res as List<dynamic>);
      final allowed = {'Group A','Group B','Group C','Group D','Group E','Group F','Group G'};
      allGroups = allGroups.where((g)=> allowed.contains(g['name'])).toList();

      if (mounted) {
        _groups = allGroups;
        _groups.sort((a,b)=> (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      }
    } catch (e) {
      debugPrint('loadGroups error: $e');
      if (mounted) _groups = [];
    }
  }

  String _generateToken([int length = 32]) {
    final rnd = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) bytes[i] = rnd.nextInt(256);
    return base64Url.encode(bytes);
  }

  Future<void> _showRegisterDialog() async {
    // Ensure latest groups before opening dialog
    await _loadGroups();
    final nameCtrl = TextEditingController();
    String? selectedGroupId = _groups.isNotEmpty ? _groups.first['id'] as String : null;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Register Device'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Device name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                if (_groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'No groups available. Join or claim a group first in Admin Dashboard.',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: selectedGroupId,
                    items: _groups.map((g) => DropdownMenuItem(value: g['id'] as String, child: Text(g['name'] ?? 'Group'))).toList(),
                    onChanged: (v) {
                      setDialogState(() => selectedGroupId = v);
                    },
                    decoration: const InputDecoration(labelText: 'Group'),
                    validator: (v) => v == null ? 'Select a group' : null,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
            onPressed: () async {
              if (_groups.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a group first.')));
                return;
              }
              if (!formKey.currentState!.validate()) return;
              if (selectedGroupId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a group')));
                return;
              }
              setState(() => _loading = true);
              final token = _generateToken(48);
              final name = nameCtrl.text.trim();
              final userId = _client.auth.currentUser?.id;
              try {
                // Insert device
                await _client.from('devices').insert([
                  {
                    'name': name,
                    'device_key': token,
                    'group_id': selectedGroupId,
                    'registered_by': userId,
                  }
                ]);

                // Add user to group_members if not already a member
                if (userId != null && selectedGroupId != null) {
                  final groupId = selectedGroupId!;
                  final existing = await _client
                      .from('group_members')
                      .select()
                      .eq('group_id', groupId)
                      .eq('user_id', userId);
                  if ((existing as List).isEmpty) {
                    await _client.from('group_members').insert({
                      'group_id': groupId,
                      'user_id': userId,
                      'role': 'member'
                    });
                  }
                }

                // Close the registration dialog first
                Navigator.of(context).pop();
                
                // Show success popup
                await showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 28),
                        SizedBox(width: 8),
                        Text('Device Registered!'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your device "$name" has been successfully registered.', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 16),
                        Text('Device Token:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SelectableText(token, style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                        ),
                        SizedBox(height: 12),
                        Text('Copy this token and install it on your device. Keep it secure!', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                      ],
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Done'))],
                  ),
                );

                // after user sees token, notify parent or close the register screen
                if (widget.onRegistered != null) {
                  widget.onRegistered!();
                } else {
                  if (mounted) Navigator.of(context).pop(true);
                }
              } catch (e, st) {
                debugPrint('registerDevice error: $e\n$st');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
            child: const Text('Register'),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTile(Map<String, dynamic> d) {
    return ListTile(
      title: Text(d['name'] ?? 'Device'),
      subtitle: Text('id: ${d['id']}\ngroup: ${d['group_id'] ?? ''}'),
      isThreeLine: true,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Remove device?'),
              content: const Text('This will remove the device registration.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove')),
              ],
            ),
          );
          if (ok != true) return;
          await _client.from('devices').delete().eq('id', d['id']);
          await _loadDevices();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: _devices.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text('No devices registered yet. Tap + to add one.'),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _devices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _buildDeviceTile(_devices[i]),
                    ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Builder(builder: (context) {
        final paddingBottom = MediaQuery.of(context).padding.bottom;
        const extra = 140.0; // raise above footer
        return Padding(
          padding: EdgeInsets.only(bottom: paddingBottom + extra),
          child: FloatingActionButton(
            heroTag: 'fab_register_device',
            onPressed: _showRegisterDialog,
            child: const Icon(Icons.add),
          ),
        );
      }),
    );
  }
}
