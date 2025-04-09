import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_admin_screen.dart';

class AdminServicosScreen extends StatefulWidget {
  const AdminServicosScreen({super.key});

  @override
  _AdminServicosScreenState createState() => _AdminServicosScreenState();
}

class _AdminServicosScreenState extends State<AdminServicosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
              "GESTÃO DE SERVIÇOS",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Container(height: 2, width: 40, color: Colors.pink),
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
        stream: _firestore.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.pink));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Nenhum serviço cadastrado"));
          }

          var servicos =
              snapshot.data!.docs.map((doc) {
                var serviceData = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  'name': serviceData['name'],
                  'price': serviceData['price'],
                };
              }).toList();

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: servicos.length,
            itemBuilder: (context, index) {
              var servico = servicos[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    servico['name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Preço: R\$ ${servico['price']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editService(servico),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteService(servico['id']),
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
        backgroundColor: Colors.pink,
        onPressed: _addService,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Editar serviço
  void _editService(Map<String, dynamic> service) {
    TextEditingController nameController = TextEditingController(
      text: service['name'],
    );
    TextEditingController priceController = TextEditingController(
      text: service['price'].toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Editar Serviço"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Nome",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: "Preço",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text("Cancelar"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text("Salvar"),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final price = double.tryParse(priceController.text);

                  if (name.isEmpty || price == null) return;

                  await _firestore
                      .collection('services')
                      .doc(service['id'])
                      .update({'name': name, 'price': price});

                  Navigator.pop(context); // Fecha o modal corretamente
                },
              ),
            ],
          ),
    );
  }

  /// Excluir serviço
  void _deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).delete();
  }

  /// Adicionar novo serviço
  void _addService() {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Adicionar Serviço"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Nome",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: "Preço",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text("Cancelar"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text("Adicionar"),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final price = double.tryParse(priceController.text);

                  if (name.isEmpty || price == null) return;

                  await _firestore.collection('services').add({
                    'name': name,
                    'price': price,
                  });

                  Navigator.pop(context); // Fecha o modal corretamente
                },
              ),
            ],
          ),
    );
  }
}
