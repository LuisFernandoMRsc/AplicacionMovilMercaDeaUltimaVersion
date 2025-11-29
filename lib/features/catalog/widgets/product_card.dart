import 'package:flutter/material.dart';

import '../../../data/models/producto.dart';
import '../../../data/models/productor.dart';
import '../../../utils/formatters.dart';
import '../../../utils/image_resolver.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.producto,
    this.productor,
    this.onAdd,
    this.onTap,
    this.showAddButton = true,
  });

  final Producto producto;
  final ProductorModel? productor;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    final imageUrl = producto.imagenes.isNotEmpty ? producto.imagenes.first : null;
    final resolvedImageUrl = imageUrl != null ? resolveImageUrl(imageUrl) : null;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resolvedImageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  resolvedImageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          producto.nombre,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        formatMoney(producto.precioActual),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.green.shade700),
                      ),
                    ],
                  ),
                  if (producto.tienePrecioMayorista &&
                      producto.precioMayorista != null &&
                      producto.cantidadMinimaMayorista != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Mayorista: ${formatMoney(producto.precioMayorista!)} '
                      'desde ${producto.cantidadMinimaMayorista} u.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.green.shade800),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    producto.descripcion,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      Chip(
                        label: Text('${producto.stock.toStringAsFixed(0)} en stock'),
                      ),
                      Chip(label: Text(producto.unidadMedida)),
                      if (productor != null)
                        Chip(label: Text('Productor: ${productor!.nombreUsuario}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: showAddButton
                        ? FilledButton.icon(
                            onPressed: onAdd,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Agregar'),
                          )
                        : onTap != null
                            ? OutlinedButton.icon(
                                onPressed: onTap,
                                icon: const Icon(Icons.storefront),
                                label: const Text('Ver productor'),
                              )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
