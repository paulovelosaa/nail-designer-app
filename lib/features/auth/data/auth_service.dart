import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Registrar Usuário
  Future<UserModel?> register(
    String name,
    String email,
    String password,
    String phone,
    String instagram,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        UserModel newUser = UserModel(
          id: user.uid,
          name: name,
          email: email,
          role: 'cliente',
        );

        Map<String, dynamic> userData = {
          "name": name,
          "email": email,
          "phone": phone,
          "instagram": instagram,
          "role": "cliente",
          "createdAt": FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(user.uid).set(userData);
        return newUser;
      }
      return null;
    } catch (e) {
      print("Erro no registro: $e");
      return null;
    }
  }

  // 🔹 Login Usuário
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await getCurrentUser();
    } catch (e) {
      print("Erro no login: $e");
      return null;
    }
  }

  // 🔹 Logout (Resetando Estado)
  Future<void> logout() async {
    await _auth.signOut();
    _resetUserState(); // Resetando o estado do usuário
  }

  // 🔹 Método para resetar estado ao deslogar
  void _resetUserState() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print("Usuário deslogado. Resetando estado...");
      }
    });
  }

  // 🔹 Obtém usuário logado
  Future<UserModel?> getCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userData =
            await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromMap(
          userData.data() as Map<String, dynamic>,
          user.uid,
        );
      }
      return null;
    } catch (e) {
      print("Erro ao obter usuário logado: $e");
      return null;
    }
  }

  // 🔹 Obtém o papel do usuário (Admin ou Cliente)
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        return userDoc.get('role') ??
            'cliente'; // Retorna "admin" ou "cliente", garantindo não ser nulo
      }
      return 'cliente'; // Se não existir, assume "cliente"
    } catch (e) {
      print("Erro ao obter role do usuário: $e");
      return 'cliente'; // Tratamento de erro assume "cliente"
    }
  }
}
