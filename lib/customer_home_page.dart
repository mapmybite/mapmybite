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
  Future<void> _stopChuchu() async {
    await _flutterTts.stop();
  }
  Future<void> _speakChuchuMessage({
    required String en,
    required String es,
    required String hi,
    required String pa,
  }) async {
    String message;

    switch (AppText.language) {
      case 'es':
        message = es;
        await _flutterTts.setLanguage('es-ES');
        break;
      case 'hi':
        message = hi;
        await _flutterTts.setLanguage('hi-IN');
        break;
      case 'pa':
        message = pa;
        await _flutterTts.setLanguage('pa-IN');
        break;
      default:
        message = en;
        await _flutterTts.setLanguage('en-US');
    }

    await _flutterTts.setSpeechRate(0.38);
    await _flutterTts.setPitch(1.35);
    await _flutterTts.speak(message);
  }
  Future<void> _readCurrentScreen() async {
    if (_selectedIndex == 0 &&
        !TruckPage.listViewNotifier.value) {
      await _speakChuchuMessage(
        en: 'You are on the Map page. Here you can search for food trucks, home kitchens, open places, favorites, and nearby food.',
        es: 'Estás en la página del mapa. Aquí puedes buscar food trucks, cocinas caseras, lugares abiertos, favoritos y comida cercana.',
        hi: 'आप मैप पेज पर हैं। यहाँ आप फूड ट्रक, होम किचन, खुले हुए स्थान, पसंदीदा जगह और पास का खाना खोज सकते हैं।',
        pa: 'ਤੁਸੀਂ ਨਕਸ਼ਾ ਪੇਜ ਤੇ ਹੋ। ਇੱਥੇ ਤੁਸੀਂ ਫੂਡ ਟਰੱਕ, ਘਰੇਲੂ ਰਸੋਈਆਂ, ਖੁੱਲ੍ਹੀਆਂ ਥਾਵਾਂ, ਮਨਪਸੰਦ ਅਤੇ ਨੇੜੇ ਦਾ ਖਾਣਾ ਲੱਭ ਸਕਦੇ ਹੋ।',
      );
    } else if (_selectedIndex == 0 &&
        TruckPage.listViewNotifier.value) {
      await _speakChuchuMessage(
        en: 'You are viewing the food list. Here you can browse nearby food trucks and home kitchens in list mode.',
        es: 'Estás viendo la lista de comida. Aquí puedes explorar food trucks y cocinas caseras cercanas en modo lista.',
        hi: 'आप फूड लिस्ट देख रहे हैं। यहाँ आप पास के फूड ट्रक और होम किचन लिस्ट मोड में देख सकते हैं।',
        pa: 'ਤੁਸੀਂ ਖਾਣੇ ਦੀ ਲਿਸਟ ਵੇਖ ਰਹੇ ਹੋ। ਇੱਥੇ ਤੁਸੀਂ ਨੇੜਲੇ ਫੂਡ ਟਰੱਕ ਅਤੇ ਘਰੇਲੂ ਰਸੋਈਆਂ ਲਿਸਟ ਮੋਡ ਵਿੱਚ ਵੇਖ ਸਕਦੇ ਹੋ।',
      );
    } else if (_selectedIndex == 1) {
      await _speakChuchuMessage(
        en: 'You are on the Rewards page. Rewards and loyalty points will be shown here soon.',
        es: 'Estás en la página de recompensas. Tus recompensas y puntos aparecerán aquí pronto.',
        hi: 'आप रिवॉर्ड पेज पर हैं। आपके रिवॉर्ड और लॉयल्टी पॉइंट यहाँ जल्द दिखेंगे।',
        pa: 'ਤੁਸੀਂ ਰਿਵਾਰਡ ਪੇਜ ਤੇ ਹੋ। ਤੁਹਾਡੇ ਰਿਵਾਰਡ ਅਤੇ ਲੋਇਲਟੀ ਪੁਆਇੰਟ ਜਲਦੀ ਇੱਥੇ ਦਿਖਣਗੇ।',
      );
    } else if (_selectedIndex == 2) {
      await _speakChuchuMessage(
        en: 'You are on the Orders page. Here you can check your food order history and order status.',
        es: 'Estás en la página de pedidos. Aquí puedes revisar tu historial de pedidos y el estado de tus órdenes.',
        hi: 'आप ऑर्डर पेज पर हैं। यहाँ आप अपने खाने के ऑर्डर की हिस्ट्री और स्टेटस देख सकते हैं।',
        pa: 'ਤੁਸੀਂ ਆਰਡਰ ਪੇਜ ਤੇ ਹੋ। ਇੱਥੇ ਤੁਸੀਂ ਆਪਣੇ ਖਾਣੇ ਦੇ ਆਰਡਰ ਦੀ ਹਿਸਟਰੀ ਅਤੇ ਸਟੇਟਸ ਵੇਖ ਸਕਦੇ ਹੋ।',
      );
    } else {
      await _speakChuchuMessage(
        en: 'You are on the Profile page. Here you can manage favorites, language, help, and account options.',
        es: 'Estás en la página de perfil. Aquí puedes manejar favoritos, idioma, ayuda y opciones de cuenta.',
        hi: 'आप प्रोफाइल पेज पर हैं। यहाँ आप पसंदीदा, भाषा, मदद और अकाउंट विकल्प संभाल सकते हैं।',
        pa: 'ਤੁਸੀਂ ਪ੍ਰੋਫਾਈਲ ਪੇਜ ਤੇ ਹੋ। ਇੱਥੇ ਤੁਸੀਂ ਮਨਪਸੰਦ, ਭਾਸ਼ਾ, ਮਦਦ ਅਤੇ ਅਕਾਊਂਟ ਵਿਕਲਪ ਸੰਭਾਲ ਸਕਦੇ ਹੋ।',
      );
    }
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
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            builder: (context) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Chuchu Assistant',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 18),

                      ListTile(
                        leading: const Icon(Icons.record_voice_over),
                        title: const Text('Welcome Help'),
                        onTap: () {
                          Navigator.pop(context);
                          _speakChuchu();
                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.map),
                        title: const Text('Explain Map'),
                        onTap: () async {
                          Navigator.pop(context);

                          await _speakChuchuMessage(
                            en: 'The map helps you discover nearby food trucks and home kitchens.',
                            es: 'El mapa te ayuda a descubrir food trucks y cocinas caseras cerca de ti.',
                            hi: 'मैप आपको पास के फूड ट्रक और होम किचन ढूंढने में मदद करता है।',
                            pa: 'ਨਕਸ਼ਾ ਤੁਹਾਨੂੰ ਨੇੜਲੇ ਫੂਡ ਟਰੱਕ ਅਤੇ ਘਰੇਲੂ ਰਸੋਈਆਂ ਲੱਭਣ ਵਿੱਚ ਮਦਦ ਕਰਦਾ ਹੈ।',
                          );
                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: const Text('Explain Orders'),
                        onTap: () async {
                          Navigator.pop(context);

                          await _speakChuchuMessage(
                            en: 'Orders page helps you track your current and previous food orders.',
                            es: 'La página de pedidos te ayuda a ver tus pedidos actuales y anteriores.',
                            hi: 'ऑर्डर पेज आपको अपने नए और पुराने खाने के ऑर्डर देखने में मदद करता है।',
                            pa: 'ਆਰਡਰ ਪੇਜ ਤੁਹਾਨੂੰ ਆਪਣੇ ਨਵੇਂ ਅਤੇ ਪੁਰਾਣੇ ਖਾਣੇ ਦੇ ਆਰਡਰ ਵੇਖਣ ਵਿੱਚ ਮਦਦ ਕਰਦਾ ਹੈ।',
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.chrome_reader_mode),
                        title: const Text('Read This Screen'),
                        onTap: () async {
                          Navigator.pop(context);
                          await _readCurrentScreen();
                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.stop_circle),
                        title: const Text('Stop Talking'),
                        onTap: () async {
                          Navigator.pop(context);
                          await _stopChuchu();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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