import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'booking_screen.dart';
import 'bookings_screen.dart';
import 'notifications_screen.dart';
import 'plans_screen.dart';
import 'help_screen.dart';
import 'admin_screen.dart';
import 'receipt_screen.dart';
import 'forgot_password_screen.dart';
import 'language_service.dart';
import 'qr_scanner_screen.dart';
import 'payment_methods_screen.dart';
import 'add_card_screen.dart';
import 'directions.dart';
import 'airport_directions_screen.dart';
import 'railway_directions_screen.dart';
import 'l10n/strings.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF2E3449),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const SmartSecureApp());
}

class SmartSecureApp extends StatelessWidget {
  const SmartSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.notifier,
      builder: (_, locale, __) => _buildApp(locale),
    );
  }

  Widget _buildApp(Locale locale) {
    return MaterialApp(
      title: 'SmartSecure',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF2E3449),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5A623),
          secondary: Color(0xFF00C9A7),
          surface: Color(0xFF434A64),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF434A64),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x12FFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x12FFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFF5A623), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE05A7A)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE05A7A), width: 1.5),
          ),
          hintStyle: GoogleFonts.dmSans(color: const Color(0xFF6A7090), fontSize: 14),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Color(0xFFEEF0F6)),
          titleTextStyle: GoogleFonts.syne(
            fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/':         (_) => const SplashScreen(),
        '/login':    (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home':     (_) => const HomeScreen(),
        '/profile':  (_) => const ProfileScreen(),
        '/wallet':   (_) => const WalletScreen(),
        '/book':          (_) => const BookingScreen(),
        '/bookings':      (_) => const BookingsScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/plans':         (_) => const PlansScreen(),
        '/help':          (_) => const HelpScreen(),
        '/admin':           (_) => const AdminScreen(),
        '/receipt':         (_) => const ReceiptScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/qr-scanner':      (_) => const QrScannerScreen(),
        '/payment-methods': (_) => const PaymentMethodsScreen(),
        '/add-card':        (_) => const AddCardScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/directions') {
          final args = settings.arguments as Map<String, dynamic>?;
          final stepsRaw = args?['steps'] as List<dynamic>?;
          final steps = stepsRaw
                  ?.map((e) => e is DirectionStep ? e : null)
                  .whereType<DirectionStep>()
                  .toList() ??
              const <DirectionStep>[
                DirectionStep(icon: Icons.login_rounded, label: 'Enter the mall'),
                DirectionStep(icon: Icons.straight_rounded, label: 'Walk straight to the locker zone'),
                DirectionStep(icon: Icons.lock_rounded, label: 'Your locker is ahead'),
              ];

          return MaterialPageRoute<void>(
            builder: (_) => IndoorDirectionsScreen(
              locationName: args?['locationName']?.toString() ?? 'Locker Location',
              mallName: args?['mallName']?.toString() ?? 'Selected Mall',
              lockerId: args?['lockerId']?.toString() ?? 'N/A',
              steps: steps,
            ),
            settings: settings,
          );
        }

        if (settings.name == '/airport-directions') {
          final args = settings.arguments as Map<String, dynamic>?;
          final stepsRaw = args?['steps'] as List<dynamic>?;
          final steps = stepsRaw
                  ?.map((e) => e is DirectionStep ? e : null)
                  .whereType<DirectionStep>()
                  .toList() ??
              defaultAirportSteps();

          return MaterialPageRoute<void>(
            builder: (_) => AirportDirectionsScreen(
              terminalName: args?['terminalName']?.toString() ?? 'Terminal',
              airportName:  args?['airportName']?.toString()  ?? 'Airport',
              lockerId:     args?['lockerId']?.toString()     ?? 'N/A',
              steps: steps,
            ),
            settings: settings,
          );
        }

        if (settings.name == '/railway-directions') {
          final args = settings.arguments as Map<String, dynamic>?;
          final stepsRaw = args?['steps'] as List<dynamic>?;
          final steps = stepsRaw
                  ?.map((e) => e is DirectionStep ? e : null)
                  .whereType<DirectionStep>()
                  .toList() ??
              defaultRailwaySteps();

          return MaterialPageRoute<void>(
            builder: (_) => RailwayDirectionsScreen(
              stationName: args?['stationName']?.toString() ?? 'Railway Station',
              cityName:    args?['cityName']?.toString()    ?? 'City',
              lockerId:    args?['lockerId']?.toString()    ?? 'N/A',
              steps: steps,
            ),
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}