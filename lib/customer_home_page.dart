import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'app_text.dart';

import 'truck_page.dart';
import 'customer_order_history_page.dart';
import 'customer_profile_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;
  int _mapRefreshKey = 0;
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _speakChuchu() async {
    String message;

    switch (AppText.language) {
      case 'es':
        message =
        'Hola, soy Chuchu. Puedo ayudarte a encontrar comida, revisar tus órdenes y leer la app en voz alta.';
        await _flutterTts.setLanguage('es-ES');
        break;
      case 'hi':
        message =
        'नमस्ते, मैं चूचू हूँ। मैं खाना ढूंढने, ऑर्डर देखने और ऐप पढ़ने में आपकी मदद कर सकती हूँ।';
        await _flutterTts.setLanguage('hi-IN');
        break;
      case 'pa':
        message =
        'ਸਤ ਸ੍ਰੀ ਅਕਾਲ, ਮੈਂ ਚੂਚੂ ਹਾਂ। ਮੈਂ ਖਾਣਾ ਲੱਭਣ, ਆਰਡਰ ਵੇਖਣ ਅਤੇ ਐਪ ਪੜ੍ਹਣ ਵਿੱਚ ਤੁਹਾਡੀ ਮਦਦ ਕਰ ਸਕਦੀ ਹਾਂ।';
        await _flutterTts.setLanguage('pa-IN');
        break;
      default:
        message =
        'Hi, I am Chuchu. I can help you find food, check your orders, and read the app out loud.';
        await _flutterTts.setLanguage('en-US');
    }

    await _flutterTts.setSpeechRate(0.38);
    await _flutterTts.setPitch(1.35);
    await _flutterTts.speak(message);
  }

  List<Widget> get _pages => [
    TruckPage(key: ValueKey(_mapRefreshKey)),
    const _RewardsPlaceholderPage(),
    const CustomerOrderHistoryPage(),
    const CustomerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: GestureDetector(
        onTap: _speakChuchu,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.95, end: 1.05),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),

              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                backgroundImage:
                const AssetImage('assets/images/chuchu.png'),
              ),

              Positioned(
                top: -34,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Need help?',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: (index) {
          setState(() {
            if (index == 0) {
              _mapRefreshKey++;
            }

            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _RewardsPlaceholderPage extends StatelessWidget {
  const _RewardsPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Rewards coming soon'),
    );
  }
}

class _OrdersPlaceholderPage extends StatelessWidget {
  const _OrdersPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Orders coming soon'),
    );
  }
}

class _ProfilePlaceholderPage extends StatelessWidget {
  const _ProfilePlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile coming soon'),
    );
  }
}