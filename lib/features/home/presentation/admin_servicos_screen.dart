import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminServicosScreen extends StatefulWidget {
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
        iconTheme: IconThemeData(color: Colors.black),
        title: Text("Serviços", style: TextStyle(color: Colors.black)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.pink));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Nenhum serviço cadastrado."));
          }

          var services = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              var service = services[index];
              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    service['name'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "R\$ ${service['price']}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editService(service),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteService(service.id),
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
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _addService,
      ),
    );
  }

  void _editService(DocumentSnapshot service) {
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
                  decoration: InputDecoration(labelText: "Nome"),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: "Preço"),
                  keyboardType: TextInputType.number,
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
                  await _firestore
                      .collection('services')
                      .doc(service.id)
                      .update({
                        'name': nameController.text,
                        'price': double.parse(priceController.text),
                      });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  void _deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).delete();
  }

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
                  decoration: InputDecoration(labelText: "Nome"),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: "Preço"),
                  keyboardType: TextInputType.number,
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
                  await _firestore.collection('services').add({
                    'name': nameController.text,
                    'price': double.parse(priceController.text),
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }
}
