import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeClienteScreen extends StatefulWidget {
  @override
  _HomeClienteScreenState createState() => _HomeClienteScreenState();
}

class _HomeClienteScreenState extends State<HomeClienteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String _nomeUsuario = "";
  bool _isLoading = true;
  bool _mostrarHorarios = false;
  bool _mostrarAgendamentos = false;

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
            _nomeUsuario = (userData['name'] ?? "Cliente").split(" ")[0];
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
              "Bem-vinda, $_nomeUsuario",
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
                    _nomeUsuario,
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ],
              ),
            ),
            _menuItem(Icons.person, "Perfil", () {}),
            _menuItem(Icons.calendar_today, "Agendar horário", () {
              setState(() {
                _mostrarHorarios = true;
                _mostrarAgendamentos = false;
              });
              Navigator.pop(context);
            }),
            _menuItem(Icons.list_alt, "Meus Agendamentos", () {
              setState(() {
                _mostrarHorarios = false;
                _mostrarAgendamentos = true;
              });
              Navigator.pop(context);
            }),
            _menuItem(Icons.exit_to_app, "Sair", _logout),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.pink))
              : _mostrarHorarios
              ? _buildHorarios()
              : _mostrarAgendamentos
              ? _buildAgendamentos()
              : Center(child: Text("Tela inicial do Cliente")),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.pink),
      title: Text(title, style: TextStyle(color: Colors.black)),
      onTap: onTap,
    );
  }

  Widget _buildHorarios() {
    return Center(child: Text("Tela de Agendamento de Horários"));
  }

  Widget _buildAgendamentos() {
    return Center(child: Text("Tela de Meus Agendamentos"));
  }
}
