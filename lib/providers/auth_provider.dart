import 'package:flutter/foundation.dart';

import '../core/graphql_service.dart';
import '../data/models/register_input.dart';
import '../data/models/usuario.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _bootstrap();
  }

  final AuthRepository _repository;

  UsuarioProfile? _perfil;
  bool _initializing = true;
  bool _loading = false;
  String? _error;

  UsuarioProfile? get perfil => _perfil;
  bool get isAuthenticated => _perfil != null;
  bool get isInitializing => _initializing;
  bool get isBusy => _loading;
  String? get errorMessage => _error;

  Future<void> _bootstrap() async { 
    try {
      final payload = await _repository.decodeToken();
      if (payload != null && payload['id'] != null) {
        final perfil = await _repository.fetchPerfilActual(payload['id'] as String);
        _perfil = perfil;
      } else {
        await _repository.logout();
      }
    } on GraphQLFailure catch (e) {
      _error = e.message;
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String correo, String password) async {
    _setLoading(true);
    try {
      await _repository.login(correo, password);
      final payload = await _repository.decodeToken();
      final userId = payload?['id'] as String?;
      if (userId == null) {
        throw GraphQLFailure('Token inválido: falta el identificador.');
      }
      _perfil = await _repository.fetchPerfilActual(userId);
      _error = null;
      return true;
    } on GraphQLFailure catch (e) {
      _error = _mapearErrorCredenciales(e.message);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registrar(RegisterInput input) async {
    _setLoading(true);
    try {
      await _repository.registrarUsuario(input);
      _error = null;
      return true;
    } on GraphQLFailure catch (e) {
      _error = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshPerfil() async {
    try {
      final payload = await _repository.decodeToken();
      final userId = payload?['id'] as String?;
      if (userId == null) return;
      _perfil = await _repository.fetchPerfilActual(userId);
      notifyListeners();
    } on GraphQLFailure catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<bool> convertirEnProductor({
    required String direccion,
    required String nit,
    required String numeroCuenta,
    required String banco,
  }) async {
    _setLoading(true);
    try {
      await _repository.convertirEnProductor(
        direccion: direccion,
        nit: nit,
        numeroCuenta: numeroCuenta,
        banco: banco,
      );
      await refreshPerfil();
      _error = null;
      return true;
    } on GraphQLFailure catch (e) {
      _error = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> actualizarPerfil({
    String? nombre,
    String? apellido,
    String? telefono,
  }) async {
    _setLoading(true);
    try {
      final actualizado = await _repository.actualizarPerfil(
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
      );
      _perfil = actualizado;
      _error = null;
      notifyListeners();
      return true;
    } on GraphQLFailure catch (e) {
      _error = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _perfil = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  String _mapearErrorCredenciales(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('usuario no encontrado') ||
        normalized.contains('contraseña incorrecta')) {
      return 'Correo o contraseña incorrecta.';
    }
    return message;
  }
}
