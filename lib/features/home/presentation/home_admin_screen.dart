import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_agenda_semanal_screen.dart';
import 'admin_agenda_completa_screen.dart';
import 'admin_servicos_screen.dart';
import 'package:nail_designer_app/features/home/presentation/admin_horarios_screen.dart';
import 'admin_usuarios_screen.dart';
import 'package:nail_designer_app/features/auth/presentation/login_screen.dart';

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  _HomeAdminScreenState createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String _nomeAdmin = "Admin";
  Widget _currentScreen = AdminAgendaSemanalScreen();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      try {
        final docRef = _firestore.collection('users').doc(_currentUser!.uid);
        final userData = await docRef.get();

        if (userData.exists) {
          final data = userData.data() as Map<String, dynamic>;
          setState(() {
            _nomeAdmin = (data['name'] ?? "Admin").split(" ")[0];
          });
        } else {
          print("Admin sem dados na collection 'users'. Usando padrão.");
          setState(() {
            _nomeAdmin = "Admin";
          });
        }
      } catch (e) {
        print("Erro ao carregar dados do admin: $e");
      }
    }
  }

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  void _selectScreen(Widget screen) {
    setState(() => _currentScreen = screen);
    Navigator.pop(context);
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(),
            Text(
              "Bem-vinda, $_nomeAdmin",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[300],
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 8), // 👈 Pequeno espaço para não colar no topo
              _menuItem(
                Icons.list,
                "Agenda Completa",
                () => _selectScreen(AdminAgendaCompletaScreen()),
              ),
              _menuItem(
                Icons.design_services,
                "Serviços",
                () => _selectScreen(AdminServicosScreen()),
              ),
              _menuItem(
                Icons.access_time,
                "Horários Disponíveis",
                () => _selectScreen(AdminHorariosScreen()),
              ),
              _menuItem(
                Icons.group,
                "Usuários",
                () => _selectScreen(AdminUsuariosScreen()),
              ),
              _menuItem(Icons.exit_to_app, "Sair", _logout),
            ],
          ),
        ),
      ),
      body: _currentScreen,
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.pink),
      title: Text(title, style: TextStyle(color: Colors.black)),
      onTap: onTap,
    );
  }
}
