import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'agendar_horario_screen.dart';
import 'meus_agendamentos_screen.dart';
import 'editar_perfil_screen.dart';

class HomeClienteScreen extends StatefulWidget {
  const HomeClienteScreen({super.key});

  @override
  _HomeClienteScreenState createState() => _HomeClienteScreenState();
}

class _HomeClienteScreenState extends State<HomeClienteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    }
  }

  void _abrirTelaEditarPerfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
    );
    setState(() {}); // Garante atualização caso algo não esteja com stream
  }

  void _abrirTelaAgendamento() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AgendarHorarioScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(),
            if (_currentUser != null)
              StreamBuilder<DocumentSnapshot>(
                stream:
                    _firestore
                        .collection('users')
                        .doc(_currentUser!.uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text(
                      "Bem-vinda",
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    );
                  }
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final nome = data['name'] ?? "Cliente";
                  final primeiroNome = nome.toString().split(" ").first;
                  return Text(
                    "Bem-vinda, $primeiroNome",
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                  );
                },
              ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[300],
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _menuItem(Icons.person, "Perfil", _abrirTelaEditarPerfil),
              _menuItem(
                Icons.calendar_today,
                "Agendar horário",
                _abrirTelaAgendamento,
              ),
              _menuItem(Icons.exit_to_app, "Sair", _logout),
            ],
          ),
        ),
      ),
      body: MeusAgendamentosScreen(),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.pink),
      title: Text(title, style: const TextStyle(color: Colors.black)),
      onTap: onTap,
    );
  }
}
