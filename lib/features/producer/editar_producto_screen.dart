import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/producto.dart';
import '../../data/models/producto_input.dart';
import '../../providers/catalog_provider.dart';
import '../../utils/image_resolver.dart';
import '../../utils/validators.dart';

class EditarProductoScreen extends StatefulWidget {
  const EditarProductoScreen({super.key, required this.producto});

  final Producto producto;

  @override
  State<EditarProductoScreen> createState() => _EditarProductoScreenState();
}

class _EditarProductoScreenState extends State<EditarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _precioMayoristaCtrl;
  late final TextEditingController _cantidadMayoristaCtrl;
  late final TextEditingController _unidadCtrl;
  late final TextEditingController _categoriaCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _atributosCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreCtrl = TextEditingController(text: p.nombre);
    _descripcionCtrl = TextEditingController(text: p.descripcion);
    _precioCtrl = TextEditingController(text: p.precioActual.toStringAsFixed(2));
    _precioMayoristaCtrl = TextEditingController(
      text: p.precioMayorista?.toStringAsFixed(2) ?? '',
    );
    _cantidadMayoristaCtrl = TextEditingController(
      text: p.cantidadMinimaMayorista?.toString() ?? '',
    );
    _unidadCtrl = TextEditingController(text: p.unidadMedida);
    _categoriaCtrl = TextEditingController(text: p.categoria);
    _stockCtrl = TextEditingController(text: p.stock.toStringAsFixed(0));
    _atributosCtrl = TextEditingController(text: p.atributos.join(', '));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _precioMayoristaCtrl.dispose();
    _cantidadMayoristaCtrl.dispose();
    _unidadCtrl.dispose();
    _categoriaCtrl.dispose();
    _stockCtrl.dispose();
    _atributosCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final provider = context.read<CatalogProvider>();

    final mayoristaPrecioText = _precioMayoristaCtrl.text.trim();
    final mayoristaCantidadText = _cantidadMayoristaCtrl.text.trim();
    if ((mayoristaPrecioText.isEmpty && mayoristaCantidadText.isNotEmpty) ||
        (mayoristaPrecioText.isNotEmpty && mayoristaCantidadText.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa precio y cantidad mínima para ofertar precio mayorista.',
          ),
        ),
      );
      setState(() => _submitting = false);
      return;
    }

    final input = ProductoInput(
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      precioActual: double.parse(_precioCtrl.text.trim()),
      precioMayorista:
          mayoristaPrecioText.isEmpty ? null : double.parse(mayoristaPrecioText),
      cantidadMinimaMayorista: mayoristaCantidadText.isEmpty
          ? null
          : int.parse(mayoristaCantidadText),
      unidadMedida: _unidadCtrl.text.trim(),
      categoria: _categoriaCtrl.text.trim(),
      stock: double.parse(_stockCtrl.text.trim()),
      atributos: _atributosCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
        imagenes: List<String>.from(widget.producto.imagenes),
    );

    final ok = await provider.editarProducto(widget.producto.id, input);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado.')),
      );
    } else {
      final error = provider.createError ?? 'No fue posible actualizar el producto.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar producto')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: Validators.required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3,
                  validator: Validators.required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _precioCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio (Bs)'),
                  validator: Validators.decimal,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _precioMayoristaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Precio mayorista (opcional)',
                  ),
                  validator: Validators.optionalDecimal,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cantidadMayoristaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad mínima mayorista (opcional)',
                  ),
                  validator: Validators.optionalPositiveInt,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unidadCtrl,
                  decoration: const InputDecoration(labelText: 'Unidad de medida'),
                  validator: Validators.required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoriaCtrl,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  validator: Validators.required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock disponible'),
                  validator: Validators.decimal,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _atributosCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Atributos (separados por coma)',
                  ),
                ),
                const SizedBox(height: 12),
                _ImagenesActualesSection(imagenes: widget.producto.imagenes),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.save),
                  label: Text(_submitting ? 'Guardando...' : 'Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagenesActualesSection extends StatelessWidget {
  const _ImagenesActualesSection({required this.imagenes});

  final List<String> imagenes;

  @override
  Widget build(BuildContext context) {
    final visibles = imagenes.take(4).toList();
    final restante = imagenes.length - visibles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imágenes registradas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (visibles.isEmpty)
          const Text('Este producto aún no tiene imágenes cargadas.')
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: visibles
                .map(
                  (url) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      resolveImageUrl(url),
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 24),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        if (restante > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Solo se muestran 4 de ${imagenes.length} imágenes.'),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Las fotos existentes no se pueden editar. Para actualizarlas elimina el producto y créalo nuevamente.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
