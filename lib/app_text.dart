class AppText {
  static String language = 'en';

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
}