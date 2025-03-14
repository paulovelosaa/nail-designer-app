import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // 🔹 Import necessário para inicialização
import 'core/config/firebase_options.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/home/presentation/home_cliente_screen.dart';
import 'features/home/presentation/home_admin_screen.dart';
import 'features/auth/data/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting(
    'pt_BR',
    null,
  ); // 🔹 Inicializa formatação de data para evitar erro no calendário

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nail Designer App',
      supportedLocales: [
        Locale('pt', 'BR'), // 🔹 Adiciona suporte ao idioma português
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: "/",
      routes: {
        "/": (context) => AuthChecker(),
        "/login": (context) => LoginScreen(),
        "/register": (context) => RegisterScreen(),
        "/home_cliente": (context) => HomeClienteScreen(),
        "/home_admin": (context) => HomeAdminScreen(),
      },
    );
  }
}

// 🔹 Verifica autenticação e redireciona corretamente
class AuthChecker extends StatefulWidget {
  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  final AuthService _authService = AuthService();
  bool _isChecking = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String role = await _authService.getUserRole(user.uid);
      if (mounted) {
        setState(() {
          _userRole = role;
          _isChecking = false;
        });
      }
    } else {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        body: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    if (_userRole == "admin") {
      return HomeAdminScreen();
    } else if (_userRole == "cliente") {
      return HomeClienteScreen();
    } else {
      return LoginScreen();
    }
  }
}
