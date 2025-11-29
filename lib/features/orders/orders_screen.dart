import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/venta.dart';
import '../../providers/venta_provider.dart';
import '../../utils/formatters.dart';
import '../common/empty_view.dart';
import '../common/loading_view.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<VentaProvider>().loadVentas());
  }

  Future<void> _refresh() async {
    await context.read<VentaProvider>().loadVentas(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis ventas')),
      body: Consumer<VentaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.ventas.isEmpty) {
            return const LoadingView();
          }

          if (provider.errorMessage != null && provider.ventas.isEmpty) {
            return EmptyView(message: provider.errorMessage!);
          }

          if (provider.ventas.isEmpty) {
            return const EmptyView(message: 'Aún no realizaste compras.');
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.ventas.length,
              itemBuilder: (context, index) {
                final venta = provider.ventas[index];
                final statusColor = _statusColor(venta);
                final statusIcon = _statusIcon(venta);
                final statusLabel = VentaStatus.label(venta.estado);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.15),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    title: Text(formatMoney(venta.montoTotal)),
                    subtitle: Text(
                      '${formatDate(venta.fecha)} • ${venta.detalles.length} ítems',
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
                            const SizedBox(height: 8),
                            Text(
                              'Nro. transacción: ${venta.numeroTransaccion.isEmpty ? 'No registrado' : venta.numeroTransaccion}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade700),
                            ),
                            if ((venta.telefonoComprobador ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Teléfono comprobador: ${venta.telefonoComprobador}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey.shade700),
                                ),
                              ),
                            const SizedBox(height: 8),
                            for (final detalle in venta.detalles)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(detalle.nombreProducto),
                                subtitle: Text('${detalle.cantidad} x ${formatMoney(detalle.precioUnitario)}'),
                                trailing: Text(formatMoney(detalle.subtotal)),
                              ),
                          ],
                        ),
                      )
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
  if (venta.estaDenegada) return Colors.red.shade700;
  if (venta.estaCompletada) return Colors.green.shade700;
  if (venta.estaAceptadaEnRevision) return Colors.blue.shade700;
  return Colors.orange.shade700;
}

IconData _statusIcon(VentaModel venta) {
  if (venta.estaDenegada) return Icons.report;
  if (venta.estaCompletada) return Icons.task_alt;
  if (venta.estaAceptadaEnRevision) return Icons.fact_check;
  return Icons.pending_outlined;
}
