import 'package:flutter/material.dart';
import 'package:primeprof/Views/Prof/professor_drawer.dart.dart';
import 'package:primeprof/Views/etudiant/ResourceScreen.dart';
import 'package:primeprof/Views/etudiant/student_drawer.dart';
import 'package:primeprof/view_models/resource_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/socket_service.dart';
import 'Views/UserManagement/drawer_menu.dart';
import 'view_models/login_view_model.dart';
import 'view_models/forgot_password_view_model.dart';
import 'view_models/course_view_model.dart';
import 'Views/UserManagement/ChangePasswordScreen.dart';
import 'Views/UserManagement/ForgotPasswordScreen.dart';
import 'Views/UserManagement/VerificationCodeScreen.dart';
import 'Views/UserManagement/login_screen.dart';
import 'Views/Prof/ProfScreen.dart';
import 'Views/etudiant/StudentScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(sharedPreferences: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MyApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordViewModel()),
        ChangeNotifierProvider(create: (_) => ResourceViewModel()),
        ChangeNotifierProvider(create: (_) => CourseViewModel()),
      ],
      child: StreamBuilder<SharedPreferences>(
        stream: Stream.periodic(
            const Duration(seconds: 1), (_) => sharedPreferences),
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp(
            title: 'PrimeProfs',
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: sharedPreferences.getBool('isDarkMode') ?? false
                ? ThemeMode.dark
                : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: SplashScreen(sharedPreferences: sharedPreferences),
            routes: _appRoutes(),
          );
        },
      ),
    );
  }

  void _handleLogout(BuildContext context, SharedPreferences prefs) {
    Provider.of<LoginViewModel>(context, listen: false).logout();
    SocketService.disconnect();
    prefs.setBool('isLoggedIn', false);
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Déconnecté avec succès')),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF748FFF),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodySmall: TextStyle(fontSize: 12),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF748FFF),
        secondary: Colors.green,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
      ),
      dividerColor: Colors.grey.shade300,
      shadowColor: Colors.black.withOpacity(0.05),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF748FFF),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF748FFF),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF748FFF),
        secondary: Colors.green,
        surface: Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      dividerColor: Colors.grey.shade800,
      shadowColor: Colors.black.withOpacity(0.2),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF748FFF),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Map<String, WidgetBuilder> _appRoutes() {
    return {
      '/forgot-password': (context) => ForgotPasswordScreen(),
      '/verification-code': (context) => const VerificationCodeScreen(),
      '/change-password': (context) => const ChangePasswordScreen(),
      '/resources': (context) => ResourceScreen(),
    };
  }
}

class SplashScreen extends StatefulWidget {
  final SharedPreferences sharedPreferences;

  const SplashScreen({super.key, required this.sharedPreferences});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Démarrez l'animation après 2 secondes
    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Naviguez vers l'écran principal après 5 secondes
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              MainScreen(sharedPreferences: widget.sharedPreferences),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(seconds: 1),

          // Si vous avez une image, décommentez ceci et commentez le Text ci-dessus :
          child: Image.asset(
            'assets/spach.png',
            fit: BoxFit.contain,
            width: 250,
            height: 250,
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MainScreen({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    final prefs = sharedPreferences;
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String? role = prefs.getString('role');

    if (isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SocketService.initialize();
      });
    }

    Widget initialScreen = const LoginScreen();
    Widget drawerWidget = const SizedBox.shrink();

    if (isLoggedIn && role != null) {
      if (role == 'teacher') {
        initialScreen = const ProfScreen();
        drawerWidget = ProfessorDrawer(
          selectedIndex: 0,
          onItemTapped: (index) {
            if (index == 3) _handleLogout(context, prefs);
          },
        );
      } else if (role == 'student') {
        initialScreen = const EtudiantScreen();
        drawerWidget = StudentDrawer(
          selectedIndex: 0,
          onItemTapped: (index) {
            if (index == 5) _handleLogout(context, prefs);
          },
        );
      }
    } else {
      drawerWidget = DrawerMenu(
        menuItems: [],
        selectedIndex: 0,
        onItemTapped: (_) {},
        isProfessor: false,
      );
    }

    return Scaffold(
      body: initialScreen,
      drawer: drawerWidget != const SizedBox.shrink()
          ? Drawer(child: drawerWidget)
          : null,
    );
  }

  void _handleLogout(BuildContext context, SharedPreferences prefs) {
    Provider.of<LoginViewModel>(context, listen: false).logout();
    SocketService.disconnect();
    prefs.setBool('isLoggedIn', false);
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Déconnecté avec succès')),
    );
  }
}
