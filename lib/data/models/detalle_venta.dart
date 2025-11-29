class DetalleVentaModel {
  const DetalleVentaModel({
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  final String productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  factory DetalleVentaModel.fromJson(Map<String, dynamic> json) {
    return DetalleVentaModel(
      productoId: json['productoId'] as String? ?? '',
      nombreProducto: json['nombreProducto'] as String? ?? '',
      cantidad: json['cantidad'] as int? ?? 0,
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }
}
