import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/appointment_card.dart';
import 'widgets/appointment_modal.dart';
import 'home_admin_screen.dart';

class AdminAgendaCompletaScreen extends StatefulWidget {
  const AdminAgendaCompletaScreen({super.key});

  @override
  _AdminAgendaCompletaScreenState createState() =>
      _AdminAgendaCompletaScreenState();
}

class _AdminAgendaCompletaScreenState extends State<AdminAgendaCompletaScreen> {
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      print("🟡 Carregando agendamentos...");
      QuerySnapshot appointmentsSnapshot =
          await FirebaseFirestore.instance.collection('appointments').get();
      QuerySnapshot servicesSnapshot =
          await FirebaseFirestore.instance.collection('services').get();

      final appointments =
          appointmentsSnapshot.docs
              .map(
                (doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              )
              .toList();

      appointments.sort((a, b) {
        final dateA =
            a['date'] is Timestamp ? a['date'].toDate() : DateTime.now();
        final dateB =
            b['date'] is Timestamp ? b['date'].toDate() : DateTime.now();
        return dateA.compareTo(dateB);
      });

      setState(() {
        _appointments = appointments;
        _services =
            servicesSnapshot.docs
                .map(
                  (doc) => {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  },
                )
                .toList();
      });
      print("✅ Agendamentos carregados com sucesso");
    } catch (e, stack) {
      print("❌ Erro ao carregar agendamentos: $e");
      print(stack);
    }
  }

  Future<void> _updateStatus(String appointmentId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({'status': newStatus});
    _loadAppointments();
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .delete();
    _loadAppointments();
  }

  void _editAppointment(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder:
          (context) => AppointmentModal(
            appointment: appointment,
            onSave: (updatedData) async {
              print("🟡 Atualizando agendamento ID: ${appointment['id']}");
              await FirebaseFirestore.instance
                  .collection('appointments')
                  .doc(appointment['id'])
                  .update(updatedData);
              print("✅ Atualizado");

              await _loadAppointments();

              if (context.mounted) {
                print("🔵 Fechando modal");
                Navigator.of(context).pop();
              }
            },
          ),
    );
  }

  void _addAppointment() {
    showDialog(
      context: context,
      builder:
          (context) => AppointmentModal(
            onSave: (newData) async {
              print("🟡 Salvando novo agendamento...");
              await FirebaseFirestore.instance
                  .collection('appointments')
                  .add(newData);
              print("✅ Agendamento salvo");

              await _loadAppointments();
              print("🔁 Lista atualizada");

              if (context.mounted) {
                print("🔵 Fechando modal");
                Navigator.of(context).pop();
              } else {
                print("❗ Context desmontado ao fechar modal");
              }
            },
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
        title: Column(
          children: [
            Text(
              "AGENDA COMPLETA",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
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
      body:
          _appointments.isEmpty
              ? Center(child: Text("Não temos agendamentos futuros"))
              : ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final appointment = _appointments[index];
                  final service = _services.firstWhere(
                    (s) => s["id"] == appointment["service_id"],
                    orElse: () => {"name": "Serviço não encontrado"},
                  );

                  return AppointmentCard(
                    appointment: appointment,
                    service: service,
                    isWeeklyView: false,
                    isCliente: false, // ✅ adicionado
                    onUpdateStatus: (newStatus) {
                      _updateStatus(appointment["id"], newStatus);
                    },
                    onEdit: () {
                      _editAppointment(appointment);
                    },
                    onDelete: () {
                      _deleteAppointment(appointment["id"]);
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAppointment,
        child: Icon(Icons.add),
      ),
    );
  }
}
