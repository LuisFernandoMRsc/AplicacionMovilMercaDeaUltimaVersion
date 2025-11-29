class ComprobadorModel {
  const ComprobadorModel({
    required this.id,
    required this.nombreUsuario,
    required this.estaDisponible,
    required this.cuposDisponibles,
  });

  final String id;
  final String nombreUsuario;
  final bool estaDisponible;
  final int cuposDisponibles;

  bool get tieneCupos => cuposDisponibles > 0;

  factory ComprobadorModel.fromJson(Map<String, dynamic> json) {
    return ComprobadorModel(
      id: json['id'] as String? ?? '',
      nombreUsuario: json['nombreUsuario'] as String? ?? '',
      estaDisponible: json['estaDisponible'] as bool? ?? false,
      cuposDisponibles: json['cuposDisponibles'] as int? ?? 0,
    );
  }
}
