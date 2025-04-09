import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'widgets/appointment_card.dart';

class MeusAgendamentosScreen extends StatefulWidget {
  const MeusAgendamentosScreen({super.key});

  @override
  State<MeusAgendamentosScreen> createState() => _MeusAgendamentosScreenState();
}

class _MeusAgendamentosScreenState extends State<MeusAgendamentosScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() => _userName = data['name']);
      }
    } catch (e) {
      debugPrint("Erro ao carregar nome do usuário: $e");
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "MEUS AGENDAMENTOS",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child:
                _userName == null
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.pink),
                    )
                    : StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('appointments')
                              .where('cliente', isEqualTo: _userName)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.pink,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text("Erro ao carregar agendamentos"),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text("Nenhum agendamento encontrado"),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        final agendamentos =
                            docs.where((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>?;
                                return data != null && data.containsKey('date');
                              }).toList()
                              ..sort((a, b) {
                                final d1 = (a['date'] as Timestamp).toDate();
                                final d2 = (b['date'] as Timestamp).toDate();
                                return d1.compareTo(d2);
                              });

                        return ListView.builder(
                          itemCount: agendamentos.length,
                          itemBuilder: (context, index) {
                            final data =
                                agendamentos[index].data()
                                    as Map<String, dynamic>;

                            return AppointmentCard(
                              appointment: {
                                ...data,
                                'id': agendamentos[index].id,
                              },
                              service: {},
                              isWeeklyView: true,
                              isCliente: true, // ✅ Adicionado aqui
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
