import 'package:flutter/material.dart';
import 'package:safehajj2/screen/guide_screen.dart';
import 'package:safehajj2/services/prayer_time_service.dart';
import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:safehajj2/screen/explore_screen.dart';
import 'package:safehajj2/services/supabase_service.dart';
import 'package:safehajj2/screen/settings_screen.dart';
import 'package:safehajj2/screen/device_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:safehajj2/widgets/glass_slider.dart';
import 'package:safehajj2/screen/health_safety_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safehajj2/screen/admin_groups_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Placeholder for IoT data (can be connected to MQTT/Firebase later)
  int _selectedIndex = 0;

  PrayerDayTimes? _prayers;
  Timer? _tick;
  String _displayName = '';
  String _locationName = 'Makkah';
  String _todayDate = '';
  String _todayHijri = '';
  Timer? _dateTimer;
  Duration? _countdown; // live ticking countdown to next prayer
  Timer? _secondTick;
  bool _isRefreshingNext = false;
  bool _isCardFlipped = false;
  Map<String, dynamic>? _profileData;
  AnimationController? _flipController;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    // Flip animation driven by controller's value directly via AnimatedBuilder
    _loadPrayerTimes();
    _loadProfileName();
    _loadLocation();
    _checkIsAdmin();
    _updateDate();
    // Refresh countdown periodically to keep "Next" timer accurate
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadPrayerTimes();
      // Only update date if day changed (cheap check)
      final newDate = DateFormat.yMMMMd().format(DateTime.now());
      if (newDate != _todayDate) _updateDate();
    });
    // Separate timer to refresh date display at midnight boundary (fallback) every hour
    _dateTimer = Timer.periodic(const Duration(hours: 1), (_) => _updateDate());
    // Per-second tick for the countdown display only
    _secondTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_countdown == null) return;
      if (_countdown!.inSeconds > 0) {
        setState(() => _countdown = _countdown! - const Duration(seconds: 1));
      } else {
        if (!_isRefreshingNext) {
          _isRefreshingNext = true;
          _loadPrayerTimes().whenComplete(() => _isRefreshingNext = false);
        }
      }
    });
  }

  Future<void> _checkIsAdmin() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final res = await Supabase.instance.client
          .from('groups')
          .select('id')
          .eq('admin_user', uid);
      if (!mounted) return;
      // res from select is already a List<dynamic>
      _isAdmin = res.isNotEmpty;
      setState(() {});
    } catch (e) {
      // silent
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _dateTimer?.cancel();
    _secondTick?.cancel();
    _flipController?.dispose();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    final data = await PrayerTimeService.getTodayTimes();
    if (mounted) {
      setState(() {
        _prayers = data;
        _countdown = data.timeToNext ?? Duration.zero;
      });
    }
  }

  Future<void> _loadProfileName() async {
    try {
      final profile = await SupabaseService.getMyProfile();
      final email = SupabaseService.currentUser?.email;
      final name = (profile?['full_name'] as String?)?.trim();
      final fallback = (email != null && email.contains('@')) ? email.split('@').first : 'Pilgrim';
      if (mounted) setState(() {
        _displayName = (name != null && name.isNotEmpty) ? name : fallback;
        _profileData = profile; // Store full profile for flip card back side
      });
    } catch (_) {
      // Silent fallback in case Supabase is not initialized
      if (mounted) setState(() {
        _displayName = 'Pilgrim';
        _profileData = null;
      });
    }
  }

  // Legacy flip toggle (no longer used) removed; flip handled inline in GestureDetector.

  Future<void> _loadLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationName = 'Makkah');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = (p.locality?.isNotEmpty == true)
            ? p.locality
            : (p.subAdministrativeArea?.isNotEmpty == true)
                ? p.subAdministrativeArea
                : (p.administrativeArea?.isNotEmpty == true)
                    ? p.administrativeArea
                    : null;
        if (mounted) setState(() => _locationName = city ?? 'Current');
      }
    } catch (_) {
      if (mounted) setState(() => _locationName = 'Makkah');
    }
  }

  void _updateDate() {
    final now = DateTime.now();
    final formatted = DateFormat.yMMMMd().format(now); // e.g., November 7, 2025
    final hijri = HijriCalendar.fromDate(now);
    final hijriStr = '${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear}H';
    if (mounted) setState(() { _todayDate = formatted; _todayHijri = hijriStr; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: _selectedIndex == 0
          ? AppBar(
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
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.mosque,
                          color: Colors.white, size: 28);
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "SafeHajj",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                if (_isAdmin)
                  IconButton(
                    tooltip: 'Manage Groups',
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminGroupsScreen()),
                      ).then((_) => _checkIsAdmin());
                    },
                  ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeBody(), // Use a dedicated body builder
          const ExploreScreen(),
          const DeviceScreen(),
          const SettingsScreen(),
        ],
      ),

      // --- Bottom Navigation ---
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60,
        backgroundColor: Colors.transparent, // allow underlying content to show through
        color: const Color(0xFF67A9D5), // curved bar color
        buttonBackgroundColor: const Color(0xFF67A9D5), // active circle
        animationCurve: Curves.easeOutCubic,
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.home_rounded, size: 28, color: Colors.white),
          Icon(Icons.explore_outlined, size: 28, color: Colors.white),
          Icon(Icons.sensors, size: 28, color: Colors.white),
          Icon(Icons.settings, size: 28, color: Colors.white),
        ],
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  // Home Body Widget (No Scaffold)
  Widget _buildHomeBody() {
    return Container(
      color: Colors.white, //  provides the white background for the page
      child: SafeArea(
        bottom: false, //  have padding below,  disable bottom safe area 
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.only(bottom: 80), // Extra padding to clear nav bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Welcome Card with Flip Animation ---
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  // Robust toggle ensuring controller direction always set
                  if (_flipController == null) return;
                  if (_isCardFlipped) {
                    _flipController!.reverse();
                  } else {
                    _flipController!.forward();
                  }
                  setState(() => _isCardFlipped = !_isCardFlipped);
                },
                child: AnimatedBuilder(
                  animation: _flipController ?? const AlwaysStoppedAnimation(0),
                  builder: (context, child) {
                    final controllerValue = (_flipController?.value ?? 0);
                    // Map 0..1 to 0..π
                    double angle = controllerValue * 3.1415926535;
                    // Determine which side to show
                    final showFront = angle <= 3.1415926535 / 2;
                    // If showing back, adjust angle so text isn't mirrored
                    Widget face;
                    if (showFront) {
                      face = _buildWelcomeCardFront();
                    } else {
                      // subtract π to keep readable
                      angle -= 3.1415926535;
                      face = _buildWelcomeCardBack();
                    }
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle);
                    return Transform(
                      transform: transform,
                      alignment: Alignment.center,
                      child: face,
                    );
                  },
                ),
              ),

              // --- Prayer Time Title ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: const [
                    Icon(Icons.access_time, color: Color(0xFF4663AC), size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Prayer Time",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // --- Prayer Times (New Style) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Blurred background image (falls back to gradient if missing)
                        SizedBox(
                          width: double.infinity,
                          child: ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Image.asset(
                              'assets/images/masjid_nabawi.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF8B9CA5),
                                        Color(0xFF5D7B8A),
                                        Color(0xFF2C3E50),
                                        Color(0xFF1A252F),
                                      ],
                                    ),
                                  ),
                                  height: 180,
                                );
                              },
                            ),
                          ),
                        ),
                        // Ensure minimum height for visibility
                        const SizedBox(height: 220),
                        // Bottom-up darkening gradient (top transparent-ish, bottom black)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.15), // clearer at top
                                  Colors.black.withOpacity(0.75), // deeper at bottom
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  _prayers?.nextPrayer != null
                                      ? 'Left until ${PrayerTimeService.prayerName(_prayers!.nextPrayer!)} prayer'
                                      : 'Prayer time',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _countdown != null
                                      ? _formatDurationClock(_countdown!)
                                      : '--:--',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                                const SizedBox(height: 36),
                                _buildPrayerTimesRow(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- Modern Glass Slider Quick Actions ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: const [
                    Icon(Icons.apps, color: Color(0xFF4663AC), size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassMorphismSlider(
                items: [
                  GlassSliderItem(
                    title: 'Umrah & Hajj Guide',
                    subtitle: 'Learn the rituals',
                    icon: Icons.menu_book,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GuideScreen(),
                        ),
                      );
                    },
                  ),
                  const GlassSliderItem(
                    title: 'Find Your Group',
                    subtitle: 'Locate companions',
                    icon: Icons.groups,
                  ),
                  GlassSliderItem(
                    title: 'Health & Safety',
                    subtitle: 'Stay informed',
                    icon: Icons.medical_services,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HealthSafetyScreen(),
                        ),
                      );
                    },
                  ),
                ],
                height: 240,
                viewportFraction: 0.82,
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Device screen moved to its own file (DeviceScreen)

  // Profile placeholder removed; now using ProfileScreen

  // legacy grid card builder removed in favor of glass slider

  String _formatDurationClock(Duration d) {
    int hours = d.inHours;
    int minutes = d.inMinutes % 60;
    int seconds = d.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }


  Widget _buildPrayerTimesRow() {
    if (_prayers == null) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final order = [
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    final iconMap = <Prayer, IconData>{
      Prayer.fajr: Icons.wb_twilight,
      Prayer.sunrise: Icons.wb_sunny_outlined,
      Prayer.dhuhr: Icons.wb_sunny,
      Prayer.asr: Icons.cloud_outlined,
      Prayer.maghrib: Icons.wb_twilight,
      Prayer.isha: Icons.nightlight_round,
    };

    final next = _prayers!.nextPrayer;

    Widget buildItem(Prayer p) {
      final isActive = next == p;
      final timeStr = _prayers!.timeString(p);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconMap[p]!,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.55),
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            PrayerTimeService.prayerName(p),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timeStr,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: order.map(buildItem).toList(),
    );
  }

  Widget _buildWelcomeCardFront() {
    return Container(
      key: const ValueKey('front'),
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bgcard.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'As-salamu alaykum',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayName.isEmpty ? 'Guest' : _displayName,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _locationName,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _todayDate,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _todayHijri,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCardBack() {
    return Container(
      key: const ValueKey('back'),
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bgcard.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.30),
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Account Details',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.person, color: Colors.white70, size: 24),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Only show Name, Age, Health Condition
                  _buildAccountDetailRow(
                    Icons.person_outline,
                    'Name',
                    _profileData?['full_name'] ?? (_displayName.isNotEmpty ? _displayName : 'Not set'),
                  ),
                  const SizedBox(height: 12),
                  _buildAccountDetailRow(
                    Icons.cake_outlined,
                    'Age',
                    (_profileData?['age'] != null) ? _profileData!['age'].toString() : 'Not set',
                  ),
                  const SizedBox(height: 12),
                  _buildAccountDetailRow(
                    Icons.health_and_safety_outlined,
                    'Health',
                    (() {
                      final hc = (_profileData?['health_condition'] ?? '').toString();
                      return hc.isNotEmpty ? hc : 'Not set';
                    })(),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Tap to flip back',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  
}