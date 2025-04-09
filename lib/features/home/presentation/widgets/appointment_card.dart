import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic> service;
  final Function(String)? onUpdateStatus;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isWeeklyView;
  final bool isCliente;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.service,
    required this.isWeeklyView,
    required this.isCliente,
    this.onUpdateStatus,
    this.onEdit,
    this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "CONFIRMADO":
        return Colors.green;
      case "PENDENTE":
        return Colors.amber;
      case "RECUSADO":
      case "CANCELADO PELO CLIENTE":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date is String) return date;
    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(date.toDate());
    }
    return "Data inválida";
  }

  DateTime? _getDateTime(dynamic date, String time) {
    try {
      if (date is Timestamp) {
        final data = date.toDate();
        final partes = time.split(":");
        return DateTime(
          data.year,
          data.month,
          data.day,
          int.parse(partes[0]),
          int.parse(partes[1]),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _cancelarAgendamento(BuildContext context, String idDoc) async {
    try {
      await FirebaseFirestore.instance
          .collection("appointments")
          .doc(idDoc)
          .update({'status': 'CANCELADO PELO CLIENTE'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento cancelado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao cancelar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.035;
    double iconSize = screenWidth * 0.06;

    final cliente = appointment["cliente"] ?? "Não informado";
    final telefone = appointment["telefone"] ?? "Não informado";
    final instagram = appointment["instagram"] ?? "Não informado";
    final servico = appointment["servico"] ?? "Serviço não encontrado";
    final horario = appointment["time"] ?? "Não informado";
    final status = (appointment["status"] ?? "PENDENTE").toString();
    final id = appointment["id"];
    final dataAgendamento = _getDateTime(appointment["date"], horario);

    final podeCancelar =
        isCliente &&
        status != "CANCELADO PELO CLIENTE" &&
        dataAgendamento != null &&
        dataAgendamento.isAfter(DateTime.now().add(const Duration(hours: 24)));

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              Icons.person,
              "Cliente: $cliente",
              fontSize,
              iconSize,
            ),
            _buildInfoRow(
              Icons.phone,
              "Telefone: $telefone",
              fontSize,
              iconSize,
            ),
            _buildInfoRow(
              Icons.camera_alt,
              "Instagram: $instagram",
              fontSize,
              iconSize,
            ),
            _buildInfoRow(Icons.build, "Serviço: $servico", fontSize, iconSize),
            _buildInfoRow(
              Icons.calendar_today,
              "Data: ${_formatDate(appointment["date"])}",
              fontSize,
              iconSize,
            ),
            _buildInfoRow(
              Icons.access_time,
              "Horário: $horario",
              fontSize,
              iconSize,
            ),
            const SizedBox(height: 12),
            _buildStatus(fontSize, iconSize, status),

            Align(
              alignment: Alignment.centerRight,
              child: Builder(
                builder: (_) {
                  if (podeCancelar && id != null) {
                    return ElevatedButton.icon(
                      onPressed: () => _cancelarAgendamento(context, id),
                      icon: const Icon(Icons.cancel),
                      label: const Text("Cancelar Agendamento"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }

                  if (!isCliente && !isWeeklyView) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.check,
                                color: Colors.green,
                                size: iconSize,
                              ),
                              onPressed:
                                  () => onUpdateStatus?.call("CONFIRMADO"),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.red,
                                size: iconSize,
                              ),
                              onPressed: () => onUpdateStatus?.call("RECUSADO"),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: iconSize,
                              ),
                              onPressed: onEdit,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.pink,
                                size: iconSize,
                              ), // ✅ Cor rosa
                              onPressed: onDelete,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 80,
                        ), // ✅ Espaço extra para não sobrepor o FAB
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    double fontSize,
    double iconSize,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[700], size: iconSize),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(double fontSize, double iconSize, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label,
            color: _getStatusColor(status),
            size: iconSize * 0.8,
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }
}
