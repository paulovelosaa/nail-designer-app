import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentModal extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? appointment;

  const AppointmentModal({super.key, required this.onSave, this.appointment});

  @override
  _AppointmentModalState createState() => _AppointmentModalState();
}

class _AppointmentModalState extends State<AppointmentModal> {
  late TextEditingController _clienteController;
  late TextEditingController _telefoneController;
  late TextEditingController _instagramController;
  late TextEditingController _dateController;

  String? _selectedServico;
  String? _selectedHorario;

  List<String> _servicos = [];
  List<String> _horarios = [];

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final appointment = widget.appointment ?? {};

    _clienteController = TextEditingController(
      text: appointment["cliente"] ?? "",
    );
    _telefoneController = TextEditingController(
      text: appointment["telefone"] ?? "",
    );
    _instagramController = TextEditingController(
      text: appointment["instagram"] ?? "",
    );
    _selectedServico = appointment["servico"];
    _selectedHorario = appointment["time"];

    final dynamic dateValue = appointment["date"];
    if (dateValue is Timestamp) {
      _selectedDate = dateValue.toDate();
    }

    _dateController = TextEditingController(
      text:
          _selectedDate != null
              ? DateFormat("dd/MM/yyyy").format(_selectedDate!)
              : "",
    );

    _fetchServicos();
    if (_selectedDate != null) {
      _fetchHorariosPorData(_selectedDate!);
    }
  }

  Future<void> _fetchServicos() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('services').get();
    setState(() {
      _servicos =
          snapshot.docs.map((doc) => doc['name'] as String).toSet().toList();
    });
  }

  Future<void> _fetchHorariosPorData(DateTime date) async {
    final formattedDate =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('available_slots')
              .where('available', isEqualTo: true)
              .where('date', isEqualTo: formattedDate)
              .get();

      final horarios =
          snapshot.docs
              .map((doc) => doc['time']?.toString())
              .whereType<String>()
              .toSet()
              .toList();

      horarios.sort((a, b) {
        final timeA = TimeOfDay(
          hour: int.tryParse(a.split(":")[0]) ?? 0,
          minute: int.tryParse(a.split(":")[1]) ?? 0,
        );
        final timeB = TimeOfDay(
          hour: int.tryParse(b.split(":")[0]) ?? 0,
          minute: int.tryParse(b.split(":")[1]) ?? 0,
        );
        return timeA.hour != timeB.hour
            ? timeA.hour.compareTo(timeB.hour)
            : timeA.minute.compareTo(timeB.minute);
      });

      setState(() {
        _horarios = horarios;
        if (!_horarios.contains(_selectedHorario)) {
          _selectedHorario = null;
        }
      });
    } catch (e) {
      print("❌ Erro ao buscar horários: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao buscar horários disponíveis.")),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale("pt", "BR"),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat("dd/MM/yyyy").format(picked);
        _fetchHorariosPorData(picked);
      });
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _telefoneController.dispose();
    _instagramController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.appointment == null ? "Novo Agendamento" : "Editar Agendamento",
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _clienteController,
              decoration: const InputDecoration(labelText: "Cliente"),
            ),
            TextField(
              controller: _telefoneController,
              decoration: const InputDecoration(labelText: "Telefone"),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _instagramController,
              decoration: const InputDecoration(labelText: "Instagram"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value:
                  _servicos.contains(_selectedServico)
                      ? _selectedServico
                      : null,
              items:
                  _servicos
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              decoration: const InputDecoration(labelText: "Serviço"),
              onChanged: (value) => setState(() => _selectedServico = value),
            ),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: "Data",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              value:
                  _horarios.contains(_selectedHorario)
                      ? _selectedHorario
                      : null,
              items:
                  _horarios
                      .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                      .toList(),
              decoration: const InputDecoration(labelText: "Horário"),
              onChanged: (value) => setState(() => _selectedHorario = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () async {
            if (_selectedDate == null ||
                _selectedServico == null ||
                _selectedHorario == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Preencha todos os campos obrigatórios."),
                ),
              );
              return;
            }

            await widget.onSave({
              "cliente": _clienteController.text.trim(),
              "telefone": _telefoneController.text.trim(),
              "instagram": _instagramController.text.trim(),
              "servico": _selectedServico,
              "date": Timestamp.fromDate(_selectedDate!),
              "time": _selectedHorario,
              "status": widget.appointment?['status'] ?? 'PENDENTE',
            });

            // 🔐 Atualiza slot como indisponível
            final formattedDate =
                "${_selectedDate!.year.toString().padLeft(4, '0')}-"
                "${_selectedDate!.month.toString().padLeft(2, '0')}-"
                "${_selectedDate!.day.toString().padLeft(2, '0')}";

            final query =
                await FirebaseFirestore.instance
                    .collection('available_slots')
                    .where('date', isEqualTo: formattedDate)
                    .where('time', isEqualTo: _selectedHorario)
                    .limit(1)
                    .get();

            if (query.docs.isNotEmpty) {
              await query.docs.first.reference.update({'available': false});
            }
          },
          child: const Text("Salvar"),
        ),
      ],
    );
  }
}
