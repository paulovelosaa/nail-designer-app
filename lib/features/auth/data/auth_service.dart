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
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print("⚠️ E-mail já cadastrado.");
      } else {
        print("❌ FirebaseAuthException no registro: ${e.code} - ${e.message}");
      }
      return null;
    } catch (e) {
      print("Erro no registro: $e");
      return null;
    }
  }

  // 🔹 Login Usuário (com logs e tratamento de erro)
  Future<UserModel?> login(String email, String password) async {
    print("🔐 Iniciando login com $email");

    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("✅ FirebaseAuth: Login autenticado");

      if (result.user == null) {
        print("❌ FirebaseAuth retornou usuário nulo");
        return null;
      }

      final uid = result.user!.uid;
      print("🧾 Buscando dados no Firestore para UID: $uid");

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      print("📄 Documento encontrado? ${userDoc.exists}");

      if (!userDoc.exists) {
        print("⚠️ Documento do usuário não existe no Firestore");
        return null;
      }

      final userModel = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        uid,
      );

      print("✅ Login completo para ${userModel.email}");
      return userModel;
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("❌ Erro inesperado no login: $e");
      return null;
    }
  }

  // 🔹 Logout (Resetando Estado)
  Future<void> logout() async {
    await _auth.signOut();
    _resetUserState();
  }

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
        final mappedUser = UserModel.fromMap(
          userData.data() as Map<String, dynamic>,
          user.uid,
        );
        print("🔍 Dados do usuário carregados: ${mappedUser.email}");
        return mappedUser;
      }
      print("⚠️ Nenhum usuário autenticado no momento.");
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
        final role = userDoc.get('role') ?? 'cliente';
        print("📌 Papel do usuário: $role");
        return role;
      }
      print("⚠️ Documento de usuário não encontrado. Retornando 'cliente'.");
      return 'cliente';
    } catch (e) {
      print("Erro ao obter role do usuário: $e");
      return 'cliente';
    }
  }

  // 🔹 Redefinir senha
  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print("📨 E-mail de redefinição de senha enviado para $email");
    } catch (e) {
      print("❌ Erro ao enviar e-mail de redefinição: $e");
    }
  }

  // 🔹 Excluir usuário do Firebase Authentication e Firestore
  Future<bool> deleteUser(String email, String password, String userId) async {
    try {
      User? userToDelete = await _auth
          .fetchSignInMethodsForEmail(email)
          .then((methods) => methods.isNotEmpty ? _auth.currentUser : null);

      if (userToDelete != null) {
        await userToDelete.delete();
      } else {
        print("Usuário não encontrado no Firebase Authentication.");
      }

      await _firestore.collection('users').doc(userId).delete();

      print("Usuário excluído com sucesso.");
      return true;
    } catch (e) {
      print("Erro ao excluir usuário: $e");
      return false;
    }
  }
}
