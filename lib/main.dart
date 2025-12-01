import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/graphql_service.dart';
import 'core/token_storage.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/repositories/venta_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/venta_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final graphQLService = GraphQLService(tokenStorage: tokenStorage);

  final authRepository = AuthRepository(graphQLService, tokenStorage);
  final catalogRepository = CatalogRepository(graphQLService);
  final ventaRepository = VentaRepository(graphQLService);

  runApp(
    _AppScope(
      authRepository: authRepository,
      catalogRepository: catalogRepository,
      ventaRepository: ventaRepository,
    ),
  );
}

class _AppScope extends StatelessWidget {
  const _AppScope({
    required this.authRepository,
    required this.catalogRepository,
    required this.ventaRepository,
  });

  final AuthRepository authRepository;
  final CatalogRepository catalogRepository;
  final VentaRepository ventaRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => CatalogProvider(catalogRepository)),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => VentaProvider(ventaRepository),
        ),
      ],
      child: const MercaDeaApp(),
    );
  }
}
