import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/productor.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../common/empty_view.dart';
import '../common/loading_view.dart';
import 'widgets/product_card.dart';

class ProducerProductsScreen extends StatefulWidget {
  const ProducerProductsScreen({super.key, required this.productor});

  final ProductorModel productor;

  @override
  State<ProducerProductsScreen> createState() => _ProducerProductsScreenState();
}

class _ProducerProductsScreenState extends State<ProducerProductsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CatalogProvider>().loadCatalog());
  }

  Future<void> _refresh() async {
    await context.read<CatalogProvider>().loadCatalog(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.productor.nombreUsuario)),
      body: Consumer2<CatalogProvider, CartProvider>(
        builder: (context, catalog, cart, _) {
          final productos = catalog.productos
              .where((producto) => producto.productorId == widget.productor.id)
              .toList();

          if (catalog.isLoading && productos.isEmpty) {
            return const LoadingView();
          }

          if (productos.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                children: const [
                  EmptyView(message: 'Este productor aún no tiene productos publicados.'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: productos.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ProducerHeader(productor: widget.productor);
                }

                final producto = productos[index - 1];
                return ProductCard(
                  producto: producto,
                  productor: widget.productor,
                  onAdd: () {
                    try {
                      cart.addProduct(producto);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${producto.nombre} agregado al carrito')),
                      );
                    } on Exception catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$e')));
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProducerHeader extends StatelessWidget {
  const _ProducerHeader({required this.productor});

  final ProductorModel productor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productor.nombreUsuario,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Dirección: ${productor.direccion}'),
            Text('NIT: ${productor.nit}'),
          ],
        ),
      ),
    );
  }
}
