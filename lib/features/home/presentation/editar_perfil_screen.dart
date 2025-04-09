import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _senhaAtualController = TextEditingController();

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      _nomeController.text = data['name'] ?? '';
      _telefoneController.text = data['phone'] ?? '';
      _emailController.text = data['email'] ?? '';
      _instagramController.text = data['instagram'] ?? '';
    }

    setState(() => _carregando = false);
  }

  Future<void> _salvarPerfil() async {
    final uid = _auth.currentUser?.uid;
    final user = _auth.currentUser;
    if (uid == null || user == null) return;

    final docRef = _firestore.collection('users').doc(uid);
    final docSnapshot = await docRef.get();
    final dadosAntigos = docSnapshot.data();

    final nomeAntigo = dadosAntigos?['name'] ?? '';
    final novoNome = _nomeController.text.trim();
    final novoTelefone = _telefoneController.text.trim();
    final novoInstagram = _instagramController.text.trim();
    final novoEmail = _emailController.text.trim();
    final senhaAtual = _senhaAtualController.text.trim();

    print("DEBUG >> E-mail atual: ${user.email}");
    print("DEBUG >> Novo e-mail: $novoEmail");

    try {
      if (novoEmail != user.email) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: senhaAtual,
        );

        await user.reauthenticateWithCredential(cred);
        await user.verifyBeforeUpdateEmail(novoEmail);

        if (mounted) {
          await showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Verificação enviada"),
                  content: const Text(
                    "Enviamos um link de verificação para o novo e-mail.\n\nClique no link na sua caixa de entrada e, em seguida, faça login novamente para concluir a alteração.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await _auth.signOut();
                        if (mounted) {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        }
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }

        return; // Impede atualização do Firestore agora
      }

      await docRef.update({
        'name': novoNome,
        'phone': novoTelefone,
        'email': novoEmail,
        'instagram': novoInstagram,
      });

      final agendamentos =
          await _firestore
              .collection('appointments')
              .where('cliente', isEqualTo: nomeAntigo)
              .get();

      for (final doc in agendamentos.docs) {
        await doc.reference.update({
          'cliente': novoNome,
          'telefone': novoTelefone,
          'instagram': novoInstagram,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ Erro ao atualizar perfil: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao atualizar perfil: ${e.toString()}")),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Editar Perfil",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.pink,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _carregando
              ? const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildTextField("Nome", _nomeController),
                    _buildTextField("Telefone", _telefoneController),
                    _buildTextField("Email", _emailController),
                    _buildTextField("Instagram", _instagramController),
                    const SizedBox(height: 8),
                    _buildTextField(
                      "Senha atual (necessária para alterar o e-mail)",
                      _senhaAtualController,
                      obscure: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _salvarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Salvar",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
