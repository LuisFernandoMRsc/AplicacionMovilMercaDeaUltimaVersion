class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioActual,
    this.precioMayorista,
    this.cantidadMinimaMayorista,
    required this.unidadMedida,
    required this.categoria,
    required this.atributos,
    required this.imagenes,
    required this.productorId,
    required this.stock,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final double precioActual;
  final double? precioMayorista;
  final int? cantidadMinimaMayorista;
  final String unidadMedida;
  final String categoria;
  final List<String> atributos;
  final List<String> imagenes;
  final String productorId;
  final double stock;

  bool get tienePrecioMayorista =>
      precioMayorista != null && cantidadMinimaMayorista != null;

  double precioParaCantidad(int cantidad) {
    if (tienePrecioMayorista &&
        cantidadMinimaMayorista != null &&
        cantidad >= cantidadMinimaMayorista! &&
        precioMayorista != null) {
      return precioMayorista!;
    }
    return precioActual;
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    final rawImagenes = List<String>.from(json['imagenes'] ?? const []);

    return Producto(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      precioActual: (json['precioActual'] as num?)?.toDouble() ?? 0,
      precioMayorista: (json['precioMayorista'] as num?)?.toDouble(),
      cantidadMinimaMayorista: json['cantidadMinimaMayorista'] as int?,
      unidadMedida: json['unidadMedida'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      atributos: List<String>.from(json['atributos'] ?? const []),
      imagenes: rawImagenes.take(4).toList(),
      productorId: json['productorId'] as String? ?? '',
      stock: (json['stock'] as num?)?.toDouble() ?? 0,
    );
  }
}
