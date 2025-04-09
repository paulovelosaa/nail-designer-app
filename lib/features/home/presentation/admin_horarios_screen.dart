import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'home_admin_screen.dart';

class AdminHorariosScreen extends StatefulWidget {
  const AdminHorariosScreen({super.key});

  @override
  _AdminHorariosScreenState createState() => _AdminHorariosScreenState();
}

class _AdminHorariosScreenState extends State<AdminHorariosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _dataSelecionada = DateTime.now();
  List<String> _horarios = [];
  Map<String, bool> _disponibilidade = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _atualizarHorarios();
  }

  void _atualizarHorarios() {
    setState(() {
      _horarios = _gerarHorarios(_dataSelecionada);
      _disponibilidade = {for (var h in _horarios) h: true};
      _carregarHorariosDoFirestore();
    });
  }

  List<String> _gerarHorarios(DateTime data) {
    if (data.weekday == DateTime.sunday) return [];

    int inicio = (data.weekday == DateTime.saturday) ? 8 : 7;
    int fim = (data.weekday == DateTime.saturday) ? 17 : 19;

    return List.generate(
      fim - inicio + 1,
      (index) => "${(inicio + index).toString().padLeft(2, '0')}:00",
    );
  }

  void _carregarHorariosDoFirestore() async {
    String dataFormatada = DateFormat('yyyy-MM-dd').format(_dataSelecionada);
    QuerySnapshot snapshot =
        await _firestore
            .collection('available_slots')
            .where('date', isEqualTo: dataFormatada)
            .get();

    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        String horario = doc['time'];
        bool disponivel = doc['available'] ?? true;
        if (_disponibilidade.containsKey(horario)) {
          setState(() {
            _disponibilidade[horario] = disponivel;
          });
        }
      }
    }
  }

  void _alterarDisponibilidade(String horario) async {
    String dataFormatada = DateFormat('yyyy-MM-dd').format(_dataSelecionada);
    bool disponivel = !_disponibilidade[horario]!;

    setState(() {
      _disponibilidade[horario] = disponivel;
    });

    QuerySnapshot snapshot =
        await _firestore
            .collection('available_slots')
            .where('date', isEqualTo: dataFormatada)
            .where('time', isEqualTo: horario)
            .get();

    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        await _firestore.collection('available_slots').doc(doc.id).update({
          'available': disponivel,
        });
      }
    } else {
      await _firestore.collection('available_slots').add({
        'date': dataFormatada,
        'time': horario,
        'available': disponivel,
      });
    }
  }

  Future<void> _selecionarData() async {
    DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      locale: const Locale('pt', 'BR'),
    );

    if (dataEscolhida != null && dataEscolhida != _dataSelecionada) {
      setState(() {
        _dataSelecionada = dataEscolhida;
        _atualizarHorarios();
      });
    }
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
            const Text(
              "Gestão de Horários",
              style: TextStyle(
                fontSize: 20,
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeAdminScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: ElevatedButton.icon(
              onPressed: _selecionarData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                side: const BorderSide(color: Colors.pink),
              ),
              icon: const Icon(Icons.calendar_today, color: Colors.pink),
              label: Text(
                DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataSelecionada),
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children:
                    _horarios.map((horario) {
                      bool disponivel = _disponibilidade[horario] ?? true;
                      return GestureDetector(
                        onTap: () => _alterarDisponibilidade(horario),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: disponivel ? Colors.pink : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            horario,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
