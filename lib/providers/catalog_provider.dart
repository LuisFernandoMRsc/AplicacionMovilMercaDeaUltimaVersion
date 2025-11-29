import 'package:flutter/foundation.dart';

import '../core/graphql_service.dart';
import '../data/models/producto.dart';
import '../data/models/producto_input.dart';
import '../data/models/productor.dart';
import '../data/repositories/catalog_repository.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._repository);

  final CatalogRepository _repository;

  List<Producto> _productos = const [];
  Map<String, ProductorModel> _productores = const <String, ProductorModel>{};
  bool _loading = false;
  bool _creatingProduct = false;
  String? _error;
  String? _createError;

  List<Producto> get productos => _productos;
  Map<String, ProductorModel> get productores => _productores;
  bool get isLoading => _loading;
  bool get isCreatingProduct => _creatingProduct;
  String? get errorMessage => _error;
  String? get createError => _createError;

  Future<void> loadCatalog({bool refresh = false}) async {
    if (_productos.isNotEmpty && !refresh) return;
    _setLoading(true);
    try {
      final data = await _repository.fetchCatalog();
      _productos = data.productos;
      _productores = {
        for (final productor in data.productores) productor.id: productor,
      };
      _error = null;
    } on GraphQLFailure catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> crearProducto(ProductoInput input) async {
    _creatingProduct = true;
    _createError = null;
    notifyListeners();
    try {
      await _repository.crearProducto(input);
      await loadCatalog(refresh: true);
      return true;
    } on GraphQLFailure catch (e) {
      _createError = e.message;
      return false;
    } finally {
      _creatingProduct = false;
      notifyListeners();
    }
  }

  Future<bool> editarProducto(String productoId, ProductoInput input) async {
    _createError = null;
    notifyListeners();
    try {
      await _repository.editarProducto(productoId, input);
      await loadCatalog(refresh: true);
      return true;
    } on GraphQLFailure catch (e) {
      _createError = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> eliminarProducto(String nombreProducto) async {
    _createError = null;
    notifyListeners();
    try {
      final deleted = await _repository.eliminarProducto(nombreProducto);
      if (deleted) {
        await loadCatalog(refresh: true);
      }
      return deleted;
    } on GraphQLFailure catch (e) {
      _createError = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
