import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/presentation/home_cliente_screen.dart';
import '../../home/presentation/home_admin_screen.dart';
import '../presentation/login_screen.dart';

class AuthChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.grey[200],
            body: Center(child: CircularProgressIndicator(color: Colors.pink)),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(snapshot.data!.uid)
                    .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: Colors.grey[200],
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.pink),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final role = userSnapshot.data!.get('role');
                if (role == 'admin') {
                  return HomeAdminScreen();
                } else {
                  return HomeClienteScreen();
                }
              } else {
                return LoginScreen(); // Redireciona se não encontrar o usuário
              }
            },
          );
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
