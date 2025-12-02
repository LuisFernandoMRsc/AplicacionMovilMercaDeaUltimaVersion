import 'package:flutter/foundation.dart';

import '../core/graphql_service.dart';
import '../data/models/productor.dart';
import '../data/models/register_input.dart';
import '../data/models/usuario.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _bootstrap();
  }

  final AuthRepository _repository;

  UsuarioProfile? _perfil;
  ProductorModel? _productor;
  bool _initializing = true;
  bool _loading = false;
  String? _error;

  UsuarioProfile? get perfil => _perfil;
  ProductorModel? get productor => _productor;
  bool get isAuthenticated => _perfil != null;
  bool get isInitializing => _initializing;
  bool get isBusy => _loading;
  String? get errorMessage => _error;

  Future<void> _bootstrap() async { 
    try {
      final payload = await _repository.decodeToken();
      if (payload != null && payload['id'] != null) {
        final userId = payload['id'] as String;
        final perfil = await _repository.fetchPerfilActual(userId);
        _perfil = perfil;
        await _loadProductor(userId);
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
      await _loadProductor(userId);
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
      _error = _mapearErrorRegistro(e.message);
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
      await _loadProductor(userId);
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

  Future<bool> actualizarDatosProductor({
    String? nombreUsuario,
    String? direccion,
    String? nit,
    String? numeroCuenta,
    String? banco,
  }) async {
    if (!(_perfil?.esProductor ?? false)) {
      _error = 'No eres productor.';
      notifyListeners();
      return false;
    }

    String? trimOrNull(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    }

    final payload = <String, String?>{
      'nombreUsuario': trimOrNull(nombreUsuario),
      'direccion': trimOrNull(direccion),
      'nit': trimOrNull(nit),
      'numeroCuenta': trimOrNull(numeroCuenta),
      'banco': trimOrNull(banco),
    };

    if (payload.values.every((value) => value == null)) {
      _error = 'No hay cambios para guardar.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final actualizado = await _repository.editarProductor(
        nombreUsuario: payload['nombreUsuario'],
        direccion: payload['direccion'],
        nit: payload['nit'],
        numeroCuenta: payload['numeroCuenta'],
        banco: payload['banco'],
      );
      _productor = actualizado;
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
    _productor = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> _loadProductor(String userId) async {
    try {
      if (_perfil?.esProductor ?? false) {
        _productor = await _repository.fetchProductorActual(userId);
      } else {
        _productor = null;
      }
    } on GraphQLFailure catch (e) {
      _error = e.message;
    }
  }

  String _mapearErrorCredenciales(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('usuario no encontrado') ||
        normalized.contains('contraseña incorrecta') ||
        normalized.contains('correo o contraseña incorrectos') ||
        normalized.contains('unexpected execution error')) {
      return 'Correo o contraseña incorrectos.';
    }
    return message;
  }

  String _mapearErrorRegistro(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('usuario_duplicado') ||
        normalized.contains('correo o teléfono') ||
        normalized.contains('correo ya está en uso')) {
      return 'Este correo ya está en uso.';
    }

    if (normalized.contains('unexpected execution error')) {
      return 'No pudimos crear la cuenta. Intenta nuevamente en unos minutos.';
    }

    return message;
  }
}
