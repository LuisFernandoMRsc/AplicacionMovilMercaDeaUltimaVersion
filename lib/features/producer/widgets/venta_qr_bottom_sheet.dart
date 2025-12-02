import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/models/venta.dart';

class VentaQrBottomSheet extends StatefulWidget {
  const VentaQrBottomSheet({super.key, required this.venta});

  final VentaModel venta;

  @override
  State<VentaQrBottomSheet> createState() => _VentaQrBottomSheetState();
}

class _VentaQrBottomSheetState extends State<VentaQrBottomSheet> {
  final GlobalKey _qrBoundaryKey = GlobalKey();
  bool _downloading = false;

  String get _qrPayload => widget.venta.id;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'QR de la venta',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Center(
              child: RepaintBoundary(
                key: _qrBoundaryKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _qrPayload,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ID: ${widget.venta.id}\nTransacción: ${widget.venta.numeroTransaccion.isEmpty ? 'No registrada' : widget.venta.numeroTransaccion}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _downloading ? null : _saveQrToGallery,
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_downloading ? 'Guardando...' : 'Descargar QR'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQrToGallery() async {
    final boundary = _qrBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      _showMessage('No se pudo generar la imagen del QR.');
      return;
    }

    try {
      setState(() => _downloading = true);
      final image = await boundary.toImage(pixelRatio: 4);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List bytes = byteData!.buffer.asUint8List();
      final savedPath = await _persistImage(bytes);
      if (savedPath != null) {
        _showMessage('QR guardado en $savedPath');
      } else {
        _showMessage('No se pudo guardar la imagen.');
      }
    } catch (e) {
      _showMessage('Error al guardar el QR: $e');
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<String?> _persistImage(Uint8List bytes) async {
    if (!await _ensurePermissions()) {
      return null;
    }

    Directory? targetDir;

    if (Platform.isAndroid) {
      targetDir = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      targetDir = await getApplicationDocumentsDirectory();
    } else {
      targetDir = await getDownloadsDirectory();
    }

    if (targetDir == null) {
      return null;
    }

    final folder = Directory('${targetDir.path}/qr_ventas');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final fileName = 'venta_${widget.venta.id}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${folder.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }

  Future<bool> _ensurePermissions() async {
    if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();
      return status.isGranted;
    }

    if (await Permission.storage.isGranted) {
      return true;
    }

    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
