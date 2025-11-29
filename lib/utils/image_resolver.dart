import '../config/graphql_config.dart';

Uri getApiBaseUri() {
  final endpoint = GraphQLConfig.endpoint;
  final uri = Uri.parse(endpoint);
  return uri.replace(path: '', query: null, fragment: null);
}

String resolveImageUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  try {
    final baseUri = getApiBaseUri();
    final sanitizedBase = baseUri.toString().replaceAll(RegExp(r'/+$'), '');
    final sanitizedPath = url.startsWith('/') ? url : '/$url';
    return '$sanitizedBase$sanitizedPath';
  } catch (_) {
    return url;
  }
}
