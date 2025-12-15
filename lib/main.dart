import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'DoctorLoginPage.dart';
import 'AdminLoginPage.dart';
import 'PatientLoginPage.dart';
import 'ContactUsPage.dart';
import 'patient_tutorial.dart';
import 'PatientDashboardPage.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint('Notification permission: ${settings.authorizationStatus}');

  final token = await messaging.getToken();
  debugPrint('FCM device token: $token');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'English';

  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        final title = notification.title ?? 'New notification';
        final body = notification.body ?? '';

        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('$title\n$body')),
          );
        }
      }
    });
  }

  Future<bool> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final key = "tutorial_completed_${user.uid}";
    return prefs.getBool(key) ?? false;
  }

  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _changeLanguage(String? selectedLang) {
    if (selectedLang != null) {
      setState(() {
        _language = selectedLang;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = _language == 'Arabic';

    return MaterialApp(
      navigatorKey: _MyAppState.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: isArabic ? 'نظام شفاء' : 'Heal System',

      locale: isArabic ? const Locale('ar') : const Locale('en'),
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          if (!authSnap.hasData) {
            return HealSystem(
              title: isArabic ? 'نظام شفاء' : 'Heal System',
              onThemeChanged: _toggleTheme,
              onLanguageChanged: _changeLanguage,
              currentLanguage: _language,
              isDarkMode: _themeMode == ThemeMode.dark,
            );
          }
          return FutureBuilder<bool>(
            future: _checkTutorial(),
            builder: (context, tutSnap) {
              if (!tutSnap.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final completed = tutSnap.data ?? false;

              if (!completed) {
                return const PatientTutorialPage();
              }

              return const PatientDashboardPage();
            },
          );
        },
      ),
    );
  }
}

class HealSystem extends StatefulWidget {
  final String title;
  final void Function(bool) onThemeChanged;
  final void Function(String?) onLanguageChanged;
  final String currentLanguage;
  final bool isDarkMode;

  const HealSystem({
    super.key,
    required this.title,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLanguage,
    required this.isDarkMode,
  });

  @override
  State<HealSystem> createState() => _HealSystemState();
}

class _HealSystemState extends State<HealSystem> {
  @override
  Widget build(BuildContext context) {
    final bool isArabic = widget.currentLanguage == 'Arabic';

    final welcomeText       = isArabic ? 'أهلاً بك!' : 'Welcome!';
    final chooseLoginText   = isArabic ? 'اختر نوع تسجيل الدخول:' : 'Choose login type:';
    final doctorLoginText   = isArabic ? 'تسجيل دخول دكتور' : 'Doctor Login';
    final adminLoginText    = isArabic ? 'تسجيل دخول مشرف' : 'Admin Login';
    final contactUsText     = isArabic ? 'تواصل معنا' : 'Contact Us';
    final changeLangText    = isArabic ? 'تغيير اللغة' : 'Change Language';
    final darkModeText      = isArabic ? 'الوضع الداكن' : 'Dark Mode';

    final welcomeTitle      = isArabic ? 'مرحباً بك في نظام شفاء' : 'Welcome to Heal System';
    final welcomeDesc       = isArabic
        ? 'مساحة رعاية لكل امرأة ولكل رحلة حمل. تابعي صحتك، تواصلي مع الأطباء، وأشعري بالدعم في كل خطوة.'
        : 'A caring space for every woman and every pregnancy journey. Track health, connect with doctors, and feel supported every step of the way.';
    final getStartedText    = isArabic ? 'ابدئي الآن' : 'Get Started';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8A2BE2), Color(0xFFD8B7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    welcomeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chooseLoginText,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: Text(doctorLoginText),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorLoginPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(adminLoginText),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminLoginPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_page),
              title: Text(contactUsText),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContactUsPage(
                      currentLanguage: widget.currentLanguage,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(changeLangText),
              trailing: DropdownButton<String>(
                value: widget.currentLanguage,
                items: const [
                  DropdownMenuItem(
                    value: 'English',
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: 'Arabic',
                    child: Text('العربية'),
                  ),
                ],
                onChanged: widget.onLanguageChanged,
              ),
            ),
            SwitchListTile(
              title: Text(darkModeText),
              value: widget.isDarkMode,
              onChanged: widget.onThemeChanged,
              secondary: const Icon(Icons.brightness_6),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFFFFB6C1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(90)),
                  child: Image(
                    image: AssetImage('images/logo.png'),
                    height: 120,
                    width: 120,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                welcomeTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8A2BE2),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  welcomeDesc,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A2BE2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientLoginPage(
                        currentLanguage: widget.currentLanguage,
                      ),
                    ),
                  );
                },
                child: Text(
                  getStartedText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
