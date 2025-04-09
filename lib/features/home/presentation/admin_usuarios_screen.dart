import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_admin_screen.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  _AdminUsuariosScreenState createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _editarUsuario(String userId, Map<String, dynamic> userData) {
    TextEditingController nomeController = TextEditingController(
      text: userData['name'],
    );
    TextEditingController emailController = TextEditingController(
      text: userData['email'],
    );
    TextEditingController telefoneController = TextEditingController(
      text: userData['phone'] ?? '',
    );
    TextEditingController instagramController = TextEditingController(
      text: userData['instagram'] ?? '',
    );
    bool isAdminChecked = userData['role'] == 'admin';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text("Editar Usuário"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nomeController,
                        decoration: InputDecoration(
                          labelText: "Nome",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: telefoneController,
                        decoration: InputDecoration(
                          labelText: "Telefone",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: instagramController,
                        decoration: InputDecoration(
                          labelText: "Instagram",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      CheckboxListTile(
                        title: Text("Admin"),
                        value: isAdminChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            isAdminChecked = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _firestore.collection('users').doc(userId).update({
                        'name': nomeController.text.trim(),
                        'email': emailController.text.trim(),
                        'phone': telefoneController.text.trim(),
                        'instagram': instagramController.text.trim(),
                        'role': isAdminChecked ? 'admin' : 'cliente',
                      });
                      Navigator.pop(context);
                    },
                    child: Text("Salvar"),
                  ),
                ],
              ),
        );
      },
    );
  }

  void _adicionarUsuario() {
    TextEditingController nomeController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController telefoneController = TextEditingController();
    TextEditingController instagramController = TextEditingController();
    bool isAdminChecked = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text("Novo Usuário"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nomeController,
                        decoration: InputDecoration(
                          labelText: "Nome",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: telefoneController,
                        decoration: InputDecoration(
                          labelText: "Telefone",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: instagramController,
                        decoration: InputDecoration(
                          labelText: "Instagram",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      CheckboxListTile(
                        title: Text("Admin"),
                        value: isAdminChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            isAdminChecked = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _firestore.collection('users').add({
                        'name': nomeController.text.trim(),
                        'email': emailController.text.trim(),
                        'phone': telefoneController.text.trim(),
                        'instagram': instagramController.text.trim(),
                        'role': isAdminChecked ? 'admin' : 'cliente',
                      });
                      Navigator.pop(context);
                    },
                    child: Text("Adicionar"),
                  ),
                ],
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        title: Column(
          children: [
            Text(
              "GESTÃO DE USUÁRIOS",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 5),
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
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeAdminScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.pink));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Nenhum usuário encontrado"));
          }

          var usuarios =
              snapshot.data!.docs.map((doc) {
                var userData = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  'name': userData['name'],
                  'email': userData['email'],
                  'phone': userData['phone'] ?? '',
                  'instagram': userData['instagram'] ?? '',
                  'role': userData['role'] ?? 'cliente',
                };
              }).toList();

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              var usuario = usuarios[index];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(usuario['name']),
                  subtitle: Text(usuario['email']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editarUsuario(usuario['id'], usuario),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed:
                            () =>
                                _firestore
                                    .collection('users')
                                    .doc(usuario['id'])
                                    .delete(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarUsuario,
        backgroundColor: Colors.pink,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
