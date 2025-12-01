import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/venta_provider.dart';
import '../../utils/formatters.dart';
import '../common/empty_view.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const _bancoEmpresa = 'Mercantil';
  static const _cuentaEmpresa = '40745060029';

  void _changeQuantity(CartProvider cart, String productoId, int cantidad) {
    try {
      cart.updateQuantity(productoId, cantidad);
    } on Exception catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _checkout(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final ventas = context.read<VentaProvider>();

    if (!cart.canCheckout) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos en el carrito.')),
      );
      return;
    }

    try {
      final numeroTx = await _requestTransactionNumber(context, cart);
      if (numeroTx == null) return;
      cart.setNumeroTransaccion(numeroTx);
      await ventas.crearVenta(
        cart: cart,
        numeroTransaccion: numeroTx,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta creada correctamente.')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      final message = e.toString();
      const propioProductoMsg = 'No puedes comprar tus propios productos.';
      final displayMessage =
          message.contains(propioProductoMsg) ? propioProductoMsg : message;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(displayMessage)));
    }
  }

  Future<String?> _requestTransactionNumber(
    BuildContext context,
    CartProvider cart,
  ) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _NumeroTransaccionDialog(
          initialValue: cart.numeroTransaccion,
          banco: _bancoEmpresa,
          cuenta: _cuentaEmpresa,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const EmptyView(message: 'Tu carrito está vacío.');
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final unitPrice = item.precioUnitario;
                    final usaMayorista =
                        item.producto.tienePrecioMayorista &&
                        unitPrice != item.producto.precioActual;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(item.producto.nombre),
                        subtitle: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${formatMoney(unitPrice)} • ${item.producto.unidadMedida}' +
                                  (usaMayorista ? ' (mayorista)' : ''),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Subtotal: ${formatMoney(item.subtotal)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 140,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () => _changeQuantity(
                                  cart,
                                  item.producto.id,
                                  item.cantidad - 1,
                                ),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${item.cantidad}', style: const TextStyle(fontSize: 16)),
                              IconButton(
                                onPressed: () => _changeQuantity(
                                  cart,
                                  item.producto.id,
                                  item.cantidad + 1,
                                ),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 18)),
                        Text(
                          formatMoney(cart.total),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (cart.items.any((item) =>
                        item.producto.tienePrecioMayorista &&
                        item.precioUnitario != item.producto.precioActual)) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Incluye precios mayoristas según las cantidades seleccionadas.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet_outlined),
                        title: const Text('Datos para transferir'),
                        subtitle: Text('Banco $_bancoEmpresa • Cuenta $_cuentaEmpresa'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'El comprobador verá los datos del productor. Tú solo debes transferir a la cuenta oficial de la empresa.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _checkout(context),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirmar compra'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NumeroTransaccionDialog extends StatefulWidget {
  const _NumeroTransaccionDialog({
    required this.initialValue,
    required this.banco,
    required this.cuenta,
  });

  final String? initialValue;
  final String banco;
  final String cuenta;

  @override
  State<_NumeroTransaccionDialog> createState() => _NumeroTransaccionDialogState();
}

class _NumeroTransaccionDialogState extends State<_NumeroTransaccionDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar transferencia'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transfiere el total a la cuenta oficial de la empresa y registra el número de transacción.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: ListTile(
                  leading: const Icon(Icons.account_balance),
                  title: Text('Banco ${widget.banco}'),
                  subtitle: Text('Cuenta: ${widget.cuenta}'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Número de transacción',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el número de transacción';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_controller.text.trim());
          },
          icon: const Icon(Icons.verified),
          label: const Text('Confirmar'),
        ),
      ],
    );
  }
}
