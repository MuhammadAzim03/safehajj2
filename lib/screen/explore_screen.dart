import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safehajj2/screen/navigation_screen.dart';
import 'package:safehajj2/services/supabase_service.dart';

// Provider to fetch explore items from Supabase
final exploreItemsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return supabaseService.getExploreItems();
});

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> with SingleTickerProviderStateMixin {
  // Feature flags so you can easily remove sections without refactoring
  static const bool showSearchBar = true;
  static const bool showCategories = false;
  static const bool showCityFilter = true;
  static const bool showMapPreview = false; // reserved for future

  late AnimationController _animController;
  String? _selectedCity = 'Makkah'; // Default selection
  String _selectedCategory = 'All'; // Add this line

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(exploreItemsProvider);

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
            child: itemsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => _emptyBox('Error loading data: $err'),
              data: (items) {
                // Filter items based on the selected city (_selectedCity)
                final filteredItems = _selectedCity == null
                    ? items
                    : items.where((item) => item['city'] == _selectedCity).toList();

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
                          Text(
                            _selectedCity == null ? 'All Essentials' : 'Essentials in $_selectedCity',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (filteredItems.isEmpty)
                      _emptyBox('No essentials found for the selected city.')
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: filteredItems.map(_buildModernPoiCard).toList(),
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
    final name = (e['title'] ?? 'No Title').toString();
    final desc = (e['description'] ?? 'No Description').toString();
    final imageUrl = e['image_url'] as String?;
    final type = (e['type'] ?? 'Other').toString();
    final city = (e['city'] ?? _selectedCity ?? 'Makkah').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  distance: 'N/A', // Distance is not available from DB yet
                  city: city,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon or Image
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _defaultIcon(type),
                          )
                        : _defaultIcon(type),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultIcon(String type) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4663AC), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(_iconForType(type), color: Colors.white, size: 28),
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
    // Use type from DB to determine icon
    switch (type.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital;
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'landmark':
        return Icons.account_balance;
      case 'other':
        return Icons.place;
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
