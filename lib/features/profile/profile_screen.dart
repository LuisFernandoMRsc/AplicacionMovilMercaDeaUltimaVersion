import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/venta_provider.dart';
import '../../data/models/usuario.dart';
import '../../utils/validators.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final perfil = auth.perfil;
          if (perfil == null) {
            return const Center(
              child: Text('Inicia sesión para ver tu información.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('${perfil.nombre} ${perfil.apellido}'),
                subtitle: Text(perfil.correo),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: perfil.roles
                    .map((rol) => Chip(label: Text(rol)))
                    .toList(),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(perfil.telefono.isEmpty ? 'Sin teléfono' : perfil.telefono),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: auth.isBusy
                    ? null
                    : () => _showEditarPerfilSheet(context, perfil),
                icon: const Icon(Icons.edit),
                label: const Text('Editar datos'),
              ),
              const SizedBox(height: 16),
              if (!perfil.esProductor)
                FilledButton.icon(
                  onPressed: auth.isBusy
                      ? null
                      : () => _showConvertirProductorSheet(context),
                  icon: const Icon(Icons.storefront),
                  label: const Text('Empezar a vender'),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: auth.isBusy ? null : () => auth.refreshPerfil(),
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar datos'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<CartProvider>().clear();
                  context.read<VentaProvider>().reset();
                  auth.logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditarPerfilSheet(BuildContext context, UsuarioProfile perfil) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditarPerfilSheet(perfil: perfil),
    );
  }

  void _showConvertirProductorSheet(BuildContext context) {
    final direccionCtrl = TextEditingController();
    final nitCtrl = TextEditingController();
    final numeroCuentaCtrl = TextEditingController();
    final bancoCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final auth = ctx.watch<AuthProvider>();
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Convertirme en productor',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: direccionCtrl,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nitCtrl,
                decoration: const InputDecoration(labelText: 'NIT'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numeroCuentaCtrl,
                decoration: const InputDecoration(labelText: 'Número de cuenta'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bancoCtrl,
                decoration: const InputDecoration(labelText: 'Banco'),
              ),
              const SizedBox(height: 8),
              Text(
                'Estos datos bancarios serán visibles para los compradores al confirmar una venta.',
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: auth.isBusy
                    ? null
                    : () async {
                        if (direccionCtrl.text.trim().isEmpty ||
                            nitCtrl.text.trim().isEmpty ||
                            numeroCuentaCtrl.text.trim().isEmpty ||
                            bancoCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Completa todos los campos para continuar.'),
                            ),
                          );
                          return;
                        }
                        final ok = await auth.convertirEnProductor(
                          direccion: direccionCtrl.text.trim(),
                          nit: nitCtrl.text.trim(),
                          numeroCuenta: numeroCuentaCtrl.text.trim(),
                          banco: bancoCtrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        if (ok) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ahora eres productor.'),
                            ),
                          );
                        } else {
                          final message = auth.errorMessage ??
                              'No se pudo completar la solicitud.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        }
                      },
                icon: const Icon(Icons.store_mall_directory),
                label: const Text('Enviar solicitud'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EditarPerfilSheet extends StatefulWidget {
  const _EditarPerfilSheet({required this.perfil});

  final UsuarioProfile perfil;

  @override
  State<_EditarPerfilSheet> createState() => _EditarPerfilSheetState();
}

class _EditarPerfilSheetState extends State<_EditarPerfilSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _telefonoCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.perfil.nombre);
    _apellidoCtrl = TextEditingController(text: widget.perfil.apellido);
    _telefonoCtrl = TextEditingController(text: widget.perfil.telefono);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Editar datos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: Validators.required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apellidoCtrl,
              decoration: const InputDecoration(labelText: 'Apellido'),
              validator: Validators.required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoCtrl,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: auth.isBusy ? null : () => _onSubmit(context, auth),
              icon: const Icon(Icons.save_alt),
              label: Text(auth.isBusy ? 'Guardando...' : 'Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit(BuildContext outerContext, AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await auth.actualizarPerfil(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(outerContext).showSnackBar(
        const SnackBar(content: Text('Datos actualizados correctamente.')),
      );
    } else {
      final message = auth.errorMessage ?? 'No se pudo actualizar la información.';
      ScaffoldMessenger.of(outerContext).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
