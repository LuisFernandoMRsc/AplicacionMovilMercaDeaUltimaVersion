import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/productor.dart';
import '../../providers/catalog_provider.dart';
import '../common/empty_view.dart';
import '../common/loading_view.dart';
import 'producer_products_screen.dart';
import 'widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CatalogProvider>().loadCatalog());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<CatalogProvider>().loadCatalog(refresh: true);
  }

  void _goToProducer(ProductorModel productor) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProducerProductsScreen(productor: productor)),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      decoration: const InputDecoration(
        hintText: 'Buscar por producto o productor',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() => _searchFilter = value.trim().toLowerCase());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: Consumer<CatalogProvider>(
        builder: (context, catalog, _) {
          if (catalog.isLoading && catalog.productos.isEmpty) {
            return const LoadingView();
          }

          if (catalog.errorMessage != null && catalog.productos.isEmpty) {
            return EmptyView(message: catalog.errorMessage!);
          }

          if (catalog.productos.isEmpty) {
            return const EmptyView(message: 'Aún no hay productos disponibles.');
          }

          final productosFiltrados = catalog.productos.where((producto) {
            if (_searchFilter.isEmpty) return true;

            final nombreProducto = producto.nombre.toLowerCase();
            final productor = catalog.productores[producto.productorId];
            final nombreProductor = (productor?.nombreUsuario ?? '').toLowerCase();

            return nombreProducto.contains(_searchFilter) ||
                nombreProductor.contains(_searchFilter);
          }).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: (productosFiltrados.isEmpty ? 2 : productosFiltrados.length + 1),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSearchBar();
                }

                if (productosFiltrados.isEmpty) {
                  return const EmptyView(
                    message: 'No se encontraron coincidencias.',
                  );
                }

                final producto = productosFiltrados[index - 1];
                final productor = catalog.productores[producto.productorId];
                return ProductCard(
                  producto: producto,
                  productor: productor,
                  onTap: productor != null ? () => _goToProducer(productor) : null,
                  showAddButton: false,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
