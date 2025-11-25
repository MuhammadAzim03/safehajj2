import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

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
  bool isDeviceConnected = false;
  DateTime? _lastDataTime;

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
            final timestamp = _latestData?['created_at'] as String?;
            if (timestamp != null) {
              _lastDataTime = DateTime.parse(timestamp);
              final difference = DateTime.now().difference(_lastDataTime!);
              isDeviceConnected = difference.inSeconds < 30;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('load member data error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildClickableGpsCard(String latitude, String longitude, bool isConnected) {
    final lat = double.tryParse(latitude);
    final lng = double.tryParse(longitude);
    final hasValidCoords = lat != null && lng != null && lat != 0.0 && lng != 0.0;
    final displayValue = hasValidCoords ? '$latitude, $longitude' : 'Acquiring GPS...';
    
    return InkWell(
      onTap: hasValidCoords && isConnected
          ? () => _openInGoogleMaps(lat, lng)
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConnected ? Colors.grey.shade200 : Colors.red.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.location_on, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "GPS Location",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (hasValidCoords && isConnected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new, size: 12, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                "Tap to view",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected ? displayValue : "--",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isConnected ? "Live Tracking Active" : "Device Offline",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (hasValidCoords && isConnected)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(
    IconData icon,
    String title,
    String value,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDeviceConnected ? Colors.grey.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isDeviceConnected ? value : "--",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDeviceConnected ? Colors.black87 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIotCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDeviceConnected ? Colors.grey.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDeviceConnected ? value : "--",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDeviceConnected ? Colors.black87 : Colors.grey.shade400,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
        title: Text(widget.userName, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.sensors, color: Color(0xFF4663AC), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  "Real-Time Monitoring",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDeviceConnected ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: isDeviceConnected ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isDeviceConnected ? "Connected" : "Offline",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDeviceConnected ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_lastDataTime != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Last update: ${_formatTimestamp(_lastDataTime!)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_latestData == null)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.sensors_off, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No data received yet',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Waiting for IoT device to send data...',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactCard(
                                Icons.favorite,
                                "Heart Rate",
                                '$heartRate bpm',
                                Colors.red.shade50,
                                Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCompactCard(
                                Icons.battery_charging_full,
                                "Battery",
                                '$battery%',
                                Colors.green.shade50,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildClickableGpsCard(
                          latitude,
                          longitude,
                          isDeviceConnected,
                        ),
                        if (temperature != '--') ...[
                          const SizedBox(height: 12),
                          _buildIotCard(
                            Icons.thermostat,
                            "Temperature",
                            '$temperature°C',
                            "Body Temperature",
                            Colors.orange.shade50,
                            Colors.orange,
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _openInGoogleMaps(double latitude, double longitude) async {
    try {
      // Try to open in Google Maps app first (Android/iOS)
      final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch geo URI: $e');
      try {
        // Fallback to web browser
        final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e2) {
        debugPrint('Could not launch web URL: $e2');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening maps: $e2'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
