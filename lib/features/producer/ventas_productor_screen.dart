import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/venta.dart';
import '../../providers/venta_provider.dart';
import '../../utils/formatters.dart';
import '../common/empty_view.dart';
import '../common/loading_view.dart';

class VentasProductorScreen extends StatefulWidget {
  const VentasProductorScreen({super.key});

  @override
  State<VentasProductorScreen> createState() => _VentasProductorScreenState();
}

class _VentasProductorScreenState extends State<VentasProductorScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<VentaProvider>().loadVentasProductor());
  }

  Future<void> _refresh() async {
    await context.read<VentaProvider>().loadVentasProductor(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas recibidas')),
      body: Consumer<VentaProvider>(
        builder: (context, ventasProvider, _) {
          if (ventasProvider.isLoadingProductor &&
              ventasProvider.ventasProductor.isEmpty) {
            return const LoadingView();
          }

          if (ventasProvider.errorProductor != null &&
              ventasProvider.ventasProductor.isEmpty) {
            return EmptyView(message: ventasProvider.errorProductor!);
          }

          if (ventasProvider.ventasProductor.isEmpty) {
            return const EmptyView(message: 'Aún no recibiste ventas.');
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: ventasProvider.ventasProductor.length,
              itemBuilder: (context, index) {
                final venta = ventasProvider.ventasProductor[index];
                final statusColor = _statusColor(venta);
                final statusIcon = _statusIcon(venta);
                final statusLabel = VentaStatus.label(venta.estado);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    title: Text(formatMoney(venta.montoTotal)),
                    subtitle: Text('Fecha: ${formatDate(venta.fecha)}'),
                    trailing: venta.estaSolicitada
                        ? FilledButton(
                            onPressed: ventasProvider.isLoadingProductor
                                ? null
                                : () => ventasProvider.aceptarVenta(venta.id),
                            child: const Text('Aceptar'),
                          )
                        : Chip(
                            label: Text(statusLabel),
                            avatar: Icon(statusIcon, color: statusColor, size: 18),
                            backgroundColor: statusColor.withOpacity(0.15),
                          ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusLabel,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Nro. transacción: ${venta.numeroTransaccion.isEmpty ? 'No registrado' : venta.numeroTransaccion}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Detalle de productos',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...venta.detalles.map(
                              (detalle) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(detalle.nombreProducto),
                                subtitle: Text(
                                  '${detalle.cantidad} x ${formatMoney(detalle.precioUnitario)}',
                                ),
                                trailing: Text(formatMoney(detalle.subtotal)),
                              ),
                            ),
                            const Divider(),
                            Text('Total: ${formatMoney(venta.montoTotal)}'),
                          ],
                        ),
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

Color _statusColor(VentaModel venta) {
  if (venta.estaCompletada) return Colors.green.shade700;
  if (venta.estaAceptadaEnRevision) return Colors.blue.shade700;
  return Colors.orange.shade700;
}

IconData _statusIcon(VentaModel venta) {
  if (venta.estaCompletada) return Icons.task_alt;
  if (venta.estaAceptadaEnRevision) return Icons.fact_check;
  return Icons.schedule;
}
