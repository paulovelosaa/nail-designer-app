import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsuariosScreen extends StatefulWidget {
  @override
  _AdminUsuariosScreenState createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, bool> _expandedCards = {}; // Controla a expansão dos cards

  /// 🔹 Função para excluir usuário
  void _excluirUsuario(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Usuário excluído com sucesso")));
  }

  /// 🔹 Função para editar usuário
  void _editarUsuario(Map<String, dynamic> usuario) {
    _abrirFormularioUsuario(
      title: "Editar Usuário",
      usuario: usuario,
      onSave: (userData) async {
        await _firestore
            .collection('users')
            .doc(usuario['id'])
            .update(userData);
      },
    );
  }

  /// 🔹 Função para adicionar novo usuário
  void _adicionarUsuario() {
    _abrirFormularioUsuario(
      title: "Novo Usuário",
      usuario: null,
      onSave: (userData) async {
        await _firestore.collection('users').add(userData);
      },
    );
  }

  /// 🔹 Função para abrir formulário de edição/cadastro
  void _abrirFormularioUsuario({
    required String title,
    Map<String, dynamic>? usuario,
    required Function(Map<String, dynamic>) onSave,
  }) {
    TextEditingController nomeController = TextEditingController(
      text: usuario?['name'] ?? '',
    );
    TextEditingController emailController = TextEditingController(
      text: usuario?['email'] ?? '',
    );
    TextEditingController telefoneController = TextEditingController(
      text: usuario?['phone'] ?? '',
    );
    TextEditingController instagramController = TextEditingController(
      text: usuario?['instagram'] ?? '',
    );
    String role = usuario?['role'] ?? 'cliente';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(nomeController, "Nome"),
                _buildTextField(emailController, "E-mail"),
                _buildTextField(telefoneController, "Telefone"),
                _buildTextField(instagramController, "Instagram"),
                DropdownButtonFormField<String>(
                  value: role,
                  items:
                      ["admin", "cliente"]
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.toUpperCase()),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => role = value!,
                  decoration: InputDecoration(labelText: "Cargo"),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Cancelar", style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () async {
                Map<String, dynamic> userData = {
                  'name': nomeController.text,
                  'email': emailController.text,
                  'phone': telefoneController.text,
                  'instagram': instagramController.text,
                  'role': role,
                };
                await onSave(userData);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Usuário salvo com sucesso")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Salvar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Widget de TextField personalizado
  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
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
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          "Gestão de Usuários",
          style: TextStyle(color: Colors.black),
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
                  'phone': userData['phone'] ?? 'Não informado',
                  'instagram': userData['instagram'] ?? 'Não informado',
                  'role': userData['role'] ?? 'cliente',
                };
              }).toList();

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              var usuario = usuarios[index];
              bool isExpanded = _expandedCards[usuario['id']] ?? false;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(usuario['name']),
                      subtitle: Text(usuario['email']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editarUsuario(usuario),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _excluirUsuario(usuario['id']),
                          ),
                          IconButton(
                            icon: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _expandedCards[usuario['id']] = !isExpanded;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded) _infoRow("Telefone", usuario['phone']),
                    if (isExpanded) _infoRow("Instagram", usuario['instagram']),
                    if (isExpanded) _infoRow("Cargo", usuario['role']),
                  ],
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

  /// 🔹 Widget para exibir as informações do usuário
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.black))),
        ],
      ),
    );
  }
}
