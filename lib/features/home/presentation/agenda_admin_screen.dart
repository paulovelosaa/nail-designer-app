import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AgendaAdminScreen extends StatefulWidget {
  @override
  _AgendaAdminScreenState createState() => _AgendaAdminScreenState();
}

class _AgendaAdminScreenState extends State<AgendaAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _agendamentos = [];
  List<String> _horariosDisponiveis = [];
  DateTime? _dataSelecionada;
  String? _horarioSelecionado;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  /// 🔹 Carrega os agendamentos futuros
  Future<void> _loadAppointments() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('appointments')
              .orderBy('date', descending: false)
              .get();

      setState(() {
        _agendamentos =
            querySnapshot.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return {'id': doc.id, ...data};
            }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Erro ao carregar agendamentos: $e");
    }
  }

  /// 🔹 Carrega horários disponíveis para a data selecionada
  Future<void> _loadHorariosDisponiveis(DateTime dataSelecionada) async {
    String dataFormatada = DateFormat('yyyy-MM-dd').format(dataSelecionada);
    print("Buscando horários disponíveis para: $dataFormatada");

    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('available_slots')
              .where('date', isEqualTo: dataFormatada)
              .where('available', isEqualTo: true)
              .get();

      List<String> horarios =
          querySnapshot.docs.map((doc) => doc['time'].toString()).toList();

      /// 🔹 Ordenando os horários do menor para o maior
      horarios.sort((a, b) => a.compareTo(b));

      setState(() {
        _horariosDisponiveis = horarios;
        _horarioSelecionado =
            _horariosDisponiveis.isNotEmpty ? _horariosDisponiveis.first : null;
      });

      print("Horários disponíveis carregados: $_horariosDisponiveis");
    } catch (e) {
      print("Erro ao carregar horários disponíveis: $e");
    }
  }

  /// 🔹 Cria um novo agendamento manualmente
  void _criarAgendamento() {
    TextEditingController nomeController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController telefoneController = TextEditingController();
    TextEditingController instagramController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Novo Agendamento"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField(nomeController, "Nome do Cliente"),
                    _buildTextField(emailController, "E-mail"),
                    _buildTextField(telefoneController, "Telefone"),
                    _buildTextField(instagramController, "Instagram"),

                    /// 🔹 Seletor de Data
                    ListTile(
                      title: Text(
                        _dataSelecionada == null
                            ? "Selecione a Data"
                            : DateFormat(
                              'dd/MM/yyyy',
                            ).format(_dataSelecionada!),
                      ),
                      trailing: Icon(Icons.calendar_today, color: Colors.pink),
                      onTap: () async {
                        DateTime? dataEscolhida = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 60)),
                        );

                        if (dataEscolhida != null) {
                          setStateDialog(() {
                            _dataSelecionada = dataEscolhida;
                            _horariosDisponiveis = [];
                            _horarioSelecionado = null;
                          });

                          await _loadHorariosDisponiveis(dataEscolhida);
                          setStateDialog(
                            () {},
                          ); // 🔹 Força atualização do dropdown
                        }
                      },
                    ),

                    /// 🔹 Dropdown para seleção de horário disponível
                    _horariosDisponiveis.isEmpty
                        ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Nenhum horário disponível"),
                        )
                        : DropdownButtonFormField<String>(
                          value: _horarioSelecionado,
                          items:
                              _horariosDisponiveis
                                  .map(
                                    (horario) => DropdownMenuItem(
                                      value: horario,
                                      child: Text(horario),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setStateDialog(() {
                              _horarioSelecionado = value;
                            });
                          },
                          decoration: InputDecoration(labelText: "Horário"),
                        ),
                  ],
                ),
              ),
              actions: [
                _buildActionButton("Cancelar", Colors.grey, () {
                  Navigator.pop(context);
                }),
                _buildActionButton("Salvar", Colors.pink, () async {
                  if (nomeController.text.isNotEmpty &&
                      emailController.text.isNotEmpty &&
                      _dataSelecionada != null &&
                      _horarioSelecionado != null) {
                    try {
                      DateTime dataComHorario = DateTime(
                        _dataSelecionada!.year,
                        _dataSelecionada!.month,
                        _dataSelecionada!.day,
                        int.parse(_horarioSelecionado!.split(':')[0]),
                      );

                      await _firestore.collection('appointments').add({
                        'username': nomeController.text,
                        'userId': emailController.text,
                        'phone': telefoneController.text,
                        'instagram': instagramController.text,
                        'date': Timestamp.fromDate(
                          dataComHorario,
                        ), // 🔹 Salvando a data correta
                        'time': _horarioSelecionado,
                        'status': 'pending',
                      });
                      _loadAppointments();
                      Navigator.pop(context);
                    } catch (e) {
                      print("Erro ao criar agendamento: $e");
                    }
                  }
                }),
              ],
            );
          },
        );
      },
    );
  }

  /// 🔹 Campo de texto reutilizável
  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// 🔹 Botão de ação reutilizável
  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: Text(
          "Agenda de Agendamentos",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.pink),
            onPressed: _criarAgendamento,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.pink))
              : Container(),
    );
  }
}
