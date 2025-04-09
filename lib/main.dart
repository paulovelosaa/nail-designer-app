import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // necessário para kReleaseMode
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_admin_screen.dart';
import 'features/home/presentation/home_cliente_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Erro ao iniciar firebase: $e')),
        ),
      ),
    );
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nail Designer App',
      theme: ThemeData(primarySwatch: Colors.pink),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      // ✅ ROTAS REGISTRADAS AQUI
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home_cliente': (context) => const HomeClienteScreen(),
        '/home_admin': (context) => const HomeAdminScreen(),
      },
      // ✅ HOME GERENCIADO DINAMICAMENTE PELO FirebaseAuth
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const LoginScreen();
          }

          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(snapshot.data!.uid)
                    .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasError) {
                return Scaffold(
                  body: Center(child: Text('Erro: ${userSnapshot.error}')),
                );
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const Scaffold(
                  body: Center(child: Text('Usuário não encontrado')),
                );
              }

              final data = userSnapshot.data!.data() as Map<String, dynamic>;
              final role = data['role'];

              if (role == 'admin') {
                return const HomeAdminScreen();
              } else {
                return const HomeClienteScreen();
              }
            },
          );
        },
      ),
    );
  }
}
