import 'package:flutter/material.dart';
import 'truck_page.dart';
import 'app_text.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String _language = 'en';

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: const Text('🇺🇸'),
                title: const Text('English'),
                onTap: () {
                  setState(() {
                    _language = 'en';
                    AppText.language = _language;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇪🇸'),
                title: const Text('Español'),
                onTap: () {
                  setState(() {
                    _language = 'es';
                    AppText.language = _language;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇮🇳'),
                title: const Text('हिन्दी'),
                onTap: () {
                  setState(() {
                    _language = 'hi';
                    AppText.language = _language;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇮🇳'),
                title: const Text('ਪੰਜਾਬੀ'),
                onTap: () {
                  setState(() {
                    _language = 'pa';
                    AppText.language = _language;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _showLanguageSheet(context),
              icon: const Icon(Icons.language, size: 18),
              label: Text(
                _language == 'en'
                    ? 'English'
                    : _language == 'es'
                    ? 'Español'
                    : _language == 'hi'
                    ? 'हिन्दी'
                    : 'ਪੰਜਾਬੀ',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [

            Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 96,
                        width: 96,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fastfood,
                          size: 48,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppText.welcome(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppText.continueText(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _RoleCard(
                        icon: Icons.person,
                        title: _language == 'en'
                            ? 'Continue as Customer'
                            : _language == 'es'
                            ? 'Continuar como cliente'
                            : _language == 'hi'
                            ? 'ग्राहक के रूप में जारी रखें'
                            : 'ਗਾਹਕ ਵਜੋਂ ਜਾਰੀ ਰੱਖੋ',
                        subtitle:
                        'Browse food trucks and home kitchens, build orders, and track your orders.',
                        buttonText: AppText.customer(),
                        buttonColor: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TruckPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _RoleCard(
                        icon: Icons.storefront,
                        title: _language == 'en'
                            ? 'Continue as Owner'
                            : _language == 'es'
                            ? 'Continuar como dueño'
                            : _language == 'hi'
                            ? 'मालिक के रूप में जारी रखें'
                            : 'ਮਾਲਕ ਵਜੋਂ ਜਾਰੀ ਰੱਖੋ',
                        subtitle:
                        'Manage your profile, menu, incoming orders, POS, and business tools.',
                        buttonText: AppText.owner(),
                        buttonColor: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TruckPage(
                                openOwnerPortalOnStart: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: buttonColor.withOpacity(0.12),
            child: Icon(
              icon,
              color: buttonColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}