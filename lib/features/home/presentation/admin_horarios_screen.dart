import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class AdminHorariosScreen extends StatefulWidget {
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
    initializeDateFormatting(); // Inicializa a formatação de datas
    _gerarHorariosParaAno(); // Garante que todos os horários do ano existam no Firestore
    _atualizarHorarios();
  }

  /// 🔹 Garante que todos os dias até o final do ano tenham horários cadastrados
  void _gerarHorariosParaAno() async {
    DateTime hoje = DateTime.now();
    DateTime fimDoAno = DateTime(hoje.year, 12, 31);

    for (
      DateTime data = hoje;
      data.isBefore(fimDoAno);
      data = data.add(Duration(days: 1))
    ) {
      if (data.weekday == DateTime.sunday) continue; // Ignora domingos

      String dataFormatada = DateFormat('yyyy-MM-dd').format(data);
      List<String> horarios = _gerarHorarios(data);

      // Verifica se já existem horários cadastrados para esta data
      QuerySnapshot snapshot =
          await _firestore
              .collection('available_slots')
              .where('date', isEqualTo: dataFormatada)
              .get();

      if (snapshot.docs.isEmpty) {
        // Se não existir, cria os horários disponíveis
        for (String horario in horarios) {
          await _firestore.collection('available_slots').add({
            'date': dataFormatada,
            'time': horario,
            'available': true,
          });
        }
      }
    }
  }

  /// 🔹 Atualiza os horários conforme a data selecionada
  void _atualizarHorarios() {
    setState(() {
      _horarios = _gerarHorarios(_dataSelecionada);
      _disponibilidade = {for (var h in _horarios) h: true};
      _carregarHorariosDoFirestore();
    });
  }

  /// 🔹 Gera os horários disponíveis conforme o dia da semana
  List<String> _gerarHorarios(DateTime data) {
    if (data.weekday == DateTime.sunday) {
      return []; // Domingo não há atendimento
    }

    int inicio = (data.weekday == DateTime.saturday) ? 8 : 7;
    int fim = (data.weekday == DateTime.saturday) ? 17 : 19;

    return List.generate(
      fim - inicio + 1,
      (index) => "${(inicio + index).toString().padLeft(2, '0')}:00",
    );
  }

  /// 🔹 Carrega horários disponíveis do Firestore
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

  /// 🔹 Alterna a disponibilidade do horário ao clicar no botão
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
    }
  }

  /// 🔹 Exibe o DatePicker para selecionar a data
  Future<void> _selecionarData() async {
    DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 60)),
      locale: Locale('pt', 'BR'),
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
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          "Gestão de Horários",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          // 🔹 Botão de seleção de data com ícone de calendário
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.calendar_today, color: Colors.pink),
                  onPressed: _selecionarData,
                ),
                SizedBox(width: 10),
                Text(
                  DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataSelecionada),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 🔹 Exibição dos horários disponíveis
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child:
                  _horarios.isEmpty
                      ? Center(child: Text("Domingo não há atendimento"))
                      : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _horarios.length,
                        itemBuilder: (context, index) {
                          String horario = _horarios[index];
                          bool disponivel = _disponibilidade[horario] ?? true;

                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  disponivel ? Colors.pink : Colors.grey[400],
                            ),
                            onPressed: () => _alterarDisponibilidade(horario),
                            child: Text(horario),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
