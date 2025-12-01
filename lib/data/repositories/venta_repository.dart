import '../../core/graphql_service.dart';
import '../models/venta.dart';

class VentaRepository {
  VentaRepository(this._service);

  final GraphQLService _service;

  Future<List<VentaModel>> fetchMisVentas() async {
    const query = r'''
      query MisVentas {
        ventasPorComprador {
          id
          productorId
          comprobadorId
          fecha
          montoTotal
          numeroTransaccion
          estado
          telefonoComprobador
          detalles {
            productoId
            nombreProducto
            cantidad
            precioUnitario
            subtotal
          }
        }
      }
    ''';

    final result = await _service.query(document: query);
    final ventas = result.data?['ventasPorComprador'] as List<dynamic>? ?? const [];
    return ventas
        .map((e) => VentaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VentaModel> crearVenta({
    required String productorId,
    required String numeroTransaccion,
    required List<Map<String, dynamic>> detalles,
  }) async {
    const mutation = r'''
      mutation CrearVenta($input: CrearVentaInput!) {
        crearVenta(input: $input) {
          id
          productorId
          comprobadorId
          fecha
          montoTotal
          numeroTransaccion
          estado
          telefonoComprobador
          detalles {
            productoId
            nombreProducto
            cantidad
            precioUnitario
            subtotal
          }
        }
      }
    ''';

    final result = await _service.mutate(
      document: mutation,
      variables: {
        'input': {
          'productorId': productorId,
          'numeroTransaccion': numeroTransaccion,
          'detalles': detalles,
        },
      },
    );

    final data = result.data?['crearVenta'] as Map<String, dynamic>?;
    if (data == null) {
      throw GraphQLFailure('No se recibió la venta generada.');
    }

    return VentaModel.fromJson(data);
  }

  Future<List<VentaModel>> fetchVentasProductor() async {
    const query = r'''
      query VentasProductor {
        ventasPorProductor {
          id
          usuarioId
          productorId
          comprobadorId
          fecha
          montoTotal
          numeroTransaccion
          estado
          telefonoComprobador
          detalles {
            productoId
            nombreProducto
            cantidad
            precioUnitario
            subtotal
          }
        }
      }
    ''';

    final result = await _service.query(document: query);
    final ventas = result.data?['ventasPorProductor'] as List<dynamic>? ?? const [];
    return ventas
        .map((e) => VentaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> aceptarVenta({
    required String ventaId,
  }) async {
    const mutation = r'''
      mutation AceptarVenta($idVenta: String!) {
        aceptarVenta(idVenta: $idVenta) {
          id
          estado
        }
      }
    ''';

    await _service.mutate(
      document: mutation,
      variables: {
        'idVenta': ventaId,
      },
    );
  }

  Future<void> denegarVentaProductor({
    required String ventaId,
  }) async {
    const mutation = r'''
      mutation DenegarVentaProductor($idVenta: String!) {
        denegarVentaProductor(idVenta: $idVenta) {
          id
          estado
        }
      }
    ''';

    await _service.mutate(
      document: mutation,
      variables: {
        'idVenta': ventaId,
      },
    );
  }

  Future<void> confirmarVenta({
    required String ventaId,
  }) async {
    const mutation = r'''
      mutation ConfirmarVenta($idVenta: String!) {
        confirmarVenta(idVenta: $idVenta) {
          id
          estado
        }
      }
    ''';

    await _service.mutate(
      document: mutation,
      variables: {
        'idVenta': ventaId,
      },
    );
  }
}
