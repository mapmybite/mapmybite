import 'package:shared_preferences/shared_preferences.dart';
class AppText {
  static String language = 'en';
  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    language = prefs.getString('app_language') ?? 'en';
  }

  static Future<void> setLanguage(String newLanguage) async {
    language = newLanguage;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', newLanguage);
  }

  static String welcome() {
    switch (language) {
      case 'es':
        return 'Bienvenido a MapMyBite';
      case 'hi':
        return 'MapMyBite में आपका स्वागत है';
      case 'pa':
        return 'MapMyBite ਵਿੱਚ ਤੁਹਾਡਾ ਸਵਾਗਤ ਹੈ';
      default:
        return 'Welcome to MapMyBite';
    }
  }

  static String continueText() {
    switch (language) {
      case 'es':
        return 'Elige cómo quieres continuar';
      case 'hi':
        return 'चुनें कि आप कैसे जारी रखना चाहते हैं';
      case 'pa':
        return 'ਚੁਣੋ ਤੁਸੀਂ ਕਿਵੇਂ ਜਾਰੀ ਰੱਖਣਾ ਚਾਹੁੰਦੇ ਹੋ';
      default:
        return 'Choose how you want to continue';
    }
  }

  static String customer() {
    switch (language) {
      case 'es':
        return 'Cliente';
      case 'hi':
        return 'ग्राहक';
      case 'pa':
        return 'ਗਾਹਕ';
      default:
        return 'Customer';
    }
  }

  static String owner() {
    switch (language) {
      case 'es':
        return 'Dueño';
      case 'hi':
        return 'मालिक';
      case 'pa':
        return 'ਮਾਲਕ';
      default:
        return 'Owner';
    }
  }
  static String languageLabel() {
    switch (language) {
      case 'es':
        return 'Idioma';
      case 'hi':
        return 'भाषा';
      case 'pa':
        return 'ਭਾਸ਼ਾ';
      default:
        return 'Language';
    }
  }

  static String chooseLanguage() {
    switch (language) {
      case 'es':
        return 'Elegir idioma';
      case 'hi':
        return 'भाषा चुनें';
      case 'pa':
        return 'ਭਾਸ਼ਾ ਚੁਣੋ';
      default:
        return 'Choose Language';
    }
  }
  static String map() {
    switch (language) {
      case 'es':
        return 'Mapa';
      case 'hi':
        return 'नक्शा';
      case 'pa':
        return 'ਨਕਸ਼ਾ';
      default:
        return 'Map';
    }
  }

  static String orders() {
    switch (language) {
      case 'es':
        return 'Pedidos';
      case 'hi':
        return 'ऑर्डर';
      case 'pa':
        return 'ਆਰਡਰ';
      default:
        return 'Orders';
    }
  }

  static String ownerPortal() {
    switch (language) {
      case 'es':
        return 'Panel de dueño';
      case 'hi':
        return 'ओनर पोर्टल';
      case 'pa':
        return 'ਓਨਰ ਪੋਰਟਲ';
      default:
        return 'Owner Portal';
    }
  }
  static String home() {
    switch (language) {
      case 'es':
        return 'Inicio';
      case 'hi':
        return 'होम';
      case 'pa':
        return 'ਘਰ';
      default:
        return 'Home';
    }
  }

  static String myLocation() {
    switch (language) {
      case 'es':
        return 'Mi ubicación';
      case 'hi':
        return 'मेरा स्थान';
      case 'pa':
        return 'ਮੇਰਾ ਸਥਾਨ';
      default:
        return 'My Location';
    }
  }

  static String foodTrucks() {
    switch (language) {
      case 'es':
        return 'Camiones de comida';
      case 'hi':
        return 'फूड ट्रक';
      case 'pa':
        return 'ਫੂਡ ਟਰੱਕ';
      default:
        return 'Food Trucks';
    }
  }

  static String homeKitchens() {
    switch (language) {
      case 'es':
        return 'Cocinas caseras';
      case 'hi':
        return 'होम किचन';
      case 'pa':
        return 'ਘਰੇਲੂ ਰਸੋਈ';
      default:
        return 'Home Kitchens';
    }
  }

  static String menuTitle() {
    switch (language) {
      case 'es':
        return 'Menú MapMyBite';
      case 'hi':
        return 'मैपमायबाइट मेन्यू';
      case 'pa':
        return 'ਮੈਪਮਾਈਬਾਈਟ ਮੈਨੂ';
      default:
        return 'MapMyBite Menu';
    }
  }
}
