import 'package:flutter/foundation.dart';

import '../core/graphql_service.dart';
import '../data/models/comprobador.dart';
import '../data/models/venta.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/venta_repository.dart';
import 'cart_provider.dart';

class VentaProvider extends ChangeNotifier {
  VentaProvider(this._ventaRepository, this._catalogRepository);

  final VentaRepository _ventaRepository;
  final CatalogRepository _catalogRepository;

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
    notifyListeners();
  }

  Future<void> loadVentas({bool refresh = false}) async {
    if (_ventas.isNotEmpty && !refresh) return;
    _setLoading(true);
    try {
      _ventas = await _ventaRepository.fetchMisVentas();
      _error = null;
    } on GraphQLFailure catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadVentasProductor({bool refresh = false}) async {
    if (_ventasProductor.isNotEmpty && !refresh) return;
    _setLoadingProductor(true);
    try {
      _ventasProductor = await _ventaRepository.fetchVentasProductor();
      _errorProductor = null;
    } on GraphQLFailure catch (e) {
      _errorProductor = e.message;
    } finally {
      _setLoadingProductor(false);
    }
  }

  Future<void> aceptarVenta(String ventaId) async {
    _setLoadingProductor(true);
    try {
      await _ventaRepository.aceptarVenta(ventaId: ventaId);
      await loadVentasProductor(refresh: true);
    } on GraphQLFailure catch (e) {
      _errorProductor = e.message;
    } finally {
      _setLoadingProductor(false);
    }
  }

  Future<VentaModel?> crearVenta({
    required CartProvider cart,
    required String comprobadorId,
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
        comprobadorId: comprobadorId,
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

  Future<List<ComprobadorModel>> comprobadoresDisponibles() async {
    final comprobadores = await _catalogRepository.fetchComprobadores();
    return comprobadores
        .where((c) => c.estaDisponible && c.tieneCupos)
        .toList();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setLoadingProductor(bool value) {
    _loadingProductor = value;
    notifyListeners();
  }
}
