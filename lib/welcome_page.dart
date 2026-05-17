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
  bool _isDarkMode = false;

  Color get _welcomeBg1 => _isDarkMode ? Colors.black : const Color(0xFFFFF7EF);
  Color get _welcomeBg2 => _isDarkMode ? Colors.grey.shade900 : const Color(0xFFFFEFE5);
  Color get _welcomeBg3 => _isDarkMode ? Colors.black : Colors.white;
  Color get _cardColor => _isDarkMode ? Colors.grey.shade900 : Colors.white.withValues(alpha: 0.90);
  Color get _mainText => _isDarkMode ? Colors.white : Colors.black87;
  Color get _subText => _isDarkMode ? Colors.grey.shade300 : Colors.black54;

  String _languageName() {
    if (AppText.language == 'es') return 'Español';
    if (AppText.language == 'hi') return 'हिन्दी';
    if (AppText.language == 'pa') return 'ਪੰਜਾਬੀ';
    return 'English';
  }

  String _t(String en, String es, String hi, String pa) {
    if (AppText.language == 'es') return es;
    if (AppText.language == 'hi') return hi;
    if (AppText.language == 'pa') return pa;
    return en;
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
      MaterialPageRoute(
        builder: (_) => const TruckPage(isGuestMode: true),
      ),
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
              Text(
                _t(
                  'Choose Language',
                  'Elegir idioma',
                  'भाषा चुनें',
                  'ਭਾਸ਼ਾ ਚੁਣੋ',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
          title: Row(
            children: [
              const Icon(Icons.notifications, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Text(
                _t(
                  'Notifications',
                  'Notificaciones',
                  'सूचनाएं',
                  'ਸੂਚਨਾਵਾਂ',
                ),
              ),
            ],
          ),
          content: Text(
            _t(
              'Welcome to MapMyBite!\n\n'
                  '• Discover food trucks\n'
                  '• Order from home kitchens\n'
                  '• Track rewards & loyalty\n'
                  '• Get order updates',
              '¡Bienvenido a MapMyBite!\n\n'
                  '• Descubre food trucks\n'
                  '• Ordena de cocinas caseras\n'
                  '• Sigue recompensas y lealtad\n'
                  '• Recibe actualizaciones de pedidos',
              'MapMyBite में आपका स्वागत है!\n\n'
                  '• फूड ट्रक खोजें\n'
                  '• होम किचन से ऑर्डर करें\n'
                  '• रिवॉर्ड और लॉयल्टी ट्रैक करें\n'
                  '• ऑर्डर अपडेट पाएं',
              'MapMyBite ਵਿੱਚ ਤੁਹਾਡਾ ਸਵਾਗਤ ਹੈ!\n\n'
                  '• ਫੂਡ ਟਰੱਕ ਲੱਭੋ\n'
                  '• ਹੋਮ ਕਿਚਨ ਤੋਂ ਆਰਡਰ ਕਰੋ\n'
                  '• ਰਿਵਾਰਡ ਅਤੇ ਲੋਇਲਟੀ ਟ੍ਰੈਕ ਕਰੋ\n'
                  '• ਆਰਡਰ ਅਪਡੇਟ ਲਵੋ',
            ),
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _t('Close', 'Cerrar', 'बंद करें', 'ਬੰਦ ਕਰੋ'),
              ),
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
      onTap: () {
        setState(() {
          AppText.language = code;
        });

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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _welcomeBg1,
                  _welcomeBg2,
                  _welcomeBg3,
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
                  12,
                ),
                child: Column(
                  children: [
                    _topBar(),
                    _hero(float: float, pulse: pulse, wide: wide),
                    const SizedBox(height: 1),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _t(
                              'Welcome to ',
                              'Bienvenido a ',
                              'स्वागत है ',
                              'ਸਵਾਗਤ ਹੈ ',
                            ),
                            style: TextStyle(
                              color: _mainText,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const TextSpan(
                            text: 'MapMyBite',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t(
                        'How would you like to continue?',
                        '¿Cómo quieres continuar?',
                        'आप कैसे जारी रखना चाहते हैं?',
                        'ਤੁਸੀਂ ਕਿਵੇਂ ਜਾਰੀ ਰੱਖਣਾ ਚਾਹੁੰਦੇ ਹੋ?',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: _subText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      const SizedBox(height: 7),
                      _ownerCard(wide: false),
                    ],
                    const SizedBox(height: 7),
                    _guestCard(),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        text: _t(
                          'By continuing you agree to our ',
                          'Al continuar aceptas nuestros ',
                          'जारी रखकर आप हमारी ',
                          'ਜਾਰੀ ਰੱਖ ਕੇ ਤੁਸੀਂ ਸਾਡੇ ',
                        ),
                        style: TextStyle(
                          color: _subText,
                          fontSize: 10.5,
                        ),
                        children: [
                          TextSpan(
                            text: _t(
                              'Terms of Service',
                              'Términos de Servicio',
                              'सेवा शर्तें',
                              'ਸੇਵਾ ਸ਼ਰਤਾਂ',
                            ),
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: _t(' & ', ' y ', ' और ', ' ਅਤੇ '),
                          ),
                          TextSpan(
                            text: _t(
                              'Privacy Policy',
                              'Política de Privacidad',
                              'गोपनीयता नीति',
                              'ਪਰਾਈਵੇਸੀ ਨੀਤੀ',
                            ),
                            style: const TextStyle(
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
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
          onTap: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(10),
            decoration: _softBox(),
            child: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: _isDarkMode ? Colors.yellow : Colors.black87,
              size: 22,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _showNotifications,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: _softBox(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications,
                  color: Colors.deepOrange,
                  size: 22,
                ),
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
      height: wide ? 310 : 222,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MapLinesPainter()),
          ),
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
          Positioned(
            top: wide ? 45 : 34,
            left: 0,
            right: 0,
            child: Transform.scale(
              scale: pulse,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: wide ? 140 : 96,
                    height: wide ? 140 : 96,
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
                  SizedBox(height: wide ? 12 : 7),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Map',
                          style: TextStyle(
                            color: _mainText,
                            fontSize: wide ? 40 : 29,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: 'My',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontSize: wide ? 40 : 29,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: 'Bite',
                          style: TextStyle(
                            color: _mainText,
                            fontSize: wide ? 40 : 29,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: wide ? 4 : 2),
                  Text(
                    _t(
                      'Discover. Order. Enjoy.',
                      'Descubre. Ordena. Disfruta.',
                      'खोजें। ऑर्डर करें। आनंद लें।',
                      'ਲੱਭੋ। ਆਰਡਰ ਕਰੋ। ਆਨੰਦ ਲਵੋ।',
                    ),
                    style: TextStyle(
                      fontSize: wide ? 18 : 13.5,
                      fontWeight: FontWeight.w700,
                      color: _mainText,
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
      badgeText: _t(
        'FOR HUNGRY PEOPLE',
        'PARA CLIENTES',
        'ग्राहकों के लिए',
        'ਗਾਹਕਾਂ ਲਈ',
      ),
      title: _t(
        'Continue as\nCustomer',
        'Continuar como\nCliente',
        'ग्राहक के रूप में\nजारी रखें',
        'ਗਾਹਕ ਵਜੋਂ\nਜਾਰੀ ਰੱਖੋ',
      ),
      description: _t(
        'Find verified food trucks & home kitchens near you on a live map.',
        'Encuentra food trucks y cocinas caseras verificadas cerca de ti.',
        'अपने पास सत्यापित फूड ट्रक और होम किचन खोजें।',
        'ਆਪਣੇ ਨੇੜੇ ਵੈਰੀਫਾਈਡ ਫੂਡ ਟਰੱਕ ਅਤੇ ਹੋਮ ਕਿਚਨ ਲੱਭੋ।',
      ),
      art: _phoneArt(),
      chips: [
        _t('📍 Live Map', '📍 Mapa', '📍 मैप', '📍 ਨਕਸ਼ਾ'),
        _t('✅ Verified Spots', '✅ Verificado', '✅ सत्यापित', '✅ ਵੈਰੀਫਾਈਡ'),
        _t('🛒 Easy Orders', '🛒 Pedidos', '🛒 ऑर्डर', '🛒 ਆਰਡਰ'),
      ],
      buttonText: _t(
        '🍴  Find Food Near Me  →',
        '🍴  Buscar comida cerca  →',
        '🍴  पास में खाना खोजें  →',
        '🍴  ਨੇੜੇ ਖਾਣਾ ਲੱਭੋ  →',
      ),
      buttonColor: Colors.deepOrange,
      onTap: _openCustomer,
    );
  }

  Widget _ownerCard({required bool wide}) {
    return _roleCard(
      wide: wide,
      borderColor: Colors.green.shade100,
      badgeColor: Colors.green,
      badgeText: _t(
        'FOR FOOD BUSINESSES',
        'PARA NEGOCIOS',
        'फूड बिजनेस के लिए',
        'ਫੂਡ ਬਿਜ਼ਨਸ ਲਈ',
      ),
      title: _t(
        'Continue as\nOwner',
        'Continuar como\nDueño',
        'मालिक के रूप में\nजारी रखें',
        'ਮਾਲਕ ਵਜੋਂ\nਜਾਰੀ ਰੱਖੋ',
      ),
      description: _t(
        'List your truck or kitchen, manage menus, orders & payments.',
        'Publica tu negocio y administra menús, pedidos y pagos.',
        'अपना ट्रक या किचन जोड़ें, मेनू, ऑर्डर और पेमेंट संभालें।',
        'ਆਪਣਾ ਟਰੱਕ ਜਾਂ ਕਿਚਨ ਜੋੜੋ, ਮੀਨੂ, ਆਰਡਰ ਅਤੇ ਪੇਮੈਂਟ ਸੰਭਾਲੋ।',
      ),
      art: _tabletArt(),
      chips: [
        _t('📋 Menu Tools', '📋 Menú', '📋 मेनू', '📋 ਮੀਨੂ'),
        _t('📦 Orders & POS', '📦 POS', '📦 POS', '📦 POS'),
        _t('📈 Analytics', '📈 Datos', '📈 एनालिटिक्स', '📈 ਐਨਾਲਿਟਿਕਸ'),
      ],
      buttonText: _t(
        '🏪  Manage My Business  →',
        '🏪  Administrar negocio  →',
        '🏪  मेरा बिजनेस संभालें  →',
        '🏪  ਮੇਰਾ ਬਿਜ਼ਨਸ ਸੰਭਾਲੋ  →',
      ),
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
      padding: EdgeInsets.all(wide ? 18 : 9),
      decoration: BoxDecoration(
        color: _cardColor,
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
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 12 : 8,
                    vertical: wide ? 7 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '●  $badgeText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: wide ? 11.5 : 10.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: wide ? 92 : 48,
                height: wide ? 92 : 44,
                child: art,
              ),
            ],
          ),
          SizedBox(height: wide ? 8 : 1),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              wide ? title : title.replaceAll('\n', ' '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: wide ? 24 : 18,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: _mainText,
              ),
            ),
          ),
          SizedBox(height: wide ? 9 : 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              wide ? description : description.replaceAll(' on a live map.', '.'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _subText,
                height: 1.2,
                fontSize: wide ? 14 : 12.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: wide ? 12 : 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 5,
              runSpacing: 4,
              children: chips.map((chip) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 8 : 6,
                    vertical: wide ? 5 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    wide ? chip : _shortChip(chip),
                    style: TextStyle(
                      fontSize: wide ? 10.6 : 9.5,
                      fontWeight: FontWeight.w800,
                      color: _subText,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: wide ? 13 : 5),
          SizedBox(
            width: double.infinity,
            height: wide ? 52 : 38,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: wide ? 16 : 13.4,
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
        .replaceAll('Orders & POS', 'POS')
        .replaceAll('Verificado', 'Verif.')
        .replaceAll('Analytics', 'Stats');
  }

  Widget _guestCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _openGuest,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _cardColor,
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Text('👀', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(
                      'Continue as Guest',
                      'Continuar como invitado',
                      'गेस्ट के रूप में जारी रखें',
                      'ਗੈਸਟ ਵਜੋਂ ਜਾਰੀ ਰੱਖੋ',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.6,
                      fontWeight: FontWeight.w900,
                      color: _mainText,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _t(
                      'Browse nearby spots without signing up. Limited features.',
                      'Explora sin registrarte. Funciones limitadas.',
                      'साइन अप बिना देखें। सीमित सुविधाएं।',
                      'ਸਾਈਨ ਅਪ ਤੋਂ ਬਿਨਾਂ ਵੇਖੋ। ਸੀਮਿਤ ਫੀਚਰ।',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _subText,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      fontSize: 11.6,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 38,
              height: 38,
              child: FloatingActionButton.small(
                heroTag: 'guestBtn',
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 3,
                onPressed: _openGuest,
                child: const Icon(Icons.arrow_forward, size: 20),
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
          Icon(Icons.phone_android, color: Colors.deepOrange, size: 30),
          Positioned(
            top: 10,
            right: 11,
            child: Icon(Icons.location_on, color: Colors.blue, size: 11),
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
          Icon(Icons.tablet_mac, color: Colors.green, size: 30),
          Positioned(
            top: 8,
            right: 9,
            child: Text(
              '24',
              style: TextStyle(
                fontSize: 10,
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
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