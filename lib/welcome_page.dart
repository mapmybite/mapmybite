import 'dart:math';
import 'package:flutter/material.dart';
import 'app_text.dart';
import 'truck_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  String _languageName() {
    if (AppText.language == 'es') return 'Español';
    if (AppText.language == 'hi') return 'हिन्दी';
    if (AppText.language == 'pa') return 'ਪੰਜਾਬੀ';
    return 'English';
  }

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _openCustomer() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TruckPage()),
    );
  }

  void _openOwner() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const TruckPage(openOwnerPortalOnStart: true),
      ),
    );
  }

  void _openGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TruckPage()),
    );
  }
  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _languageTile('🇺🇸', 'English', 'en'),
              _languageTile('🇪🇸', 'Español', 'es'),
              _languageTile('🇮🇳', 'हिन्दी', 'hi'),
              _languageTile('🇮🇳', 'ਪੰਜਾਬੀ', 'pa'),
            ],
          ),
        );
      },
    );
  }
  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text('Notifications'),
            ],
          ),
          content: const Text(
            'Welcome to MapMyBite!\n\n'
                '• Discover food trucks\n'
                '• Order from home kitchens\n'
                '• Track rewards & loyalty\n'
                '• Get order updates',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _languageTile(String flag, String title, String code) {
    return ListTile(
      leading: Text(flag),
      title: Text(title),
      onTap: () async {
        setState(() {
          AppText.language = code;
        });

        if (!mounted) return;
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool wide = size.width >= 700 || size.width > size.height;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_floatController, _pulseController]),
        builder: (context, child) {
          final float = sin(_floatController.value * pi) * 8;
          final pulse = 1 + (_pulseController.value * 0.035);

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF7EF),
                  Color(0xFFFFEFE5),
                  Color(0xFFFFFFFF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 42 : 14,
                  8,
                  wide ? 42 : 14,
                  14,
                ),
                child: Column(
                  children: [
                    _topBar(),
                    _hero(
                      float: float,
                      pulse: pulse,
                      wide: wide,
                    ),
                    const SizedBox(height: 2),
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Welcome to ',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(
                            text: 'MapMyBite',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'How would you like to continue?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (wide)
                      Row(
                        children: [
                          Expanded(child: _customerCard(wide: true)),
                          const SizedBox(width: 14),
                          Expanded(child: _ownerCard(wide: true)),
                        ],
                      )
                    else ...[
                      _customerCard(wide: false),
                      const SizedBox(height: 9),
                      _ownerCard(wide: false),
                    ],

                    const SizedBox(height: 9),
                    _guestCard(),
                    const SizedBox(height: 9),
                    const Text.rich(
                      TextSpan(
                        text: 'By continuing you agree to our ',
                        style: TextStyle(color: Colors.black54, fontSize: 11),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _showLanguageSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: _softBox(),
            child: Row(
              children: [
                const Icon(Icons.language, color: Colors.blue, size: 20),
                const SizedBox(width: 7),
                Text(
                  _languageName(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _showNotifications,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: _softBox(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications,
                    color: Colors.deepOrange, size: 22),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.deepOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero({
    required double float,
    required double pulse,
    required bool wide,
  }) {
    return SizedBox(
      height: wide ? 310 : 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MapLinesPainter()),
          ),

          // LEFT SIDE ICONS
          Positioned(
            left: wide ? 55 : 10,
            top: wide ? 85 + float : 74 + float,
            child: _mapPin(),
          ),
          Positioned(
            left: wide ? 35 : 8,
            bottom: wide ? 35 + float : 20 + float,
            child: _foodTruck(),
          ),
          Positioned(
            left: wide ? 145 : 52,
            bottom: wide ? 92 - float : 76 - float,
            child: _foodBubble('🍔', wide ? 56 : 44),
          ),

          // RIGHT SIDE ICONS
          Positioned(
            right: wide ? 150 : 48,
            top: wide ? 80 - float : 70 - float,
            child: _foodBubble('🌮', wide ? 54 : 42),
          ),
          Positioned(
            right: wide ? 55 : 8,
            top: wide ? 145 + float : 118 + float,
            child: _homeKitchen(),
          ),
          Positioned(
            right: wide ? 70 : 14,
            bottom: wide ? 30 - float : 18 - float,
            child: _foodBubble('🧋', wide ? 52 : 42),
          ),

          // CENTER CLEAN LOGO - always on top
          Positioned(
            top: wide ? 45 : 36,
            left: 0,
            right: 0,
            child: Transform.scale(
              scale: pulse,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: wide ? 140 : 100,
                    height: wide ? 140 : 100,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withValues(alpha: 0.22),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/images/mapmybite_logo.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  SizedBox(height: wide ? 12 : 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Map',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: wide ? 40 : 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: 'My',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontSize: wide ? 40 : 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: 'Bite',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: wide ? 40 : 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: wide ? 4 : 2),
                  Text(
                    'Discover. Order. Enjoy.',
                    style: TextStyle(
                      fontSize: wide ? 18 : 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
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

  Widget _customerCard({required bool wide}) {
    return _roleCard(
      wide: wide,
      borderColor: Colors.deepOrange.shade100,
      badgeColor: Colors.deepOrange,
      badgeText: 'FOR HUNGRY PEOPLE',
      title: 'Continue as\nCustomer',
      description: 'Find verified food trucks & home kitchens near you on a live map.',
      art: _phoneArt(),
      chips: const ['📍 Live Map', '✅ Verified Spots', '🛒 Easy Orders'],
      buttonText: '🍴  Find Food Near Me  →',
      buttonColor: Colors.deepOrange,
      onTap: _openCustomer,
    );
  }

  Widget _ownerCard({required bool wide}) {
    return _roleCard(
      wide: wide,
      borderColor: Colors.green.shade100,
      badgeColor: Colors.green,
      badgeText: 'FOR FOOD BUSINESSES',
      title: 'Continue as\nOwner',
      description: 'List your truck or kitchen, manage menus, orders & payments.',
      art: _tabletArt(),
      chips: const ['📋 Menu Tools', '📦 Orders & POS', '📈 Analytics'],
      buttonText: '🏪  Manage My Business  →',
      buttonColor: Colors.green,
      onTap: _openOwner,
    );
  }

  Widget _roleCard({
    required bool wide,
    required Color borderColor,
    required Color badgeColor,
    required String badgeText,
    required String title,
    required String description,
    required Widget art,
    required List<String> chips,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(wide ? 18 : 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 12 : 9,
                  vertical: wide ? 7 : 5,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '●  $badgeText',
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: wide ? 11.5 : 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: wide ? 92 : 56,
                height: wide ? 92 : 52,
                child: art,
              ),
            ],
          ),
          SizedBox(height: wide ? 8 : 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  wide ? title : title.replaceAll('\n', ' '),
                  style: TextStyle(
                    fontSize: wide ? 24 : 19,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: wide ? 9 : 3),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              wide ? description : description.replaceAll(' on a live map.', '.'),
              style: TextStyle(
                color: Colors.black54,
                height: 1.28,
                fontSize: wide ? 14 : 12.7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: wide ? 12 : 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: chips.map((chip) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 8 : 7,
                    vertical: wide ? 5 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    wide ? chip : _shortChip(chip),
                    style: TextStyle(
                      fontSize: wide ? 10.6 : 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.black54,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: wide ? 13 : 6),
          SizedBox(
            width: double.infinity,
            height: wide ? 52 : 40,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 7,
                shadowColor: buttonColor.withValues(alpha: 0.30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: wide ? 16 : 14.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortChip(String chip) {
    return chip
        .replaceAll('Verified Spots', 'Verified')
        .replaceAll('Easy Orders', 'Orders')
        .replaceAll('Menu Tools', 'Menu')
        .replaceAll('Orders & POS', 'POS');
  }

  Widget _guestCard() {
    return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _openGuest,
        child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 11,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text('👀', style: TextStyle(fontSize: 23)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Browse nearby spots without signing up. Limited features.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    fontSize: 12.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: FloatingActionButton.small(
              heroTag: 'guestBtn',
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 3,
              onPressed: _openGuest,
              child: const Icon(Icons.arrow_forward, size: 21),
            ),
          ),
        ],
      ),
        ),
    );
  }

  Widget _phoneArt() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Icon(Icons.phone_android, color: Colors.deepOrange, size: 34),
          Positioned(
            top: 13,
            right: 15,
            child: Icon(Icons.location_on, color: Colors.blue, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _tabletArt() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Icon(Icons.tablet_mac, color: Colors.green, size: 34),
          Positioned(
            top: 10,
            right: 12,
            child: Text('24', style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _foodBubble(String emoji, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.14),
            blurRadius: 14,
          ),
        ],
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.47)),
      ),
    );
  }

  Widget _foodTruck() {
    return Container(
      width: 74,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.16),
            blurRadius: 16,
          ),
        ],
      ),
      child: const Center(
        child: Text('🚚', style: TextStyle(fontSize: 32)),
      ),
    );
  }

  Widget _homeKitchen() {
    return Container(
      width: 68,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.15),
            blurRadius: 16,
          ),
        ],
      ),
      child: const Center(
        child: Text('🏪', style: TextStyle(fontSize: 30)),
      ),
    );
  }

  Widget _mapPin() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.14),
            blurRadius: 14,
          ),
        ],
      ),
      child: const Icon(Icons.location_on, color: Colors.deepOrange, size: 34),
    );
  }

  BoxDecoration _softBox() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

class _MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.09)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final bluePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.065)
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(-20, size.height * 0.32)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.08,
        size.width + 20,
        size.height * 0.25,
      );

    final path2 = Path()
      ..moveTo(size.width + 20, size.height * 0.03)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.45,
        size.width * 0.95,
        size.height,
      );

    canvas.drawPath(path1, roadPaint);
    canvas.drawPath(path2, bluePaint);

    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.032)
      ..strokeWidth = 1.6;

    for (double x = 0; x < size.width; x += 65) {
      canvas.drawLine(Offset(x, 0), Offset(x + 45, size.height), gridPaint);
    }

    for (double y = 18; y < size.height; y += 55) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 34), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}