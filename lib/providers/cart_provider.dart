import 'package:flutter/foundation.dart';

import '../core/graphql_service.dart';
import '../data/models/cart_item.dart';
import '../data/models/producto.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? _productorId;
  String? _numeroTransaccion;

  List<CartItem> get items => _items.values.toList();
  String? get productorId => _productorId;
  bool get isEmpty => _items.isEmpty;
  bool get canCheckout => _items.isNotEmpty && _productorId != null;
  double get total =>
      _items.values.fold(0, (sum, item) => sum + item.subtotal);
  String? get numeroTransaccion => _numeroTransaccion;

  void addProduct(Producto producto) {
    if (_productorId != null && _productorId != producto.productorId) {
      throw GraphQLFailure(
        'Solo puedes comprar productos del mismo productor en una venta.',
      );
    }

    _productorId ??= producto.productorId;
    final item = _items[producto.id];
    if (item == null) {
      if (producto.stock < 1) {
        throw GraphQLFailure('No hay stock disponible para este producto.');
      }
      _items[producto.id] = CartItem(producto: producto, cantidad: 1);
    } else {
      final nextCantidad = item.cantidad + 1;
      if (nextCantidad > producto.stock) {
        throw GraphQLFailure('Stock insuficiente para ${producto.nombre}.');
      }
      _items[producto.id] = item.copyWith(cantidad: nextCantidad);
    }
    notifyListeners();
  }

  void updateQuantity(String productoId, int cantidad) {
    if (!_items.containsKey(productoId)) return;
    if (cantidad <= 0) {
      removeItem(productoId);
      return;
    }
    final item = _items[productoId]!;
    if (cantidad > item.producto.stock) {
      throw GraphQLFailure('Stock insuficiente para ${item.producto.nombre}.');
    }
    _items[productoId] = item.copyWith(cantidad: cantidad);
    notifyListeners();
  }

  void removeItem(String productoId) {
    _items.remove(productoId);
    if (_items.isEmpty) {
      _productorId = null;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _productorId = null;
    _numeroTransaccion = null;
    notifyListeners();
  }

  void setNumeroTransaccion(String? valor) {
    _numeroTransaccion = valor;
    notifyListeners();
  }

  List<Map<String, dynamic>> toDetalleInput() {
    return _items.values
        .map((item) => {
              'productoId': item.producto.id,
              'cantidad': item.cantidad,
            })
        .toList();
  }
}
