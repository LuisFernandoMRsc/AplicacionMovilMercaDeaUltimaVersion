import '../../core/graphql_service.dart';
import '../models/comprobador.dart';
import '../models/producto.dart';
import '../models/producto_input.dart';
import '../models/productor.dart';

class CatalogRepository {
  CatalogRepository(this._service);

  final GraphQLService _service;

  Future<CatalogData> fetchCatalog() async {
    const query = r'''
      query Catalogo {
        productos {
          id
          nombre
          descripcion
          precioActual
          precioMayorista
          cantidadMinimaMayorista
          unidadMedida
          categoria
          atributos
          imagenes
          productorId
          stock
        }
        productores {
          id
          idUsuario
          nombreUsuario
          direccion
          nit
          numeroCuenta
          banco
        }
      }
    ''';

    final result = await _service.query(document: query);
    final productosJson = result.data?['productos'] as List<dynamic>? ?? const [];
    final productoresJson = result.data?['productores'] as List<dynamic>? ?? const [];

    final productos = productosJson
        .map((e) => Producto.fromJson(e as Map<String, dynamic>))
        .toList();

    final productores = productoresJson
        .map((e) => ProductorModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return CatalogData(productos: productos, productores: productores);
  }

  Future<List<ComprobadorModel>> fetchComprobadores() async {
    const query = r'''
      query Comprobadores {
        comprobador {
          id
          nombreUsuario
          estaDisponible
          cuposDisponibles
        }
      }
    ''';

    final result = await _service.query(document: query);
    final data = result.data?['comprobador'] as List<dynamic>? ?? const [];
    return data
        .map((e) => ComprobadorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Producto> crearProducto(ProductoInput input) async {
    const mutation = r'''
      mutation CrearProducto($input: CrearProductoInput!) {
        crearProducto(input: $input) {
          id
          nombre
          descripcion
          precioActual
          precioMayorista
          cantidadMinimaMayorista
          unidadMedida
          categoria
          atributos
          imagenes
          productorId
          stock
        }
      }
    ''';

    final result = await _service.mutate(
      document: mutation,
      variables: {'input': input.toJson()},
    );

    final data = result.data?['crearProducto'] as Map<String, dynamic>?;
    if (data == null) {
      throw GraphQLFailure('No fue posible crear el producto.');
    }

    return Producto.fromJson(data);
  }

  Future<Producto> editarProducto(String productoId, ProductoInput input) async {
    const mutation = r'''
      mutation EditarProducto($productoId: String!, $input: CrearProductoInput!) {
        editarProducto(productoId: $productoId, input: $input) {
          id
          nombre
          descripcion
          precioActual
          precioMayorista
          cantidadMinimaMayorista
          unidadMedida
          categoria
          atributos
          imagenes
          productorId
          stock
        }
      }
    ''';

    final result = await _service.mutate(
      document: mutation,
      variables: {
        'productoId': productoId,
        'input': input.toJson(),
      },
    );

    final data = result.data?['editarProducto'] as Map<String, dynamic>?;
    if (data == null) {
      throw GraphQLFailure('No fue posible actualizar el producto.');
    }

    return Producto.fromJson(data);
  }

  Future<bool> eliminarProducto(String productoId) async {
    const mutation = r'''
      mutation EliminarProducto($productoId: String!) {
        eliminarProducto(productoId: $productoId)
      }
    ''';

    final result = await _service.mutate(
      document: mutation,
      variables: {'productoId': productoId},
    );

    final deleted = result.data?['eliminarProducto'] as bool?;
    if (deleted == null) {
      throw GraphQLFailure('El servidor no respondió a la eliminación.');
    }

    return deleted;
  }
}

class CatalogData {
  CatalogData({required this.productos, required this.productores});

  final List<Producto> productos;
  final List<ProductorModel> productores;
}
