import 'package:flutter/material.dart';
import 'package:safehajj2/screen/device_register.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  // Placeholder state; wire these to your real data source later
  String heartRate = "No Device Detected";
  String gpsLocation = "No Device Detected";
  bool isDeviceConnected = false;

  @override
  void initState() {
    super.initState();
    _myDevicesFuture = _fetchMyDevices();
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
                          "Smart Device Status",
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
                _buildIotCard(
                  Icons.favorite,
                  "Heart Rate",
                  heartRate,
                  "Normal Range",
                  Colors.red.shade50,
                  Colors.red,
                  isConnected: isDeviceConnected,
                ),
                const SizedBox(height: 12),
                _buildIotCard(
                  Icons.location_on,
                  "GPS Location",
                  gpsLocation,
                  "Live Tracking Active",
                  Colors.blue.shade50,
                  Colors.blue,
                  isConnected: isDeviceConnected,
                ),
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
      final client = Supabase.instance.client;
      final resp = await client.from('my_devices').select();
      // The project's Supabase usage returns raw list; cast safely
      return resp as List<dynamic>;
    } catch (e) {
      debugPrint('fetchMyDevices error: $e');
      return <dynamic>[];
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

}
