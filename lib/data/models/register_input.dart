class RegisterInput {
  const RegisterInput({
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.password,
    required this.telefono,
  });

  final String nombre;
  final String apellido;
  final String correo;
  final String password;
  final String telefono;

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'password': password,
      'telefono': telefono,
    };
  }
}
