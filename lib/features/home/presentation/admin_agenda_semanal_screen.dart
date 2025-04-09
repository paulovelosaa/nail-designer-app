import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/appointment_card.dart';

class AdminAgendaSemanalScreen extends StatefulWidget {
  const AdminAgendaSemanalScreen({super.key});

  @override
  _AdminAgendaSemanalScreenState createState() =>
      _AdminAgendaSemanalScreenState();
}

class _AdminAgendaSemanalScreenState extends State<AdminAgendaSemanalScreen> {
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    QuerySnapshot appointmentsSnapshot =
        await FirebaseFirestore.instance.collection('appointments').get();
    QuerySnapshot servicesSnapshot =
        await FirebaseFirestore.instance.collection('services').get();

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    final appointments =
        appointmentsSnapshot.docs
            .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
            .where((appointment) {
              final date = appointment['date'];
              if (date is Timestamp) {
                final appointmentDate = date.toDate();
                return appointmentDate.isAfter(
                      startOfWeek.subtract(Duration(days: 1)),
                    ) &&
                    appointmentDate.isBefore(endOfWeek.add(Duration(days: 1)));
              }
              return false;
            })
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
                (doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              )
              .toList();
    });
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
              "AGENDA SEMANAL",
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
      ),
      body:
          _appointments.isEmpty
              ? Center(child: Text("Não temos agendamentos futuros"))
              : ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  return AppointmentCard(
                    appointment: _appointments[index],
                    service: _services.firstWhere(
                      (s) => s["id"] == _appointments[index]["service_id"],
                      orElse: () => {},
                    ),
                    isWeeklyView: true,
                    isCliente: false, // ✅ adicionado
                  );
                },
              ),
    );
  }
}
