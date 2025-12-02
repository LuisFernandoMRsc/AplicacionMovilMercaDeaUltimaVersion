import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/graphql_service.dart';
import '../data/models/venta.dart';
import '../data/repositories/venta_repository.dart';
import 'cart_provider.dart';

class VentaProvider extends ChangeNotifier {
  VentaProvider(this._ventaRepository);

  final VentaRepository _ventaRepository;
  Timer? _autoRefreshTimer;
  bool _autoRefreshStarted = false;
  bool _ventasInitialized = false;
  bool _ventasProductorInitialized = false;

  List<VentaModel> _ventas = const [];
  List<VentaModel> _ventasProductor = const [];
  bool _loading = false;
  bool _loadingProductor = false;
  String? _error;
  String? _errorProductor;

  List<VentaModel> get ventas => _ventas;
  List<VentaModel> get ventasProductor => _ventasProductor;
  bool get isLoading => _loading;
  bool get isLoadingProductor => _loadingProductor;
  String? get errorMessage => _error;
  String? get errorProductor => _errorProductor;

  void reset() {
    _ventas = const [];
    _ventasProductor = const [];
    _error = null;
    _errorProductor = null;
    _loading = false;
    _loadingProductor = false;
    _ventasInitialized = false;
    _ventasProductorInitialized = false;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    _autoRefreshStarted = false;
    notifyListeners();
  }

  Future<void> loadVentas({bool refresh = false, bool silent = false}) async {
    _ventasInitialized = true;
    if (_ventas.isNotEmpty && !refresh) {
      _ensureAutoRefresh();
      return;
    }
    if (!silent) {
      _setLoading(true);
    }
    try {
      _ventas = await _ventaRepository.fetchMisVentas();
      _error = null;
    } on GraphQLFailure catch (e) {
      _error = e.message;
    } finally {
      if (!silent) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
      _ensureAutoRefresh();
    }
  }

  Future<void> loadVentasProductor({bool refresh = false, bool silent = false}) async {
    _ventasProductorInitialized = true;
    if (_ventasProductor.isNotEmpty && !refresh) {
      _ensureAutoRefresh();
      return;
    }
    if (!silent) {
      _setLoadingProductor(true);
    }
    try {
      _ventasProductor = await _ventaRepository.fetchVentasProductor();
      _errorProductor = null;
    } on GraphQLFailure catch (e) {
      _errorProductor = e.message;
    } finally {
      if (!silent) {
        _setLoadingProductor(false);
      } else {
        notifyListeners();
      }
      _ensureAutoRefresh();
    }
  }

  Future<void> aceptarVenta(String ventaId) async {
    _setLoadingProductor(true);
    try {
      await _ventaRepository.aceptarVenta(ventaId: ventaId);
      _errorProductor = null;
      await loadVentasProductor(refresh: true);
    } on GraphQLFailure catch (e) {
      _errorProductor = e.message;
    } finally {
      _setLoadingProductor(false);
    }
  }

  Future<void> denegarVentaProductor(String ventaId) async {
    _setLoadingProductor(true);
    try {
      await _ventaRepository.denegarVentaProductor(ventaId: ventaId);
      _errorProductor = null;
      await loadVentasProductor(refresh: true);
    } on GraphQLFailure catch (e) {
      _errorProductor = e.message;
    } finally {
      _setLoadingProductor(false);
    }
  }

  Future<VentaModel?> crearVenta({
    required CartProvider cart,
    required String numeroTransaccion,
  }) async {
    if (!cart.canCheckout) {
      throw GraphQLFailure('No hay productos en el carrito.');
    }
    if (numeroTransaccion.trim().isEmpty) {
      throw GraphQLFailure('Debes ingresar el número de transacción.');
    }
    _setLoading(true);
    try {
      final venta = await _ventaRepository.crearVenta(
        productorId: cart.productorId!,
        numeroTransaccion: numeroTransaccion.trim(),
        detalles: cart.toDetalleInput(),
      );
      _ventas = [venta, ..._ventas];
      cart.clear();
      _error = null;
      return venta;
    } on GraphQLFailure catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setLoadingProductor(bool value) {
    _loadingProductor = value;
    notifyListeners();
  }

  void _ensureAutoRefresh() {
    if (_autoRefreshStarted) return;
    _autoRefreshStarted = true;
    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_ventasInitialized) {
        await loadVentas(refresh: true, silent: true);
      }
      if (_ventasProductorInitialized) {
        await loadVentasProductor(refresh: true, silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
