import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/venta_provider.dart';
import '../cart/cart_screen.dart';
import '../catalog/product_list_screen.dart';
import '../orders/orders_screen.dart';
import '../producer/mis_productos_screen.dart';
import '../producer/ventas_productor_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final esProductor = context.watch<AuthProvider>().perfil?.esProductor ?? false;
    final pages = [
      const ProductListScreen(),
      const CartScreen(),
      const OrdersScreen(),
      if (esProductor) const MisProductosScreen(),
      if (esProductor) const VentasProductorScreen(),
      const ProfileScreen(),
    ];

    final ventasTabIndex = esProductor
        ? pages.indexWhere((page) => page is VentasProductorScreen)
        : -1;

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront),
        label: 'Productos',
      ),
      const NavigationDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart),
        label: 'Carrito',
      ),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Mis compras',
      ),
      if (esProductor)
        const NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Mis productos',
        ),
      if (esProductor)
        const NavigationDestination(
          icon: Icon(Icons.fact_check_outlined),
          selectedIcon: Icon(Icons.fact_check),
          label: 'Ventas recibidas',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    if (_index >= pages.length) {
      _index = pages.length - 1;
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          if (ventasTabIndex >= 0 && value == ventasTabIndex) {
            context
                .read<VentaProvider>()
                .loadVentasProductor(refresh: true);
          }
          setState(() => _index = value);
        },
        destinations: destinations,
      ),
    );
  }
}
