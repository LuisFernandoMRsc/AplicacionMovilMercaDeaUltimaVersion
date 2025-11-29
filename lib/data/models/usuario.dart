class UsuarioProfile {
  const UsuarioProfile({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    required this.roles,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final List<String> roles;

  bool get esProductor => roles.contains('productor');
  bool get esComprobador => roles.contains('comprobador');
  bool get esAdmin => roles.contains('admin');

  factory UsuarioProfile.fromJson(Map<String, dynamic> json) {
    return UsuarioProfile(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      roles: List<String>.from(json['roles'] ?? const []),
    );
  }
}
