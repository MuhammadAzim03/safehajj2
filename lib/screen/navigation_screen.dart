import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class NavigationScreen extends StatelessWidget {
  final String destinationName;
  final String destinationType;
  final String description;
  final String distance;
  final String city;

  const NavigationScreen({
    Key? key,
    required this.destinationName,
    required this.destinationType,
    required this.description,
    required this.distance,
    this.city = 'Madinah',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine start point based on city
    final LatLng startPoint;
    final String startLocationName;
    
    if (city == 'Makkah') {
      startPoint = LatLng(21.4225, 39.8262); // Masjid al-Haram
      startLocationName = 'Masjid al-Haram';
    } else {
      startPoint = LatLng(24.4672, 39.6111); // Masjid Nabawi
      startLocationName = 'Masjid Nabawi';
    }
    
    // Calculate destination based on city and type
    final LatLng endPoint;
    final List<LatLng> routePoints;
    
    if (city == 'Makkah') {
      // Makkah destinations
      if (destinationName.contains('Haram Emergency')) {
        endPoint = LatLng(21.426619, 39.823333); // Haram Emergency Hospital accurate coordinates
        routePoints = [
          startPoint,
          LatLng(21.4240, 39.8250),
          LatLng(21.4253, 39.8265),
          endPoint,
        ];
      } else if (destinationName.contains('King Faisal')) {
        endPoint = LatLng(21.435086, 39.853511); // King Faisal Hospital accurate coordinates
        routePoints = [
          startPoint,
          LatLng(21.4280, 39.8350),
          LatLng(21.4315, 39.8445),
          endPoint,
        ];
      } else if (destinationName.contains('Azka') || destinationName.contains('InterContinental')) {
        // Use accurate coordinates for each hotel
        if (destinationName.contains('Azka')) {
          endPoint = LatLng(21.420108, 39.828064); // Azka Al Maqam accurate coordinates
        } else {
          endPoint = LatLng(21.421006, 39.822747); // InterContinental Dar al Tawhid accurate coordinates
        }
        routePoints = [
          startPoint,
          LatLng(21.4230, 39.8270),
          LatLng(21.4220, 39.8254),
          endPoint,
        ];
      } else if (destinationName.contains('Al Bayt') || destinationName.contains('Al Shorfa')) {
        // Use accurate coordinates for each restaurant
        if (destinationName.contains('Al Bayt')) {
          endPoint = LatLng(21.419494, 39.826211); // Al Bayt Restaurant accurate coordinates
        } else {
          endPoint = LatLng(21.419733, 39.826461); // Al Shorfa Restaurant accurate coordinates
        }
        routePoints = [
          startPoint,
          LatLng(21.4227, 39.8268),
          endPoint,
        ];
      } else {
        endPoint = LatLng(21.4240, 39.8280);
        routePoints = [startPoint, endPoint];
      }
    } else {
      // Madinah destinations
      if (destinationName.contains('Bab Jebreel')) {
        endPoint = LatLng(24.467833, 39.613444); // Bab Jebreel accurate coordinates
        routePoints = [
          startPoint,
          LatLng(24.4675, 39.6120),
          LatLng(24.4677, 39.6127),
          endPoint,
        ];
      } else if (destinationName.contains('Free Medical')) {
        endPoint = LatLng(24.465258, 39.610072); // Free Medical Center accurate coordinates
        routePoints = [
          startPoint,
          LatLng(24.4665, 39.6115),
          LatLng(24.4658, 39.6108),
          endPoint,
        ];
      } else if (destinationName.contains('Faraj') || destinationName.contains('Golden')) {
        // Use accurate coordinates for each hotel
        if (destinationName.contains('Faraj')) {
          endPoint = LatLng(24.490861, 39.602406); // Faraj Al Madinah Hotel accurate coordinates
        } else {
          endPoint = LatLng(24.465319, 39.609878); // Al Madinah Golden Hotel accurate coordinates
        }
        routePoints = [
          startPoint,
          LatLng(24.4680, 39.6118),
          endPoint,
        ];
      } else if (destinationName.contains('Arabesque') || destinationName.contains('Habibi')) {
        // Use accurate coordinates for each restaurant
        if (destinationName.contains('Arabesque')) {
          endPoint = LatLng(24.472383, 39.611622); // Arabesque Restaurant accurate coordinates
        } else {
          endPoint = LatLng(24.469464, 39.626950); // Habibi Restaurant accurate coordinates
        }
        routePoints = [
          startPoint,
          LatLng(24.4678, 39.6120),
          endPoint,
        ];
      } else {
        endPoint = LatLng(24.4700, 39.6140);
        routePoints = [startPoint, endPoint];
      }
    }
    
    // Calculate center point for map
    final double centerLat = (startPoint.latitude + endPoint.latitude) / 2;
    final double centerLng = (startPoint.longitude + endPoint.longitude) / 2;

    return Scaffold(
      body: Stack(
        children: [
          // Real Map with route
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng), // Center between start and end
              initialZoom: 15.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.safehajj2',
                tileProvider: NetworkTileProvider(),
              ),
              // Route polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 6.0,
                    color: const Color(0xFF3572A6),
                    borderStrokeWidth: 2.0,
                    borderColor: const Color(0xFF67A9D5),
                    gradientColors: const [
                      Color(0xFF67A9D5),
                      Color(0xFF3572A6),
                      Color(0xFF1A4363),
                    ],
                  ),
                ],
              ),
              // Markers
              MarkerLayer(
                markers: [
                  // Start marker (Masjid Nabawi)
                  Marker(
                    point: startPoint,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A4363),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mosque,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // End marker (Destination)
                  Marker(
                    point: endPoint,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF67A9D5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        destinationType == 'clinic'
                            ? Icons.local_hospital
                            : destinationType == 'food'
                                ? Icons.restaurant
                                : Icons.hotel,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Search/Location bar at top
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Icon(Icons.location_on_outlined, color: Color(0xFF3572A6)),
                  ),
                  Expanded(
                    child: Text(
                      destinationName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // Navigation button (bottom right)
          Positioned(
            bottom: 240,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF67A9D5), Color(0xFF1A4363)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.navigation, color: Colors.white, size: 28),
                onPressed: () {
                  // Start navigation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting navigation...')),
                  );
                },
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),

          // Bottom card with destination info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    destinationName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: const Color(0xFF3572A6),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'From $startLocationName',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  distance,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A4363),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '3 min',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: _buildTransportOption(
                            icon: Icons.directions_walk,
                            time: 'Walking',
                            isSelected: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportOption({
    required IconData icon,
    required String time,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF67A9D5), Color(0xFF1A4363)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
