import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:safehajj2/screen/navigation_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  // Feature flags so you can easily remove sections without refactoring
  static const bool showSearchBar = true;
  static const bool showCategories = false;
  static const bool showCityFilter = true;
  static const bool showMapPreview = false; // reserved for future

  late Future<List<Map<String, dynamic>>> _itemsFuture;
  late AnimationController _animController;
  String _selectedCategory = 'All';
  String? _selectedCity = 'Makkah'; // Nullable to allow showing all

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadItems() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/explore_items.json');
      final data = json.decode(jsonStr) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient + image, solid when collapsed
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            // Use transparent so the flexibleSpace gradient shows in both
            // expanded and collapsed states, matching other headers
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Explore',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              background: LayoutBuilder(
                builder: (context, constraints) {
                  final double h = constraints.maxHeight;
                  // Estimate collapsed vs expanded factor (0..1)
                  final double minH = kToolbarHeight + MediaQuery.of(context).padding.top;
                  const double maxH = 200.0; // expandedHeight
                  double t = (h - minH) / (maxH - minH);
                  if (!t.isFinite) t = 0;
                  if (t < 0) t = 0; else if (t > 1) t = 1;
                  // Darken more when collapsed (t->0)
                  final double darkOpacity = (1 - t) * 0.22; // up to 0.22 when fully collapsed

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Base multi-stop gradient
                      Container(
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
                      // Subtle background image
                      Opacity(
                        opacity: 0.28,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?w=1200',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox();
                          },
                        ),
                      ),
                      // Top fade overlay to keep title readable
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF1A4363).withOpacity(0.7),
                              const Color(0xFF1A4363).withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      // Collapsed darkening overlay (dynamic)
                      Container(color: Colors.black.withOpacity(darkOpacity)),

                      // Decorative watermark icon
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Opacity(
                          opacity: 0.15,
                          child: Icon(
                            Icons.explore_outlined,
                            size: 180,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Tagline
                      const Positioned(
                        left: 20,
                        bottom: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📍 Discover around you',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Find essentials, mosques & more',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                // Filter essentials based on selected city
                final List<Map<String, dynamic>> essentials;
                
                if (_selectedCity == null) {
                  // Show all locations from both cities
                  essentials = [
                    // Madinah
                    {
                      "name": "Bab Jebreel Health Center",
                      "type": "clinic",
                      "description": "Official health center near Gate 94.",
                      "tags": ["Official", "24/7"],
                      "distance": "250m",
                      "city": "Madinah"
                    },
                    {
                      "name": "Free Medical Center",
                      "type": "clinic",
                      "description": "Volunteer-run medical services.",
                      "tags": ["Free", "Charity"],
                      "distance": "400m",
                      "city": "Madinah"
                    },
                    {
                      "name": "Faraj Al Madinah Hotel",
                      "type": "landmark",
                      "description": "Comfortable accommodation near the Haram.",
                      "tags": ["Hotel", "Accommodation"],
                      "distance": "500m",
                      "city": "Madinah"
                    },
                    {
                      "name": "Al Madinah Golden Hotel",
                      "type": "landmark",
                      "description": "Premium hotel with modern amenities.",
                      "tags": ["Hotel", "Premium"],
                      "distance": "650m",
                      "city": "Madinah"
                    },
                    {
                      "name": "Arabesque Restaurant",
                      "type": "food",
                      "description": "Traditional Middle Eastern cuisine.",
                      "tags": ["Restaurant", "Halal"],
                      "distance": "300m",
                      "city": "Madinah"
                    },
                    {
                      "name": "Habibi Restaurant",
                      "type": "food",
                      "description": "Popular dining spot with local flavors.",
                      "tags": ["Restaurant", "Popular"],
                      "distance": "450m",
                      "city": "Madinah"
                    },
                    // Makkah
                    {
                      "name": "Haram Emergency Hospital",
                      "type": "clinic",
                      "description": "Emergency medical services near the Haram.",
                      "tags": ["Emergency", "24/7"],
                      "distance": "300m",
                      "city": "Makkah"
                    },
                    {
                      "name": "King Faisal Hospital",
                      "type": "clinic",
                      "description": "Major hospital facility in Makkah.",
                      "tags": ["Hospital", "Full Service"],
                      "distance": "1.2km",
                      "city": "Makkah"
                    },
                    {
                      "name": "Azka Al Maqam",
                      "type": "landmark",
                      "description": "Luxury hotel near the Haram.",
                      "tags": ["Hotel", "Luxury"],
                      "distance": "400m",
                      "city": "Makkah"
                    },
                    {
                      "name": "InterContinental Dar al Tawhid Makkah",
                      "type": "landmark",
                      "description": "5-star hotel with stunning Haram views.",
                      "tags": ["Hotel", "5-Star"],
                      "distance": "350m",
                      "city": "Makkah"
                    },
                    {
                      "name": "Al Bayt Restaurant",
                      "type": "food",
                      "description": "Authentic Saudi cuisine and traditional dishes.",
                      "tags": ["Restaurant", "Saudi"],
                      "distance": "280m",
                      "city": "Makkah"
                    },
                    {
                      "name": "Al Shorfa Restaurant",
                      "type": "food",
                      "description": "Fine dining with panoramic city views.",
                      "tags": ["Restaurant", "Fine Dining"],
                      "distance": "500m",
                      "city": "Makkah"
                    }
                  ];
                } else if (_selectedCity == 'Madinah') {
                  essentials = [
                    {
                      "name": "Bab Jebreel Health Center",
                      "type": "clinic",
                      "description": "Official health center near Gate 94.",
                      "tags": ["Official", "24/7"],
                      "distance": "250m",
                      "city": "Madinah"
                    },
                    {
                      "name": "Free Medical Center",
                      "type": "clinic",
                      "description": "Volunteer-run medical services.",
                      "tags": ["Free", "Charity"],
                      "distance": "400m",
                      "city": "Madinah"
                    },
                    {
                      "name": "Faraj Al Madinah Hotel",
                      "type": "landmark",
                      "description": "Comfortable accommodation near the Haram.",
                      "tags": ["Hotel", "Accommodation"],
                      "distance": "500m",
                      "city": "Madinah"
                    },
                    {
                      "name": "Al Madinah Golden Hotel",
                      "type": "landmark",
                      "description": "Premium hotel with modern amenities.",
                      "tags": ["Hotel", "Premium"],
                      "distance": "650m",
                      "city": "Madinah"
                    },
                    {
                      "name": "Arabesque Restaurant",
                      "type": "food",
                      "description": "Traditional Middle Eastern cuisine.",
                      "tags": ["Restaurant", "Halal"],
                      "distance": "300m",
                      "city": "Madinah"
                    },
                    {
                      "name": "Habibi Restaurant",
                      "type": "food",
                      "description": "Popular dining spot with local flavors.",
                      "tags": ["Restaurant", "Popular"],
                      "distance": "450m",
                      "city": "Madinah"
                    }
                  ];
                } else {
                  // Makkah hospitals
                  essentials = [
                    {
                      "name": "Haram Emergency Hospital",
                      "type": "clinic",
                      "description": "Emergency medical services near the Haram.",
                      "tags": ["Emergency", "24/7"],
                      "distance": "300m",
                      "city": "Makkah"
                    },
                    {
                      "name": "King Faisal Hospital",
                      "type": "clinic",
                      "description": "Major hospital facility in Makkah.",
                      "tags": ["Hospital", "Full Service"],
                      "distance": "1.2km",
                      "city": "Makkah"
                    },
                    {
                      "name": "Azka Al Maqam",
                      "type": "landmark",
                      "description": "Luxury hotel near the Haram.",
                      "tags": ["Hotel", "Luxury"],
                      "distance": "400m",
                      "city": "Makkah"
                    },
                    {
                      "name": "InterContinental Dar al Tawhid Makkah",
                      "type": "landmark",
                      "description": "5-star hotel with stunning Haram views.",
                      "tags": ["Hotel", "5-Star"],
                      "distance": "350m",
                      "city": "Makkah"
                    },
                    {
                      "name": "Al Bayt Restaurant",
                      "type": "food",
                      "description": "Authentic Saudi cuisine and traditional dishes.",
                      "tags": ["Restaurant", "Saudi"],
                      "distance": "280m",
                      "city": "Makkah"
                    },
                    {
                      "name": "Al Shorfa Restaurant",
                      "type": "food",
                      "description": "Fine dining with panoramic city views.",
                      "tags": ["Restaurant", "Fine Dining"],
                      "distance": "500m",
                      "city": "Makkah"
                    }
                  ];
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (showSearchBar) _buildSearchBar(),
                    if (showCityFilter) _buildCityFilter(),

                    if (showCategories) ...[
                      const SizedBox(height: 24),
                      _buildQuickCategories(),
                    ],

                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4663AC).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.place,
                              color: Color(0xFF4663AC),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Essentials near you',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (essentials.isEmpty)
                      _emptyBox('No essentials found')
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: essentials.map(_buildModernPoiCard).toList(),
                        ),
                      ),

                    if (showMapPreview) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _sectionTitle('Map preview'),
                      ),
                      const SizedBox(height: 12),
                      _mapPlaceholder(),
                    ],
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityFilter() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 0, left: 20, right: 20),
      child: Row(
        children: [
          Expanded(child: _buildCityChip('Makkah')),
          const SizedBox(width: 16),
          Expanded(child: _buildCityChip('Madinah')),
        ],
      ),
    );
  }

  Widget _buildCityChip(String name) {
    final isSelected = _selectedCity == name;
    return Material(
      color: isSelected ? const Color(0xFF3572A6) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: isSelected ? 4 : 1,
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        onTap: () {
          setState(() {
            // Toggle: if already selected, deselect (show all), otherwise select this city
            _selectedCity = isSelected ? null : name;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search places, gates, services…',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF4663AC)),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4663AC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: Color(0xFF4663AC), size: 20),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCategories() {
    final categories = [
      {'icon': Icons.health_and_safety, 'label': 'Essentials', 'color': const Color(0xFF4663AC)},
      {'icon': Icons.mosque, 'label': 'Mosques', 'color': const Color(0xFF4663AC)},
      {'icon': Icons.restaurant, 'label': 'Food', 'color': const Color(0xFF4663AC)},
      {'icon': Icons.directions_bus, 'label': 'Transport', 'color': const Color(0xFF4663AC)},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _selectedCategory = cat['label'] as String);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _selectedCategory == cat['label']
                        ? LinearGradient(
                            colors: [
                              (cat['color'] as Color),
                              (cat['color'] as Color).withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _selectedCategory == cat['label']
                        ? null
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        color: _selectedCategory == cat['label']
                            ? Colors.white
                            : (cat['color'] as Color),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selectedCategory == cat['label']
                              ? Colors.white
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernPoiCard(Map<String, dynamic> e) {
    final type = (e['type'] ?? '').toString();
    final name = (e['name'] ?? '').toString();
    final desc = (e['description'] ?? '').toString();
    final tags = (e['tags'] as List?)?.cast<String>() ?? [];
    final distance = (e['distance'] ?? '').toString();
    final city = (e['city'] ?? _selectedCity ?? 'Madinah').toString(); // Get city from data or use selected

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFC8D9ED).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigate to navigation screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NavigationScreen(
                  destinationName: name,
                  destinationType: type,
                  description: desc,
                  distance: distance,
                  city: city,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4663AC),
                        const Color(0xFF1E88E5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4663AC).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _iconForType(type),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? type.toUpperCase() : name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc.isNotEmpty ? desc : 'Nearby facility',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: tags.take(2).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4663AC).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4663AC),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                // Distance badge and arrow
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '< 1km',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        const Icon(Icons.explore, color: Color(0xFF4663AC)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  Widget _emptyBox(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'clinic':
        return Icons.local_hospital;
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_bus;
      case 'landmark':
        return Icons.hotel;
      default:
        return Icons.location_on_outlined;
    }
  }

  Widget _mapPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4663AC).withOpacity(0.1),
            const Color(0xFFC8D9ED).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: const Color(0xFF4663AC).withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Interactive map coming soon',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
