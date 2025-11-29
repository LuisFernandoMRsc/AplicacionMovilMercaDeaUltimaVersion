import 'package:jwt_decoder/jwt_decoder.dart';

import '../../core/graphql_service.dart';
import '../../core/token_storage.dart';
import '../models/register_input.dart';
import '../models/usuario.dart';

class AuthRepository {
  AuthRepository(this._service, this._tokenStorage);

  final GraphQLService _service;
  final TokenStorage _tokenStorage;

  Future<String> login(String correo, String password) async {
    const mutation = r'''
      mutation Login($correo: String!, $password: String!) {
        login(correo: $correo, password: $password)
      }
    ''';

    final result = await _service.mutate(
      document: mutation,
      variables: {'correo': correo, 'password': password},
      requiresAuth: false,
    );

    final token = result.data?['login'] as String?;
    if (token == null || token.isEmpty) {
      throw GraphQLFailure('No se recibió token de autenticación.');
    }
    await _tokenStorage.saveToken(token);
    return token;
  }

  Future<UsuarioProfile> fetchPerfilActual(String userId) async {
    const query = r'''
      query Perfil {
        usuarios {
          id
          nombre
          apellido
          correo
          telefono
          roles
        }
      }
    ''';

    final result = await _service.query(document: query);
    final usuarios = result.data?['usuarios'] as List<dynamic>?;
    if (usuarios == null) {
      throw GraphQLFailure('No se pudo obtener el perfil de usuario.');
    }

    final perfilJson = usuarios.cast<Map<String, dynamic>>()
        .firstWhere((u) => u['id'] == userId, orElse: () => {});

    if (perfilJson.isEmpty) {
      throw GraphQLFailure('El usuario no existe en la base de datos.');
    }

    return UsuarioProfile.fromJson(perfilJson);
  }

  Future<UsuarioProfile> registrarUsuario(RegisterInput input) async {
    const mutation = r'''
      mutation CrearUsuario($input: CrearUsuarioInput!) {
        crearUsuario(input: $input) {
          id
          nombre
          apellido
          correo
          telefono
          roles
        }
      }
    ''';

    final result = await _service.mutate(
      document: mutation,
      variables: {
        'input': {
          'nombre': input.nombre,
          'apellido': input.apellido,
          'correo': input.correo,
          'password': input.password,
          'telefono': input.telefono,
        },
      },
      requiresAuth: false,
    );

    final data = result.data?['crearUsuario'] as Map<String, dynamic>?;
    if (data == null) {
      throw GraphQLFailure('No fue posible registrar al usuario.');
    }

    return UsuarioProfile.fromJson(data);
  }

  Future<void> convertirEnProductor({
    required String direccion,
    required String nit,
    required String numeroCuenta,
    required String banco,
  }) async {
    const mutation = r'''
      mutation ConvertirEnProductor(
        $direccion: String!,
        $nit: String!,
        $numeroCuenta: String!,
        $banco: String!
      ) {
        convertirEnProductor(
          direccion: $direccion,
          nit: $nit,
          numeroCuenta: $numeroCuenta,
          banco: $banco
        ) {
          idUsuario
        }
      }
    ''';

    await _service.mutate(
      document: mutation,
      variables: {
        'direccion': direccion,
        'nit': nit,
        'numeroCuenta': numeroCuenta,
        'banco': banco,
      },
    );
  }

  Future<UsuarioProfile> actualizarPerfil({
    String? nombre,
    String? apellido,
    String? telefono,
  }) async {
    const mutation = r'''
      mutation ActualizarUsuario($input: ActualizarUsuarioInput!) {
        actualizarUsuario(input: $input) {
          id
          nombre
          apellido
          correo
          telefono
          roles
        }
      }
    ''';

    final input = <String, dynamic>{};
    if (nombre != null) input['nombre'] = nombre;
    if (apellido != null) input['apellido'] = apellido;
    if (telefono != null) input['telefono'] = telefono;

    if (input.isEmpty) {
      throw GraphQLFailure('No hay cambios para actualizar.');
    }

    final result = await _service.mutate(
      document: mutation,
      variables: {'input': input},
    );

    final data = result.data?['actualizarUsuario'] as Map<String, dynamic>?;
    if (data == null) {
      throw GraphQLFailure('No se pudo actualizar el perfil.');
    }

    return UsuarioProfile.fromJson(data);
  }

  Future<Map<String, dynamic>?> decodeToken() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;
    return JwtDecoder.tryDecode(token);
  }

  Future<String?> readToken() => _tokenStorage.readToken();

  Future<void> logout() async {
    await _tokenStorage.clearToken();
  }
}
