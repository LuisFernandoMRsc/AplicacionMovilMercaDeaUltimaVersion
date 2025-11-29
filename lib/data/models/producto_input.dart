class ProductoInput {
  const ProductoInput({
    required this.nombre,
    required this.descripcion,
    required this.precioActual,
    this.precioMayorista,
    this.cantidadMinimaMayorista,
    required this.unidadMedida,
    required this.categoria,
    required this.stock,
    required this.atributos,
    required this.imagenes,
  });

  final String nombre;
  final String descripcion;
  final double precioActual;
  final double? precioMayorista;
  final int? cantidadMinimaMayorista;
  final String unidadMedida;
  final String categoria;
  final double stock;
  final List<String> atributos;
  final List<String> imagenes;

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precioActual': precioActual,
      'precioMayorista': precioMayorista,
      'cantidadMinimaMayorista': cantidadMinimaMayorista,
      'unidadMedida': unidadMedida,
      'categoria': categoria,
      'stock': stock,
      'atributo': atributos,
      'imagenes': imagenes,
    };
  }
}
