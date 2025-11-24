import 'package:flutter/material.dart';
import 'dart:ui';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  late final List<_GuideCardData> _cards;

  @override
  void initState() {
    super.initState();
    _cards = [
      _GuideCardData(
        title: 'Umrah Guide',
        subtitle: 'Complete step-by-step guidance',
        description: 'Detailed pillars (Rukun), obligations (Wajib) and Sunnah practices for performing Umrah correctly.',
        color: const Color(0xFF67A9D5),
        icon: Icons.mosque,
        heroTag: 'guide_umrah',
        onTap: () => _openGuideDetail(
          type: 'Umrah',
          color: const Color(0xFF67A9D5),
          icon: Icons.mosque,
          heroTag: 'guide_umrah',
        ),
      ),
      _GuideCardData(
        title: 'Hajj Guide',
        subtitle: 'Comprehensive pilgrimage instructions',
        description: 'Structured overview of the multi-day Hajj journey including Wukuf, Tawaf, Sa\'i and stoning rituals.',
        color: const Color(0xFF3572A6),
        icon: Icons.menu_book,
        heroTag: 'guide_hajj',
        onTap: () => _openGuideDetail(
          type: 'Hajj',
          color: const Color(0xFF3572A6),
          icon: Icons.menu_book,
          heroTag: 'guide_hajj',
        ),
      ),
      _GuideCardData(
        title: 'Du\'a & Supplications',
        subtitle: 'Essential prayers collection',
        description: 'A curated list of du\'a to recite during different stages of your journey.',
        color: const Color(0xFF67A9D5),
        icon: Icons.auto_stories,
        heroTag: 'guide_dua',
        onTap: () => _showDuaSection(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Umrah & Hajj Guide',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
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
            child: _AnimatedGuideCard(data: _cards[index]),
          ),
        ),
      ),
    );
  }

  void _openGuideDetail({required String type, required Color color, required IconData icon, required String heroTag}) {
    final pages = <GuideDetailPageData>[
      GuideDetailPageData(title: 'Rukun (Pillars)', items: type == 'Umrah' ? _getUmrahRukun() : _getHajjRukun(), color: color),
      GuideDetailPageData(title: 'Wajib (Obligations)', items: type == 'Umrah' ? _getUmrahWajib() : _getHajjWajib(), color: color),
      GuideDetailPageData(title: 'Sunnah (Recommended)', items: type == 'Umrah' ? _getUmrahSunnah() : _getHajjSunnah(), color: color),
    ];
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: GuideDetailScreen(heroTag: heroTag, title: '$type Guide', icon: icon, color: color, pages: pages),
        ),
      ),
    );
  }
}


class _GuideCardData {
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final String heroTag;
  const _GuideCardData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.heroTag,
  });
}

class _AnimatedGuideCard extends StatefulWidget {
  final _GuideCardData data;
  const _AnimatedGuideCard({required this.data});

  @override
  State<_AnimatedGuideCard> createState() => _AnimatedGuideCardState();
}

// Detail data model for paged guide content
class GuideDetailPageData {
  final String title;
  final List<String> items;
  final Color color;
  const GuideDetailPageData({required this.title, required this.items, required this.color});
}

class GuideDetailScreen extends StatefulWidget {
  final String heroTag;
  final String title;
  final IconData icon;
  final Color color;
  final List<GuideDetailPageData> pages;
  const GuideDetailScreen({
    super.key,
    required this.heroTag,
    required this.title,
    required this.icon,
    required this.color,
    required this.pages,
  });
  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
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

class _AnimatedGuideCardState extends State<_AnimatedGuideCard> with SingleTickerProviderStateMixin {
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

  // Deprecated: old section card builder removed after full-screen redesign

  // --- Data Methods ---
  List<String> _getUmrahRukun() {
    return [
      'Ihram – Intention to perform Umrah from the Miqat',
      'Tawaf – Circumambulating the Kaabah seven times',
      'Sa\'i – Walking between Safa and Marwah seven times',
      'Tahallul – Cutting or shaving hair after Sa\'i',
      'Tertib – Performing the steps in correct order',
    ];
  }

  List<String> _getUmrahWajib() {
    return [
      'Wearing Ihram from Miqat',
      'Avoiding all prohibited acts during Ihram',
    ];
  }

  List<String> _getUmrahSunnah() {
    return [
      'Performing Tawaf arrival (Tawaf Qudum)',
      'Performing Sunnah prayers after Tawaf',
      'Drinking Zamzam water and praying at Multazam',
    ];
  }

  List<String> _getHajjRukun() {
    return [
      'Ihram – With intention from Miqat',
      'Wukuf at Arafah – From noon to sunset on 9th Dhul Hijjah',
      'Tawaf Ifadah – After returning from Mina',
      'Sa\'i – Between Safa and Marwah',
      'Tahallul – Cutting or shaving hair',
      'Tertib – Correct order of performance',
    ];
  }

  List<String> _getHajjWajib() {
    return [
      'Ihram from Miqat',
      'Staying overnight in Muzdalifah',
      'Staying overnight in Mina',
      'Throwing the Jamrah',
      'Avoiding all forbidden acts during Ihram',
      'Tawaf Wada\' before leaving Makkah',
    ];
  }

  List<String> _getHajjSunnah() {
    return [
      'Performing Tawaf Qudum upon arrival',
      'Touching Hajar Aswad',
      'Performing Sunnah prayers after Tawaf',
      'Making frequent du\'a throughout the journey',
    ];
  }

  // --- Du'a Section ---
  void _showDuaSection(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Du\'a section coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
 
