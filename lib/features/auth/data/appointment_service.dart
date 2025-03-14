import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createAppointment(
    String userId,
    String userName,
    String serviceId,
    String serviceName,
    String slotId,
    DateTime date,
  ) async {
    try {
      // Referências aos documentos
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      DocumentReference serviceRef = _firestore
          .collection('services')
          .doc(serviceId);
      DocumentReference slotRef = _firestore
          .collection('available_slots')
          .doc(slotId);

      await _firestore.collection('appointments').add({
        "userId": userId,
        "userRef": userRef,
        "userName": userName,
        "serviceId": serviceId,
        "serviceRef": serviceRef,
        "serviceName": serviceName,
        "slotId": slotId,
        "slotRef": slotRef,
        "date": Timestamp.fromDate(date),
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });
      print("Agendamento criado com sucesso!");
    } catch (e) {
      print("Erro ao criar agendamento: $e");
    }
  }
}
