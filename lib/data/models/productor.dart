class ProductorModel {
  const ProductorModel({
    required this.id,
    required this.idUsuario,
    required this.nombreUsuario,
    required this.direccion,
    required this.nit,
    required this.numeroCuenta,
    required this.banco,
  });

  final String id;
  final String idUsuario;
  final String nombreUsuario;
  final String direccion;
  final String nit;
  final String numeroCuenta;
  final String banco;

  factory ProductorModel.fromJson(Map<String, dynamic> json) {
    return ProductorModel(
      id: json['id'] as String? ?? '',
      idUsuario: json['idUsuario'] as String? ?? '',
      nombreUsuario: json['nombreUsuario'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      nit: json['nit'] as String? ?? '',
      numeroCuenta: json['numeroCuenta'] as String? ?? '',
      banco: json['banco'] as String? ?? '',
    );
  }
}
