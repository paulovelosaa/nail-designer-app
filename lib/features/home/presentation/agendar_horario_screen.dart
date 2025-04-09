import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AgendarHorarioScreen extends StatefulWidget {
  const AgendarHorarioScreen({super.key});

  @override
  State<AgendarHorarioScreen> createState() => _AgendarHorarioScreenState();
}

class _AgendarHorarioScreenState extends State<AgendarHorarioScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();

  String? _servicoSelecionado;
  double? _precoSelecionado;
  DateTime? _dataSelecionada;
  String? _horarioSelecionado;

  List<Map<String, dynamic>> _servicos = [];
  List<String> _horariosDisponiveis = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
    _carregarServicos();
  }

  Future<void> _carregarDadosUsuario() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _nomeController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _telefoneController.text = data['phone'] ?? '';
        _instagramController.text = data['instagram'] ?? '';
      });
    }
  }

  Future<void> _carregarServicos() async {
    final snapshot = await _firestore.collection('services').get();
    setState(() {
      _servicos =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'name': data['name'],
              'price': (data['price'] as num).toDouble(),
            };
          }).toList();
    });
  }

  Future<void> _selecionarData() async {
    DateTime? escolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      locale: const Locale('pt', 'BR'),
    );
    if (escolhida != null) {
      setState(() {
        _dataSelecionada = escolhida;
        _horarioSelecionado = null;
      });
      await _carregarHorariosDisponiveis();
    }
  }

  Future<void> _carregarHorariosDisponiveis() async {
    if (_dataSelecionada == null) return;
    final dataStr = DateFormat('yyyy-MM-dd').format(_dataSelecionada!);
    final snapshot =
        await _firestore
            .collection('available_slots')
            .where('date', isEqualTo: dataStr)
            .where('available', isEqualTo: true)
            .get();

    setState(() {
      _horariosDisponiveis =
          snapshot.docs.map((doc) => doc['time'].toString()).toList()
            ..sort((a, b) {
              final t1 = int.parse(a.replaceAll(':', ''));
              final t2 = int.parse(b.replaceAll(':', ''));
              return t1.compareTo(t2);
            });
    });
  }

  Future<void> _confirmarAgendamento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_servicoSelecionado == null ||
        _dataSelecionada == null ||
        _horarioSelecionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    await _firestore.collection('appointments').add({
      'cliente': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'telefone': _telefoneController.text.trim(),
      'instagram': _instagramController.text.trim(),
      'servico': _servicoSelecionado,
      'price': _precoSelecionado,
      'date': _dataSelecionada,
      'time': _horarioSelecionado,
      'status': 'PENDENTE',
    });

    final dataStr = DateFormat('yyyy-MM-dd').format(_dataSelecionada!);
    final query =
        await _firestore
            .collection('available_slots')
            .where('date', isEqualTo: dataStr)
            .where('time', isEqualTo: _horarioSelecionado)
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({'available': false});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agendamento realizado com sucesso!')),
    );

    Navigator.pop(context);
  }

  Widget _buildReadOnly(String label, TextEditingController controller) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
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
            "Agendar Horário",
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
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildReadOnly("Nome", _nomeController),
                    _buildReadOnly("E-mail", _emailController),
                    _buildReadOnly("Telefone", _telefoneController),
                    _buildReadOnly("Instagram", _instagramController),
                    DropdownButtonFormField<String>(
                      value: _servicoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Serviço',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items:
                          _servicos.map<DropdownMenuItem<String>>((servico) {
                            return DropdownMenuItem<String>(
                              value: servico['name'],
                              child: Text(
                                "${servico['name']} - R\$ ${servico['price'].toStringAsFixed(2)}",
                              ),
                              onTap: () {
                                _precoSelecionado = servico['price'];
                              },
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() => _servicoSelecionado = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _selecionarData,
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.pink,
                      ),
                      label: Text(
                        _dataSelecionada == null
                            ? "Selecionar data"
                            : DateFormat(
                              'dd/MM/yyyy',
                            ).format(_dataSelecionada!),
                        style: const TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.pink),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_horariosDisponiveis.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _horarioSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Horário disponível',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items:
                            _horariosDisponiveis
                                .map(
                                  (hora) => DropdownMenuItem<String>(
                                    value: hora,
                                    child: Text(hora),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() => _horarioSelecionado = value);
                        },
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _confirmarAgendamento,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Confirmar Agendamento",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
