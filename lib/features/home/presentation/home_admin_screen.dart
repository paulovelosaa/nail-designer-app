import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'agenda_admin_screen.dart';
import 'admin_servicos_screen.dart';
import 'admin_horarios_screen.dart';
import 'admin_usuarios_screen.dart'; // 🔹 Importação da tela de usuários

class HomeAdminScreen extends StatefulWidget {
  @override
  _HomeAdminScreenState createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String _nomeAdmin = "";
  bool _isLoading = true;
  String _menuSelecionado = "Agenda";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      try {
        DocumentSnapshot userData =
            await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (mounted) {
          setState(() {
            _nomeAdmin = (userData['name'] ?? "Admin").split(" ")[0];
          });
        }
      } catch (e) {
        print("Erro ao carregar dados do usuário: $e");
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Bem-vindo, $_nomeAdmin",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
            SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: Colors.grey[400],
              child: Icon(Icons.person, color: Colors.black),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[300],
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: 40, bottom: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[400],
                    child: Icon(Icons.person, color: Colors.black, size: 40),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _nomeAdmin,
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ],
              ),
            ),
            _menuItem(Icons.person, "Perfil", () {}),
            _menuItem(Icons.calendar_today, "Agenda", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AgendaAdminScreen()),
              );
            }),
            _menuItem(Icons.design_services, "Serviços", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminServicosScreen()),
              );
            }),
            _menuItem(Icons.access_time, "Horários", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminHorariosScreen()),
              );
            }),
            _menuItem(Icons.people, "Usuários", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminUsuariosScreen()),
              );
            }),
            _menuItem(Icons.exit_to_app, "Sair", _logout),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.pink))
              : _buildMenuContent(),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.pink),
      title: Text(title, style: TextStyle(color: Colors.black)),
      selected: _menuSelecionado == title,
      selectedTileColor: Colors.grey[400],
      onTap: onTap,
    );
  }

  Widget _buildMenuContent() {
    switch (_menuSelecionado) {
      case "Serviços":
        return AdminServicosScreen();
      case "Horários":
        return AdminHorariosScreen();
      case "Usuários":
        return AdminUsuariosScreen(); // 🔹 Agora carrega corretamente a tela de usuários
      default:
        return Center(child: Text("Selecione uma opção no menu"));
    }
  }
}
