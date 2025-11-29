import 'producto.dart';

class CartItem {
  const CartItem({required this.producto, required this.cantidad});

  final Producto producto;
  final int cantidad;

  double get precioUnitario => producto.precioParaCantidad(cantidad);
  double get subtotal => precioUnitario * cantidad;

  CartItem copyWith({Producto? producto, int? cantidad}) {
    return CartItem(
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}
