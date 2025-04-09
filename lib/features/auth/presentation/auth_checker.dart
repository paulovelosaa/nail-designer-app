import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/presentation/home_cliente_screen.dart';
import '../../home/presentation/home_admin_screen.dart';
import '../presentation/login_screen.dart';

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.grey[200],
            body: const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final uid = snapshot.data!.uid;

          return FutureBuilder<String?>(
            future: _handleUserRoleAndSyncEmail(uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: Colors.grey[200],
                  body: const Center(
                    child: CircularProgressIndicator(color: Colors.pink),
                  ),
                );
              }

              if (roleSnapshot.hasData) {
                final role = roleSnapshot.data!;
                if (role == 'admin') {
                  return const HomeAdminScreen();
                } else {
                  return const HomeClienteScreen();
                }
              } else {
                Future.microtask(() => FirebaseAuth.instance.signOut());
                return const LoginScreen();
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }

  Future<String?> _handleUserRoleAndSyncEmail(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    final authEmail = refreshedUser?.email;
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) return null;

    final data = docSnapshot.data()!;
    final firestoreEmail = data['email'];

    debugPrint('🔍 Firestore: $firestoreEmail | Auth: $authEmail');

    if (authEmail != null && firestoreEmail != authEmail) {
      try {
        await docRef.update({'email': authEmail});
        debugPrint('✅ Email sincronizado no Firestore: $authEmail');
      } catch (e) {
        debugPrint('❌ Erro ao atualizar email no Firestore: $e');
      }
    } else {
      debugPrint('ℹ️ Emails iguais. Nenhuma atualização necessária.');
    }

    return data['role'];
  }
}
