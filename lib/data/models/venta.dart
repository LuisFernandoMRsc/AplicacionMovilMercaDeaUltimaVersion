import 'detalle_venta.dart';

class VentaModel {
  const VentaModel({
    required this.id,
    required this.productorId,
    required this.comprobadorId,
    required this.fecha,
    required this.montoTotal,
    required this.numeroTransaccion,
    required this.estado,
    required this.detalles,
  });

  final String id;
  final String productorId;
  final String comprobadorId;
  final DateTime fecha;
  final double montoTotal;
  final String numeroTransaccion;
  final String estado;
  final List<DetalleVentaModel> detalles;

  String get estadoNormalizado => estado.toLowerCase();
  bool get estaSolicitada => estadoNormalizado == VentaStatus.solicitada;
  bool get estaAceptadaEnRevision => estadoNormalizado == VentaStatus.aceptadaRevision;
  bool get estaCompletada => estadoNormalizado == VentaStatus.completadaRevisionAceptada;

  factory VentaModel.fromJson(Map<String, dynamic> json) {
    final detallesJson = json['detalles'] as List<dynamic>? ?? const [];
    return VentaModel(
      id: json['id'] as String? ?? '',
      productorId: json['productorId'] as String? ?? '',
      comprobadorId: json['comprobadorId'] as String? ?? '',
      fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
      montoTotal: (json['montoTotal'] as num?)?.toDouble() ?? 0,
      numeroTransaccion: json['numeroTransaccion'] as String? ?? '',
      estado: (json['estado'] as String? ?? VentaStatus.solicitada),
      detalles: detallesJson
          .map((e) => DetalleVentaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VentaStatus {
  static const solicitada = 'solicitada';
  static const aceptadaRevision = 'aceptada-en revision';
  static const completadaRevisionAceptada = 'completada-revision aceptada';

  static String label(String value) {
    final normalized = value.toLowerCase();
    switch (normalized) {
      case aceptadaRevision:
        return 'Aceptada - en revisión';
      case completadaRevisionAceptada:
        return 'Completada - revisión aceptada';
      case solicitada:
      default:
        return 'Solicitada';
    }
  }
}
