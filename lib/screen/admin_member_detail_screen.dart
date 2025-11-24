import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class AdminMemberDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String groupId;
  final String groupName;

  const AdminMemberDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<AdminMemberDetailScreen> createState() => _AdminMemberDetailScreenState();
}

class _AdminMemberDetailScreenState extends State<AdminMemberDetailScreen> {
  final _client = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _latestData;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Load devices registered by this user in this group
      final devRes = await _client
          .from('devices')
          .select()
          .eq('registered_by', widget.userId)
          .eq('group_id', widget.groupId);
      _devices = List<Map<String, dynamic>>.from(devRes as List<dynamic>);

      // Load latest device data if devices exist
      if (_devices.isNotEmpty) {
        final deviceId = _devices.first['id'] as String?;
        if (deviceId != null) {
          final dataRes = await _client
              .from('device_data')
              .select()
              .eq('device_id', deviceId)
              .order('created_at', ascending: false)
              .limit(1);
          final dataList = dataRes as List<dynamic>;
          if (dataList.isNotEmpty) {
            _latestData = dataList.first as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      debugPrint('load member data error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract IoT data from payload
    final payload = _latestData?['payload'] as Map<String, dynamic>?;
    final heartRate = payload?['heart_rate']?.toString() ?? '--';
    final temperature = payload?['temperature']?.toString() ?? '--';
    final latitude = payload?['latitude']?.toString() ?? '--';
    final longitude = payload?['longitude']?.toString() ?? '--';
    final battery = payload?['battery']?.toString() ?? '--';
    final timestamp = _latestData?['created_at'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: const Color(0xFF4663AC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading && _devices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // User Info Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: const Color(0xFF4663AC),
                                child: Text(
                                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                                  style: const TextStyle(fontSize: 24, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.userName,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.groupName,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Devices Section
                  const Text(
                    'Registered Devices',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_devices.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No devices registered',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ..._devices.map((device) {
                      final deviceName = device['name'] as String? ?? 'Unnamed Device';
                      final isActive = device['is_active'] as bool? ?? false;
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.watch,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                          title: Text(deviceName),
                          subtitle: Text(isActive ? 'Active' : 'Inactive'),
                          trailing: Icon(
                            Icons.circle,
                            size: 12,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 24),

                  // IoT Data Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Latest IoT Data',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (timestamp != null)
                        Text(
                          _formatTimestamp(timestamp),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_latestData == null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.sensors_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No data received yet',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Waiting for IoT device to send data...',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Vital Signs Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'Heart Rate',
                                '$heartRate bpm',
                                Icons.favorite,
                                Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInfoCard(
                                'Temperature',
                                '$temperature°C',
                                Icons.thermostat,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Location Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'Latitude',
                                latitude,
                                Icons.location_on,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInfoCard(
                                'Longitude',
                                longitude,
                                Icons.location_on,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Battery
                        _buildInfoCard(
                          'Battery',
                          '$battery%',
                          Icons.battery_charging_full,
                          Colors.green,
                        ),

                        const SizedBox(height: 16),

                        // Raw Payload (for debugging)
                        ExpansionTile(
                          title: const Text('Raw Payload'),
                          leading: const Icon(Icons.code),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.grey.shade100,
                              child: SelectableText(
                                payload?.toString() ?? 'No payload',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return timestamp;
    }
  }
}
