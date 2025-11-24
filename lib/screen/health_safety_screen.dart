import 'package:flutter/material.dart';
import 'dart:ui';

class HealthSafetyScreen extends StatefulWidget {
  const HealthSafetyScreen({super.key});

  @override
  State<HealthSafetyScreen> createState() => _HealthSafetyScreenState();
}

class _HealthSafetyScreenState extends State<HealthSafetyScreen> {
  late final List<_HSCardData> _cards;

  @override
  void initState() {
    super.initState();
    _cards = [
      _HSCardData(
        title: 'Heat & Hydration',
        subtitle: 'Avoid heat exhaustion',
        description: 'Stay shaded, hydrate regularly, and recognize signs of heat stress (dizziness, nausea, rapid pulse).',
        color: const Color(0xFF67A9D5),
        icon: Icons.wb_sunny_outlined,
        heroTag: 'hs_heat',
        onTap: () => _openDetail(
          title: 'Heat & Hydration',
          color: const Color(0xFF67A9D5),
          icon: Icons.wb_sunny_outlined,
          heroTag: 'hs_heat',
          pages: [
            _HSPage('Hydration Basics', _tipsHydration(), const Color(0xFF67A9D5)),
            _HSPage('Heat Protection', _tipsHeatProtection(), const Color(0xFF67A9D5)),
            _HSPage('Warning Signs', _tipsHeatSigns(), const Color(0xFF67A9D5)),
          ],
        ),
      ),
      _HSCardData(
        title: 'Crowd Safety',
        subtitle: 'Move safely in masses',
        description: 'Keep group formation, avoid bottlenecks, and follow staff instructions during peak times.',
        color: const Color(0xFF3572A6),
        icon: Icons.groups_2_outlined,
        heroTag: 'hs_crowd',
        onTap: () => _openDetail(
          title: 'Crowd Safety',
          color: const Color(0xFF3572A6),
          icon: Icons.groups_2_outlined,
          heroTag: 'hs_crowd',
          pages: [
            _HSPage('Movement Tips', _tipsCrowdMove(), const Color(0xFF3572A6)),
            _HSPage('Avoid Risks', _tipsCrowdRisks(), const Color(0xFF3572A6)),
            _HSPage('Emergency Flow', _tipsCrowdEmergency(), const Color(0xFF3572A6)),
          ],
        ),
      ),
      _HSCardData(
        title: 'Medical & Meds',
        subtitle: 'Keep essentials handy',
        description: 'Carry prescriptions, allergies info, and a basic first-aid kit at all times.',
        color: const Color(0xFF67A9D5),
        icon: Icons.medical_services_outlined,
        heroTag: 'hs_medical',
        onTap: () => _openDetail(
          title: 'Medical & Medications',
          color: const Color(0xFF67A9D5),
          icon: Icons.medical_services_outlined,
          heroTag: 'hs_medical',
          pages: [
            _HSPage('Medical Prep', _tipsMedicalPrep(), const Color(0xFF67A9D5)),
            _HSPage('Meds & Storage', _tipsMedsStorage(), const Color(0xFF67A9D5)),
            _HSPage('When to Seek Help', _tipsSeekHelp(), const Color(0xFF67A9D5)),
          ],
        ),
      ),
      _HSCardData(
        title: 'Foot Care',
        subtitle: 'Prevent blisters & pain',
        description: 'Use proper footwear, breathable socks, and treat hotspots early to avoid injuries.',
        color: const Color(0xFF3572A6),
        icon: Icons.directions_walk_outlined,
        heroTag: 'hs_foot',
        onTap: () => _openDetail(
          title: 'Foot Care',
          color: const Color(0xFF3572A6),
          icon: Icons.directions_walk_outlined,
          heroTag: 'hs_foot',
          pages: [
            _HSPage('Footwear', _tipsFootwear(), const Color(0xFF3572A6)),
            _HSPage('Blister Prevention', _tipsBlisters(), const Color(0xFF3572A6)),
            _HSPage('Aftercare', _tipsAftercare(), const Color(0xFF3572A6)),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Health & Safety',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF67A9D5),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF67A9D5), Color(0xFF1A4363)],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          itemCount: _cards.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _AnimatedHSCard(data: _cards[index]),
          ),
        ),
      ),
    );
  }

  void _openDetail({
    required String title,
    required Color color,
    required IconData icon,
    required String heroTag,
    required List<_HSPage> pages,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: _HSDetailScreen(heroTag: heroTag, title: title, icon: icon, color: color, pages: pages),
        ),
      ),
    );
  }

  // --- Content builders ---
  List<String> _tipsHydration() => [
        'Drink small amounts frequently; aim 200–300 ml every 15–20 minutes in heat.',
        'Use electrolyte solutions if sweating heavily; avoid excessive caffeine.',
        'Carry a reusable bottle; refill whenever possible.',
      ];
  List<String> _tipsHeatProtection() => [
        'Seek shade during peak sun; use umbrellas or lightweight head coverings.',
        'Wear breathable, light-colored clothing; avoid dark heavy fabrics.',
        'Apply sunscreen (SPF 30+) and reapply every 2 hours if exposed.',
      ];
  List<String> _tipsHeatSigns() => [
        'Warning signs: dizziness, heavy sweating or none at all, nausea, rapid pulse, confusion.',
        'Act fast: move to shade, cool the body, sip water, and seek medical help if severe.',
      ];
  List<String> _tipsCrowdMove() => [
        'Walk in sync with the crowd flow; avoid sudden stops.',
        'Keep an eye on exits and staff directions; follow signs.',
        'Assign meeting points in case your group gets separated.',
      ];
  List<String> _tipsCrowdRisks() => [
        'Avoid dense bottlenecks; wait for off-peak times if possible.',
        'Do not push; keep hands near chest to protect breathing space.',
        'If you drop something, do not bend; move aside first.',
      ];
  List<String> _tipsCrowdEmergency() => [
        'If trapped, keep moving with flow at a diagonal angle toward the edges.',
        'Signal staff/security for assistance and follow their lanes.',
      ];
  List<String> _tipsMedicalPrep() => [
        'Keep medical ID, allergies list, and emergency contacts on your phone and printed.',
        'Pack a basic kit: plasters, antiseptic wipes, pain relief, oral rehydration salts.',
      ];
  List<String> _tipsMedsStorage() => [
        'Carry prescriptions in original packaging; bring extra dosage.',
        'Store meds away from direct heat; use insulated pouch if needed.',
      ];
  List<String> _tipsSeekHelp() => [
        'Call local emergency number if chest pain, shortness of breath, fainting, severe dehydration.',
        'Head to nearest clinic indicated by official signage inside the mosque complex.',
      ];
  List<String> _tipsFootwear() => [
        'Wear cushioned, broken-in walking shoes; avoid brand-new pairs for long walks.',
        'Use moisture-wicking socks; change if they get wet.',
      ];
  List<String> _tipsBlisters() => [
        'Treat hotspots early with tape; use blister pads as needed.',
        'Keep feet dry; apply foot powder to reduce friction.',
      ];
  List<String> _tipsAftercare() => [
        'Elevate feet after long walks; stretch calves and arches.',
        'Soak feet in cool water and inspect for cuts or blisters.',
      ];
}

class _HSCardData {
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final String heroTag;
  const _HSCardData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.heroTag,
  });
}

class _AnimatedHSCard extends StatefulWidget {
  final _HSCardData data;
  const _AnimatedHSCard({required this.data});

  @override
  State<_AnimatedHSCard> createState() => _AnimatedHSCardState();
}

class _AnimatedHSCardState extends State<_AnimatedHSCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.data.color;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final BorderRadius topRadius = _expanded
            ? const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22))
            : BorderRadius.circular(22);
        return Transform.scale(
          scale: _scale.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: widget.data.onTap,
                child: Hero(
                  tag: widget.data.heroTag,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: topRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.withOpacity(0.85), c.withOpacity(0.55)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.withOpacity(0.35),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
                    ),
                    child: ClipRRect(
                      borderRadius: topRadius,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(color: Colors.white.withOpacity(0.06)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                                  ),
                                  child: Icon(widget.data.icon, color: Colors.white, size: 32),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.data.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.data.subtitle,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _expanded = !_expanded),
                                  child: AnimatedRotation(
                                    turns: _expanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 28),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                    border: Border(
                      left: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.2),
                      right: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.2),
                      bottom: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(color: Colors.black.withOpacity(0.18)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                        child: Text(
                          widget.data.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 350),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HSPage {
  final String title;
  final List<String> items;
  final Color color;
  const _HSPage(this.title, this.items, this.color);
}

class _HSDetailScreen extends StatefulWidget {
  final String heroTag;
  final String title;
  final IconData icon;
  final Color color;
  final List<_HSPage> pages;
  const _HSDetailScreen({
    required this.heroTag,
    required this.title,
    required this.icon,
    required this.color,
    required this.pages,
  });
  @override
  State<_HSDetailScreen> createState() => _HSDetailScreenState();
}

class _HSDetailScreenState extends State<_HSDetailScreen> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: widget.heroTag,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [widget.color.withOpacity(0.9), widget.color.withOpacity(0.6), const Color(0xFF0A0A0A)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _glassBtn(Icons.arrow_back, () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.pages.length, (i) => _dot(i == _index)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemCount: widget.pages.length,
                    itemBuilder: (context, i) {
                      final page = widget.pages[i];
                      return _DetailListPage(title: page.title, items: page.items, color: page.color);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(icon: Icon(icon, color: Colors.white), onPressed: onTap),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 18 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(active ? 0.9 : 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _DetailListPage extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  const _DetailListPage({required this.title, required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) => _bullet(items[idx], color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text, Color color) {
    final isLight = color.computeLuminance() > 0.7;
    final chip = isLight ? const Color(0xFFE5E7EB) : color.withOpacity(0.2);
    final numColor = isLight ? const Color(0xFF1F2937) : color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: chip, shape: BoxShape.circle),
            child: Icon(Icons.check, color: numColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
