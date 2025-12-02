import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/producto.dart';
import '../../data/models/productor.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/image_resolver.dart';
import '../common/empty_view.dart';
import '../common/loading_view.dart';
import 'editar_producto_screen.dart';
import 'crear_producto_screen.dart';

class MisProductosScreen extends StatefulWidget {
  const MisProductosScreen({super.key});

  @override
  State<MisProductosScreen> createState() => _MisProductosScreenState();
}

class _MisProductosScreenState extends State<MisProductosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CatalogProvider>().loadCatalog());
  }

  Future<void> _refresh() async {
    await context.read<CatalogProvider>().loadCatalog(refresh: true);
  }

  void _goToCrearProducto() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CrearProductoScreen()),
    );
  }

  Future<void> _editarProducto(Producto producto) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditarProductoScreen(producto: producto)),
    );
    if (updated == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _eliminarProducto(Producto producto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Deseas eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final catalog = context.read<CatalogProvider>();
    final ok = await catalog.eliminarProducto(producto.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${producto.nombre} eliminado.')),
      );
    } else {
      final error = catalog.createError ?? 'No fue posible eliminar el producto.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<AuthProvider>().perfil;
    final userId = perfil?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis productos')),
      floatingActionButton: userId != null
          ? FloatingActionButton.extended(
              onPressed: _goToCrearProducto,
              icon: const Icon(Icons.add),
              label: const Text('Agregar producto'),
            )
          : null,
      body: Consumer<CatalogProvider>(
        builder: (context, catalog, _) {
          if (catalog.isLoading && catalog.productos.isEmpty) {
            return const LoadingView();
          }

          if (catalog.errorMessage != null && catalog.productos.isEmpty) {
            return EmptyView(message: catalog.errorMessage!);
          }

          if (userId == null) {
            return const EmptyView(
              message: 'Debes iniciar sesión para ver tus productos.',
            );
          }

          ProductorModel? productorActual;
          for (final productor in catalog.productores.values) {
            if (productor.idUsuario == userId) {
              productorActual = productor;
              break;
            }
          }

          final productorSeleccionado = productorActual;

          if (productorSeleccionado == null) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                children: const [
                  EmptyView(
                    message:
                        'Aún no estás registrado como productor en el catálogo.',
                  ),
                ],
              ),
            );
          }

          final propios = catalog.productos
              .where((producto) => producto.productorId == productorSeleccionado.id)
              .toList();

          if (propios.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                children: [
                  const EmptyView(
                    message:
                        'Aún no registraste productos. Usa el botón para agregar uno nuevo.',
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _goToCrearProducto,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Crear producto'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: propios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final producto = propios[index];
                final imageUrl = producto.imagenes.isNotEmpty
                    ? resolveImageUrl(producto.imagenes.first)
                    : null;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child:
                                  const Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto.nombre,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              producto.descripcion,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              children: [
                                Chip(
                                  label: Text(
                                    'Precio: ${formatMoney(producto.precioActual)}',
                                  ),
                                ),
                                if (producto.tienePrecioMayorista &&
                                    producto.precioMayorista != null &&
                                    producto.cantidadMinimaMayorista != null)
                                  Chip(
                                    label: Text(
                                      'Mayorista: ${formatMoney(producto.precioMayorista!)} '
                                      'desde ${producto.cantidadMinimaMayorista} u.',
                                    ),
                                  ),
                                Chip(
                                  label: Text(
                                    '${producto.stock.toStringAsFixed(0)} en stock',
                                  ),
                                ),
                                Chip(label: Text(producto.unidadMedida)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _editarProducto(producto),
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                          ),
                          TextButton.icon(
                            onPressed: () => _eliminarProducto(producto),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
