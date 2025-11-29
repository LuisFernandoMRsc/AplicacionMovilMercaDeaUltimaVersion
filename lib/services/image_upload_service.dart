import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/graphql_service.dart';
import '../core/token_storage.dart';
import '../utils/image_resolver.dart';

class ImageUploadService {
  ImageUploadService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;

  Future<List<String>> uploadImages(List<File> files) async {
    if (files.isEmpty) return const [];

    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw GraphQLFailure('Debes iniciar sesión para subir imágenes.');
    }

    final baseUri = getApiBaseUri();
    final uri = baseUri.replace(path: '/api/Imagenes/agregar');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token';

    for (final file in files) {
      final path = file.path;
      if (path.isEmpty) continue;
      request.files.add(await http.MultipartFile.fromPath('archivos', path));
    }

    final streamedResponse = await request.send();
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final urls = decoded['imagenes'] as List<dynamic>?;
      if (urls == null) return const [];
      return urls.map((e) => e.toString()).toList();
    }

    throw GraphQLFailure(
      'Error al subir imágenes (${streamedResponse.statusCode}). ${body.isNotEmpty ? body : 'Respuesta vacía'}',
    );
  }
}
