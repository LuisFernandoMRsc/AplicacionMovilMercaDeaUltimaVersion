import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/graphql_service.dart';
import '../../data/models/producto_input.dart';
import '../../providers/catalog_provider.dart';
import '../../services/image_upload_service.dart';
import '../../utils/validators.dart';

class CrearProductoScreen extends StatefulWidget {
  const CrearProductoScreen({super.key});

  @override
  State<CrearProductoScreen> createState() => _CrearProductoScreenState();
}

class _CrearProductoScreenState extends State<CrearProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _precioMayoristaCtrl = TextEditingController();
  final _cantidadMayoristaCtrl = TextEditingController();
  final _unidadCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _atributosCtrl = TextEditingController();
  final _imageUploadService = ImageUploadService();
  final List<PlatformFile> _imagenes = [];
  bool _uploadingImages = false;

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

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null) return;

    final selected = result.files.where((file) => file.path != null).toList();
    final limited = selected.take(4).toList();

    if (selected.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo puedes seleccionar hasta 4 imágenes.')),
      );
    }

    setState(() {
      _imagenes
        ..clear()
        ..addAll(limited);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una imagen.')),
      );
      return;
    }

    final files = _imagenes
        .where((file) => file.path != null && file.path!.isNotEmpty)
        .map((file) => File(file.path!))
        .toList();
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo acceder a los archivos seleccionados.')),
      );
      return;
    }

    setState(() => _uploadingImages = true);
    List<String> uploadedUrls = const [];
    try {
      uploadedUrls = await _imageUploadService.uploadImages(files);
    } on GraphQLFailure catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } on Exception catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al subir imágenes: $e')));
    } finally {
      setState(() => _uploadingImages = false);
    }

    if (uploadedUrls.isEmpty) return;

    final precioMayoristaText = _precioMayoristaCtrl.text.trim();
    final cantidadMayoristaText = _cantidadMayoristaCtrl.text.trim();
    if ((precioMayoristaText.isEmpty && cantidadMayoristaText.isNotEmpty) ||
        (precioMayoristaText.isNotEmpty && cantidadMayoristaText.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa precio y cantidad mínima para ofertar un precio mayorista.',
          ),
        ),
      );
      return;
    }

    final catalog = context.read<CatalogProvider>();
    final input = ProductoInput(
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      precioActual: double.parse(_precioCtrl.text.trim()),
      precioMayorista:
          precioMayoristaText.isEmpty ? null : double.parse(precioMayoristaText),
      cantidadMinimaMayorista: cantidadMayoristaText.isEmpty
          ? null
          : int.parse(cantidadMayoristaText),
      unidadMedida: _unidadCtrl.text.trim(),
      categoria: _categoriaCtrl.text.trim(),
      stock: double.parse(_stockCtrl.text.trim()),
      atributos: _atributosCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      imagenes: uploadedUrls,
    );

    final ok = await catalog.crearProducto(input);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto creado exitosamente.')),
      );
      Navigator.of(context).pop();
    } else {
      final error = catalog.createError ?? 'No fue posible crear el producto.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar producto')),
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
                const SizedBox(height: 12),
                Text(
                  'Imágenes del producto',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Máximo 4 fotos. Solo se mostrarán hasta cuatro en la app.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _uploadingImages ? null : _pickImages,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Seleccionar imágenes'),
                ),
                const SizedBox(height: 8),
                if (_imagenes.isEmpty)
                  const Text('Aún no seleccionaste imágenes.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final file in _imagenes)
                        Chip(
                          label: Text(file.name),
                          onDeleted: _uploadingImages
                              ? null
                              : () {
                                  setState(() {
                                    _imagenes.remove(file);
                                  });
                                },
                        ),
                    ],
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed:
                      (catalog.isCreatingProduct || _uploadingImages) ? null : _submit,
                  icon: const Icon(Icons.save_alt),
                  label: Text(
                    catalog.isCreatingProduct
                        ? 'Guardando...'
                        : _uploadingImages
                            ? 'Subiendo imágenes...'
                            : 'Crear producto',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
