import 'package:flutter/material.dart';
import 'package:safehajj2/screen/device_register.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _client = Supabase.instance.client;
  String heartRate = "No Device Detected";
  String gpsLocation = "No Device Detected";
  String battery = "--";
  String temperature = "--";
  bool isDeviceConnected = false;
  String? deviceId;
  Timer? _refreshTimer;
  DateTime? _lastDataTime;

  @override
  void initState() {
    super.initState();
    _myDevicesFuture = _fetchMyDevices();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadDeviceData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  late Future<List<dynamic>> _myDevicesFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _myDevicesFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final hasDevices = snap.hasData && (snap.data?.isNotEmpty == true);
        if (!hasDevices) {
          // If user has no devices, show registration screen first (inline)
          return DeviceRegisterScreen(
            onRegistered: () {
              setState(() {
                _myDevicesFuture = _fetchMyDevices();
              });
            },
          );
        }

        // Otherwise show the usual dashboard
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
            title: const Text('Device', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadDeviceData,
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDeviceConnected ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDeviceConnected ? Colors.green.shade200 : Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isDeviceConnected ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDeviceConnected ? 'Connected' : 'Disconnected',
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
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactCard(
                        Icons.favorite,
                        "Heart Rate",
                        heartRate,
                        Colors.red.shade50,
                        Colors.red,
                        isConnected: isDeviceConnected,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactCard(
                        Icons.battery_charging_full,
                        "Battery",
                        battery,
                        Colors.green.shade50,
                        Colors.green,
                        isConnected: isDeviceConnected,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildClickableGpsCard(
                  gpsLocation,
                  isDeviceConnected,
                ),
                if (temperature != '--') ...[
                  const SizedBox(height: 12),
                  _buildIotCard(
                    Icons.thermostat,
                    "Temperature",
                    temperature,
                    "Body Temperature",
                    Colors.orange.shade50,
                    Colors.orange,
                    isConnected: isDeviceConnected,
                  ),
                ],
                const SizedBox(height: 24),
                _buildEmergencyCard(),
              ],
            ),
          ),
          // No FAB after device is registered (users shouldn't register multiple devices)
        );
      },
    );
  }

  Future<List<dynamic>> _fetchMyDevices() async {
    try {
      final resp = await _client.from('my_devices').select();
      final devices = resp as List<dynamic>;
      
      // If user has devices, load the first device's data
      if (devices.isNotEmpty) {
        deviceId = devices.first['id'] as String?;
        await _loadDeviceData();
      }
      
      return devices;
    } catch (e) {
      debugPrint('fetchMyDevices error: $e');
      return <dynamic>[];
    }
  }

  Future<void> _loadDeviceData() async {
    if (deviceId == null) return;
    
    try {
      // Get latest device data
      final dataRes = await _client
          .from('device_data')
          .select()
          .eq('device_id', deviceId!)
          .order('created_at', ascending: false)
          .limit(1);
      
      if (dataRes.isEmpty) {
        if (mounted) {
          setState(() {
            isDeviceConnected = false;
            heartRate = "No Data Yet";
            gpsLocation = "No Data Yet";
          });
        }
        return;
      }
      
      final latestData = dataRes.first as Map<String, dynamic>;
      final payload = latestData['payload'] as Map<String, dynamic>?;
      final timestamp = latestData['created_at'] as String?;
      
      if (timestamp != null) {
        _lastDataTime = DateTime.parse(timestamp);
        final difference = DateTime.now().difference(_lastDataTime!);
        // Consider device connected if data is less than 30 seconds old
        isDeviceConnected = difference.inSeconds < 30;
      }
      
      if (payload != null && mounted) {
        setState(() {
          final hr = payload['heart_rate'];
          heartRate = hr != null ? '$hr bpm' : '--';
          
          final lat = payload['latitude'];
          final lng = payload['longitude'];
          if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
            gpsLocation = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
          } else {
            gpsLocation = 'Acquiring GPS...';
          }
          
          final batt = payload['battery'];
          battery = batt != null ? '$batt%' : '--';
          
          final temp = payload['temperature'];
          temperature = temp != null ? '$temp°C' : '--';
        });
      }
    } catch (e) {
      debugPrint('loadDeviceData error: $e');
      if (mounted) {
        setState(() {
          isDeviceConnected = false;
        });
      }
    }
  }

  Widget _buildIotCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color bgColor,
    Color iconColor, {
    bool isConnected = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected ? value : "No Data",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.black87 : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected ? subtitle : "Device Offline",
                  style: TextStyle(
                    fontSize: 11,
                    color: isConnected ? Colors.green.shade600 : Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isConnected)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.chevron_right, color: iconColor, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE76F51), Color(0xFFE85D45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE76F51).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emergency,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Emergency Services",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "24/7 Support Available",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              // Placeholder for panic/SOS action. Integrate device or call functionality here.
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.phone,
                color: Color(0xFFE76F51),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableGpsCard(String gpsLocation, bool isConnected) {
    // Parse coordinates from gpsLocation string
    double? lat;
    double? lng;
    if (gpsLocation.contains(',')) {
      final parts = gpsLocation.split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
      }
    }
    
    final hasValidCoords = lat != null && lng != null && lat != 0.0 && lng != 0.0;
    
    return InkWell(
      onTap: hasValidCoords && isConnected
          ? () => _openInGoogleMaps(lat!, lng!)
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
                    isConnected ? gpsLocation : "--",
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
    Color iconColor, {
    bool isConnected = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            isConnected ? value : "--",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isConnected ? Colors.black87 : Colors.grey.shade400,
            ),
          ),
        ],
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
